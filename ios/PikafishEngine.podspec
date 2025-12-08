#
# Đây là file cấu hình giúp Codemagic tự động biên dịch mã nguồn C++
# Hãy lưu file này tại: ios/PikafishEngine.podspec
#

Pod::Spec.new do |s|
  s.name             = 'PikafishEngine'
  s.version          = '1.0.0'
  s.summary          = 'Pikafish Xiangqi Engine for iOS compiled via Podspec.'
  s.description      = <<-DESC
This podspec tells Xcode to compile the Pikafish C++ source code directly directly during the build process.
                       DESC
  s.homepage         = 'https://github.com/your_username/your_repo'
  s.license          = { :type => 'GPLv3', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'email@example.com' }
  
  s.source           = { :path => '.' }
  s.source_files     = 'pikafish_src/**/*.{h,cpp,c,hpp}'

  # --- QUAN TRỌNG: BIẾN THÀNH THƯ VIỆN TĨNH ---
  # Dòng này giúp trộn engine vào App, tránh lỗi Crash khi khởi động
  s.static_framework = true

  s.library          = 'c++'
  s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'ENABLE_BITCODE' => 'NO',
    'OTHER_CPLUSPLUSFLAGS' => '-O3 -DNDEBUG -std=c++17',
    
    # Giữ nguyên cờ xuất khẩu hàm để Dart tìm thấy
    'OTHER_LDFLAGS' => '-Wl,-exported_symbol,_init_pikafish_ios -Wl,-exported_symbol,_send_command_ios -Wl,-exported_symbol,_read_stdout_ios'
  }
  
  s.ios.deployment_target = '12.0'
end