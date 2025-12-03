import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Class lưu thông tin cấu hình của một mũi tên
class ArrowDef {
  final int fromX, fromY, toX, toY;
  final Color color;
  
  ArrowDef({
    required this.fromX, 
    required this.fromY, 
    required this.toX, 
    required this.toY, 
    required this.color
  });
}

class BoardOverlayPainter extends CustomPainter {
  // Thay vì nhận 1 toạ độ lẻ, giờ "thợ vẽ" nhận cả một danh sách mũi tên
  final List<ArrowDef> arrows;
  
  // Highlight nước vừa đi
  final int? lastMoveFromX, lastMoveFromY, lastMoveToX, lastMoveToY;

  BoardOverlayPainter({
    this.arrows = const [], // Mặc định danh sách rỗng
    this.lastMoveFromX, this.lastMoveFromY, this.lastMoveToX, this.lastMoveToY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cellW = size.width / 9;
    final double cellH = size.height / 10;

    // 1. VẼ HIGHLIGHT NƯỚC VỪA ĐI (Giữ nguyên)
    final Paint highlightPaint = Paint()..color = const Color(0x402196F3)..style = PaintingStyle.fill;
    
    if (lastMoveFromX != null && lastMoveFromY != null) {
      canvas.drawRect(Rect.fromLTWH(lastMoveFromX! * cellW, lastMoveFromY! * cellH, cellW, cellH), highlightPaint);
    }
    if (lastMoveToX != null && lastMoveToY != null) {
      canvas.drawRect(Rect.fromLTWH(lastMoveToX! * cellW, lastMoveToY! * cellH, cellW, cellH), highlightPaint);
    }

    // 2. VẼ DANH SÁCH MŨI TÊN (LOGIC MỚI)
    // Lưu ý: Vẽ ngược danh sách (reversed) để mũi tên quan trọng nhất (Rank 1) nằm đè lên trên cùng nếu bị trùng
    for (var arrow in arrows.reversed) {
      _drawArrow(canvas, arrow, cellW, cellH);
    }
  }

  void _drawArrow(Canvas canvas, ArrowDef arrow, double cellW, double cellH) {
      // Màu sắc lấy từ cấu hình của từng mũi tên
      final Paint arrowPaint = Paint()
        ..color = arrow.color.withOpacity(0.85) // Giảm opacity chút cho đẹp
        ..strokeWidth = 4.0 
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Paint headPaint = Paint()
        ..color = arrow.color.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      double x1 = (arrow.fromX * cellW) + (cellW / 2);
      double y1 = (arrow.fromY * cellH) + (cellH / 2);
      double x2 = (arrow.toX * cellW) + (cellW / 2);
      double y2 = (arrow.toY * cellH) + (cellH / 2);

      // Vẽ thân
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), arrowPaint);
      
      // Vẽ đầu mũi tên (Tam giác)
      double arrowSize = 14.0;
      double angle = math.atan2(y2 - y1, x2 - x1);
      Path path = Path();
      path.moveTo(x2, y2);
      // Tính toán 2 cánh của tam giác
      path.lineTo(x2 - arrowSize * math.cos(angle - math.pi / 6), y2 - arrowSize * math.sin(angle - math.pi / 6));
      path.lineTo(x2 - arrowSize * math.cos(angle + math.pi / 6), y2 - arrowSize * math.sin(angle + math.pi / 6));
      path.close();
      canvas.drawPath(path, headPaint);

      // Vẽ chấm tròn nhỏ ở đuôi cho chuyên nghiệp
      canvas.drawCircle(Offset(x1, y1), 4.0, headPaint);
  }

  @override
  bool shouldRepaint(covariant BoardOverlayPainter oldDelegate) => true; // Luôn vẽ lại khi có thay đổi
}