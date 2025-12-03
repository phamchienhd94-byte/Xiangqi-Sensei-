import 'package:audioplayers/audioplayers.dart';

class SoundService {
  // Thay vì dùng 1 biến static _player, ta tạo hàm helper để phát tiếng ngay lập tức
  static Future<void> _playSound(String fileName) async {
    try {
      final player = AudioPlayer();
      // Chế độ ReleaseMode.release để giải phóng tài nguyên ngay sau khi phát xong
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      // Bỏ qua lỗi
    }
  }

  static Future<void> playMove() async {
    await _playSound('move.mp3');
  }

  static Future<void> playCapture() async {
    await _playSound('capture.mp3');
  }
  
  static Future<void> playCheck() async {
    await _playSound('check.mp3');
  }

  static Future<void> playWin() async {
    await _playSound('win.mp3');
  }
  
  static Future<void> playLoss() async {
    // Nếu chưa có file loss thì dùng tạm win
    await _playSound('loss.mp3'); 
  }
}