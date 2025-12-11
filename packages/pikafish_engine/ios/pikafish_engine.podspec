Pod::Spec.new do |s|
  s.name             = 'pikafish_engine'
  s.version          = '0.0.1'
  s.summary          = 'Pikafish Xiangqi Engine Wrapper'
  s.description      = 'Bundled Pikafish C++ engine Source Code for Flutter iOS'
  s.homepage         = 'https://github.com/phamchienhd94-byte/Xiangqi-Sensei-'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Pham Chien' => 'email@example.com' }
  s.source           = { :path => '.' }

  # === SOURCE CODE ===
  # Lấy toàn bộ mã nguồn
  s.source_files = 'Classes/**/*.{h,m,mm,swift,cpp,c,hpp}'

  # CHỈ public header cầu nối (Tránh lỗi iosfwd)
  s.public_header_files = 'Classes/pikafish_bridge.h'

  # === PLATFORM ===
  s.platform = :ios, '11.0'
  s.requires_arc = true
  s.static_framework = true
  s.dependency 'Flutter'

  # === BUILD CONFIG (SỰ KẾT HỢP HOÀN HẢO) ===
  s.pod_target_xcconfig = {
    # C++ Chuẩn 17
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'ENABLE_BITCODE' => 'NO',
    
    # Tối ưu hóa tối đa cho Engine (Release mode)
    'OTHER_CPLUSPLUSFLAGS' => '-O3 -DNDEBUG -std=c++17',

    # Đường dẫn Header Search (Quan trọng để tìm file trong folder con)
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/Classes/pikafish"',

    # === BÙA HỘ MỆNH (LINKER FLAGS) ===
    # 1. $(inherited): Giữ lại các cờ mặc định của Flutter
    # 2. -ObjC: Hỗ trợ tốt các thư viện Objective-C
    # 3. -all_load: Bắt buộc nạp toàn bộ code, không bỏ sót file nào
    # 4. -exported_symbol: CHÌA KHÓA VÀNG - Ép Xcode phải public 4 hàm này ra cho Dart tìm thấy
    'OTHER_LDFLAGS' => '$(inherited) -ObjC -all_load -Wl,-exported_symbol,_init_pikafish_ios -Wl,-exported_symbol,_send_command_ios -Wl,-exported_symbol,_read_stdout_ios -Wl,-exported_symbol,_uci_inject_command',

    # TẮT TÍNH NĂNG XÓA CODE THỪA (Để bảo vệ Engine)
    'DEAD_CODE_STRIPPING' => 'NO',
  }

  s.swift_version = '5.0'
end