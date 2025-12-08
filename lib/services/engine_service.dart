import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ffi' as ffi; // Thư viện FFI
import 'package:ffi/ffi.dart'; // Thư viện hỗ trợ String C++
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// --- ĐỊNH NGHĨA HÀM C++ CHO IOS ---
typedef InitFunc = ffi.Void Function();
typedef InitFuncDart = void Function();

typedef SendFunc = ffi.Void Function(ffi.Pointer<Utf8>);
typedef SendFuncDart = void Function(ffi.Pointer<Utf8>);

typedef ReadFunc = ffi.Int32 Function(ffi.Pointer<Utf8>, ffi.Int32);
typedef ReadFuncDart = int Function(ffi.Pointer<Utf8>, int);

class EngineService {
  static final EngineService _instance = EngineService._internal();
  factory EngineService() => _instance;
  EngineService._internal();

  // --- BIẾN CHO ANDROID/WINDOWS ---
  Process? _process;
  StreamSubscription? _stdoutSubscription;

  // --- BIẾN CHO IOS (FFI) ---
  Timer? _iosOutputTimer;
  InitFuncDart? _iosInit;
  SendFuncDart? _iosSend;
  ReadFuncDart? _iosRead;

  // Stream Output chung cho cả 2 hệ
  final StreamController<String> _engineOutputController =
      StreamController.broadcast();
  Stream<String> get engineOutput => _engineOutputController.stream;

  bool _isReady = false;
  String _absoluteNnuePath = "";

  static const platform = MethodChannel('com.example.co_tuong_ai/engine_channel');

  Future<void> startup() async {
    await shutdown(); // Tắt engine cũ nếu có
    debugPrint("🚀 STARTUP ENGINE...");

    try {
      // 1. Chuẩn bị file NNUE (Bắt buộc cho mọi nền tảng)
      final appSupportDir = await getApplicationSupportDirectory();
      _absoluteNnuePath = "${appSupportDir.path}/pikafish.nnue";
      await _copyAssetToFile("assets/engine/pikafish.nnue", _absoluteNnuePath);

      // 2. Phân chia luồng xử lý theo hệ điều hành
      if (Platform.isIOS) {
        await _startupIOS();
      } else {
        await _startupProcess(appSupportDir.path);
      }

    } catch (e) {
      debugPrint("❌❌❌ LỖI FATAL: $e");
    }
  }

  // ================= LOGIC IOS (FFI) =================
  Future<void> _startupIOS() async {
    debugPrint("🍎 Đang khởi động chế độ iOS FFI...");
    
    // Liên kết với chính process của App (vì thư viện đã được nhúng vào)
    final dylib = ffi.DynamicLibrary.process();

    try {
      // Tìm các hàm C++ chúng ta vừa viết
      _iosInit = dylib.lookupFunction<InitFunc, InitFuncDart>('init_pikafish_ios');
      _iosSend = dylib.lookupFunction<SendFunc, SendFuncDart>('send_command_ios');
      _iosRead = dylib.lookupFunction<ReadFunc, ReadFuncDart>('read_stdout_ios');

      // Gọi hàm khởi tạo
      _iosInit!();
      debugPrint("✅ iOS Engine Thread Started!");

      // Tạo vòng lặp để đọc dữ liệu từ C++ về (Polling)
      _iosOutputTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        _readIOSOutput();
      });

      // Gửi lệnh chào hỏi
      sendCommand("uci");

    } catch (e) {
      debugPrint("❌ Không tìm thấy hàm FFI: $e");
    }
  }

  void _readIOSOutput() {
    if (_iosRead == null) return;

    // Cấp phát bộ nhớ đệm để đọc
    final buffer = calloc<Utf8>(4096); 
    try {
      // Gọi hàm C++ để đọc
      int bytesRead = _iosRead!(buffer, 4096);
      
      if (bytesRead > 0) {
        // Chuyển từ C String sang Dart String
        String chunk = buffer.toDartString(length: bytesRead);
        // Tách dòng vì có thể nhận nhiều dòng 1 lúc
        LineSplitter ls = const LineSplitter();
        List<String> lines = ls.convert(chunk);
        
        for (var line in lines) {
          if (line.trim().isNotEmpty) {
            _handleEngineResponse(line);
            _engineOutputController.add(line);
          }
        }
      }
    } finally {
      calloc.free(buffer); // Giải phóng bộ nhớ
    }
  }

  // ================= LOGIC ANDROID/WINDOWS (PROCESS) =================
  Future<void> _startupProcess(String workingDir) async {
    String executablePath = "";
    
    if (Platform.isAndroid) {
      try {
        final String libDir = await platform.invokeMethod('getNativeLibDir');
        executablePath = "$libDir/libpikafish.so";
      } catch (e) {
        debugPrint("❌ Lỗi Android native path: $e");
        return;
      }
    } else if (Platform.isWindows) {
      executablePath = "$workingDir/pikafish.exe";
      if (!await File(executablePath).exists()) {
         await _copyAssetToFile("assets/engine/pikafish.exe", executablePath);
      }
    }

    debugPrint("➤ Executing: $executablePath");
    _process = await Process.start(
      executablePath, 
      [],
      workingDirectory: workingDir, 
    );

    _stdoutSubscription = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _handleEngineResponse(line);
      _engineOutputController.add(line);
    });
    
    sendCommand("uci");
  }

  // ================= CHUNG =================
  void _handleEngineResponse(String line) {
    // debugPrint("Engine: $line"); // Uncomment nếu muốn debug kỹ
    if (line == "uciok") {
      debugPrint("✓ uciok -> Config...");
      sendCommand("setoption name EvalFile value $_absoluteNnuePath");
      sendCommand("setoption name Threads value 4"); 
      sendCommand("setoption name Hash value ${Platform.isIOS ? 64 : 128}"); // iOS giảm RAM chút cho an toàn
      sendCommand("isready");
    }

    if (line == "readyok") {
      _isReady = true;
      debugPrint("🎉 READYOK! Engine sẵn sàng chiến đấu.");
    }
  }

  void sendCommand(String command) {
    if (Platform.isIOS) {
      if (_iosSend != null) {
        final cStr = command.toNativeUtf8();
        _iosSend!(cStr);
        calloc.free(cStr);
      }
    } else {
      if (_process != null) {
        _process!.stdin.writeln(command);
      }
    }
  }

  Future<void> shutdown() async {
    if (Platform.isIOS) {
      sendCommand("quit");
      _iosOutputTimer?.cancel();
    } else {
      if (_process != null) {
        sendCommand("quit");
        _process!.kill();
        _process = null;
      }
    }
  }

  Future<void> _copyAssetToFile(String assetKey, String filePath) async {
    try {
      // Chỉ copy nếu file chưa tồn tại hoặc file rỗng
      if (!File(filePath).existsSync() || File(filePath).lengthSync() == 0) {
        final data = await rootBundle.load(assetKey);
        final bytes = data.buffer.asUint8List();
        await File(filePath).writeAsBytes(bytes, flush: true);
        debugPrint("📂 Copied asset: $assetKey");
      }
    } catch (e) {
      debugPrint("⚠️ Asset warning: $e");
    }
  }
}