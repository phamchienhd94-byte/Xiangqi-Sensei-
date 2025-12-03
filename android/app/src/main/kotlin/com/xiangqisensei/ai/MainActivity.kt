package com.xiangqisensei.ai

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.co_tuong_ai/engine_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getNativeLibDir") {
                val libDir = applicationInfo.nativeLibraryDir
                
                // Log kiểm tra đường dẫn
                Log.d("ENGINE_CHECK", "Đường dẫn Native Lib: $libDir")
                
                val directory = File(libDir)
                val files = directory.listFiles()
                if (files != null) {
                    for (file in files) {
                        Log.d("ENGINE_CHECK", " -> Tìm thấy: ${file.name}")
                    }
                }

                result.success(libDir)
            } else {
                result.notImplemented()
            }
        }
    }
}