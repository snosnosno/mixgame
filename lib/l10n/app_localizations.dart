import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  static const supportedLocales = [
    Locale('ko', ''), // 한국어
    Locale('en', ''), // 영어
  ];

  static const localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  // 현재 언어 코드를 저장하는 SharedPreferences 키
  static const String _languageCodeKey = 'language_code';

  // 기본 언어
  static const Locale defaultLocale = Locale('ko', '');

  // 현재 로케일을 가져오는 메서드
  static Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_languageCodeKey);
    
    if (languageCode != null) {
      return Locale(languageCode, '');
    }
    
    return defaultLocale;
  }

  // 로케일 변경 메서드
  static Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, languageCode);
  }

  // 언어 이름 가져오기
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      default:
        return 'Unknown';
    }
  }
} 