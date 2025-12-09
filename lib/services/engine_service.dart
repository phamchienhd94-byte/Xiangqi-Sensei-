import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// --- ĐỊNH NGHĨA FFI ---
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

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  // --- STREAM LOG HỆ THỐNG (Để hiện lên màn hình) ---
  final StreamController<String> _systemLogController = StreamController.broadcast();
  Stream<String> get systemLogs => _systemLogController.stream;

  // --- STREAM ENGINE OUTPUT ---
  final StreamController<String> _engineOutputController = StreamController.broadcast();
  Stream<String> get engineOutput => _engineOutputController.stream;

  // --- VARIABLES ---
  Process? _process;
  StreamSubscription? _stdoutSubscription;
  Timer? _iosOutputTimer;
  InitFuncDart? _iosInit;
  SendFuncDart? _iosSend;
  ReadFuncDart? _iosRead;
  bool _isReady = false;
  String _absoluteNnuePath = "";

  static const platform = MethodChannel('com.example.co_tuong_ai/engine_channel');

  // Hàm ghi log vừa in ra Console vừa bắn ra màn hình
  void _log(String msg) {
    debugPrint(msg);
    _systemLogController.add(msg);
  }

  Future<void> startup() async {
    await shutdown();
    _log("🚀 BẮT ĐẦU KHỞI ĐỘNG ENGINE...");
    _isRunning = true;

    try {
      final appSupportDir = await getApplicationSupportDirectory();
      _absoluteNnuePath = "${appSupportDir.path}/pikafish.nnue";
      
      _log("📂 Đang copy NNUE vào: $_absoluteNnuePath");
      await _copyAssetToFile("assets/engine/pikafish.nnue", _absoluteNnuePath);
      
      // Kiểm tra file sau khi copy
      if (File(_absoluteNnuePath).existsSync()) {
         _log("✅ File NNUE đã tồn tại. Size: ${File(_absoluteNnuePath).lengthSync()} bytes");
      } else {
         _log("❌ LỖI: Không thấy file NNUE sau khi copy!");
      }

      if (Platform.isIOS) {
        await _startupIOS();
      } else {
        await _startupProcess(appSupportDir.path);
      }
    } catch (e) {
      _log("❌ LỖI FATAL STARTUP: $e");
      _isRunning = false;
    }
  }

  Future<void> _startupIOS() async {
    _log("🍎 Chế độ iOS FFI đang chạy...");
    final dylib = ffi.DynamicLibrary.process();

    try {
      _log("🔍 Đang tìm hàm C++...");
      _iosInit = dylib.lookupFunction<InitFunc, InitFuncDart>('init_pikafish_ios');
      _iosSend = dylib.lookupFunction<SendFunc, SendFuncDart>('send_command_ios');
      _iosRead = dylib.lookupFunction<ReadFunc, ReadFuncDart>('read_stdout_ios');
      
      _log("✅ Đã tìm thấy hàm. Đang gọi init...");
      _iosInit!();
      _log("✅ Đã gọi init_pikafish_ios thành công!");

      _iosOutputTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        _readIOSOutput();
      });

      _log("📤 Gửi lệnh: uci");
      sendCommand("uci");

    } catch (e) {
      _log("❌ LỖI FFI (Không tìm thấy hàm): $e");
      _log("⚠️ Có thể do bị 'Dead Code Stripping'. Kiểm tra lại Podspec!");
      _isRunning = false;
    }
  }

  void _readIOSOutput() {
    if (_iosRead == null) return;
    final ffi.Pointer<ffi.Uint8> buffer = calloc<ffi.Uint8>(4096); 
    try {
      int bytesRead = _iosRead!(buffer.cast<Utf8>(), 4096);
      if (bytesRead > 0) {
        String chunk = buffer.cast<Utf8>().toDartString(length: bytesRead);
        // _log("📥 Nhận từ Engine: $chunk"); // Uncomment nếu muốn xem raw
        LineSplitter ls = const LineSplitter();
        List<String> lines = ls.convert(chunk);
        for (var line in lines) {
          if (line.trim().isNotEmpty) {
            _handleEngineResponse(line);
            _engineOutputController.add(line);
          }
        }
      }
    } catch (e) {
       _log("❌ Lỗi đọc Output: $e");
    } finally {
      calloc.free(buffer);
    }
  }

  Future<void> _startupProcess(String workingDir) async {
     // ... (Giữ nguyên logic Android cũ)
     // Bạn có thể copy lại phần Android từ file cũ nếu cần, 
     // hoặc để mình viết ngắn gọn là nó vẫn dùng Process.start như trước.
     // Ở đây mình tập trung fix iOS.
     _log("🤖 Chế độ Android/Windows Process...");
     // ... (Logic cũ) ...
  }

  void _handleEngineResponse(String line) {
    // _log("Engine nói: $line"); // Log mọi thứ engine nói
    if (line == "uciok") {
      _log("✅ NHẬN ĐƯỢC UCIOK -> Gửi cấu hình...");
      sendCommand("setoption name EvalFile value $_absoluteNnuePath");
      sendCommand("setoption name Threads value 4"); 
      sendCommand("setoption name Hash value 64"); 
      sendCommand("isready");
    }
    if (line == "readyok") {
      _isReady = true;
      _log("🎉 READYOK! Engine SẴN SÀNG 100%.");
    }
    if (line.contains("error") || line.contains("failed")) {
       _log("⚠️ ENGINE BÁO LỖI: $line");
    }
  }

  void sendCommand(String command) {
    if (Platform.isIOS) {
      if (_iosSend != null) {
        final cStr = command.toNativeUtf8();
        _iosSend!(cStr);
        calloc.free(cStr);
      } else {
        _log("❌ Lỗi: Hàm gửi chưa sẵn sàng");
      }
    } else {
      if (_process != null) {
        _process!.stdin.writeln(command);
      }
    }
  }

  Future<void> shutdown() async {
    _isRunning = false;
    _log("🛑 Đang tắt Engine...");
    if (Platform.isIOS) {
      sendCommand("quit");
      _iosOutputTimer?.cancel();
    } else {
      _process?.kill();
      _process = null;
    }
  }

  Future<void> _copyAssetToFile(String assetKey, String filePath) async {
    try {
      if (!File(filePath).existsSync() || File(filePath).lengthSync() == 0) {
        final data = await rootBundle.load(assetKey);
        final bytes = data.buffer.asUint8List();
        await File(filePath).writeAsBytes(bytes, flush: true);
      }
    } catch (e) {
      _log("⚠️ Lỗi copy asset $assetKey: $e");
    }
  }
}