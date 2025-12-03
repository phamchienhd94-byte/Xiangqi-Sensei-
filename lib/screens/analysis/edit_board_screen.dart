import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/board/board_widget.dart'; 

class EditBoardScreen extends StatefulWidget {
  const EditBoardScreen({super.key});

  @override
  State<EditBoardScreen> createState() => _EditBoardScreenState();
}

class _EditBoardScreenState extends State<EditBoardScreen> {
  final BoardController _controller = BoardController();
  
  String _selectedPieceCode = "r_r"; 
  bool _isRedTurn = true; 

  final List<String> _redPieces = ['r_r', 'r_h', 'r_e', 'r_a', 'r_k', 'r_c', 'r_p'];
  final List<String> _blackPieces = ['b_r', 'b_h', 'b_e', 'b_a', 'b_k', 'b_c', 'b_p'];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _controller.clearBoard();
    });
  }

  void _onSquareTap(int col, int row) {
    if (_selectedPieceCode == 'delete') {
      _controller.putPiece(col, row, ""); 
    } else {
      _controller.putPiece(col, row, _selectedPieceCode);
    }
  }

  void _finish() {
    String fen = _controller.getFen(isRedTurn: _isRedTurn);
    Navigator.pop(context, fen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2A28),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Xếp Cờ Thế", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(onPressed: () => _controller.clearBoard(), icon: const Icon(Icons.delete_sweep, color: Colors.redAccent)),
          IconButton(onPressed: () => _controller.resetBoard(), icon: const Icon(Icons.refresh, color: Colors.white)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: BoardWidget(controller: _controller, onSquareTap: _onSquareTap),
            ),
          ),
          
          // KHU VỰC CHỌN QUÂN (Dùng GridView cho dễ nhìn)
          Container(
            height: 200, // Tăng chiều cao để chứa đủ
            color: const Color(0xFF1F1E1C),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Chọn Tiên
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(label: const Text("Đỏ đi trước"), selected: _isRedTurn, onSelected: (v) => setState(() => _isRedTurn = true), selectedColor: Colors.red[900], labelStyle: TextStyle(color: _isRedTurn ? Colors.white : Colors.black)),
                    const SizedBox(width: 10),
                    ChoiceChip(label: const Text("Đen đi trước"), selected: !_isRedTurn, onSelected: (v) => setState(() => _isRedTurn = false), selectedColor: Colors.grey[800], labelStyle: TextStyle(color: !_isRedTurn ? Colors.white : Colors.black)),
                    const Spacer(),
                    // Nút Xóa
                    _buildOptionItem(icon: Icons.delete_outline, label: "Xóa", isSelected: _selectedPieceCode == 'delete', onTap: () => setState(() => _selectedPieceCode = 'delete')),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Hàng Quân Đỏ
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _redPieces.map((code) => _buildPieceItem(code)).toList(),
                        ),
                        const Divider(color: Colors.white24, height: 16),
                        // Hàng Quân Đen
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _blackPieces.map((code) => _buildPieceItem(code)).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          InkWell(
            onTap: _finish,
            child: Container(width: double.infinity, height: 50, color: Colors.green[700], alignment: Alignment.center, child: const Text("HOÀN THÀNH & PHÂN TÍCH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceItem(String code) {
    bool isSelected = _selectedPieceCode == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedPieceCode = code),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellowAccent.withOpacity(0.2) : null,
          border: isSelected ? Border.all(color: Colors.yellow, width: 2) : Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SvgPicture.asset("assets/pieces/$code.svg", width: 38, height: 38),
      ),
    );
  }

  Widget _buildOptionItem({required IconData icon, required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: isSelected ? Colors.redAccent : Colors.white10, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 4), Text(label, style: const TextStyle(color: Colors.white))]),
      ),
    );
  }
}