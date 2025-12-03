import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../widgets/board/board_widget.dart';
import '../../widgets/board/eval_bar.dart'; 
import '../../services/engine_service.dart';
import '../../services/sound_service.dart';
import 'edit_board_screen.dart'; 
import '../../utils/app_localizations.dart'; 

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

enum PlayMode { analysis, vsComputer }
enum Difficulty { beginner, intermediate, master, grandmaster }

class _AnalysisScreenState extends State<AnalysisScreen> {
  final BoardController _boardController = BoardController();
  
  String _depth = "0"; 
  String _nodes = "0"; 
  String _nps = "0";
  bool _isAnalyzing = false;
  double _scoreValue = 0.0; 
  bool _isMate = false;
  
  int _mateIn = 0;

  final Map<int, String> _multiPvInfo = {}; 
  final Map<int, String> _multiPvUci = {};
  
  final List<String> _moves = [];
  bool _isRedTurn = true; 
  bool _gameOverDialogShown = false; 

  PlayMode _playMode = PlayMode.analysis; 
  Difficulty _difficulty = Difficulty.intermediate; 
  
  bool _userIsRed = true; 
  bool _isComputerThinking = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initEngine();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _initEngine() async {
    await EngineService().startup();
    EngineService().engineOutput.listen((line) {
      if (line.startsWith("info")) _parseInfo(line);
      if (line.startsWith("bestmove")) _handleBestMove(line);
    });
    Future.delayed(const Duration(milliseconds: 500), () {
       if (EngineService().isRunning) {
         EngineService().sendCommand("isready");
         EngineService().sendCommand("setoption name MultiPV value 3");
       }
    });
  }

  String get _bestScoreText {
    if (_multiPvInfo.containsKey(1)) {
       String info = _multiPvInfo[1]!;
       if (info.contains("(") && info.contains(")")) return info.split("(")[1].split(")")[0];
    }
    return "0.00";
  }

  String get _statusText {
    if (_playMode == PlayMode.vsComputer) {
       if (_isComputerThinking) return AppLocalizations.t('computer_thinking');
       return _userIsRed ? AppLocalizations.t('your_turn_red') : AppLocalizations.t('your_turn_black');
    }
    return AppLocalizations.t('computer_hint');
  }

  void _handleBestMove(String line) {
    if (_playMode == PlayMode.vsComputer && _isComputerThinking) {
      _isComputerThinking = false; 

      final parts = line.split(" ");
      if (parts.length > 1) {
        String bestMove = parts[1];
        
        if (bestMove == "(none)" || bestMove == "null") {
           _showGameOver(true); 
           return;
        }

        int artificialDelay = 0; 

        Future.delayed(Duration(milliseconds: artificialDelay), () {
          if (!mounted) return;
          _boardController.makeMove(bestMove);
          _boardController.clearHint();
          
          setState(() {
            _moves.add(bestMove); 
            _isRedTurn = !_isRedTurn;
            _multiPvInfo.clear(); 
            _multiPvUci.clear();
            _isAnalyzing = false; 
          });
          
          _syncEnginePosition();

          if (_isMate && _mateIn.abs() <= 1) {
             bool computerWon = true; 
             _showGameOver(!computerWon); 
          } else {
             _checkGameState(); 
          }
        });
      }
    }
  }

  void _computerMove() {
    if (_gameOverDialogShown || !mounted) return;
    
    setState(() { 
      _isComputerThinking = true; 
      _isAnalyzing = true; 
    });

    EngineService().sendCommand("stop"); 
    EngineService().sendCommand("setoption name MultiPV value 1");
    _syncEnginePosition();

    String cmd = ""; 
    switch (_difficulty) {
      case Difficulty.beginner: cmd = "go depth 5"; break;
      case Difficulty.intermediate: cmd = "go depth 10"; break;
      case Difficulty.master: cmd = "go depth 16"; break;
      case Difficulty.grandmaster: cmd = "go wtime 900000 btime 900000"; break; 
    }
    EngineService().sendCommand(cmd);
  }

