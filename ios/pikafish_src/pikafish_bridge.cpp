#include <iostream>
#include <thread>
#include <vector>
#include <string>
#include <cstring>
#include <unistd.h>
#include <fcntl.h>

// Khai báo hàm main gốc của Pikafish (đã đổi tên)
extern int pikafish_main(int argc, char* argv[]);

// Biến toàn cục để quản lý đường ống (Pipes)
int stdin_pipe[2];  // Gửi lệnh TỪ Flutter VÀO Engine
int stdout_pipe[2]; // Đọc kết quả TỪ Engine RA Flutter
std::thread engine_thread;

// Hàm khởi động Engine (Được gọi từ Dart)
extern "C" __attribute__((visibility("default"))) __attribute__((used))
void init_pikafish_ios() {
    // 1. Tạo đường ống
    if (pipe(stdin_pipe) < 0 || pipe(stdout_pipe) < 0) {
        return; // Lỗi tạo pipe
    }

    // 2. Chạy Engine trong một luồng riêng biệt (Thread)
    engine_thread = std::thread([]() {
        // Chuyển hướng Standard Input (cin) -> Đọc từ stdin_pipe[0]
        dup2(stdin_pipe[0], STDIN_FILENO);
        
        // Chuyển hướng Standard Output (cout) -> Ghi vào stdout_pipe[1]
        dup2(stdout_pipe[1], STDOUT_FILENO);

        // Đóng các đầu ống không dùng trong luồng này
        close(stdin_pipe[1]); 
        close(stdout_pipe[0]);

        // Gọi hàm main của Pikafish
        char* argv[] = {(char*)"pikafish", NULL};
        pikafish_main(1, argv);
    });

    // 3. Đóng luồng ở phía cha (Flutter) để tránh xung đột
    engine_thread.detach(); 
}

// Hàm gửi lệnh vào Engine (Được gọi từ Dart)
extern "C" __attribute__((visibility("default"))) __attribute__((used))
void send_command_ios(char* command) {
    std::string cmd(command);
    cmd += "\n"; // Phải có xuống dòng thì Engine mới hiểu
    write(stdin_pipe[1], cmd.c_str(), cmd.length());
}

// Hàm đọc kết quả từ Engine (Được gọi từ Dart liên tục)
// Trả về số byte đọc được, dữ liệu ghi vào buffer
extern "C" __attribute__((visibility("default"))) __attribute__((used))
int read_stdout_ios(char* buffer, int max_len) {
    // Dùng fcntl để set chế độ KHÔNG CHẶN (Non-blocking)
    // Nghĩa là nếu không có dữ liệu thì trả về ngay, không treo App
    int flags = fcntl(stdout_pipe[0], F_GETFL, 0);
    fcntl(stdout_pipe[0], F_SETFL, flags | O_NONBLOCK);

    return read(stdout_pipe[0], buffer, max_len);
}