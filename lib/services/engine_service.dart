import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Import MethodChannel
import 'package:path_provider/path_provider.dart';

// Import Plugin cho iOS
import 'package:pikafish_engine/pikafish_engine.dart';

class EngineService {
  static final EngineService _instance = EngineService._internal();
  factory EngineService() => _instance;
  EngineService._internal();

  // --- Biến cho Android/Windows (Giữ nguyên) ---
  Process? _process;
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;

  // --- Biến cho iOS (Mới) ---
  Pikafish? _iosEngine;

  final StreamController<String> _engineOutputController =
      StreamController.broadcast();
  Stream<String> get engineOutput => _engineOutputController.stream;

  // Kiểm tra chạy: Nếu là iOS thì check _iosEngine, còn lại check _process
  bool get isRunning => Platform.isIOS ? (_iosEngine != null) : (_process != null);
  
  bool _isReady = false;
  String _absoluteNnuePath = "";

  // Kênh giao tiếp với Android Native
  static const platform = MethodChannel('com.example.co_tuong_ai/engine_channel');

  Future<void> startup() async {
    // Tắt engine cũ nếu đang chạy
    await shutdown();

    // --- NHÁNH 1: IOS (DÙNG PLUGIN) ---
    if (Platform.isIOS) {
      debugPrint("🍏 STARTUP ENGINE (IOS PLUGIN MODE)...");
      try {
        _iosEngine = Pikafish();
        
        // Đợi một chút cho engine khởi tạo native
        await Future.delayed(const Duration(milliseconds: 500));

        // Lắng nghe output từ plugin và bắn về stream chung
        _iosEngine!.stdout.listen((line) {
          _handleEngineResponse(line); // Vẫn dùng hàm xử lý logic chung
          _engineOutputController.add(line);
        });

        // Gửi lệnh khởi động UCI
        sendCommand("uci");
      } catch (e) {
        debugPrint("❌ Lỗi khởi động iOS Engine: $e");
      }
      return; // Kết thúc hàm, không chạy đoạn dưới
    }

    // --- NHÁNH 2: ANDROID / WINDOWS (GIỮ NGUYÊN LOGIC CŨ 100%) ---
    debugPrint("🚀 STARTUP ENGINE (NATIVE PROCESS MODE)...");

    try {
      String executablePath = "";
      String workingDir = ""; 

      final appSupportDir = await getApplicationSupportDirectory();
      workingDir = appSupportDir.path;

      // --- LOGIC ANDROID (Dùng MethodChannel lấy đường dẫn thật) ---
      if (Platform.isAndroid) {
        try {
          // Hỏi Android: "Thư viện của tôi đang nằm ở đâu?"
          final String libDir = await platform.invokeMethod('getNativeLibDir');
          debugPrint("📍 Android Native Lib Dir: $libDir");
          
          // Ghép tên file vào đường dẫn
          executablePath = "$libDir/libpikafish.so";
          
          if (!File(executablePath).existsSync()) {
            debugPrint("❌ Vẫn không thấy file tại: $executablePath");
          }
        } catch (e) {
          debugPrint("❌ Lỗi gọi MethodChannel: $e");
          return;
        }
      } 
      // --- LOGIC WINDOWS ---
      else if (Platform.isWindows) {
        executablePath = "$workingDir/pikafish.exe";
        if (!await File(executablePath).exists()) {
           await _copyAssetToFile("assets/engine/pikafish.exe", executablePath);
        }
      }

      // --- NNUE (Copy từ assets) ---
      // Lưu ý: iOS không dùng file NNUE rời theo cách này (plugin tự lo), 
      // nên đoạn này chỉ chạy cho Android/Windows
      _absoluteNnuePath = "$workingDir/pikafish.nnue";
      await _copyAssetToFile("assets/engine/pikafish.nnue", _absoluteNnuePath);

      debugPrint("➤ Exe Path: $executablePath");

      // --- KHỞI CHẠY ---
      _process = await Process.start(
        executablePath, 
        [],
        workingDirectory: workingDir, 
        runInShell: false, 
      );
      
      debugPrint("✅ ENGINE STARTED! PID: ${_process!.pid}");

      _process!.exitCode.then((code) {
        debugPrint("💀 Engine exited with code: $code");
        _process = null;
      });

      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        _handleEngineResponse(line);
        _engineOutputController.add(line);
      });
      
      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        debugPrint("❌ STDERR: $line");
      });

      sendCommand("uci");

    } catch (e) {
      debugPrint("❌❌❌ LỖI FATAL: $e");
    }
  }

  void _handleEngineResponse(String line) {
    if (line == "uciok") {
      debugPrint("✓ uciok -> Config...");
      
      // iOS Plugin thường đã tích hợp sẵn NNUE bên trong, 
      // nhưng nếu cần load file rời thì logic plugin sẽ khác.
      // Tạm thời với iOS ta bỏ qua lệnh load EvalFile nếu plugin tự xử lý.
      if (!Platform.isIOS) {
        sendCommand("setoption name EvalFile value $_absoluteNnuePath");
      }

      // Cấu hình Threads/Hash
      if (Platform.isAndroid || Platform.isIOS) {
         // Mobile (Android/iOS)
         sendCommand("setoption name Threads value 4"); 
         sendCommand("setoption name Hash value 32");   
      } else {
         // PC (Windows)
         sendCommand("setoption name Threads value 4"); 
         sendCommand("setoption name Hash value 128");  
      }
      sendCommand("isready");
    }

    if (line == "readyok") {
      _isReady = true;
      debugPrint("🎉 READYOK! Engine đã sẵn sàng.");
    }
  }

  Future<void> _copyAssetToFile(String assetKey, String filePath) async {
    try {
      final data = await rootBundle.load(assetKey);
      final bytes = data.buffer.asUint8List();
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      // Bỏ qua lỗi asset không tồn tại
    }
  }

  void sendCommand(String command) {
    // 1. Gửi cho iOS Plugin
    if (Platform.isIOS && _iosEngine != null) {
      // Plugin này dùng setter stdin để gửi lệnh
      _iosEngine!.stdin = command;
      return;
    }

    // 2. Gửi cho Process (Android/Windows)
    if (_process != null) {
      try {
        _process!.stdin.writeln(command);
      } catch (e) {}
    }
  }

  Future<void> shutdown() async {
    // Tắt iOS Engine
    if (_iosEngine != null) {
      // Gửi lệnh quit UCI
      try { _iosEngine!.stdin = 'quit'; } catch(_) {}
      
      // Gọi dispose của plugin (như tài liệu hướng dẫn)
      _iosEngine!.dispose();
      _iosEngine = null;
    }

    // Tắt Android/Windows Process
    if (_process != null) {
      sendCommand("quit");
      await _stdoutSubscription?.cancel();
      await _stderrSubscription?.cancel();
      _process?.kill();
      _process = null;
    }
  }
}