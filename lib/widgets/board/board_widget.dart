import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../logic/game_logic.dart'; 
import 'arrow_painter.dart'; 
import '../../utils/fen_helper.dart'; 
import '../../services/sound_service.dart';
import '../../utils/app_localizations.dart'; 

class Piece {
  final String id;      
  int col;              
  int row;              
  final String code;    

  Piece({
    required this.id, 
    required this.col, 
    required this.row, 
    required this.code
  });

  Piece copy() => Piece(id: id, col: col, row: row, code: code);
}

class BoardWidget extends StatefulWidget {
  const BoardWidget({
    super.key,
    this.size,
    this.onSquareTap,
    this.onMove, 
    this.controller,
    this.checkTurn = false, // Yêu cầu kiểm tra đúng lượt mới được chọn quân
    this.isLocked = false,  // Khóa bàn cờ (khi máy đang nghĩ)
  });

  final double? size;
  final void Function(int col, int row)? onSquareTap;
  final void Function(String uci)? onMove;
  final BoardController? controller;
  final bool checkTurn;
  final bool isLocked;

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class BoardController {
  _BoardWidgetState? _state;
  void bind(_BoardWidgetState state) { _state = state; }
  void resetBoard() { _state?.resetPieces(); }
  void makeMove(String uciMove) { _state?.makeUciMove(uciMove); }
  void showHints(List<String> moves) { _state?.setMultiHints(moves); }
  void clearHint() { _state?.clearHints(); }
  String getFen({required bool isRedTurn}) { return _state?.getCurrentFen(isRedTurn) ?? ""; }
  String getVietnameseNotation(String uci) { return _state?.translateUci(uci) ?? uci; }
  void undo() { _state?.undo(); }
  void clearBoard() { _state?.clearAllPieces(); }
  void putPiece(int col, int row, String code) { _state?.putPieceAt(col, row, code); }
  void setFen(String fen) { _state?.loadFen(fen); }
  bool get isRedTurn => _state?._isRedTurn ?? true;
}

class _BoardWidgetState extends State<BoardWidget> {
  Piece? _selectedPiece; 
  double _boardW = 0;
  double _boardH = 0;
  double _cellW = 0;
  double _cellH = 0;
  double _padX = 0;
  double _padY = 0;

  List<Piece> _pieces = [];
  final List<List<String>> _history = [];
  List<ArrowDef> _activeArrows = []; 
  List<int>? _lastMoveCoords; 
  
  bool _isRedTurn = true; 

  @override
  void initState() {
    super.initState();
    widget.controller?.bind(this);
    resetPieces();
  }

  void resetPieces() {
    loadFen("rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1");
  }

  void loadFen(String fen) {
    List<Piece> newPieces = [];
    String boardPart = fen.split(" ")[0]; 
    
    List<String> parts = fen.split(" ");
    bool isRed = true;
    if (parts.length > 1) {
      isRed = (parts[1] == 'w');
    }

    List<String> rows = boardPart.split("/");

    for (int r = 0; r < rows.length; r++) {
      int actualRow = r; 
      String rowData = rows[r];
      int col = 0;
      for (int i = 0; i < rowData.length; i++) {
        String char = rowData[i];
        if (int.tryParse(char) != null) {
           col += int.parse(char); 
        } else {
           String code = _fenCharToCode(char);
           String id = "${code}_${col}_$actualRow";
           newPieces.add(Piece(id: id, col: col, row: actualRow, code: code));
           col++;
        }
      }
    }

    setState(() {
      _pieces = newPieces;
      _isRedTurn = isRed;
      _selectedPiece = null;
      _activeArrows = [];
      _lastMoveCoords = null;
      _history.clear();
      _saveHistory();
    });
  }

  String _fenCharToCode(String char) {
    bool isRed = char == char.toUpperCase();
    String type = char.toLowerCase();
    String prefix = isRed ? "r" : "b";
    String suffix = "p"; 
    switch (type) {
      case 'k': suffix = 'k'; break;
      case 'a': suffix = 'a'; break;
      case 'b': suffix = 'e'; break;
      case 'e': suffix = 'e'; break; 
      case 'n': suffix = 'h'; break;
      case 'h': suffix = 'h'; break; 
      case 'r': suffix = 'r'; break;
      case 'c': suffix = 'c'; break;
      case 'p': suffix = 'p'; break;
    }
    return "${prefix}_$suffix";
  }

