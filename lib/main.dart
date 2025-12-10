import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io'; // Cần để check Platform.isIOS

// Import màn hình và service
import 'screens/analysis/analysis_screen.dart';
import 'utils/app_localizations.dart';
import 'services/pikafish_ios_plugin.dart'; // Import Plugin iOS

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // --- KÍCH HOẠT PLUGIN CHO IOS ---
  if (Platform.isIOS) {
    // Hàm này sẽ nạp file .mm và khởi động thread engine ngầm
    PikafishIOSPlugin().initialize();
  }
  // --------------------------------

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cờ Tướng AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFF2C2A28),
        useMaterial3: true,
      ),
      // Cấu hình đa ngôn ngữ
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', ''), // Tiếng Việt
        Locale('en', ''), // English
        Locale('zh', ''), // Trung Quốc
      ],
      home: const AnalysisScreen(),
    );
  }
}