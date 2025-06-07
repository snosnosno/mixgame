import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'l10n/app_language.dart';
import 'dart:ui' as ui;

// 빌드 타임스탬프 (GitHub Actions에서 주입)
final String BUILD_TIMESTAMP = const String.fromEnvironment(
  'BUILD_TIMESTAMP',
  defaultValue: 'local',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 웹에서 로그 출력 최소화
  if (kIsWeb) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  
  // 앱 시작 시 언어 설정 (필요한 경우)
  // AppLanguage.setLanguage(true); // 예: 한국어로 시작
  // print('Current language is Korean: ${AppLanguage.isKorean}'); // 주석 처리

  // 빌드 타임스탬프 출력 (웹에서만)
  if (kIsWeb) {
    // print('App version: $_appVersion, Build timestamp: $BUILD_TIMESTAMP'); // 주석 처리
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

