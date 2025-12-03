import 'package:flutter/material.dart';
import '../../widgets/board/board_widget.dart'; // <-- 1. SỬA LẠI ĐƯỜNG DẪN

class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // === THAY ĐỔI ===
    // Tính toán chiều rộng bàn cờ để sát lề hơn
    // Thay vì nhân 85%, chúng ta trừ đi 1 padding ngang cố định
    const horizontalPadding = 20.0; // Tổng padding (10px mỗi bên)
    final boardWidth = MediaQuery.of(context).size.width - horizontalPadding;
    // === KẾT THÚC THAY ĐỔI ===

    final safePadding = MediaQuery.of(context).padding;

    // Nền tối - Đồng bộ 100% với AnalysisScreen
    return Scaffold(
      backgroundColor: const Color(0xFF2C2A28),

      // 1. BANNER QUẢNG CÁO (Ghim cứng ở đáy)
      bottomNavigationBar: Container(
        height: 50 + safePadding.bottom, // 50px cho banner + padding an toàn
        color: Colors.black,
        padding: EdgeInsets.only(bottom: safePadding.bottom),
        alignment: Alignment.center,
        child: const Text(
          "Banner Quảng cáo (50px)",
          // === THAY ĐỔI: Sửa white7G0 thành white70 ===
          style: TextStyle(color: Colors.white70),
          // === KẾT THÚC THAY ĐỔI ===
        ),
      ),

      // 2. NỘI DUNG CHÍNH (Bảo vệ bởi SafeArea)
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---------------- THANH INFO NGƯỜI CHƠI (AI) ----------------
            _buildPlayerInfoBar(
              name: "AI (Cấp 10)",
              icon: Icons.computer,
              time: "05:00",
            ),

            // ---------------- BÀN CỜ (Chiếm phần lớn) ----------------
            Expanded(
              child: Center(
                // 2. THAY THẾ CONTAINER BẰNG BOARDWIDGET
                child: BoardWidget(
                  size: boardWidth,
                  onSquareTap: (col, row) {
                    // Xử lý khi người dùng tap vào ô (col, row)
                    debugPrint("[Play] Tapped on: $col, $row");
                  },
                ),
              ),
            ),

            // ---------------- THANH INFO NGƯỜI CHƠI (BẠN) ----------------
            _buildPlayerInfoBar(
              name: "Bạn",
              icon: Icons.person,
              time: "05:00",
            ),

            // ---------------- THANH ĐIỀU KHIỂN (Play Mode) ----------------
            _buildControlBar(),
          ],
        ),
      ),
    );
  }

  // HÀM TẠO THANH INFO NGƯỜI CHƠI
  Widget _buildPlayerInfoBar(
      {required String name,
      required IconData icon,
      required String time}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(), // Đẩy thời gian về cuối
          Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
          const SizedBox(width: 6),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // HÀM TẠO THANH ĐIỀU KHIỂN DƯỚI
  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFF1F1E1C), // Nền thanh điều khiển
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // === THAY ĐỔI: Thêm hàm onTap ===
          _actionButton(Icons.undo, "Đi lại", () {
            debugPrint("Nút Đi lại được nhấn");
          }), // Undo
          _actionButton(Icons.lightbulb_outline, "Gợi ý", () {
            debugPrint("Nút Gợi ý được nhấn");
          }), // Hint
          _actionButton(Icons.flag_outlined, "Xin thua", () {
            debugPrint("Nút Xin thua được nhấn");
          }), // Resign
          _actionButton(Icons.swap_horiz, "Đổi bên", () {
            debugPrint("Nút Đổi bên được nhấn");
          }), // <-- CẬP NHẬT ICON
          _actionButton(Icons.settings, "Cài đặt", () {
            debugPrint("Nút Cài đặt được nhấn");
          }), // Settings
          // === KẾT THÚC THAY ĐỔI ===
        ],
      ),
    );
  }

  // HÀM TẠO NÚT (Tái sử dụng style từ AnalysisScreen)
  // === THAY ĐỔI: Bọc bằng InkWell để có hiệu ứng nhấn ===
  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0), // Bo tròn hiệu ứng nhấn
      child: Padding(
        // Thêm padding để vùng nhấn lớn hơn và đẹp hơn
        // Dùng horizontal: 12 vì có 5 nút, cần tiết kiệm không gian hơn
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  // === KẾT THÚC THAY ĐỔI ===
}