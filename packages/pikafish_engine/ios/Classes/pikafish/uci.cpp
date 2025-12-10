/*
  Stockfish, a UCI chess playing engine derived from Glaurung 2.1
  Copyright (C) 2004-2025 The Stockfish developers (see AUTHORS file)

  (Giữ nguyên License Header của Pikafish/Stockfish)
*/

#include "uci.h"

#include <algorithm>
#include <cmath>
#include <functional>
#include <iterator>
#include <optional>
#include <sstream>
#include <string_view>
#include <utility>
#include <vector>

// --- THÊM: THƯ VIỆN CHO IOS BRIDGE ---
#include <atomic>
#include <mutex>
#include <condition_variable>
#include <deque>
// -------------------------------------

#include "benchmark.h"
#include "engine.h"
#include "memory.h"
#include "movegen.h"
#include "position.h"
#include "score.h"
#include "search.h"
#include "types.h"
#include "ucioption.h"

// ----------------------------------------------------------------------------
// PHẦN CẦU NỐI IOS (IOS BRIDGE SECTION)
// ----------------------------------------------------------------------------

// Hàm gửi dữ liệu về Dart (được cài đặt trong ios_bridge.mm)
extern "C" void write_to_dart_buffer(const char* cstr);

// Cấu trúc hàng đợi lệnh an toàn luồng
static std::deque<std::string> ios_command_queue;
static std::mutex ios_command_mutex;
static std::condition_variable ios_command_cv;
static std::atomic<bool> ios_engine_running{false};

// Hàm nội bộ: Gửi string về Dart (thay thế cho sync_cout)
static void ios_post_output(const std::string& msg) {
    if (msg.empty()) return;
    // Gọi sang Objective-C++
    write_to_dart_buffer(msg.c_str());
}

// Hàm nhận lệnh từ Dart (được gọi từ ios_bridge.mm)
extern "C" void uci_inject_command(const char* cmd) {
    if (cmd == nullptr) return;
    {
        std::lock_guard<std::mutex> lock(ios_command_mutex);
        ios_command_queue.emplace_back(std::string(cmd));
    }
    ios_command_cv.notify_one();
}
// ----------------------------------------------------------------------------