  void _parseInfo(String line) {
    final parts = line.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.contains("score") && parts.contains("mate")) {
        int idx = parts.indexOf("mate");
        if (idx + 1 < parts.length) {
           int m = int.tryParse(parts[idx+1]) ?? 0;
           _mateIn = m;
           if (m == 0 && !_gameOverDialogShown) {
              _showGameOver(!_isRedTurn);
           }
        }
    }
    for (int i = 0; i < parts.length; i++) {
      if (parts[i] == "depth" && i + 1 < parts.length) _depth = parts[i+1];
      if (parts[i] == "nodes" && i + 1 < parts.length) _nodes = _formatNumber(parts[i+1]);
      if (parts[i] == "nps" && i + 1 < parts.length) _nps = _formatNumber(parts[i+1]);
    }
    int pvRank = 1; 
    if (parts.contains("multipv")) {
      int idx = parts.indexOf("multipv");
      if (idx != -1 && idx + 1 < parts.length) pvRank = int.tryParse(parts[idx + 1]) ?? 1;
    }
    String scoreDisplay = "0.00";
    if (parts.contains("score")) {
       int idx = parts.indexOf("score");
       if (idx != -1 && idx + 2 < parts.length) {
          String type = parts[idx + 1]; String val = parts[idx + 2];
          if (type == "cp") {
             double cp = double.tryParse(val) ?? 0;
             if (!_isRedTurn) cp = -cp; 
             scoreDisplay = cp > 0 ? "+$cp" : "$cp";
             if (pvRank == 1) { _scoreValue = cp; _isMate = false; }
          } else if (type == "mate") { 
             scoreDisplay = "Mate $val";
             if (pvRank == 1) {
                double mateVal = double.tryParse(val) ?? 0;
                double displayMateVal = mateVal;
                if (!_isRedTurn) displayMateVal = -displayMateVal;
                _scoreValue = displayMateVal > 0 ? 10000 : -10000;
                _isMate = true;
             }
          }
       }
    }
    if (line.contains(" pv ")) {
       int idx = line.indexOf(" pv ");
       String rawPv = line.substring(idx + 4).trim();
       List<String> pvMoves = rawPv.split(RegExp(r'\s+'));
       if (pvMoves.isNotEmpty) {
         String bestMoveUci = pvMoves[0];
         if (bestMoveUci.length >= 4) {
             String vnMove = _boardController.getVietnameseNotation(bestMoveUci);
             String infoStr = "#$pvRank: $vnMove ($scoreDisplay)";
             _multiPvInfo[pvRank] = infoStr;
             _multiPvUci[pvRank] = bestMoveUci;
             
             if (_playMode == PlayMode.analysis) {
               List<String> hints = [];
               if (_multiPvUci.containsKey(1)) hints.add(_multiPvUci[1]!);
               if (_multiPvUci.containsKey(2)) hints.add(_multiPvUci[2]!);
               if (_multiPvUci.containsKey(3)) hints.add(_multiPvUci[3]!);
               _boardController.showHints(hints);
             }
         }
       }
    }
    if (mounted) setState(() {});
  }

  void _syncEnginePosition() {
    String currentFen = _boardController.getFen(isRedTurn: _isRedTurn);
    EngineService().sendCommand("position fen $currentFen");
  }

  void _onMove(String uciMove) {
    if (_isComputerThinking) return; 

    _boardController.clearHint(); _multiPvInfo.clear(); _multiPvUci.clear();
    setState(() { 
      _moves.add(uciMove); 
      _isRedTurn = !_isRedTurn; 
    });
    _checkGameState(); 
    
    if (_playMode == PlayMode.vsComputer && !_gameOverDialogShown) {
       Future.delayed(const Duration(milliseconds: 100), _computerMove); 
    } else { 
      if (_isAnalyzing) _sendPosToEngineAnalysis(); 
    }
  }

  void _sendPosToEngineAnalysis() { 
    EngineService().sendCommand("stop");
    EngineService().sendCommand("setoption name MultiPV value 3"); 
    _syncEnginePosition(); 
    EngineService().sendCommand("go infinite"); 
  }
  
  void _checkGameState() { 
    if (_gameOverDialogShown) return; 
    String fen = _boardController.getFen(isRedTurn: _isRedTurn); 
    if (!fen.contains('K')) { _showGameOver(false); return; } 
    else if (!fen.contains('k')) { _showGameOver(true); return; } 
  }

  void _showGameOver(bool redWins) {
    if (_gameOverDialogShown) return;
    _gameOverDialogShown = true; 
    _isComputerThinking = false; 
    EngineService().sendCommand("stop");
    
    if (_playMode == PlayMode.vsComputer) {
       if ((redWins && _userIsRed) || (!redWins && !_userIsRed)) {
         SoundService.playWin();
       } else {
         SoundService.playLoss();
       }
    } else {
      SoundService.playWin();
    }

    String title = redWins ? AppLocalizations.t('game_over_red_win') : AppLocalizations.t('game_over_black_win');
    String content = "";
    if (_playMode == PlayMode.vsComputer) {
       if ((redWins && _userIsRed) || (!redWins && !_userIsRed)) { content = AppLocalizations.t('win_msg'); } else { content = AppLocalizations.t('loss_msg'); }
    } else { content = redWins ? AppLocalizations.t('congrats_red') : AppLocalizations.t('congrats_black'); }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFFE5C99A), title: Text(title, style: TextStyle(color: redWins ? Colors.red : Colors.black, fontWeight: FontWeight.bold, fontSize: 24), textAlign: TextAlign.center), content: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.emoji_events, size: 60, color: Colors.amber[800]), const SizedBox(height: 10), Text(content, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)), const SizedBox(height: 5), Text(AppLocalizations.t('checkmate_detected'), style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12))]), actions: [TextButton(onPressed: () { Navigator.of(ctx).pop(); _toggleAnalysis(); }, child: Text(AppLocalizations.t('view_board'), style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.brown), onPressed: () { Navigator.of(ctx).pop(); _resetGame(); }, child: Text(AppLocalizations.t('play_again'), style: const TextStyle(color: Colors.white)))]));
    });
  }

  void _openEditMode() async {
    EngineService().sendCommand("stop"); _boardController.clearHint();
    final resultFen = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditBoardScreen()));
    if (resultFen != null && resultFen is String) {
      bool isRed = resultFen.contains(" w ");
      
      setState(() { 
        _moves.clear(); 
        _depth = "0"; 
        _scoreValue = 0.0; 
        _isMate = false; 
        _multiPvInfo.clear(); 
        _multiPvUci.clear(); 
        _isAnalyzing = true; 
        _gameOverDialogShown = false; 
        _isRedTurn = isRed; 
      });
      
      _boardController.setFen(resultFen); 
      _syncEnginePosition(); 
      
      if (_playMode == PlayMode.vsComputer) { 
        bool isComputerTurn = (_userIsRed && !_isRedTurn) || (!_userIsRed && _isRedTurn); 
        if (isComputerTurn) _computerMove(); 
      } else {
        _sendPosToEngineAnalysis();
      }
    }
  }

  void _resetGame() {
    setState(() { 
      _moves.clear(); 
      _depth = "0"; 
      _scoreValue = 0.0; 
      _isMate = false; 
      _multiPvInfo.clear(); 
      _multiPvUci.clear(); 
      _isAnalyzing = false; 
      _isRedTurn = true; 
      _gameOverDialogShown = false; 
      _isComputerThinking = false; 
    });
    
    _boardController.clearHint(); 
    _boardController.resetBoard(); 
    EngineService().sendCommand("stop"); 
    EngineService().sendCommand("ucinewgame"); 
    EngineService().sendCommand("isready");
    
    if (_playMode == PlayMode.vsComputer && !_userIsRed) { 
        Future.delayed(const Duration(milliseconds: 500), _computerMove); 
    }
  }

  void _toggleAnalysis() {
    if (_playMode == PlayMode.vsComputer) return; 
    if (_isAnalyzing) { 
      EngineService().sendCommand("stop"); 
      _boardController.clearHint(); 
      setState(() { 
        _isAnalyzing = false; 
        _multiPvInfo.clear(); 
        _multiPvUci.clear(); 
      }); 
    } else { 
      setState(() { _isAnalyzing = true; }); 
      _sendPosToEngineAnalysis(); 
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context, 
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFFE5C99A), 
              title: Text(
                AppLocalizations.t('settings'), 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ), 
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(
                      AppLocalizations.t('language'), 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ), 
                    DropdownButton<String>(
                      value: AppLocalizations.currentLanguage, 
                      isExpanded: true, 
                      dropdownColor: const Color(0xFFE5C99A), 
                      items: const [
                        DropdownMenuItem(value: 'vi', child: Text("Tiếng Việt 🇻🇳")), 
                        DropdownMenuItem(value: 'en', child: Text("English 🇺🇸")), 
                        DropdownMenuItem(value: 'zh', child: Text("中文 🇨🇳"))
                      ], 
                      onChanged: (v) { 
                        AppLocalizations.changeLanguage(v!); 
                        setStateDialog(() {}); 
                        setState(() {}); 
                      }
                    ), 
                    const Divider(), 
                    Text(
                      AppLocalizations.t('mode'), 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ), 
                    RadioListTile<PlayMode>(
                      title: Text(AppLocalizations.t('mode_analysis')), 
                      value: PlayMode.analysis, 
                      groupValue: _playMode, 
                      activeColor: Colors.brown, 
                      onChanged: (v) => setStateDialog(() => _playMode = v!)
                    ), 
                    RadioListTile<PlayMode>(
                      title: Text(AppLocalizations.t('mode_vs_computer')), 
                      value: PlayMode.vsComputer, 
                      groupValue: _playMode, 
                      activeColor: Colors.brown, 
                      onChanged: (v) => setStateDialog(() => _playMode = v!)
                    ), 
                    
                    if (_playMode == PlayMode.vsComputer) ...[
                        const Divider(), 
                        Text(
                          AppLocalizations.t('pick_side'), 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ), 
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal, 
                          child: Row(
                            children: [
                              ChoiceChip(
                                  label: Text("Đỏ Tiên (Bạn đi trước)"), 
                                  selected: _userIsRed, 
                                  onSelected: (v) => setStateDialog(() => _userIsRed = true), 
                                  selectedColor: Colors.red[300]
                              ), 
                              const SizedBox(width: 10), 
                              ChoiceChip(
                                  // ĐÃ SỬA: Đổi từ "Đen Hậu" -> "Đen Tiên"
                                  label: Text("Đen Tiên (Máy đi trước)"), 
                                  selected: !_userIsRed, 
                                  onSelected: (v) => setStateDialog(() => _userIsRed = false), 
                                  selectedColor: Colors.black54, 
                                  labelStyle: TextStyle(color: !_userIsRed ? Colors.white : Colors.black)
                              )
                            ]
                          )
                        ), 
                    ],
                    
                    const SizedBox(height: 10), 
                    Text(
                      AppLocalizations.t('difficulty'), 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ), 
                    DropdownButton<Difficulty>(
                      value: _difficulty, 
                      isExpanded: true, 
                      dropdownColor: const Color(0xFFE5C99A), 
                      items: [
                        DropdownMenuItem(value: Difficulty.beginner, child: Text(AppLocalizations.t('diff_easy'))), 
                        DropdownMenuItem(value: Difficulty.intermediate, child: Text(AppLocalizations.t('diff_medium'))), 
                        DropdownMenuItem(value: Difficulty.master, child: Text(AppLocalizations.t('diff_hard'))), 
                        DropdownMenuItem(value: Difficulty.grandmaster, child: Text(AppLocalizations.t('diff_super')))
                      ], 
                      onChanged: (v) => setStateDialog(() => _difficulty = v!)
                    )
                  ]
                )
              ), 
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: Text(
                    AppLocalizations.t('cancel'), 
                    style: const TextStyle(color: Colors.brown)
                  )
                ), 
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown), 
                  onPressed: () { 
                    Navigator.pop(ctx); 
                    setState(() {}); 
                    _resetGame(); 
                  }, 
                  child: Text(
                    AppLocalizations.t('apply'), 
                    style: const TextStyle(color: Colors.white)
                  )
                )
              ] 
            );
          }
        );
      }
    );
  }

  String _formatNumber(String s) { double? n = double.tryParse(s); if (n == null) return s; if (n > 1000000) return "${(n/1000000).toStringAsFixed(1)}M"; if (n > 1000) return "${(n/1000).toStringAsFixed(1)}k"; return s; }
  void _hintMove() { if (!_multiPvUci.containsKey(1)) { _showMsg("..."); return; } String best = _multiPvUci[1]!; _boardController.makeMove(best); _boardController.clearHint(); setState(() { _moves.add(best); _isRedTurn = !_isRedTurn; _multiPvInfo.clear(); _multiPvUci.clear(); }); _checkGameState(); if (_playMode == PlayMode.vsComputer) { Future.delayed(const Duration(milliseconds: 500), _computerMove); } else { _sendPosToEngineAnalysis(); } }
  void _undoMove() { 
    if (_moves.isEmpty) return;
    if (_isComputerThinking) return;
    if (_playMode == PlayMode.vsComputer && _moves.length >= 2) { setState(() { _moves.removeLast(); _moves.removeLast(); _multiPvInfo.clear(); _multiPvUci.clear(); _gameOverDialogShown = false; }); _boardController.undo(); _boardController.undo(); _boardController.clearHint(); } else { setState(() { _moves.removeLast(); _isRedTurn = !_isRedTurn; _multiPvInfo.clear(); _multiPvUci.clear(); _gameOverDialogShown = false; }); _boardController.undo(); _boardController.clearHint(); } _syncEnginePosition(); if (_playMode == PlayMode.analysis) _sendPosToEngineAnalysis(); _showMsg(AppLocalizations.t('undo')); }
  
  void _toggleTurnManually() { setState(() { _isRedTurn = !_isRedTurn; _multiPvInfo.clear(); _multiPvUci.clear(); _boardController.clearHint(); }); if (_playMode == PlayMode.analysis) _sendPosToEngineAnalysis(); _showMsg(AppLocalizations.t('switch_turn')); }
  void _showMsg(String msg) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1))); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2A28),
      appBar: AppBar(backgroundColor: const Color(0xFF1F1E1C), title: Text(AppLocalizations.t('app_title'), style: const TextStyle(color: Colors.white, fontSize: 18)), actions: [IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: _showSettingsDialog, tooltip: AppLocalizations.t('settings'))]),
      body: SafeArea(
        child: Column(
          children: [
            if (_playMode == PlayMode.analysis)
              Container(
                padding: const EdgeInsets.all(12), color: Colors.black26,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _info(AppLocalizations.t('label_depth'), _depth),
                  _info(AppLocalizations.t('label_score'), _bestScoreText, color: (_bestScoreText.startsWith("-") || _bestScoreText.contains("Mate -")) ? Colors.redAccent : Colors.greenAccent),
                  _info(AppLocalizations.t('label_nodes'), _nodes),
                  _info(AppLocalizations.t('label_nps'), _nps)
                ]),
              ),
            
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double evalBarWidth = 40.0; 
                  double horizontalPadding = 16.0; 
                  double availableW = constraints.maxWidth - evalBarWidth - horizontalPadding; 
                  double availableH = constraints.maxHeight;
                  double boardRatio = 9 / 10;
                  double finalBoardW;
                  if (availableW / boardRatio <= availableH) { finalBoardW = availableW; } else { finalBoardW = availableH * boardRatio; }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: EvalBar(score: _scoreValue, isMate: _isMate)),
                       const SizedBox(width: 8),
                       Center(child: BoardWidget(
                         size: finalBoardW, 
                         controller: _boardController, 
                         onMove: _onMove,
                         checkTurn: _playMode == PlayMode.vsComputer,
                         isLocked: _isComputerThinking || (_playMode == PlayMode.vsComputer && _isRedTurn != _userIsRed),
                       )),
                       const SizedBox(width: 8),
                    ],
                  );
                }
              ),
            ),

            Container(
              width: double.infinity, padding: const EdgeInsets.all(12), color: Colors.black26,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_statusText, style: const TextStyle(color: Colors.white54, fontSize: 12)), const SizedBox(height: 4),
                  if (_playMode == PlayMode.analysis) ...[
                    if (_multiPvInfo.isEmpty) const Text("...", style: TextStyle(color: Colors.white, fontSize: 13)),
                    if (_multiPvInfo.containsKey(1)) Text(_multiPvInfo[1]!, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (_multiPvInfo.containsKey(2)) Text(_multiPvInfo[2]!, style: const TextStyle(color: Colors.amberAccent, fontSize: 13)),
                    if (_multiPvInfo.containsKey(3)) Text(_multiPvInfo[3]!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ] else ...[
                    const SizedBox(height: 20), 
                  ]
              ]),
            ),
            _buildControlBar(),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String val, {Color color = Colors.white}) {
    return Column(children: [Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)), const SizedBox(height: 2), Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15))]);
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10), color: const Color(0xFF1F1E1C),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _iconBtn(Icons.undo, AppLocalizations.t('undo'), _undoMove),
          if (_playMode == PlayMode.analysis)
             _iconBtn(Icons.swap_horiz, AppLocalizations.t('switch_turn'), _toggleTurnManually),
          
          if (_playMode == PlayMode.analysis)
            InkWell(
              onTap: _toggleAnalysis,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: _isAnalyzing ? Colors.redAccent : Colors.green, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [Icon(_isAnalyzing ? Icons.stop : Icons.bug_report, color: Colors.white), const SizedBox(width: 5), Text(_isAnalyzing ? AppLocalizations.t('stop') : AppLocalizations.t('analysis'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
              ),
            ),

          if (_playMode == PlayMode.vsComputer)
             _iconBtn(Icons.computer, "Computer", () { if(!_isComputerThinking) _computerMove(); }),

          _iconBtn(Icons.edit_road, AppLocalizations.t('edit_board'), _openEditMode),
          _iconBtn(Icons.lightbulb_outline, AppLocalizations.t('hint'), _hintMove),
          _iconBtn(Icons.cached, AppLocalizations.t('new_game'), _resetGame),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Padding(padding: const EdgeInsets.all(8.0), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white70, size: 24), const SizedBox(height: 2), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10))])));
  }
}