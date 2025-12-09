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
    // Tự động bật Engine và hiện bảng Log sau 0.5 giây
    Future.delayed(const Duration(milliseconds: 500), () {
      EngineService().startup();
      _showLogDialog(); // <-- BẮT BUỘC HIỆN LOG
    });
  }

  @override
  void dispose() {
    EngineService().shutdown();
    super.dispose();
  }

  // Hàm hiện bảng Log dạng Popup (Không thể không nhìn thấy)
  void _showLogDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho tắt bằng cách bấm ra ngoài
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        title: const Text("🔍 ENGINE LOG (Build 9)", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<String>(
            stream: EngineService().systemLogs,
            builder: (context, snapshot) {
              return SingleChildScrollView(
                reverse: true,
                child: Text(
                  snapshot.hasData ? "${snapshot.data}" : "Đang chờ khởi động...",
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => EngineService().startup(),
            child: const Text("RE-START ENGINE", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const horizontalPadding = 20.0;
    final boardWidth = MediaQuery.of(context).size.width - horizontalPadding;
    
    return Scaffold(
      // === QUAN TRỌNG: ĐỔI MÀU NỀN THÀNH ĐỎ ĐỂ KIỂM TRA UPDATE ===
      backgroundColor: Colors.red.shade900, 
      // ==========================================================

      appBar: AppBar(title: const Text("TEST MODE - BUILD 9")),

      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Nếu màn hình này MÀU ĐỎ -> Đã update code thành công!", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            
            Expanded(
              child: Center(
                child: BoardWidget(
                  size: boardWidth,
                  onSquareTap: (col, row) {
                    // Bấm vào bàn cờ cũng hiện lại log
                    _showLogDialog();
                  },
                ),
              ),
            ),
            
            ElevatedButton.icon(
              icon: const Icon(Icons.bug_report),
              label: const Text("XEM LOG ENGINE"),
              onPressed: _showLogDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}