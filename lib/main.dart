import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
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
      home: const HomePage(),
    );
  }
}

