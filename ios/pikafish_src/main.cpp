/*
  Stockfish, a UCI chess playing engine derived from Glaurung 2.1
  Copyright (C) 2004-2025 The Stockfish developers (see AUTHORS file)
*/

#include <iostream>
#include <memory>

#include "bitboard.h"
#include "misc.h"
#include "position.h"
#include "tune.h"
#include "types.h"
#include "uci.h"

using namespace Stockfish;

// --- SỬA ĐỔI: BỎ 'extern "C"', ĐƯA VỀ HÀM C++ THUẦN TÚY ---
// Để khớp với khai báo trong file pikafish_bridge.cpp
int pikafish_main(int argc, char* argv[]) {
    std::cout << engine_info() << std::endl;

    Bitboards::init();
    Position::init();

    auto uci = std::make_unique<UCIEngine>(argc, argv);

    Tune::init(uci->engine_options());

    uci->loop();

    return 0;
}