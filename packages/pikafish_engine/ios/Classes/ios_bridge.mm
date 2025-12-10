#import "pikafish_bridge.h"

#include <atomic>
#include <thread>
#include <mutex>
#include <queue>
#include <string>
#include <condition_variable>
#include <cstdio>
#include <cstring>

// ===== UCI CORE =====
#include "uci.h"

// ===== GLOBAL STATE =====
static std::thread engineThread;
static std::atomic<bool> engineStarted(false);

// Output queue (an toàn, không nghẽn)
static std::mutex outputMutex;
static std::queue<std::string> outputQueue;

// Command mutex (tránh race)
static std::mutex commandMutex;

// ===== CALLBACK TỪ ENGINE =====
extern "C" void write_to_dart_buffer(const char* text) {
    if (!text) return;

    std::lock_guard<std::mutex> lock(outputMutex);
    outputQueue.emplace(text);

    printf("[ENGINE → APP] %s\n", text);
}

// ===== ENGINE THREAD =====
static void engine_main() {
    char* argv[] = {(char*)"pikafish", nullptr};
    int argc = 1;

    Stockfish::UCIEngine engine(argc, argv);
    engine.loop(); // Blocking loop
}

// ===== EXPORTED C API =====
extern "C" {

void init_pikafish_ios() {
    if (engineStarted.exchange(true)) {
        return;
    }

    printf("[iOS Bridge] Starting Pikafish engine...\n");

    engineThread = std::thread(engine_main);
    engineThread.detach();
}

void send_command_ios(const char* cmd) {
    if (!cmd) return;

    printf("[APP → ENGINE] %s\n", cmd);

    std::lock_guard<std::mutex> lock(commandMutex);
    uci_inject_command(cmd);
}

int read_stdout_ios(char* buffer, int maxLen) {
    if (!buffer || maxLen <= 1) return 0;

    std::lock_guard<std::mutex> lock(outputMutex);

    if (outputQueue.empty()) return 0;

    std::string line = outputQueue.front();
    outputQueue.pop();

    int len = std::min((int)line.size(), maxLen - 1);
    memcpy(buffer, line.c_str(), len);
    buffer[len] = '\0';

    return len;
}

} // extern "C"