namespace Stockfish {

constexpr auto BenchmarkCommand = "speedtest";

constexpr auto StartFEN = "rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w";

template<typename... Ts>
struct overload: Ts... {
    using Ts::operator()...;
};

template<typename... Ts>
overload(Ts...) -> overload<Ts...>;

// MODIFIED: Chuyển hướng output sang iOS Bridge
void UCIEngine::print_info_string(std::string_view str) {
    for (auto& line : split(str, "\n"))
    {
        if (!is_whitespace(line))
        {
            // Fix lỗi Xcode: Ép kiểu string_view sang string tường minh
            std::string lineStr = std::string(line); 
            std::string out = "info string " + lineStr;
            ios_post_output(out);
        }
    }
}

UCIEngine::UCIEngine(int argc, char** argv) :
    engine(argv[0]),
    cli(argc, argv) {

    engine.get_options().add_info_listener([this](const std::optional<std::string>& str) {
        if (str.has_value())
            this->print_info_string(*str);
    });

    init_search_update_listeners();
}

void UCIEngine::init_search_update_listeners() {
    engine.set_on_iter([this](const auto& i) { this->on_iter(i); });
    engine.set_on_update_no_moves([this](const auto& i) { this->on_update_no_moves(i); });
    engine.set_on_update_full(
      [this](const auto& i) { this->on_update_full(i, engine.get_options()["UCI_ShowWDL"]); });
    engine.set_on_bestmove([this](const auto& bm, const auto& p) { this->on_bestmove(bm, p); });
    engine.set_on_verify_networks([this](const auto& s) { this->print_info_string(s); });
}

// MODIFIED: Vòng lặp chính xử lý lệnh (đã sửa để nhận lệnh từ Queue)
void UCIEngine::loop() {
    std::string token, cmd;

    for (int i = 1; i < cli.argc; ++i)
        cmd += std::string(cli.argv[i]) + " ";

    // Đánh dấu engine bắt đầu chạy
    ios_engine_running.store(true);

    do
    {
        // Nếu không có tham số dòng lệnh (chạy mode thư viện), chờ lệnh từ App
        if (cli.argc == 1) {
            std::unique_lock<std::mutex> lock(ios_command_mutex);
            ios_command_cv.wait(lock, [] {
                return !ios_command_queue.empty() || !ios_engine_running.load();
            });

            if (!ios_engine_running.load()) break;

            cmd = std::move(ios_command_queue.front());
            ios_command_queue.pop_front();
        }

        std::istringstream is(cmd);

        token.clear();
        is >> std::skipws >> token;

        if (token == "quit" || token == "stop")
            engine.stop();

        else if (token == "ponderhit")
            engine.set_ponderhit(false);

        else if (token == "uci")
        {
            std::stringstream ss;
            ss << "id name " << engine_info(true) << "\n"
               << engine.get_options();
            ios_post_output(ss.str());
            ios_post_output("uciok");
        }

        else if (token == "setoption")
            setoption(is);
        else if (token == "go")
        {
            // send info strings after the go command is sent for old GUIs and python-chess
            print_info_string(engine.numa_config_information_as_string());
            print_info_string(engine.thread_allocation_information_as_string());
            go(is);
        }
        else if (token == "position")
            position(is);
        else if (token == "fen" || token == "startpos")
            is.seekg(0), position(is);
        else if (token == "ucinewgame")
            engine.search_clear();
        else if (token == "isready")
            ios_post_output("readyok");

        // Add custom non-UCI commands, mainly for debugging purposes.
        else if (token == "flip")
            engine.flip();
        else if (token == "bench")
            bench(is);
        else if (token == BenchmarkCommand)
            benchmark(is);
        else if (token == "d")
            ios_post_output(engine.visualize());
        else if (token == "eval")
            engine.trace_eval();
        else if (token == "compiler")
            ios_post_output(compiler_info());
        else if (token == "export_net")
        {
            std::pair<std::optional<std::string>, std::string> files;
            if (is >> std::skipws >> files.second)
                files.first = files.second;
            engine.save_network(files);
        }
        else if (token == "--help" || token == "help" || token == "--license" || token == "license") {
             // In thông báo help qua bridge
             std::stringstream ss;
             ss << "\nStockfish/Pikafish is a powerful chess engine..."
                << "\nSee https://github.com/official-stockfish/Stockfish";
             ios_post_output(ss.str());
        }
        else if (!token.empty() && token[0] != '#') {
            std::string err = "Unknown command: '" + cmd + "'. Type help for more information.";
            ios_post_output(err);
        }
        
        // Xóa cmd để tránh lặp lại vòng lặp
        if (cli.argc == 1) cmd.clear();

    } while (token != "quit" && cli.argc == 1);
    
    // Dọn dẹp khi thoát
    ios_engine_running.store(false);
    ios_command_cv.notify_all();
}

Search::LimitsType UCIEngine::parse_limits(std::istream& is) {
    Search::LimitsType limits;
    std::string        token;

    limits.startTime = now();

    while (is >> token)
        if (token == "searchmoves")
            while (is >> token)
                limits.searchmoves.push_back(token);

        else if (token == "wtime")
            is >> limits.time[WHITE];
        else if (token == "btime")
            is >> limits.time[BLACK];
        else if (token == "winc")
            is >> limits.inc[WHITE];
        else if (token == "binc")
            is >> limits.inc[BLACK];
        else if (token == "movestogo")
            is >> limits.movestogo;
        else if (token == "depth")
            is >> limits.depth;
        else if (token == "nodes")
            is >> limits.nodes;
        else if (token == "movetime")
            is >> limits.movetime;
        else if (token == "mate")
            is >> limits.mate;
        else if (token == "perft")
            is >> limits.perft;
        else if (token == "infinite")
            limits.infinite = 1;
        else if (token == "ponder")
            limits.ponderMode = true;

    return limits;
}

void UCIEngine::go(std::istringstream& is) {

    Search::LimitsType limits = parse_limits(is);

    if (limits.perft)
        perft(limits);
    else
        engine.go(limits);
}

// MODIFIED: Giữ nguyên logic Bench gốc, chỉ thay đổi Output cuối cùng
void UCIEngine::bench(std::istream& args) {
    std::string token;
    uint64_t    num, nodes = 0, cnt = 1;
    uint64_t    nodesSearched = 0;
    const auto& options       = engine.get_options();

    engine.set_on_update_full([&](const auto& i) {
        nodesSearched = i.nodes;
        on_update_full(i, options["UCI_ShowWDL"]);
    });

    std::vector<std::string> list = Benchmark::setup_bench(engine.fen(), args);

    num = count_if(list.begin(), list.end(),
                   [](const std::string& s) { return s.find("go ") == 0 || s.find("eval") == 0; });

    TimePoint elapsed = now();

    for (const auto& cmd : list)
    {
        std::istringstream is(cmd);
        is >> std::skipws >> token;

        if (token == "go" || token == "eval")
        {
            // Thay thế std::cerr bằng ios_post_output để báo tiến độ
            {
                std::stringstream ss;
                ss << "\nPosition: " << cnt++ << '/' << num << " (" << engine.fen() << ")";
                ios_post_output(ss.str());
            }

            if (token == "go")
            {
                Search::LimitsType limits = parse_limits(is);
                if (limits.perft)
                    nodesSearched = perft(limits);
                else
                {
                    engine.go(limits);
                    engine.wait_for_search_finished();
                }
                nodes += nodesSearched;
                nodesSearched = 0;
            }
            else
                engine.trace_eval();
        }
        else if (token == "setoption")
            setoption(is);
        else if (token == "position")
            position(is);
        else if (token == "ucinewgame")
        {
            engine.search_clear();
            elapsed = now();
        }
    }

    elapsed = now() - elapsed + 1;

    // dbg_print(); 

    // MODIFIED: Gửi kết quả tổng hợp về App
    {
        std::stringstream ss;
        ss << "\n==========================="
           << "\nTotal time (ms) : " << elapsed
           << "\nNodes searched  : " << nodes
           << "\nNodes/second    : " << 1000 * nodes / elapsed;
        ios_post_output(ss.str());
    }

    engine.set_on_update_full([&](const auto& i) { on_update_full(i, options["UCI_ShowWDL"]); });
}

// MODIFIED: Giữ nguyên logic Benchmark gốc
void UCIEngine::benchmark(std::istream& args) {
    static constexpr int NUM_WARMUP_POSITIONS = 3;

    std::string token;
    uint64_t    nodes = 0, cnt = 1;
    uint64_t    nodesSearched = 0;

    engine.set_on_update_full([&](const Engine::InfoFull& i) { nodesSearched = i.nodes; });

    // Tắt các callback output khác để đỡ ồn khi benchmark
    engine.set_on_iter([](const auto&) {});
    engine.set_on_update_no_moves([](const auto&) {});
    engine.set_on_bestmove([](const auto&, const auto&) {});
    engine.set_on_verify_networks([](const auto&) {});

    Benchmark::BenchmarkSetup setup = Benchmark::setup_benchmark(args);

    const int numGoCommands = count_if(setup.commands.begin(), setup.commands.end(),
                                       [](const std::string& s) { return s.find("go ") == 0; });

    TimePoint totalTime = 0;

    // Set options once at the start.
    {
        auto ss = std::istringstream("name Threads value " + std::to_string(setup.threads));
        setoption(ss);
    }
    {
        auto ss = std::istringstream("name Hash value " + std::to_string(setup.ttSize));
        setoption(ss);
    }

    // Warmup
    for (const auto& cmd : setup.commands)
    {
        std::istringstream is(cmd);
        is >> std::skipws >> token;

        if (token == "go")
        {
            // Report Warmup progress
            {
                std::stringstream ss;
                ss << "\rWarmup position " << cnt++ << '/' << NUM_WARMUP_POSITIONS;
                ios_post_output(ss.str());
            }

            Search::LimitsType limits = parse_limits(is);

            TimePoint elapsed = now();

            engine.go(limits);
            engine.wait_for_search_finished();

            totalTime += now() - elapsed;

            nodes += nodesSearched;
            nodesSearched = 0;
        }
        else if (token == "position")
            position(is);
        else if (token == "ucinewgame")
        {
            engine.search_clear();
        }

        if (cnt > NUM_WARMUP_POSITIONS)
            break;
    }

    ios_post_output("\n"); // Newline

    cnt   = 1;
    nodes = 0;

    int numHashfullReadings                    = 0;
    constexpr int hashfullAges[]               = {0, 999};
    int           totalHashfull[std::size(hashfullAges)] = {0};
    int           maxHashfull[std::size(hashfullAges)]   = {0};

    auto updateHashfullReadings = [&]() {
        numHashfullReadings += 1;
        for (int i = 0; i < static_cast<int>(std::size(hashfullAges)); ++i)
        {
            const int hashfull = engine.get_hashfull(hashfullAges[i]);
            maxHashfull[i]     = std::max(maxHashfull[i], hashfull);
            totalHashfull[i] += hashfull;
        }
    };

    engine.search_clear();

    for (const auto& cmd : setup.commands)
    {
        std::istringstream is(cmd);
        is >> std::skipws >> token;

        if (token == "go")
        {
            // Report Progress
            {
                std::stringstream ss;
                ss << "\rPosition " << cnt++ << '/' << numGoCommands;
                ios_post_output(ss.str());
            }

            Search::LimitsType limits = parse_limits(is);

            TimePoint elapsed = now();

            engine.go(limits);
            engine.wait_for_search_finished();

            totalTime += now() - elapsed;

            updateHashfullReadings();

            nodes += nodesSearched;
            nodesSearched = 0;
        }
        else if (token == "position")
            position(is);
        else if (token == "ucinewgame")
        {
            engine.search_clear();
        }
    }

    totalTime = std::max<TimePoint>(totalTime, 1);

    dbg_print();

    ios_post_output("\n");

    static_assert(std::size(hashfullAges) == 2 && hashfullAges[0] == 0 && hashfullAges[1] == 999,
                  "Hardcoded for display.");

    std::string threadBinding = engine.thread_binding_information_as_string();
    if (threadBinding.empty())
        threadBinding = "none";
    
    // Final Report
    {
        std::stringstream ss;
        ss << "==========================="
           << "\nVersion                    : " << engine_version_info()
           << "\n" << compiler_info()
           << "Large pages                : " << (has_large_pages() ? "yes" : "no")
           << "\nUser invocation            : " << BenchmarkCommand << " " << setup.originalInvocation
           << "\nFilled invocation          : " << BenchmarkCommand << " " << setup.filledInvocation
           << "\nAvailable processors       : " << engine.get_numa_config_as_string()
           << "\nThread count               : " << setup.threads
           << "\nThread binding             : " << threadBinding
           << "\nTT size [MiB]              : " << setup.ttSize
           << "\nHash max, avg [per mille]  : "
           << "\n    single search          : " << maxHashfull[0] << ", " << totalHashfull[0] / numHashfullReadings
           << "\n    single game            : " << maxHashfull[1] << ", " << totalHashfull[1] / numHashfullReadings
           << "\nTotal nodes searched       : " << nodes
           << "\nTotal search time [s]      : " << totalTime / 1000.0
           << "\nNodes/second               : " << 1000 * nodes / totalTime;
        ios_post_output(ss.str());
    }

    init_search_update_listeners();
}

void UCIEngine::setoption(std::istringstream& is) {
    engine.wait_for_search_finished();
    engine.get_options().setoption(is);
}

std::uint64_t UCIEngine::perft(const Search::LimitsType& limits) {
    auto nodes = engine.perft(engine.fen(), limits.perft);
    // Report perft result
    {
        std::stringstream ss;
        ss << "\nNodes searched: " << nodes;
        ios_post_output(ss.str());
    }
    return nodes;
}

void UCIEngine::position(std::istringstream& is) {
    std::string token, fen;

    is >> token;

    if (token == "startpos")
    {
        fen = StartFEN;
        is >> token;
    }
    else if (token == "fen")
        while (is >> token && token != "moves")
            fen += token + " ";
    else
        return;

    std::vector<std::string> moves;
    while (is >> token)
        moves.push_back(token);

    engine.set_position(fen, moves);
}

namespace {
// ... (WinRateParams giữ nguyên) ...
struct WinRateParams {
    double a;
    double b;
};

WinRateParams win_rate_params(const Position& pos) {
    int material = 10 * pos.count<ROOK>() + 5 * pos.count<KNIGHT>() + 5 * pos.count<CANNON>()
                 + 3 * pos.count<BISHOP>() + 2 * pos.count<ADVISOR>() + pos.count<PAWN>();
    double m = std::clamp(material, 17, 110) / 65.0;
    constexpr double as[] = {220.59891365, -810.35730430, 928.68185198, 79.83955423};
    constexpr double bs[] = {61.99287416, -233.72674182, 325.85508322, -68.72720854};
    double a = (((as[0] * m + as[1]) * m + as[2]) * m) + as[3];
    double b = (((bs[0] * m + bs[1]) * m + bs[2]) * m) + bs[3];
    return {a, b};
}

int win_rate_model(Value v, const Position& pos) {
    auto [a, b] = win_rate_params(pos);
    return int(0.5 + 1000 / (1 + std::exp((a - double(v)) / b)));
}
}

std::string UCIEngine::format_score(const Score& s) {
    const auto format = overload{[](Score::Mate mate) -> std::string {
                                     auto m = (mate.plies > 0 ? (mate.plies + 1) : mate.plies) / 2;
                                     return std::string("mate ") + std::to_string(m);
                                 },
                                 [](Score::InternalUnits units) -> std::string {
                                     return std::string("cp ") + std::to_string(units.value);
                                 }};

    return s.visit(format);
}

int UCIEngine::to_cp(Value v, const Position& pos) {
    auto [a, b] = win_rate_params(pos);
    return std::round(100 * int(v) / a);
}

std::string UCIEngine::wdl(Value v, const Position& pos) {
    std::stringstream ss;
    int wdl_w = win_rate_model(v, pos);
    int wdl_l = win_rate_model(-v, pos);
    int wdl_d = 1000 - wdl_w - wdl_l;
    ss << wdl_w << " " << wdl_d << " " << wdl_l;
    return ss.str();
}

std::string UCIEngine::square(Square s) {
    return std::string{char('a' + file_of(s)), char('0' + rank_of(s))};
}

std::string UCIEngine::move(Move m) {
    if (m == Move::none()) return "(none)";
    if (m == Move::null()) return "0000";
    Square from = m.from_sq();
    Square to   = m.to_sq();
    return square(from) + square(to);
}

Move UCIEngine::to_move(const Position& pos, std::string str) {
    for (const auto& m : MoveList<LEGAL>(pos))
        if (str == move(m))
            return m;
    return Move::none();
}

// MODIFIED: CÁC HÀM CALLBACK UPDATE THÔNG TIN
// Thay thế sync_cout bằng ios_post_output

void UCIEngine::on_update_no_moves(const Engine::InfoShort& info) {
    std::stringstream ss;
    ss << "info depth " << info.depth << " score " << format_score(info.score);
    ios_post_output(ss.str());
}

void UCIEngine::on_update_full(const Engine::InfoFull& info, bool showWDL) {
    std::stringstream ss;

    ss << "info";
    ss << " depth " << info.depth
       << " seldepth " << info.selDepth
       << " multipv " << info.multiPV
       << " score " << format_score(info.score);

    if (!info.bound.empty())
        ss << " " << info.bound;

    if (showWDL)
        ss << " wdl " << info.wdl;

    ss << " nodes " << info.nodes
       << " nps " << info.nps
       << " hashfull " << info.hashfull
       << " tbhits " << info.tbHits
       << " time " << info.timeMs
       << " pv " << info.pv;

    ios_post_output(ss.str());
}

void UCIEngine::on_iter(const Engine::InfoIter& info) {
    std::stringstream ss;
    ss << "info";
    ss << " depth " << info.depth
       << " currmove " << info.currmove
       << " currmovenumber " << info.currmovenumber;
    ios_post_output(ss.str());
}

void UCIEngine::on_bestmove(std::string_view bestmove, std::string_view ponder) {
    // Fix lỗi string_view cho Xcode
    std::string out = "bestmove " + std::string(bestmove);
    if (!ponder.empty())
        out += " ponder " + std::string(ponder);
    ios_post_output(out);
}

}  // namespace Stockfish