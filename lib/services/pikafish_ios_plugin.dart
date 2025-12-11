import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// ===== C function signatures =====
typedef InitFunc = Void Function();
typedef SendCommandFunc = Void Function(Pointer<Utf8>);
typedef ReadStdoutFunc = Int32 Function(Pointer<Int8>, Int32);

// ===== Dart function signatures =====
typedef Init = void Function();
typedef SendCommand = void Function(Pointer<Utf8>);
typedef ReadStdout = int Function(Pointer<Int8>, int);

class PikafishIOSPlugin {
  static final PikafishIOSPlugin _instance = PikafishIOSPlugin._internal();
  factory PikafishIOSPlugin() => _instance;
  PikafishIOSPlugin._internal();

  late final DynamicLibrary _dylib;
  late final Init _initFn;
  late final SendCommand _sendCommandFn;
  late final ReadStdout _readStdoutFn;

  bool _isLoaded = false;
  Timer? _readTimer;
  void Function(String)? onEngineOutput;

  void initialize() {
    if (!Platform.isIOS || _isLoaded) return;

    try {
      print("🚀 PikafishIOS: Bắt đầu nạp Engine từ Main Binary...");
      
      // Trên iOS, plugin được biên dịch tĩnh vào App, nên dùng process()
      _dylib = DynamicLibrary.process();

      // --- BƯỚC KIỂM TRA SỰ SỐNG (RẤT QUAN TRỌNG) ---
      // Kiểm tra xem Linker có xóa nhầm hàm init_pikafish_ios không
      final hasSymbol = _dylib.providesSymbol('init_pikafish_ios');
      print("🔍 PikafishIOS: Kiểm tra symbol 'init_pikafish_ios'... Kết quả: $hasSymbol");

      if (!hasSymbol) {
         print("❌ LỖI NGHIÊM TRỌNG: Engine code đã bị Xcode xóa mất (Dead Code Stripping)!");
         print("👉 Giải pháp: Kiểm tra lại cờ -exported_symbol trong podspec.");
         return;
      }
      // ----------------------------------------------

      _initFn = _dylib
          .lookup<NativeFunction<InitFunc>>('init_pikafish_ios')
          .asFunction();

      _sendCommandFn = _dylib
          .lookup<NativeFunction<SendCommandFunc>>('send_command_ios')
          .asFunction();

      _readStdoutFn = _dylib
          .lookup<NativeFunction<ReadStdoutFunc>>('read_stdout_ios')
          .asFunction();

      // Gọi hàm khởi tạo C++
      _initFn();
      _isLoaded = true;

      print('✅ Pikafish iOS Engine initialized SUCCESS!');
      _startReadingLoop();
    } catch (e, s) {
      print('❌ Pikafish iOS FFI load error: $e');
      print(s);
    }
  }

  void sendCommand(String command) {
    if (!_isLoaded) {
      print("⚠️ Cảnh báo: Gửi lệnh '$command' khi Engine chưa load xong.");
      return;
    }
    final ptr = command.toNativeUtf8();
    _sendCommandFn(ptr);
    calloc.free(ptr);
  }

  void _startReadingLoop() {
    _readTimer?.cancel();

    _readTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (!_isLoaded) return;

        final buffer = calloc<Int8>(4096);
        try {
          final len = _readStdoutFn(buffer, 4096);
          if (len > 0) {
            final text = buffer.cast<Utf8>().toDartString();
            if (text.trim().isNotEmpty) {
              // Log ra để debug
              print("ENGINE -> APP: $text");
              onEngineOutput?.call(text);
            }
          }
        } finally {
          calloc.free(buffer);
        }
      },
    );
  }

  void dispose() {
    _readTimer?.cancel();
    _isLoaded = false;
  }
}