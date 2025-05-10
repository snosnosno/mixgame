import 'package:flutter_test/flutter_test.dart';
import 'package:random_card_new/models/betting_round.dart';
import 'package:random_card_new/models/player.dart';
import 'package:random_card_new/models/pot.dart';

void main() {
  group('BettingRound', () {
    late List<Player> players;
    late Pot pot;
    late BettingRound bettingRound;
    
    setUp(() {
      // 테스트용 플레이어 셋업
      players = [
        Player(name: 'Player 1', chips: 10000, hand: [], position: Position.smallBlind),
        Player(name: 'Player 2', chips: 10000, hand: [], position: Position.bigBlind),
        Player(name: 'Player 3', chips: 10000, hand: [], position: Position.underTheGun),
        Player(name: 'Player 4', chips: 10000, hand: [], position: Position.hijack),
        Player(name: 'Player 5', chips: 10000, hand: [], position: Position.cutoff),
        Player(name: 'Player 6', chips: 10000, hand: [], position: Position.dealer),
      ];
      
      // 블라인드 설정
      final smallBlind = 100;
      final bigBlind = 200;
      
      // SB, BB 베팅 설정
      final sbPlayer = players.firstWhere((p) => p.position == Position.smallBlind);
      final bbPlayer = players.firstWhere((p) => p.position == Position.bigBlind);
      sbPlayer.chips -= smallBlind;
      sbPlayer.bet = smallBlind;
      bbPlayer.chips -= bigBlind;
      bbPlayer.bet = bigBlind;
      
      pot = Pot();
      pot.addBet(sbPlayer, smallBlind);
      pot.addBet(bbPlayer, bigBlind);
      
      bettingRound = BettingRound(players: players, pot: pot);
      
      // UTG가 첫 액션을 하도록 설정
      final utgIdx = players.indexWhere((p) => p.position == Position.underTheGun);
      bettingRound.currentPlayerIndex = utgIdx;
    });
    
    test('currentPlayer가 올바르게 반환되는지 확인', () {
      expect(bettingRound.currentPlayer.position, Position.underTheGun);
    });

    test('canCheck 함수 테스트', () {
      // 프리플랍에서 UTG는 BB 이상으로 베팅해야 하므로 체크할 수 없음
      expect(bettingRound.canCheck(), false);
      
      // BB는 체크 가능
      bettingRound.currentPlayerIndex = players.indexWhere((p) => p.position == Position.bigBlind);
      expect(bettingRound.canCheck(), true);
    });

    test('getCallAmount 함수 테스트', () {
      // UTG는 BB만큼 콜해야 함 (200)
      expect(bettingRound.getCallAmount(), 200);
      
      // BB 플레이어는 콜 금액이 0
      bettingRound.currentPlayerIndex = players.indexWhere((p) => p.position == Position.bigBlind);
      expect(bettingRound.getCallAmount(), 0);
    });

    test('calculatePotLimit 함수 테스트', () {
      // 초기 팟: SB(100) + BB(200) = 300
      // UTG 플레이어의 팟 리밋 계산: 팟(300) + 콜금액(200) + 콜금액(200) = 700
      expect(bettingRound.calculatePotLimit(), 700);
      
      // UTG가 500으로 레이즈
      bettingRound.performAction('raise', 500);
      
      // UTG가 500으로 레이즈 후, 다음 플레이어(HJ)의 팟 리밋 계산
      // 팟: SB(100) + BB(200) + UTG(500) = 800
      // 콜금액: 500 - 0 = 500
      // 팟 리밋: 800 + 500 + 500 = 1800
      expect(bettingRound.calculatePotLimit(), 1800);
    });

    test('getMinimumRaise 함수 테스트', () {
      // 초기 BB: 200, 미니멈 레이즈: 200 + 200 = 400
      expect(bettingRound.getMinimumRaise(), 400);
      
      // UTG가 500으로 레이즈
      bettingRound.performAction('raise', 500);
      
      // UTG가 레이즈 후 미니멈 레이즈: 500 + (500 - 200) = 800
      expect(bettingRound.getMinimumRaise(), 800);
    });

    test('performAction - 레이즈 테스트', () {
      // UTG가 500으로 레이즈
      bettingRound.performAction('raise', 500);
      
      // UTG 베팅액 확인
      expect(players[2].bet, 500);
      expect(players[2].chips, 10000 - 500);
      
      // currentBet과 lastRaiseAmount 확인
      expect(bettingRound.currentBet, 500);
      expect(bettingRound.lastRaiseAmount, 300); // 500 - 200 = 300
    });

    test('performAction - 콜 테스트', () {
      // UTG가 BB 콜
      bettingRound.performAction('call');
      
      // UTG 베팅액 확인
      expect(players[2].bet, 200);
      expect(players[2].chips, 10000 - 200);
      
      // currentBet 확인
      expect(bettingRound.currentBet, 200);
    });

    test('performAction - 폴드 테스트', () {
      // UTG가 폴드
      bettingRound.performAction('fold');
      
      // UTG 상태 확인
      expect(players[2].isFolded, true);
      expect(players[2].bet, 0);
      expect(players[2].chips, 10000);
    });

    test('performAction - 올인 테스트', () {
      // 작은 칩 스택 설정
      players[2].chips = 300;
      
      // UTG가 올인
      bettingRound.performAction('allIn');
      
      // UTG 상태 확인
      expect(players[2].isAllIn, true);
      expect(players[2].bet, 300);
      expect(players[2].chips, 0);
    });

    test('checkRoundComplete 테스트', () {
      // UTG가 콜
      bettingRound.performAction('call');
      // HJ가 콜
      bettingRound.performAction('call');
      // CO가 콜
      bettingRound.performAction('call');
      // BTN이 콜
      bettingRound.performAction('call');
      // SB가 콜
      bettingRound.performAction('call');
      
      // 모든 플레이어가 동일한 금액을 베팅했으므로 라운드가 완료됨
      expect(bettingRound.isRoundComplete, true);
    });
  });
} 