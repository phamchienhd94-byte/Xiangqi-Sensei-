import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Import MethodChannel
import 'package:path_provider/path_provider.dart';

class EngineService {
  static final EngineService _instance = EngineService._internal();
  factory EngineService() => _instance;
  EngineService._internal();

  Process? _process;
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;

  final StreamController<String> _engineOutputController =
      StreamController.broadcast();
  Stream<String> get engineOutput => _engineOutputController.stream;

  bool get isRunning => _process != null;
  bool _isReady = false;
  String _absoluteNnuePath = "";

  // Kênh giao tiếp với Android Native
  static const platform = MethodChannel('com.example.co_tuong_ai/engine_channel');

  Future<void> startup() async {
    if (_process != null) {
      await shutdown();
    }

    debugPrint("🚀 STARTUP ENGINE (METHOD CHANNEL V2)...");

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
            // Kiểm tra lại xem bạn đã bỏ file vào jniLibs/arm64-v8a chưa?
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
      sendCommand("setoption name EvalFile value $_absoluteNnuePath");
      if (Platform.isAndroid) {
         sendCommand("setoption name Threads value 4"); 
         sendCommand("setoption name Hash value 32");   
      } else {
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
      // Bỏ qua lỗi asset không tồn tại (ví dụ exe trên android)
    }
  }

  void sendCommand(String command) {
    if (_process != null) {
      try {
        _process!.stdin.writeln(command);
      } catch (e) {}
    }
  }

  Future<void> shutdown() async {
    if (_process != null) {
      sendCommand("quit");
      await _stdoutSubscription?.cancel();
      await _stderrSubscription?.cancel();
      _process?.kill();
      _process = null;
    }
  }
}