  void clearAllPieces() { setState(() { _pieces.clear(); _selectedPiece = null; _activeArrows = []; _lastMoveCoords = null; }); }
  void putPieceAt(int col, int row, String code) {
    setState(() {
      _pieces.removeWhere((p) => p.col == col && p.row == row);
      if (code.isNotEmpty) {
        String id = "${code}_${DateTime.now().microsecondsSinceEpoch}";
        _pieces.add(Piece(id: id, col: col, row: row, code: code));
      }
    });
  }

  void _saveHistory() {
    List<String> snapshot = _pieces.map((e) => "${e.id}_${e.col}_${e.row}").toList();
    _history.add(snapshot);
  }

  void undo() {
    if (_history.length > 1) {
      setState(() {
        _history.removeLast(); 
        final previousState = _history.last;
        _pieces.clear();
        for (var s in previousState) {
          var parts = s.split('_'); 
          int row = int.parse(parts.last);
          int col = int.parse(parts[parts.length - 2]);
          String id = parts.sublist(0, parts.length - 2).join("_");
          String code = id.substring(0, 3); 
          _pieces.add(Piece(id: id, col: col, row: row, code: code));
        }
        _isRedTurn = !_isRedTurn; 
        _selectedPiece = null;
        _lastMoveCoords = null;
        _activeArrows = []; 
      });
    }
  }

  Piece? _getPieceAt(int col, int row) {
    try { return _pieces.firstWhere((p) => p.col == col && p.row == row); } catch (e) { return null; }
  }

  String _getUciMove(int c1, int r1, int c2, int r2) {
    final colToChar = (int c) => String.fromCharCode('a'.codeUnitAt(0) + c);
    final rowToChar = (int r) => (9 - r).toString(); 
    return "${colToChar(c1)}${rowToChar(r1)}${colToChar(c2)}${rowToChar(r2)}";
  }

  List<int>? _parseUci(String? uci) {
    if (uci == null || uci.length < 4) return null;
    try {
      int c1 = uci.codeUnitAt(0) - 'a'.codeUnitAt(0);
      int r1 = 9 - int.parse(uci[1]);
      int c2 = uci.codeUnitAt(2) - 'a'.codeUnitAt(0);
      int r2 = 9 - int.parse(uci[3]);
      return [c1, r1, c2, r2];
    } catch (e) {
      return null;
    }
  }

  void setMultiHints(List<String> uciMoves) {
    List<ArrowDef> newArrows = [];
    final List<Color> rankColors = [Colors.greenAccent, Colors.amber, Colors.white.withOpacity(0.6)];
    for (int i = 0; i < uciMoves.length; i++) {
      List<int>? coords = _parseUci(uciMoves[i]);
      if (coords != null) {
        Color c = (i < rankColors.length) ? rankColors[i] : Colors.white30;
        newArrows.add(ArrowDef(fromX: coords[0], fromY: coords[1], toX: coords[2], toY: coords[3], color: c));
      }
    }
    setState(() { _activeArrows = newArrows; });
  }

  void clearHints() { setState(() { _activeArrows = []; }); }
  String getCurrentFen(bool isRedTurn) { return FenHelper.generateFen(_pieces, isRedTurn); }
  String translateUci(String uci) {
    if (uci.length < 4) return uci;
    int c1 = uci.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int r1 = 9 - int.parse(uci[1]);
    int c2 = uci.codeUnitAt(2) - 'a'.codeUnitAt(0);
    int r2 = 9 - int.parse(uci[3]);
    Piece? p = _getPieceAt(c1, r1);
    if (p == null) return uci;
    bool isRed = p.code.startsWith('r_');
    String typeCode = p.code.substring(2); 
    String pieceName = AppLocalizations.t('piece_$typeCode'); 
    int colStart = isRed ? (9 - c1) : (c1 + 1);
    int colEnd = isRed ? (9 - c2) : (c2 + 1);
    String actionKey = "";
    if (r1 == r2) {
      actionKey = 'act_traverse'; 
      String actionName = AppLocalizations.t(actionKey);
      return AppLocalizations.translateMove(pieceName, colStart, actionName, colEnd);
    } else {
      bool isAdvance = isRed ? (r2 < r1) : (r2 > r1);
      actionKey = isAdvance ? 'act_advance' : 'act_retreat';
      String actionName = AppLocalizations.t(actionKey);
      int targetVal = colEnd;
      if (['a','e','h'].contains(typeCode)) {
         return AppLocalizations.translateMove(pieceName, colStart, actionName, targetVal);
      } else {
         int steps = (r1 - r2).abs();
         return AppLocalizations.translateMove(pieceName, colStart, actionName, steps);
      }
    }
  }

