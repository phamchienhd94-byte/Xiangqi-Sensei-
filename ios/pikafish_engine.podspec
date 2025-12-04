#
# Đây là file cấu hình giúp Codemagic tự động biên dịch mã nguồn C++
# Hãy lưu file này tại: ios/pikafish_engine.podspec
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
  
  # Đảm bảo đường dẫn này trỏ đúng đến nơi bạn chứa mã nguồn C++
  # Dấu **/* nghĩa là lấy tất cả file trong thư mục con
  s.source           = { :path => '.' }
  s.source_files     = 'pikafish_src/**/*.{h,cpp,c,hpp}'

  # Cấu hình biên dịch quan trọng cho iOS
  s.library          = 'c++'
  s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17', # Pikafish cần C++17 trở lên
    'CLANG_CXX_LIBRARY' => 'libc++',
    # Tắt bitcode nếu cần thiết (các bản Xcode mới mặc định tắt)
    'ENABLE_BITCODE' => 'NO',
    # Các cờ tối ưu hóa để Engine chạy nhanh
    'OTHER_CPLUSPLUSFLAGS' => '-O3 -DNDEBUG -std=c++17'
  }
  
  # Yêu cầu phiên bản iOS tối thiểu
  s.ios.deployment_target = '12.0'
end
