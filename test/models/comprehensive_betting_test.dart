import 'package:flutter_test/flutter_test.dart';
import 'package:random_card_new/models/player.dart';
import 'package:random_card_new/models/pot.dart';
import 'package:random_card_new/models/betting_round.dart';

void main() {
  group('Comprehensive Betting Tests', () {
    test('기본 레이즈와 언더레이즈 시나리오', () {
      // SB: 3,000
      // BB: 6,000
      // UTG: 15,000 레이즈
      // HIJACK: 20,000 올인 (언더레이즈)
      // CO: 28,000 베팅 (언더레이즈 - 불허용)
      // CO: 30,000 베팅 (정상 레이즈)
      
      final players = [
        Player(name: 'SB', chips: 30000, hand: [], position: Position.smallBlind),
        Player(name: 'BB', chips: 30000, hand: [], position: Position.bigBlind),
        Player(name: 'UTG', chips: 30000, hand: [], position: Position.underTheGun),
        Player(name: 'HIJACK', chips: 20000, hand: [], position: Position.hijack), // 딱 20000 칩 보유
        Player(name: 'CO', chips: 30000, hand: [], position: Position.cutoff),
        Player(name: 'DEALER', chips: 30000, hand: [], position: Position.dealer),
      ];
      
      final pot = Pot();
      
      // 블라인드 세팅
      players[0].chips -= 3000; // SB
      players[0].bet = 3000;
      players[1].chips -= 6000; // BB
      players[1].bet = 6000;
      pot.addBet(players[0], 3000);
      pot.addBet(players[1], 6000);
      
      final round = BettingRound(players: players, pot: pot);
      print('\n=== 기본 레이즈와 언더레이즈 시나리오 ===');
      print('초기 lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('초기 currentBet: ${round.currentBet}');
      
      // UTG: 15,000 레이즈
      round.currentPlayerIndex = 2;
      round.performAction('raise', 15000);
      print('\nUTG 15000 레이즈 후:');
      print('UTG 베팅: ${players[2].bet}');
      print('lastRaiseAmount: ${round.lastRaiseAmount}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      
      expect(players[2].bet, 15000);
      expect(round.lastRaiseAmount, 9000); // 15000 - 6000
      expect(round.lastValidRaiseAmount, 9000);
      expect(round.currentBet, 15000);
      
      // HIJACK: 20,000 올인 (언더레이즈 - 허용)
      round.currentPlayerIndex = 3;
      print('\nHIJACK 올인 전 (칩: ${players[3].chips}):');
      print('최소 레이즈: ${round.getMinimumRaise()}');
      round.performAction('allIn');
      print('HIJACK 올인 후:');
      print('HIJACK 베팅: ${players[3].bet}, 올인: ${players[3].isAllIn}');
      print('lastRaiseAmount: ${round.lastRaiseAmount}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      
      expect(players[3].bet, 20000);
      expect(players[3].isAllIn, true);
      expect(round.lastRaiseAmount, 5000); // 20000 - 15000
      expect(round.lastValidRaiseAmount, 9000); // 유효 레이즈 금액 유지
      expect(round.currentBet, 20000);
      
      // CO: 28,000 베팅 시도 (언더레이즈 - 불허용)
      round.currentPlayerIndex = 4;
      print('\nCO 베팅 전:');
      print('최소 레이즈: ${round.getMinimumRaise()}'); // 20000 + 9000 = 29000
      
      // 시도 1: 28,000 베팅 (언더레이즈)
      int beforeBet = players[4].bet;
      round.performAction('raise', 28000);
      print('CO 28000 레이즈 시도 후:');
      print('CO 베팅: ${players[4].bet}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      
      // 언더레이즈는 거부됨 (올인이 아니므로)
      expect(players[4].bet, beforeBet); // 베팅은 변경되지 않아야 함
      expect(round.lastValidRaiseAmount, 9000); // 그대로 유지
      expect(round.currentBet, 20000); // 그대로 유지
      
      // 시도 2: 30,000 베팅 (정상 레이즈)
      round.performAction('raise', 30000);
      print('\nCO 30000 레이즈 후:');
      print('CO 베팅: ${players[4].bet}');
      print('lastRaiseAmount: ${round.lastRaiseAmount}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      
      expect(players[4].bet, 30000);
      expect(round.lastRaiseAmount, 10000); // 30000 - 20000
      expect(round.lastValidRaiseAmount, 10000); // 새로운 유효 레이즈
      expect(round.currentBet, 30000);
    });
    
    test('CO 올인 언더레이즈 시나리오', () {
      // SB: 3,000
      // BB: 6,000
      // UTG: 15,000 레이즈
      // HIJACK: 20,000 올인 (언더레이즈)
      // CO: 28,000 올인 (언더레이즈 - 허용)
      
      final players = [
        Player(name: 'SB', chips: 30000, hand: [], position: Position.smallBlind),
        Player(name: 'BB', chips: 30000, hand: [], position: Position.bigBlind),
        Player(name: 'UTG', chips: 30000, hand: [], position: Position.underTheGun),
        Player(name: 'HIJACK', chips: 20000, hand: [], position: Position.hijack), // 딱 20000 칩 보유
        Player(name: 'CO', chips: 28000, hand: [], position: Position.cutoff), // 딱 28000 칩 보유
        Player(name: 'DEALER', chips: 30000, hand: [], position: Position.dealer),
      ];
      
      final pot = Pot();
      
      // 블라인드 세팅
      players[0].chips -= 3000; // SB
      players[0].bet = 3000;
      players[1].chips -= 6000; // BB
      players[1].bet = 6000;
      pot.addBet(players[0], 3000);
      pot.addBet(players[1], 6000);
      
      final round = BettingRound(players: players, pot: pot);
      print('\n=== CO 올인 언더레이즈 시나리오 ===');
      
      // UTG: 15,000 레이즈
      round.currentPlayerIndex = 2;
      round.performAction('raise', 15000);
      
      // HIJACK: 20,000 올인 (언더레이즈 - 허용)
      round.currentPlayerIndex = 3;
      round.performAction('allIn');
      
      // CO: 28,000 올인 (언더레이즈 - 올인이므로 허용)
      round.currentPlayerIndex = 4;
      print('\nCO 올인 전:');
      print('CO 칩: ${players[4].chips}');
      print('최소 레이즈: ${round.getMinimumRaise()}'); // 20000 + 9000 = 29000
      round.performAction('allIn');
      print('CO 올인 후:');
      print('CO 베팅: ${players[4].bet}, 올인: ${players[4].isAllIn}');
      print('lastRaiseAmount: ${round.lastRaiseAmount}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      
      expect(players[4].bet, 28000);
      expect(players[4].isAllIn, true);
      expect(round.lastRaiseAmount, 8000); // 28000 - 20000
      expect(round.lastValidRaiseAmount, 9000); // 유효 레이즈 금액 유지
      expect(round.currentBet, 28000);
    });
    
    test('복합 레이즈 시나리오', () {
      // SB: 1,000
      // BB: 2,000
      // UTG: 6,000 레이즈 (레이즈 4,000)
      // HIJACK: 14,000 레이즈 (레이즈 8,000)
      // CO: 30,000 레이즈 (레이즈 16,000)
      // DEALER: 50,000 올인 (언더레이즈 - 허용)
      // SB: 콜 50,000
      // BB: 폴드
      // UTG: 콜 50,000
      // HIJACK: 콜 50,000
      
      final players = [
        Player(name: 'SB', chips: 100000, hand: [], position: Position.smallBlind),
        Player(name: 'BB', chips: 100000, hand: [], position: Position.bigBlind),
        Player(name: 'UTG', chips: 100000, hand: [], position: Position.underTheGun),
        Player(name: 'HIJACK', chips: 100000, hand: [], position: Position.hijack),
        Player(name: 'CO', chips: 100000, hand: [], position: Position.cutoff),
        Player(name: 'DEALER', chips: 50000, hand: [], position: Position.dealer),
      ];
      
      final pot = Pot();
      
      // 블라인드 세팅
      players[0].chips -= 1000; // SB
      players[0].bet = 1000;
      players[1].chips -= 2000; // BB
      players[1].bet = 2000;
      pot.addBet(players[0], 1000);
      pot.addBet(players[1], 2000);
      
      final round = BettingRound(players: players, pot: pot);
      print('\n=== 복합 레이즈 시나리오 ===');
      
      // UTG: 6,000 레이즈
      round.currentPlayerIndex = 2;
      round.performAction('raise', 6000);
      print('\nUTG 6000 레이즈 후:');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      expect(round.lastValidRaiseAmount, 4000); // 6000 - 2000
      
      // HIJACK: 14,000 레이즈
      round.currentPlayerIndex = 3;
      round.performAction('raise', 14000);
      print('\nHIJACK 14000 레이즈 후:');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      expect(round.lastValidRaiseAmount, 8000); // 14000 - 6000
      
      // CO: 30,000 레이즈
      round.currentPlayerIndex = 4;
      round.performAction('raise', 30000);
      print('\nCO 30000 레이즈 후:');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      expect(round.lastValidRaiseAmount, 16000); // 30000 - 14000
      
      // DEALER: 50,000 올인 (레이즈 20,000 - 언더레이즈는 아님)
      round.currentPlayerIndex = 5;
      round.performAction('allIn');
      print('\nDEALER 50000 올인 후:');
      print('DEALER 베팅: ${players[5].bet}, 올인: ${players[5].isAllIn}');
      print('lastRaiseAmount: ${round.lastRaiseAmount}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      
      expect(players[5].bet, 50000);
      expect(players[5].isAllIn, true);
      expect(round.lastRaiseAmount, 20000); // 50000 - 30000
      expect(round.lastValidRaiseAmount, 20000); // 유효한 레이즈
      expect(round.currentBet, 50000);
      
      // SB: 콜 50,000
      round.currentPlayerIndex = 0;
      round.performAction('call');
      expect(players[0].bet, 50000);
      
      // BB: 폴드
      round.currentPlayerIndex = 1;
      round.performAction('fold');
      expect(players[1].isFolded, true);
      
      // UTG: 콜 50,000
      round.currentPlayerIndex = 2;
      round.performAction('call');
      expect(players[2].bet, 50000);
      
      // HIJACK: 콜 50,000
      round.currentPlayerIndex = 3;
      round.performAction('call');
      expect(players[3].bet, 50000);
      
      // CO: 콜 50,000
      round.currentPlayerIndex = 4;
      round.performAction('call');
      expect(players[4].bet, 50000);
      
      // 라운드가 완료되었는지 확인
      round.checkRoundComplete();
      expect(round.isRoundComplete, true);
      
      // 팟 크기 확인
      print('\n최종 pot.total: ${pot.total}');
      expect(pot.total, 250000); // 50000 * 5 명
    });
    
    test('연속 언더레이즈 시나리오', () {
      // SB: 1,000
      // BB: 2,000
      // UTG: 5,000 레이즈 (레이즈 3,000)
      // HIJACK: 7,000 올인 (언더레이즈 - 요구되는 최소 레이즈는 8,000)
      // CO: 9,000 올인 (언더레이즈 - 요구되는 최소 레이즈는 10,000)
      // DEALER: 11,000 레이즈 (레이즈 2,000, 최소 레이즈는 3,000 필요 - 불가)
      // DEALER: 12,000 레이즈 (레이즈 3,000 - 정상)
      
      final players = [
        Player(name: 'SB', chips: 50000, hand: [], position: Position.smallBlind),
        Player(name: 'BB', chips: 50000, hand: [], position: Position.bigBlind),
        Player(name: 'UTG', chips: 50000, hand: [], position: Position.underTheGun),
        Player(name: 'HIJACK', chips: 7000, hand: [], position: Position.hijack), // 딱 7000 칩
        Player(name: 'CO', chips: 9000, hand: [], position: Position.cutoff), // 딱 9000 칩
        Player(name: 'DEALER', chips: 50000, hand: [], position: Position.dealer),
      ];
      
      final pot = Pot();
      
      // 블라인드 세팅
      players[0].chips -= 1000; // SB
      players[0].bet = 1000;
      players[1].chips -= 2000; // BB
      players[1].bet = 2000;
      pot.addBet(players[0], 1000);
      pot.addBet(players[1], 2000);
      
      final round = BettingRound(players: players, pot: pot);
      print('\n=== 연속 언더레이즈 시나리오 ===');
      
      // UTG: 5,000 레이즈
      round.currentPlayerIndex = 2;
      round.performAction('raise', 5000);
      print('\nUTG 5000 레이즈 후:');
      print('UTG 베팅: ${players[2].bet}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      expect(round.lastValidRaiseAmount, 3000); // 5000 - 2000
      expect(round.currentBet, 5000);
      
      // HIJACK: 7,000 올인 (언더레이즈)
      round.currentPlayerIndex = 3;
      print('\nHIJACK 올인 전:');
      print('최소 레이즈: ${round.getMinimumRaise()}'); // 5000 + 3000 = 8000
      round.performAction('allIn');
      print('HIJACK 올인 후:');
      print('HIJACK 베팅: ${players[3].bet}, 올인: ${players[3].isAllIn}');
      print('lastRaiseAmount: ${round.lastRaiseAmount}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      
      expect(players[3].bet, 7000);
      expect(players[3].isAllIn, true);
      expect(round.lastRaiseAmount, 2000); // 7000 - 5000
      expect(round.lastValidRaiseAmount, 3000); // 유효 레이즈 금액 유지
      expect(round.currentBet, 7000);
      
      // CO: 9,000 올인 (언더레이즈)
      round.currentPlayerIndex = 4;
      print('\nCO 올인 전:');
      print('최소 레이즈: ${round.getMinimumRaise()}'); // 7000 + 3000 = 10000
      round.performAction('allIn');
      print('CO 올인 후:');
      print('CO 베팅: ${players[4].bet}, 올인: ${players[4].isAllIn}');
      print('lastRaiseAmount: ${round.lastRaiseAmount}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      
      expect(players[4].bet, 9000);
      expect(players[4].isAllIn, true);
      expect(round.lastRaiseAmount, 2000); // 9000 - 7000
      expect(round.lastValidRaiseAmount, 3000); // 유효 레이즈 금액 계속 유지
      expect(round.currentBet, 9000);
      
      // DEALER: 11,000 레이즈 시도 (언더레이즈)
      round.currentPlayerIndex = 5;
      print('\nDEALER 11000 레이즈 시도 전:');
      print('최소 레이즈: ${round.getMinimumRaise()}'); // 9000 + 3000 = 12000
      int beforeBet = players[5].bet;
      round.performAction('raise', 11000);
      print('DEALER 11000 레이즈 시도 후:');
      print('DEALER 베팅: ${players[5].bet}');
      
      // 언더레이즈는 거부됨
      expect(players[5].bet, beforeBet);
      expect(round.currentBet, 9000); // 변경 없음
      
      // DEALER: 12,000 레이즈 (정상 레이즈)
      round.performAction('raise', 12000);
      print('\nDEALER 12000 레이즈 후:');
      print('DEALER 베팅: ${players[5].bet}');
      print('lastRaiseAmount: ${round.lastRaiseAmount}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      
      expect(players[5].bet, 12000);
      expect(round.lastRaiseAmount, 3000); // 12000 - 9000
      expect(round.lastValidRaiseAmount, 3000); // 새 레이즈 금액
      expect(round.currentBet, 12000);
    });
  });
} 