import 'package:flutter/material.dart';
import '../../widgets/board/board_widget.dart'; 
import '../../services/engine_service.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  
  @override
  void initState() {
    super.initState();
    // Khởi động Engine ngầm khi vào màn hình chơi (nếu cần)
    EngineService().startup();
  }

  @override
  void dispose() {
    EngineService().shutdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Tính toán kích thước bàn cờ sao cho vừa vặn, trừ đi khoảng đệm 
    // Logic: Nếu màn dọc thì theo chiều ngang, màn ngang thì theo chiều dọc
    final isPortrait = screenHeight > screenWidth;
    final boardSize = isPortrait 
        ? screenWidth - 20 
        : screenHeight - 40;

    return Scaffold(
      // Màu nền chuẩn của App (Dark theme)
      backgroundColor: const Color(0xFF2C2A28), 

      appBar: AppBar(
        title: const Text("Chơi với máy"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      // === FIX LỖI KHUYẾT MÀN HÌNH (TAI THỎ) ===
      // SafeArea đảm bảo nội dung không bị che bởi tai thỏ hoặc góc bo tròn
      body: SafeArea(
        left: true,  // Tránh tai thỏ bên trái (khi xoay ngang)
        right: true, // Tránh tai thỏ bên phải
        bottom: true, // Tránh thanh vuốt home ảo
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Khu vực hiển thị bàn cờ
              BoardWidget(
                size: boardSize,
                onSquareTap: (col, row) {
                  // Logic xử lý nước đi sẽ nằm ở đây
                  print("Tap at: $col, $row");
                },
              ),
              
              const SizedBox(height: 20),
              
              // Các nút chức năng (Ví dụ: Ván mới, Hoàn tác)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Ván mới"),
                    onPressed: () {
                      // Logic ván mới
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.undo),
                    label: const Text("Đi lại"),
                    onPressed: () {
                      // Logic hoàn tác
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}