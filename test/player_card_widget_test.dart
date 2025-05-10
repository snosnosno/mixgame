import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:random_card_new/models/player.dart';
import 'package:random_card_new/widgets/pot_limit/player_card_widget.dart';

void main() {
  testWidgets('PlayerCardWidget - 기본 렌더링 테스트', (WidgetTester tester) async {
    // 테스트용 Player 객체 생성
    final player = Player(
      name: 'Test Player',
      chips: 5000,
      hand: [],
      position: Position.dealer,
    );
    
    // 테스트용 액션 히스토리
    final actionHistory = ['CALL: 200', 'RAISE: 500'];
    
    // 위젯 렌더링
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              PlayerCardWidget(
                player: player,
                index: 0,
                actionHistory: actionHistory,
                initialChips: 5000,
                screenWidth: 400,
                screenHeight: 800,
                boxWidth: 100,
                boxHeight: 110,
                isSmallScreen: false,
                fontScale: 1.0,
                formatAmount: (amount) => amount.toString(),
              ),
            ],
          ),
        ),
      ),
    );
    
    // 위젯이 화면에 렌더링되었는지 확인
    expect(find.text('DEALER'), findsOneWidget);
    expect(find.text('5000'), findsOneWidget);
    
    // 액션 히스토리가 표시되는지 확인
    expect(find.text('CALL: 200'), findsOneWidget);
    expect(find.text('RAISE: 500'), findsOneWidget);
  });
  
  testWidgets('PlayerCardWidget - ALL-IN 상태 테스트', (WidgetTester tester) async {
    // 테스트용 ALL-IN Player 객체 생성
    final player = Player(
      name: 'All-in Player',
      chips: 0,
      hand: [],
      position: Position.bigBlind,
      isAllIn: true,
    );
    
    // 위젯 렌더링
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              PlayerCardWidget(
                player: player,
                index: 0,
                actionHistory: ['ALL-IN: 5000'],
                initialChips: 5000,
                screenWidth: 400,
                screenHeight: 800,
                boxWidth: 100,
                boxHeight: 110,
                isSmallScreen: false,
                fontScale: 1.0,
                formatAmount: (amount) => amount.toString(),
              ),
            ],
          ),
        ),
      ),
    );
    
    // ALL-IN 배지가 표시되는지 확인
    expect(find.text('ALL-IN'), findsOneWidget);
    expect(find.text('BB'), findsOneWidget);
  });
  
  testWidgets('PlayerCardWidget - 작은 화면 레이아웃 테스트', (WidgetTester tester) async {
    // 테스트용 Player 객체 생성
    final player = Player(
      name: 'Small Screen Player',
      chips: 5000,
      hand: [],
      position: Position.smallBlind,
    );
    
    // 위젯 렌더링 (isSmallScreen = true)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              PlayerCardWidget(
                player: player,
                index: 0,
                actionHistory: ['SB: 100'],
                initialChips: 5000,
                screenWidth: 320, // 작은 화면
                screenHeight: 480,
                boxWidth: 80, // 작은 박스
                boxHeight: 88,
                isSmallScreen: true, // 작은 화면 모드
                fontScale: 0.8, // 축소된 폰트 크기
                formatAmount: (amount) => amount.toString(),
              ),
            ],
          ),
        ),
      ),
    );
    
    // 위젯이 화면에 렌더링되었는지 확인
    expect(find.text('SB'), findsOneWidget);
    expect(find.text('5000'), findsOneWidget);
    expect(find.text('SB: 100'), findsOneWidget);
  });
} 