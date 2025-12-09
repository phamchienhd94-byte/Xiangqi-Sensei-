import 'package:flutter/material.dart';
import '../../widgets/board/board_widget.dart'; 
import '../../services/engine_service.dart'; // <-- Import Service để lấy log

class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Tính toán chiều rộng bàn cờ
    const horizontalPadding = 20.0;
    final boardWidth = MediaQuery.of(context).size.width - horizontalPadding;
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFF2C2A28),

      bottomNavigationBar: Container(
        height: 50 + safePadding.bottom,
        color: Colors.black,
        padding: EdgeInsets.only(bottom: safePadding.bottom),
        alignment: Alignment.center,
        child: const Text(
          "Banner Quảng cáo (50px)",
          style: TextStyle(color: Colors.white70),
        ),
      ),

      // --- SỬ DỤNG STACK ĐỂ VẼ LOG ĐÈ LÊN TRÊN ---
      body: Stack(
        children: [
          // LỚP 1: GIAO DIỆN GAME CHÍNH (Như cũ)
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildPlayerInfoBar(
                  name: "AI (Cấp 10)",
                  icon: Icons.computer,
                  time: "05:00",
                ),

                Expanded(
                  child: Center(
                    child: BoardWidget(
                      size: boardWidth,
                      onSquareTap: (col, row) {
                        debugPrint("[Play] Tapped on: $col, $row");
                      },
                    ),
                  ),
                ),

                _buildPlayerInfoBar(
                  name: "Bạn",
                  icon: Icons.person,
                  time: "05:00",
                ),

                _buildControlBar(),
              ],
            ),
          ),

          // LỚP 2: BẢNG LOG DEBUG (Chỉ hiện để soi lỗi)
          Positioned(
            top: 50, // Cách mép trên 50px
            left: 10,
            right: 10,
            height: 250, // Chiều cao khung log
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85), // Nền đen đậm xuyên thấu
                border: Border.all(color: Colors.greenAccent, width: 2), // Viền xanh
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🛠 DEBUG ENGINE (Chụp ảnh gửi mình):", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                  const Divider(color: Colors.white54),
                  
                  // Khu vực hiển thị chữ chạy
                  Expanded(
                    child: StreamBuilder<String>(
                      stream: EngineService().systemLogs, // Lắng nghe log
                      builder: (context, snapshot) {
                        // Hiển thị nội dung log
                        final logText = snapshot.hasData ? "${snapshot.data}" : "Đang chờ khởi động...";
                        
                        return SingleChildScrollView(
                          reverse: true, // Luôn cuộn xuống dòng cuối
                          child: Text(
                            logText,
                            style: const TextStyle(
                              color: Colors.greenAccent, 
                              fontFamily: 'Courier', 
                              fontSize: 12
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CÁC WIDGET CON (GIỮ NGUYÊN) ---

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
          const Spacer(),
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

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFF1F1E1C),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionButton(Icons.undo, "Đi lại", () {
            debugPrint("Nút Đi lại được nhấn");
          }),
          _actionButton(Icons.lightbulb_outline, "Gợi ý", () {
            debugPrint("Nút Gợi ý được nhấn");
          }),
          _actionButton(Icons.flag_outlined, "Xin thua", () {
            debugPrint("Nút Xin thua được nhấn");
          }),
          _actionButton(Icons.swap_horiz, "Đổi bên", () {
            debugPrint("Nút Đổi bên được nhấn");
          }),
          _actionButton(Icons.settings, "Cài đặt", () {
            debugPrint("Nút Cài đặt được nhấn");
          }),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
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
}