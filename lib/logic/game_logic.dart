// lib/logic/game_logic.dart
import '../widgets/board/board_widget.dart';

class GameLogic {
  /// Kiểm tra xem có quân cờ tại (col,row) không
  static Piece? getPieceAt(int col, int row, List<Piece> pieces) {
    try {
      return pieces.firstWhere((p) => p.col == col && p.row == row);
    } catch (e) {
      return null;
    }
  }

  /// Kiểm tra nước đi hợp lệ cho một quân
  static bool isValidMove(Piece p, int toCol, int toRow, List<Piece> pieces) {
    // Không đi ra ngoài bàn
    if (toCol < 0 || toCol > 8 || toRow < 0 || toRow > 9) return false;

    // Không đi vào ô có quân cùng màu
    Piece? target = getPieceAt(toCol, toRow, pieces);
    if (target != null && target.code[0] == p.code[0]) return false;

    switch (p.code.substring(2)) {
      case 'k': // Tướng
        return _isValidKingMove(p, toCol, toRow);
      case 'a': // Sĩ
        return _isValidAdvisorMove(p, toCol, toRow);
      case 'e': // Tượng
        return _isValidElephantMove(p, toCol, toRow, pieces);
      case 'h': // Mã
        return _isValidHorseMove(p, toCol, toRow, pieces);
      case 'r': // Xe
        return _isValidRookMove(p, toCol, toRow, pieces);
      case 'c': // Pháo
        return _isValidCannonMove(p, toCol, toRow, pieces);
      case 'p': // Tốt
        return _isValidPawnMove(p, toCol, toRow);
      default:
        return false;
    }
  }

  // ================= LUẬT CHI TIẾT =================

  static bool _isValidKingMove(Piece p, int col, int row) {
    int minCol = 3, maxCol = 5;
    int minRow = p.code[0] == 'r' ? 7 : 0;
    int maxRow = p.code[0] == 'r' ? 9 : 2;

    if (col < minCol || col > maxCol || row < minRow || row > maxRow) return false;

    int dx = (col - p.col).abs();
    int dy = (row - p.row).abs();
    return (dx + dy == 1);
  }

  static bool _isValidAdvisorMove(Piece p, int col, int row) {
    int minCol = 3, maxCol = 5;
    int minRow = p.code[0] == 'r' ? 7 : 0;
    int maxRow = p.code[0] == 'r' ? 9 : 2;

    if (col < minCol || col > maxCol || row < minRow || row > maxRow) return false;

    int dx = (col - p.col).abs();
    int dy = (row - p.row).abs();
    return dx == 1 && dy == 1;
  }

  static bool _isValidElephantMove(Piece p, int col, int row, List<Piece> pieces) {
    int dx = (col - p.col).abs();
    int dy = (row - p.row).abs();
    if (dx != 2 || dy != 2) return false;

    if (p.code[0] == 'r' && row < 5) return false;
    if (p.code[0] == 'b' && row > 4) return false;

    int midCol = (col + p.col) ~/ 2;
    int midRow = (row + p.row) ~/ 2;
    if (getPieceAt(midCol, midRow, pieces) != null) return false;

    return true;
  }

  static bool _isValidHorseMove(Piece p, int col, int row, List<Piece> pieces) {
    int dx = (col - p.col).abs();
    int dy = (row - p.row).abs();
    if (!((dx == 2 && dy == 1) || (dx == 1 && dy == 2))) return false;

    int blockCol = p.col + (dx == 2 ? ((col - p.col) ~/ 2) : 0);
    int blockRow = p.row + (dy == 2 ? ((row - p.row) ~/ 2) : 0);
    if (getPieceAt(blockCol, blockRow, pieces) != null) return false;

    return true;
  }

  static bool _isValidRookMove(Piece p, int col, int row, List<Piece> pieces) {
    if (p.col != col && p.row != row) return false;
    return _countPiecesBetween(p.col, p.row, col, row, pieces) == 0;
  }

  static bool _isValidCannonMove(Piece p, int col, int row, List<Piece> pieces) {
    if (p.col != col && p.row != row) return false;
    int count = _countPiecesBetween(p.col, p.row, col, row, pieces);
    Piece? target = getPieceAt(col, row, pieces);

    if (target == null) {
      return count == 0;
    } else {
      return count == 1;
    }
  }

  static bool _isValidPawnMove(Piece p, int col, int row) {
    int dx = (col - p.col).abs();
    int dy = row - p.row;

    if (p.code[0] == 'r') {
      if (p.row >= 5) {
        if (dx != 0) return false;
        return dy == -1;
      } else {
        if ((dy == -1 && dx == 0) || (dy == 0 && dx == 1)) return true;
        return false;
      }
    } else {
      if (p.row <= 4) {
        if (dx != 0) return false;
        return dy == 1;
      } else {
        if ((dy == 1 && dx == 0) || (dy == 0 && dx == 1)) return true;
        return false;
      }
    }
  }

  // ================= HÀM HỖ TRỢ =================
  static int _countPiecesBetween(int c1, int r1, int c2, int r2, List<Piece> pieces) {
    int count = 0;
    if (c1 == c2) {
      int start = r1 < r2 ? r1 + 1 : r2 + 1;
      int end = r1 < r2 ? r2 : r1;
      for (int r = start; r < end; r++) {
        if (getPieceAt(c1, r, pieces) != null) count++;
      }
    } else if (r1 == r2) {
      int start = c1 < c2 ? c1 + 1 : c2 + 1;
      int end = c1 < c2 ? c2 : c1;
      for (int c = start; c < end; c++) {
        if (getPieceAt(c, r1, pieces) != null) count++;
      }
    }
    return count;
  }
}
