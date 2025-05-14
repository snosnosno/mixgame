import 'package:flutter_test/flutter_test.dart';
import 'package:random_card_new/providers/pot_limit_provider.dart';

void main() {
  group('PotLimitProvider', () {
    late PotLimitProvider provider;

    setUp(() {
      provider = PotLimitProvider();
    });

    test('초기 상태 확인', () {
      expect(provider.isGameStarted, false);
      expect(provider.currentScore, 0);
      expect(provider.players.length, 0);
      expect(provider.isPotGuessing, false);
      expect(provider.resultMessage, '');
      expect(provider.showNextGameButton, false);
      expect(provider.playerActionHistory.length, 6);
    });

    test('formatAmount 함수 테스트', () {
      // 일반 블라인드일 때 (1500 미만인 경우)
      provider.smallBlind = 100;
      expect(provider.formatAmount(1000), '1000');
      expect(provider.formatAmount(123), '123');
      
      // 1500-4000 미만 블라인드일 때 (500 단위로 올림)
      provider.smallBlind = 1500;
      expect(provider.formatAmount(1750), '2000'); // 1750 올림 -> 2000 (500단위)
      expect(provider.formatAmount(3300), '3500'); // 3300 올림 -> 3500 (500단위)
      
      provider.smallBlind = 3000;
      expect(provider.formatAmount(2800), '3000'); // 2800 올림 -> 3000 (500단위)
      expect(provider.formatAmount(3100), '3500'); // 3100 올림 -> 3500 (500단위)
      
      // 4000 이상 블라인드일 때 (1000 단위로 올림)
      provider.smallBlind = 4000;
      expect(provider.formatAmount(4100), '5000'); // 4100 올림 -> 5000 (1000단위)
      expect(provider.formatAmount(5400), '6000'); // 5400 올림 -> 6000 (1000단위)
      
      provider.smallBlind = 5000;
      expect(provider.formatAmount(9100), '10000'); // 9100 올림 -> 10000 (1000단위)
    });

    test('게임 시작 시 플레이어 초기화', () {
      provider.startNewGame();
      
      expect(provider.isGameStarted, true);
      expect(provider.players.length, 6);
      expect(provider.bettingRound, isNotNull);
      
      // SB, BB 플레이어 확인
      final sbPlayer = provider.players.firstWhere((p) => p.position.name == 'smallBlind');
      final bbPlayer = provider.players.firstWhere((p) => p.position.name == 'bigBlind');
      
      expect(sbPlayer.bet, provider.smallBlind);
      expect(bbPlayer.bet, provider.bigBlind);
      
      // 플레이어 초기 칩 저장 확인
      expect(provider.chipsInitial.length, 6);
    });

    test('POT 추측 확인 - 정답인 경우', () {
      provider.startNewGame();
      provider.isPotGuessing = true;
      provider.potCorrectAnswer = 2000;
      provider.potGuessController.text = '2000';
      
      provider.checkPotGuess();
      
      expect(provider.currentScore, 1);
      expect(provider.showNextGameButton, true);
      expect(provider.resultMessage.contains('정답'), true);
    });

    test('POT 추측 확인 - 오답인 경우', () {
      provider.startNewGame();
      provider.isPotGuessing = true;
      provider.potCorrectAnswer = 2000;
      provider.potGuessController.text = '3000';
      
      provider.checkPotGuess();
      
      expect(provider.currentScore, 0);
      expect(provider.showNextGameButton, true);
      expect(provider.resultMessage.contains('오답'), true);
    });
  });
} 