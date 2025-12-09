import 'package:flutter/material.dart';
import '../../widgets/board/board_widget.dart'; 
import '../../services/engine_service.dart'; // Import Service

// --- CHUYỂN THÀNH STATEFUL WIDGET ĐỂ CÓ INITSTATE ---
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  
  // --- HÀM KHỞI TẠO: CHẠY NGAY KHI MÀN HÌNH HIỆN RA ---
  @override
  void initState() {
    super.initState();
    // Gọi lệnh khởi động Engine sau 1 giây (để giao diện kịp load)
    Future.delayed(const Duration(milliseconds: 500), () {
      debugPrint("⚡ PlayScreen: Đang gọi startup()...");
      EngineService().startup();
    });
  }

  // --- HÀM HỦY: TẮT ENGINE KHI THOÁT ---
  @override
  void dispose() {
    EngineService().shutdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

      body: Stack(
        children: [
          // LỚP 1: GIAO DIỆN GAME CHÍNH
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
                        // Thử gửi lệnh khi bấm bàn cờ để test
                        EngineService().sendCommand("isready");
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

          // LỚP 2: BẢNG DEBUG LOG (NÂNG CẤP)
          Positioned(
            top: 40, 
            left: 10,
            right: 10,
            height: 280, // Cao hơn chút để chứa nút
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9), 
                border: Border.all(color: Colors.greenAccent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("🛠 DEBUG ENGINE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      // Nút Reset thủ công
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: EdgeInsets.zero, minimumSize: Size(60, 30)),
                        onPressed: () {
                          EngineService().startup();
                        },
                        child: const Text("RE-START", style: TextStyle(fontSize: 10, color: Colors.white)),
                      )
                    ],
                  ),
                  const Divider(color: Colors.white54),
                  
                  // Khu vực hiển thị chữ chạy
                  Expanded(
                    child: StreamBuilder<String>(
                      stream: EngineService().systemLogs, 
                      builder: (context, snapshot) {
                        final logText = snapshot.hasData ? "${snapshot.data}" : "Đang chờ khởi động...";
                        return SingleChildScrollView(
                          reverse: true, 
                          child: Text(
                            logText,
                            style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontSize: 11),
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

  // --- CÁC WIDGET CON ---
  Widget _buildPlayerInfoBar({required String name, required IconData icon, required String time}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
          const SizedBox(width: 6),
          Text(time, style: const TextStyle(color: Colors.white, fontSize: 16)),
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
          _actionButton(Icons.undo, "Đi lại", () {}),
          _actionButton(Icons.lightbulb_outline, "Gợi ý", () {}),
          _actionButton(Icons.flag_outlined, "Xin thua", () {}),
          _actionButton(Icons.swap_horiz, "Đổi bên", () {}),
          _actionButton(Icons.settings, "Cài đặt", () {}),
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
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}