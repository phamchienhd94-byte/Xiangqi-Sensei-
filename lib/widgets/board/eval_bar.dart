import 'package:flutter/material.dart';
import 'dart:math' as math;

class EvalBar extends StatelessWidget {
  // Điểm số từ Engine (đơn vị centipawns). Ví dụ: 100, -50, 2000...
  // Nếu là Mate (chiếu bí), truyền giá trị lớn (ví dụ 10000 hoặc -10000)
  final double score; 
  final bool isMate; // Có phải đang chiếu bí không?

  const EvalBar({super.key, required this.score, this.isMate = false});

  @override
  Widget build(BuildContext context) {
    // 1. Tính toán phần trăm chiến thắng của bên Đỏ (Red)
    // Sử dụng công thức Sigmoid để làm mượt:
    // Win% = 1 / (1 + 10^(-score / 1000))
    // Score càng lớn thì Red càng cao.
    
    double winRate;
    if (isMate) {
      // Nếu chiếu bí, đẩy full cây (Đỏ thắng -> 1.0, Đen thắng -> 0.0)
      winRate = score > 0 ? 1.0 : 0.0;
    } else {
      // Giới hạn score hiển thị trong khoảng -2000 đến 2000 để thanh bar không bị đơ
      double clampedScore = score.clamp(-2000.0, 2000.0);
      // Công thức sigmoid điều chỉnh cho cờ tướng (chia 1000 cho độ dốc vừa phải)
      winRate = 1 / (1 + math.pow(10, -clampedScore / 1000));
    }

    return Container(
      width: 14, // Chiều rộng thanh bar
      height: double.infinity, // Full chiều cao cha
      decoration: BoxDecoration(
        color: Colors.black, // Màu nền (Đại diện cho bên Đen)
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Phần màu Đỏ (Đại diện bên Đỏ)
          // Dùng FractionallySizedBox để chỉnh chiều cao theo %
          FractionallySizedBox(
            heightFactor: winRate, 
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFD64436), // Màu đỏ cờ tướng
                borderRadius: BorderRadius.vertical(top: Radius.circular(2), bottom: Radius.circular(4)),
              ),
            ),
          ),
          
          // Hiển thị điểm số nhỏ xíu ở giữa thanh bar
          // Dùng Align thay vì Positioned để dễ căn giữa tuyệt đối
          Align(
            alignment: Alignment.center,
            child: RotatedBox(
              quarterTurns: 3, // Xoay chữ dọc 270 độ
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                color: Colors.black45, // Nền mờ để dễ đọc chữ
                child: Text(
                  isMate ? "MATE" : (score / 100).toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 10, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}