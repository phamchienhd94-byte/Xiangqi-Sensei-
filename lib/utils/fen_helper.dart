import '../widgets/board/board_widget.dart';

class FenHelper {
  static String generateFen(List<Piece> pieces, bool isRedTurn) {
    // SỬA LỖI QUAN TRỌNG:
    // Quét từ Hàng 0 (Góc trên cùng/Đất Đen) đến Hàng 9 (Góc dưới cùng/Đất Đỏ)
    // Code cũ quét từ 9 về 0 là bị ngược, khiến Engine hiểu sai bàn cờ.
    
    List<String> fenRows = [];

    for (int row = 0; row <= 9; row++) { // <--- ĐÃ SỬA: row tăng dần từ 0 -> 9
      String rowStr = "";
      int emptyCount = 0;

      for (int col = 0; col <= 8; col++) {
        Piece? p = pieces.cast<Piece?>().firstWhere(
          (element) => element!.col == col && element.row == row,
          orElse: () => null,
        );

        if (p == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            rowStr += emptyCount.toString();
            emptyCount = 0;
          }
          rowStr += _getFenChar(p.code);
        }
      }

      if (emptyCount > 0) {
        rowStr += emptyCount.toString();
      }
      fenRows.add(rowStr);
    }

    String boardFen = fenRows.join("/");
    String turn = isRedTurn ? "w" : "b";

    return "$boardFen $turn - - 0 1";
  }

  static String _getFenChar(String code) {
    bool isRed = code.startsWith("r_");
    String type = code.split("_")[1]; 
    
    // Mapping chuẩn FEN (Quốc tế):
    // Tướng=k, Sĩ=a, Tượng=b, Mã=n, Xe=r, Pháo=c, Tốt=p
    // Đỏ in Hoa, Đen in thường.
    
    String char = "";
    switch (type) {
      case "k": char = "k"; break;
      case "a": char = "a"; break;
      case "e": char = "b"; break; // Tượng là 'b' (Bishop) hoặc 'e' (Elephant) tuỳ engine, Pikafish thường hiểu cả 2 hoặc ưu tiên 'b'
      case "h": char = "n"; break; // Mã là 'n' (Knight)
      case "r": char = "r"; break;
      case "c": char = "c"; break;
      case "p": char = "p"; break;
      default: char = "p";
    }

    return isRed ? char.toUpperCase() : char.toLowerCase();
  }
}