  bool _isMoveSafe(Piece piece, int targetCol, int targetRow) {
    List<Piece> simPieces = _pieces.map((e) => e.copy()).toList();
    Piece? simPiece = simPieces.firstWhere((p) => p.id == piece.id, orElse: () => Piece(id:'',col:-1,row:-1,code:''));
    if (simPiece.id.isEmpty) return false;
    simPieces.removeWhere((p) => p.col == targetCol && p.row == targetRow);
    simPiece.col = targetCol;
    simPiece.row = targetRow;
    bool isRed = piece.code.startsWith('r_');
    String myKingCode = isRed ? 'r_k' : 'b_k';
    String enemyPrefix = isRed ? 'b_' : 'r_';
    Piece? myKing = simPieces.firstWhere((p) => p.code == myKingCode, orElse: () => Piece(id:'',col:-1,row:-1,code:''));
    if (myKing.id.isEmpty) return false;
    return !_isKingUnderAttackInList(myKing, enemyPrefix, simPieces);
  }

  bool _isKingUnderAttackInList(Piece king, String enemyPrefix, List<Piece> pieceList) {
    List<Piece> enemies = pieceList.where((p) => p.code.startsWith(enemyPrefix)).toList();
    for (var enemy in enemies) {
      if (_canAttack(enemy, king.col, king.row, pieceList)) return true;
    }
    return false;
  }

  void _checkAndPlaySound({required bool isCapture, required bool movedSideIsRed}) {
    // Lưu ý: Logic này nên chạy SAU khi quân đã di chuyển trong bộ nhớ
    String enemyKingCode = movedSideIsRed ? 'b_k' : 'r_k';
    String enemyPrefix = movedSideIsRed ? 'b_' : 'r_';
    
    // Tìm vua đối phương
    Piece? enemyKing = _pieces.firstWhere((p) => p.code == enemyKingCode, orElse: () => Piece(id:'',col:-1,row:-1,code:''));
    
    bool isCheck = false;
    // Kiểm tra xem vua đối phương có đang bị chiếu bởi quân mình (phe vừa đi) không
    if (enemyKing.col != -1) {
       // Quân mình là phe vừa di chuyển (movedSideIsRed)
       String myPrefix = movedSideIsRed ? 'r_' : 'b_';
       isCheck = _isKingUnderAttackInList(enemyKing, myPrefix, _pieces);
    }

    if (isCheck) {
      SoundService.playCheck(); 
    } else if (isCapture) {
      SoundService.playCapture(); 
    } else {
      SoundService.playMove(); 
    }
  }

  bool _canAttack(Piece p, int tx, int ty, [List<Piece>? customList]) {
    int dx = (tx - p.col).abs();
    int dy = (ty - p.row).abs();
    String type = p.code.substring(2); 
    final pieceList = customList ?? _pieces;
    Piece? getP(int c, int r) {
      try { return pieceList.firstWhere((e) => e.col == c && e.row == r); } catch (_) { return null; }
    }
    int countObstacles(int x1, int y1, int x2, int y2) {
      int count = 0;
      if (x1 == x2) { 
        int min = (y1 < y2) ? y1 : y2;
        int max = (y1 > y2) ? y1 : y2;
        for (int i = min + 1; i < max; i++) {
          if (getP(x1, i) != null) count++;
        }
      } else if (y1 == y2) { 
        int min = (x1 < x2) ? x1 : x2;
        int max = (x1 > x2) ? x1 : x2;
        for (int i = min + 1; i < max; i++) {
          if (getP(i, y1) != null) count++;
        }
      }
      return count;
    }
    switch (type) {
      case 'r': if (p.col != tx && p.row != ty) return false; return countObstacles(p.col, p.row, tx, ty) == 0;
      case 'c': if (p.col != tx && p.row != ty) return false; return countObstacles(p.col, p.row, tx, ty) == 1;
      case 'n': if (!((dx == 1 && dy == 2) || (dx == 2 && dy == 1))) return false; if (dy == 2) { int stepY = (ty > p.row) ? 1 : -1; if (getP(p.col, p.row + stepY) != null) return false; } else { int stepX = (tx > p.col) ? 1 : -1; if (getP(p.col + stepX, p.row) != null) return false; } return true;
      case 'p': bool isRed = p.code.startsWith('r'); if (isRed) { if (ty > p.row) return false; if (ty == p.row) { if (p.row > 4) return false; if (dx != 1) return false; } else { if (dy != 1 || dx != 0) return false; } } else { if (ty < p.row) return false; if (ty == p.row) { if (p.row < 5) return false; if (dx != 1) return false; } else { if (dy != 1 || dx != 0) return false; } } return true;
      case 'k': if (p.col != tx) return false; return countObstacles(p.col, p.row, tx, ty) == 0;
      default: return false;
    }
  }

