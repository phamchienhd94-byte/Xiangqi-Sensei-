Pod::Spec.new do |s|
  s.name             = 'pikafish_engine'
  s.version          = '0.0.1'
  s.summary          = 'Pikafish Xiangqi Engine Wrapper'
  s.description      = 'Bundled Pikafish C++ engine Source Code for Flutter iOS'
  s.homepage         = 'https://github.com/phamchienhd94-byte/Xiangqi-Sensei-'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Pham Chien' => 'email@example.com' }
  s.source           = { :path => '.' }

  # ✅ QUY TẮC VÀNG 1: Lấy toàn bộ source code (Bridge + Engine)
  # Engine nằm trong Classes/pikafish nên ** sẽ quét thấy hết.
  s.source_files = 'Classes/**/*.{h,m,mm,swift,cpp,c,hpp}'

  # ✅ QUY TẮC VÀNG 2 (FIX LỖI IOSFWD):
  # Chỉ công khai file header cầu nối C đơn giản.
  # TUYỆT ĐỐI KHÔNG công khai các file header phức tạp của engine (như uci.h, benchmark.h)
  s.public_header_files = 'Classes/pikafish_bridge.h'

  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.requires_arc = true
  s.static_framework = true

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'ENABLE_BITCODE' => 'NO',

    # Cờ biên dịch tối ưu cho Engine
    'OTHER_CPLUSPLUSFLAGS' => '-O3 -DNDEBUG -std=c++17',

    # ✅ Header search paths: Trỏ vào folder chứa code C++ gốc
    # $(PODS_TARGET_SRCROOT) chính là thư mục ios của plugin này
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/Classes/pikafish"',
    
    # Chống xóa code (Dead code stripping)
    'OTHER_LDFLAGS' => '-Wl,-all_load',
    'DEAD_CODE_STRIPPING' => 'NO'
  }

  s.swift_version = '5.0'
end