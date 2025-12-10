Pod::Spec.new do |s|
  s.name             = 'pikafish_engine'
  s.version          = '0.0.1'
  s.summary          = 'Pikafish Xiangqi Engine Wrapper'
  s.description      = 'Bundled Pikafish C++ engine Source Code for Flutter iOS'
  s.homepage         = 'https://github.com/phamchienhd94-byte/Xiangqi-Sensei-'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Pham Chien' => 'email@example.com' }
  s.source           = { :path => '.' }

  # ✅ QUY TẮC VÀNG:
  # TẤT CẢ native code PHẢI nằm trong ios/Classes
  s.source_files = 'Classes/**/*.{h,m,mm,swift,cpp,c,hpp}'

  # Public headers (cho Swift / ObjC / FFI)
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.requires_arc = true
  s.static_framework = true

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY' => 'libc++',
    'ENABLE_BITCODE' => 'NO',

    # ✅ Quan trọng cho engine
    'OTHER_CPLUSPLUSFLAGS' => '-O3 -DNDEBUG -std=c++17',

    # ✅ Header search paths CHUẨN
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/Classes $(PODS_TARGET_SRCROOT)/Classes/pikafish'
  }

  s.swift_version = '5.0'
end
