plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// --- 1. THÊM ĐOẠN NÀY ĐỂ ĐỌC FILE KEY.PROPERTIES ---
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
// --------------------------------------------------

android {
    namespace = "com.xiangqisensei.ai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.xiangqisensei.ai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // *** BỔ SUNG: CẤU HÌNH ĐÓNG GÓI CHO FILE NATIVE (.so) ***
    // Điều này buộc Android giải nén file .so ra khỏi APK/AAB để có thể chạy được (executable).
    packaging {
        jniLibs {
            // Đảm bảo các thư viện native được giải nén ra thư mục con /lib của app
            // Đây là giải pháp hiệu quả nhất để chạy file binary (.so) từ Flutter
            useLegacyPackaging = true
        }
    }
    // *******************************************************


    // --- 2. THÊM CẤU HÌNH KÝ (SIGNING CONFIGS) ---
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    // ---------------------------------------------

    buildTypes {
        release {
            // --- 3. ÁP DỤNG CHỮ KÝ VÀO BẢN RELEASE ---
            signingConfig = signingConfigs.getByName("release")
            // -----------------------------------------
            
            // Tắt chế độ làm rối mã để tránh lỗi không mong muốn
            isMinifyEnabled = false 
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}