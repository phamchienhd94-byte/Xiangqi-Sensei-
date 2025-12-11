#include "pikafish_bridge.h"

/*
  FILE: pikafish_force_link.mm
  Mục đích: Tạo reference "cứng" từ ObjC++ -> C/C++ để Linker không xóa Engine.

  LƯU Ý:
  - Tên hàm gọi PHẢI KHỚP CHÍNH XÁC với pikafish_bridge.h
  - Đặt là extern "C" và không để static để đảm bảo symbol có visibility toàn cục
  - __attribute__((used)) giúp ngăn compiler loại bỏ hàm này
*/

#ifdef __cplusplus
extern "C" {
#endif

__attribute__((used))
void pikafish_force_link_symbols(void) {
    // Gọi các hàm thực tế hiện có trong bridge
    // Chú ý: các lời gọi này không cần có logic thực sự; chỉ để tạo reference cho linker
    init_pikafish_ios();
    send_command_ios("uci");
    // gọi read để chắc chắn symbol/read-line được giữ; truyền buffer NULL là OK theo impl
    read_stdout_ios(nullptr, 0);
}

#ifdef __cplusplus
}
#endif