  void makeUciMove(String uci) {
    List<int>? coords = _parseUci(uci);
    if (coords == null) return;
    int c1 = coords[0]; int r1 = coords[1];
    int c2 = coords[2]; int r2 = coords[3];
    setState(() {
      final piece = _getPieceAt(c1, r1);
      if (piece != null) {
        final target = _getPieceAt(c2, r2);
        bool captured = target != null;
        bool isRed = piece.code.startsWith('r');
        if (target != null) _pieces.remove(target);
        piece.col = c2;
        piece.row = r2;
        _selectedPiece = null; 
        _lastMoveCoords = coords;
        _activeArrows = []; 
        _isRedTurn = !_isRedTurn; 
        _saveHistory();
        // Phát âm thanh sau khi cập nhật state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndPlaySound(isCapture: captured, movedSideIsRed: isRed);
        });
      }
    });
  }

  // --- SỬA ĐỔI: LOGIC CHỌN QUÂN & KHÓA BÀN CỜ ---
  void _onTap(TapUpDetails details) {
    if (widget.isLocked) return; // Nếu bị khóa (máy đang nghĩ), không làm gì cả

    RenderBox box = context.findRenderObject() as RenderBox;
    Offset local = box.globalToLocal(details.globalPosition);
    final int col = (local.dx / _cellW).floor().clamp(0, 8);
    final int row = (local.dy / _cellH).floor().clamp(0, 9);
    if (widget.onSquareTap != null) widget.onSquareTap!(col, row);
    
    setState(() {
      final tappedPiece = _getPieceAt(col, row);

      if (_selectedPiece == null) {
        if (tappedPiece != null) {
          // Nếu chế độ checkTurn bật (đánh với máy), chỉ cho chọn quân đúng lượt
          if (widget.checkTurn) {
            bool pieceIsRed = tappedPiece.code.startsWith('r');
            if (pieceIsRed != _isRedTurn) return; // Không được chọn quân đối phương
          }
          _selectedPiece = tappedPiece;
        }
      } else {
        if (tappedPiece == _selectedPiece) { _selectedPiece = null; return; }
        
        // Kiểm tra nước đi hợp lệ về mặt hình học
        bool geometryValid = GameLogic.isValidMove(_selectedPiece!, col, row, _pieces);
        bool moveSuccess = false;

        if (geometryValid) {
          bool safe = _isMoveSafe(_selectedPiece!, col, row);
          if (safe) {
            bool captured = tappedPiece != null;
            bool isRed = _selectedPiece!.code.startsWith('r');
            if (tappedPiece != null) _pieces.remove(tappedPiece);
            _lastMoveCoords = [_selectedPiece!.col, _selectedPiece!.row, col, row];
            _activeArrows = []; 
            String uciMove = _getUciMove(_selectedPiece!.col, _selectedPiece!.row, col, row);
            _selectedPiece!.col = col;
            _selectedPiece!.row = row;
            _selectedPiece = null;
            
            _isRedTurn = !_isRedTurn; 
            _saveHistory();
            
            // Phát âm thanh
            _checkAndPlaySound(isCapture: captured, movedSideIsRed: isRed);

            if (widget.onMove != null) widget.onMove!(uciMove);
            moveSuccess = true;
          }
        }
        
        // Nếu không đi được (do sai luật hoặc chỉ là tap nhầm vào quân khác)
        if (!moveSuccess) {
          if (tappedPiece != null) {
            // Logic chọn lại quân:
            // Nếu checkTurn bật, chỉ được chọn lại nếu đúng quân phe mình
             if (widget.checkTurn) {
                bool pieceIsRed = tappedPiece.code.startsWith('r');
                if (pieceIsRed == _isRedTurn) {
                  _selectedPiece = tappedPiece;
                } else {
                  // Nếu tap vào quân đối phương khi đang chọn quân mình -> Coi như bỏ chọn
                  _selectedPiece = null;
                }
             } else {
                _selectedPiece = tappedPiece;
             }
          } else {
             // Tap vào ô trống -> bỏ chọn
             _selectedPiece = null; 
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _boardW = widget.size ?? MediaQuery.of(context).size.width * 0.85;
    _cellW = _boardW / 9.0;
    _cellH = _cellW;
    _padX = _cellW / 2.0;
    _padY = _cellH / 2.0;
    _boardH = _cellH * 10.0; 
    return GestureDetector(
      onTapUp: _onTap,
      child: SizedBox(
        width: _boardW,
        height: _boardH,
        child: Stack(
          children: [
            _buildBoardPainter(_boardW, _boardH),
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: BoardOverlayPainter(arrows: _activeArrows, lastMoveFromX: _lastMoveCoords?[0], lastMoveFromY: _lastMoveCoords?[1], lastMoveToX: _lastMoveCoords?[2], lastMoveToY: _lastMoveCoords?[3])))),
            if (_selectedPiece != null) _buildSelection(_selectedPiece!.col, _selectedPiece!.row),
            ..._buildPieces(), 
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPieces() {
    return _pieces.map((piece) {
      final double pieceSize = _cellW * 0.90;
      final double left = _padX + (piece.col * _cellW) - (pieceSize / 2);
      final double top = _padY + (piece.row * _cellH) - (pieceSize / 2);
      return Positioned(left: left, top: top, child: SvgPicture.asset("assets/pieces/${piece.code}.svg", width: pieceSize, height: pieceSize));
    }).toList();
  }

  Widget _buildBoardPainter(double w, double h) {
    return CustomPaint(size: Size(w, h), painter: _BoardPainter(cellWidth: _cellW, cellHeight: _cellH, paddingX: _padX, paddingY: _padY));
  }

  Widget _buildSelection(int col, int row) {
    return Positioned(
      left: _padX + (col * _cellW) - (_cellW / 2),
      top: _padY + (row * _cellH) - (_cellH / 2),
      width: _cellW, height: _cellH,
      child: Container(decoration: BoxDecoration(color: Colors.green.withOpacity(0.5), border: Border.all(color: Colors.green, width: 2), borderRadius: BorderRadius.circular(8))),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final double cellWidth, cellHeight, paddingX, paddingY;
  _BoardPainter({required this.cellWidth, required this.cellHeight, required this.paddingX, required this.paddingY});
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()..color = Colors.brown.shade700..strokeWidth = 1.2;
    final double playableWidth = cellWidth * 8.0;
    final RRect bg = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8));
    canvas.drawRRect(bg, Paint()..color = const Color(0xFFE5C99A));
    canvas.drawRRect(bg, Paint()..color = Colors.brown.shade800..style = PaintingStyle.stroke..strokeWidth = 2);
    for (int r = 0; r <= 9; r++) { final double y = paddingY + (r * cellHeight); canvas.drawLine(Offset(paddingX, y), Offset(paddingX + playableWidth, y), linePaint); }
    for (int c = 0; c <= 8; c++) { final double x = paddingX + (c * cellWidth); if (c == 0 || c == 8) { canvas.drawLine(Offset(x, paddingY), Offset(x, paddingY + size.height - paddingY * 2), linePaint); } else { canvas.drawLine(Offset(x, paddingY), Offset(x, paddingY + cellHeight * 4), linePaint); canvas.drawLine(Offset(x, paddingY + cellHeight * 5), Offset(x, paddingY + size.height - paddingY * 2), linePaint); } }
    final double pX = paddingX, pY = paddingY;
    canvas.drawLine(Offset(pX + cellWidth * 3, pY), Offset(pX + cellWidth * 5, pY + cellHeight * 2), linePaint);
    canvas.drawLine(Offset(pX + cellWidth * 3, pY + cellHeight * 2), Offset(pX + cellWidth * 5, pY), linePaint);
    canvas.drawLine(Offset(pX + cellWidth * 3, pY + cellHeight * 7), Offset(pX + cellWidth * 5, pY + cellHeight * 9), linePaint);
    canvas.drawLine(Offset(pX + cellWidth * 3, pY + cellHeight * 9), Offset(pX + cellWidth * 5, pY + cellHeight * 7), linePaint);
    final tp1 = TextPainter(text: const TextSpan(text: '楚 河', style: TextStyle(color: Colors.brown, fontSize: 18, fontWeight: FontWeight.w600)), textDirection: TextDirection.ltr)..layout();
    final tp2 = TextPainter(text: const TextSpan(text: '漢 界', style: TextStyle(color: Colors.brown, fontSize: 18, fontWeight: FontWeight.w600)), textDirection: TextDirection.ltr)..layout();
    final double rY = pY + (cellHeight * 4.5) - tp1.height / 2;
    tp1.paint(canvas, Offset(paddingX + (cellWidth * 2) - tp1.width/2, rY));
    tp2.paint(canvas, Offset(paddingX + (cellWidth * 6) - tp2.width/2, rY));
  }
  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => false;
}