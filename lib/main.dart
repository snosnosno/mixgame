import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'dart:ui' as ui;

// 앱 버전 정의
const String APP_VERSION = "1.0.0";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 웹에서 로그 출력 최소화
  if (kIsWeb) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  
  // Initialize language based on device locale
  final deviceLocale = ui.window.locale.languageCode;
  AppLanguage.setLanguage(deviceLocale == 'ko'); // Korean if 'ko', otherwise English
  
  runApp(const PLOPracticeApp());
}

class PLOPracticeApp extends StatelessWidget {
  const PLOPracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PLO Practice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1B5E20),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          bodySmall: TextStyle(fontSize: 14),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', ''),
        Locale('en', ''),
      ],
      home: const HomePage(),
    );
  }
}

