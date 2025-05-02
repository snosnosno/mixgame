import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_card_new/home_page.dart';
import 'package:random_card_new/winner_game_page.dart';
import 'package:random_card_new/pot_limit_page.dart';

void main() {
  group('HomePage Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('HomePage renders correctly on mobile', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          home: const HomePage(),
        ),
      );

      expect(find.text('PLO Practice'), findsOneWidget);
      expect(find.text('Winner Guessing Game'), findsOneWidget);
      expect(find.text('Pot Limit Calculator'), findsOneWidget);
      expect(find.text('made by SNO'), findsOneWidget);

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsNWidgets(2));

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });

    testWidgets('HomePage renders correctly on tablet', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(768, 1024);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          home: const HomePage(),
        ),
      );

      expect(find.text('PLO Practice'), findsOneWidget);
      expect(find.text('Winner Guessing Game'), findsOneWidget);
      expect(find.text('Pot Limit Calculator'), findsOneWidget);
      expect(find.text('made by SNO'), findsOneWidget);

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsNWidgets(2));

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });

    testWidgets('HomePage renders correctly on desktop', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1366, 768);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          home: const HomePage(),
        ),
      );

      expect(find.text('PLO Practice'), findsOneWidget);
      expect(find.text('Winner Guessing Game'), findsOneWidget);
      expect(find.text('Pot Limit Calculator'), findsOneWidget);
      expect(find.text('made by SNO'), findsOneWidget);

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsNWidgets(2));

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });

    testWidgets('Navigation works correctly', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(360, 640);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          home: const HomePage(),
        ),
      );

      await tester.tap(find.text('Winner Guessing Game'));
      await tester.pumpAndSettle();
      expect(find.byType(WinnerGamePage), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pot Limit Calculator'));
      await tester.pumpAndSettle();
      expect(find.byType(PotLimitPage), findsOneWidget);

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });
  });
} 