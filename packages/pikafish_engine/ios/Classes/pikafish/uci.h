/*
  Stockfish, a UCI chess playing engine derived from Glaurung 2.1
  Copyright (C) 2004-2025 The Stockfish developers (see AUTHORS file)
*/

#ifndef UCI_H_INCLUDED
#define UCI_H_INCLUDED

#include <cstdint>
#include <iostream>
#include <string>
#include <string_view>

#include "engine.h"
#include "misc.h"
#include "search.h"

namespace Stockfish {

class Position;
class Move;
class Score;
enum Square : int8_t;
using Value = int;

class UCIEngine {
   public:
    UCIEngine(int argc, char** argv);

    void loop();

    static int         to_cp(Value v, const Position& pos);
    static std::string format_score(const Score& s);
    static std::string square(Square s);
    static std::string move(Move m);
    static std::string wdl(Value v, const Position& pos);
    static Move        to_move(const Position& pos, std::string str);

    static Search::LimitsType parse_limits(std::istream& is);

    auto& engine_options() { return engine.get_options(); }

   private:
    Engine      engine;
    CommandLine cli;

    static void print_info_string(std::string_view str);

    void          go(std::istringstream& is);
    void          bench(std::istream& args);
    void          benchmark(std::istream& args);
    void          position(std::istringstream& is);
    void          setoption(std::istringstream& is);
    std::uint64_t perft(const Search::LimitsType&);

    static void on_update_no_moves(const Engine::InfoShort& info);
    static void on_update_full(const Engine::InfoFull& info, bool showWDL);
    static void on_iter(const Engine::InfoIter& info);
    static void on_bestmove(std::string_view bestmove, std::string_view ponder);

    void init_search_update_listeners();
};

}  // namespace Stockfish


// ============================================================================
// ✅ iOS / Flutter FFI – C API
// ✅ Không ảnh hưởng logic engine
// ✅ Chỉ để bridge từ Dart → C++
// ============================================================================

#ifdef __cplusplus
extern "C" {
#endif

// Inject UCI command từ iOS / Flutter (thay cho stdin)
void uci_inject_command(const char* cmd);

// Engine gọi để ghi output ra buffer (ios_bridge.mm định nghĩa)
void write_to_dart_buffer(const char* text);

#ifdef __cplusplus
}
#endif

#endif  // UCI_H_INCLUDED
