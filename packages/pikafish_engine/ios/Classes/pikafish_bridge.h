#ifndef PIKAFISH_BRIDGE_H
#define PIKAFISH_BRIDGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__GNUC__) || defined(__clang__)
#define PIKAFISH_EXPORT __attribute__((visibility("default")))
#else
#define PIKAFISH_EXPORT
#endif

// Khởi động Engine (chạy ngầm, async)
PIKAFISH_EXPORT
void init_pikafish_ios();

// Gửi lệnh UCI
PIKAFISH_EXPORT
void send_command_ios(const char* cmd);

// Đọc stdout từ engine
PIKAFISH_EXPORT
int read_stdout_ios(char* buffer, int maxLen);

#ifdef __cplusplus
}
#endif

#endif // PIKAFISH_BRIDGE_H
