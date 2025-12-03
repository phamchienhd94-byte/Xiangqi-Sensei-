import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 

class AppLocalizations {
  final Locale locale;
  static String currentLanguage = 'vi';

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static void changeLanguage(String lang) {
    if (_localizedValues.containsKey(lang)) {
      currentLanguage = lang;
    }
  }

  static String t(String key) {
    return _localizedValues[currentLanguage]?[key] ?? key;
  }

  static String translateMove(String piece, int from, String action, dynamic to) {
    if (currentLanguage == 'vi') {
      return "$piece $from $action $to";
    } else if (currentLanguage == 'zh') {
      return "$piece$from$action$to";
    } else {
      return "$piece $from$action$to"; 
    }
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'vi': {
      'app_title': 'Cờ Tướng AI',
      'analysis': 'Phân tích',
      'vs_computer': 'Đấu với Máy',
      'edit_board': 'Xếp Cờ',
      'settings': 'Cài đặt',
      'new_game': 'Ván mới',
      'undo': 'Lùi',
      'hint': 'Gợi ý',
      'flip_board': 'Xoay bàn cờ',
      'switch_turn': 'Đổi lượt',
      'stop': 'Dừng',
      'computer_thinking': 'Máy đang nghĩ...',
      'your_turn_red': 'Lượt bạn (Đỏ)',
      'your_turn_black': 'Lượt bạn (Đen)',
      'computer_hint': 'Gợi ý máy tính:',
      'game_over_red_win': 'ĐỎ THẮNG!',
      'game_over_black_win': 'ĐEN THẮNG!',
      'congrats_red': 'Bên Đỏ đã thắng.',
      'congrats_black': 'Bên Đen đã thắng.',
      'win_msg': 'Bạn đã thắng máy!',
      'loss_msg': 'Máy đã thắng!',
      'checkmate_detected': '(Chiếu bí)',
      'view_board': 'Xem lại',
      'play_again': 'Chơi lại',
      'apply': 'Áp dụng',
      'cancel': 'Hủy',
      'mode': 'Chế độ:',
      'mode_analysis': 'Phân tích',
      'mode_vs_computer': 'Chơi với Máy',
      'pick_side': 'Cầm quân:',
      'side_red': 'Đỏ (Tiên)',
      'side_black': 'Đen (Hậu)',
      'difficulty': 'Độ khó:',
      'diff_easy': 'Dễ',
      'diff_medium': 'Vừa',
      'diff_hard': 'Khó',
      'diff_super': 'Siêu khó',
      'language': 'Ngôn ngữ:',
      'piece_k': 'Tướng', 'piece_a': 'Sĩ', 'piece_e': 'Tượng', 
      'piece_h': 'Mã', 'piece_r': 'Xe', 'piece_c': 'Pháo', 'piece_p': 'Tốt',
      'act_advance': 'Tấn', 'act_retreat': 'Thoái', 'act_traverse': 'Bình',
      // THÔNG SỐ MỚI
      'label_depth': 'Độ sâu',
      'label_score': 'Điểm',
      'label_nodes': 'Số thế',
      'label_nps': 'Tốc độ',
    },
    'en': {
      'app_title': 'Chinese Chess AI',
      'analysis': 'Analysis',
      'vs_computer': 'Vs Computer',
      'edit_board': 'Edit',
      'settings': 'Settings',
      'new_game': 'New Game',
      'undo': 'Undo',
      'hint': 'Hint',
      'flip_board': 'Flip',
      'switch_turn': 'Switch',
      'stop': 'Stop',
      'computer_thinking': 'Thinking...',
      'your_turn_red': 'Your Turn (Red)',
      'your_turn_black': 'Your Turn (Black)',
      'computer_hint': 'Suggestion:',
      'game_over_red_win': 'RED WINS!',
      'game_over_black_win': 'BLACK WINS!',
      'congrats_red': 'Red Won.',
      'congrats_black': 'Black Won.',
      'win_msg': 'You Won!',
      'loss_msg': 'Computer Won!',
      'checkmate_detected': '(Checkmate)',
      'view_board': 'View',
      'play_again': 'Replay',
      'apply': 'OK',
      'cancel': 'Cancel',
      'mode': 'Mode:',
      'mode_analysis': 'Analysis',
      'mode_vs_computer': 'Vs Computer',
      'pick_side': 'Side:',
      'side_red': 'Red',
      'side_black': 'Black',
      'difficulty': 'Level:',
      'diff_easy': 'Easy',
      'diff_medium': 'Medium',
      'diff_hard': 'Hard',
      'diff_super': 'Pro',
      'language': 'Language:',
      'piece_k': 'K', 'piece_a': 'A', 'piece_e': 'E', 
      'piece_h': 'H', 'piece_r': 'R', 'piece_c': 'C', 'piece_p': 'P',
      'act_advance': '+', 'act_retreat': '-', 'act_traverse': '.',
      // Tech Specs
      'label_depth': 'Depth',
      'label_score': 'Score',
      'label_nodes': 'Nodes',
      'label_nps': 'NPS',
    },
    'zh': {
      'app_title': '中国象棋 AI',
      'analysis': '分析',
      'vs_computer': '对弈',
      'edit_board': '排局',
      'settings': '设置',
      'new_game': '新局',
      'undo': '悔棋',
      'hint': '提示',
      'flip_board': '翻转',
      'switch_turn': '换边',
      'stop': '停止',
      'computer_thinking': '思考中...',
      'your_turn_red': '红方走',
      'your_turn_black': '黑方走',
      'computer_hint': '建议:',
      'game_over_red_win': '红胜!',
      'game_over_black_win': '黑胜!',
      'congrats_red': '红方获胜',
      'congrats_black': '黑方获胜',
      'win_msg': '你赢了!',
      'loss_msg': '电脑胜!',
      'checkmate_detected': '(绝杀)',
      'view_board': '查看',
      'play_again': '重来',
      'apply': '确定',
      'cancel': '取消',
      'mode': '模式:',
      'mode_analysis': '分析',
      'mode_vs_computer': '对弈',
      'pick_side': '选边:',
      'side_red': '红(先)',
      'side_black': '黑(后)',
      'difficulty': '难度:',
      'diff_easy': '初级',
      'diff_medium': '中级',
      'diff_hard': '高级',
      'diff_super': '特大',
      'language': '语言:',
      'piece_k': '将', 'piece_a': '士', 'piece_e': '象', 
      'piece_h': '马', 'piece_r': '车', 'piece_c': '炮', 'piece_p': '卒',
      'act_advance': '进', 'act_retreat': '退', 'act_traverse': '平',
      // Tech Specs
      'label_depth': '深度',
      'label_score': '分数',
      'label_nodes': '节点',
      'label_nps': '速度',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['vi', 'en', 'zh'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) {
    AppLocalizations.currentLanguage = locale.languageCode;
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }
  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}