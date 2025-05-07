import 'package:flutter_test/flutter_test.dart';
import 'package:random_card_new/models/player.dart';
import 'package:random_card_new/models/pot.dart';
import 'package:random_card_new/models/betting_round.dart';

void main() {
  group('BettingRound Tests', () {
    test('Pot Limit Raise/Under-raise Scenario', () {
      // 플레이어 생성 (포지션 순서: SB, BB, UTG, HIJACK, CO, DEALER)
      final players = [
        Player(name: 'SB', chips: 30000, hand: [], position: Position.smallBlind),
        Player(name: 'BB', chips: 30000, hand: [], position: Position.bigBlind),
        Player(name: 'UTG', chips: 30000, hand: [], position: Position.underTheGun),
        Player(name: 'HIJACK', chips: 20000, hand: [], position: Position.hijack),
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

      print('=== 초기 세팅 ===');
      print('SB: 베팅=${players[0].bet}, 칩=${players[0].chips}');
      print('BB: 베팅=${players[1].bet}, 칩=${players[1].chips}');
      print('UTG: 베팅=${players[2].bet}, 칩=${players[2].chips}');
      print('HIJACK: 베팅=${players[3].bet}, 칩=${players[3].chips}');
      print('pot total: ${pot.total}');

      final round = BettingRound(players: players, pot: pot);
      // UTG가 첫 액션
      round.currentPlayerIndex = 2;
      print('초기 lastRaiseAmount: ${round.lastRaiseAmount}');
      print('초기 lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('초기 currentBet: ${round.currentBet}');

      // UTG: 15000 레이즈 (콜 6000 + 레이즈 9000)
      round.performAction('raise', 15000);
      print('\n=== UTG 레이즈 후 ===');
      print('UTG: 베팅=${players[2].bet}, 칩=${players[2].chips}');
      print('lastRaiseAmount: ${round.lastRaiseAmount}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      print('pot total: ${pot.total}');
      expect(players[2].bet, 15000);
      expect(round.currentBet, 15000);
      expect(round.lastValidRaiseAmount, 9000);

      // HIJACK: 20000 올인 (언더레이즈)
      round.currentPlayerIndex = 3;
      print('\n=== HIJACK 올인 전 ===');
      print('HIJACK: 베팅=${players[3].bet}, 칩=${players[3].chips}');
      print('최소 레이즈(minimumRaise): ${round.getMinimumRaise()}');
      round.performAction('allIn');
      print('\n=== HIJACK 올인 후 ===');
      print('HIJACK: 베팅=${players[3].bet}, 칩=${players[3].chips}, 올인=${players[3].isAllIn}');
      print('lastRaiseAmount: ${round.lastRaiseAmount}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      print('pot total: ${pot.total}');
      expect(players[3].bet, 20000, reason: 'HIJACK은 20000 올인해야 합니다');
      expect(players[3].isAllIn, true);
      // 언더레이즈이므로 lastValidRaiseAmount는 그대로 9000이어야 함
      expect(round.lastValidRaiseAmount, 9000, reason: '언더레이즈 후에도 lastValidRaiseAmount는 9000이어야 합니다');

      // CO: 30000 레이즈 (최소 레이즈 15000+9000=24000 이상이어야 함)
      round.currentPlayerIndex = 4;
      print('\n=== CO 레이즈 전 ===');
      print('CO: 베팅=${players[4].bet}, 칩=${players[4].chips}');
      print('최소 레이즈(minimumRaise): ${round.getMinimumRaise()}');
      round.performAction('raise', 30000);
      print('\n=== CO 레이즈 후 ===');
      print('CO: 베팅=${players[4].bet}, 칩=${players[4].chips}');
      print('lastRaiseAmount: ${round.lastRaiseAmount}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      print('pot total: ${pot.total}');
      expect(players[4].bet, 30000);
      expect(round.currentBet, 30000);
      // CO의 레이즈는 10000(30000-20000) -> 최소 레이즈(9000) 이상이므로 정상
      expect(round.lastValidRaiseAmount >= 9000, true);
    });
    
    test('올인과 미니멈 레이즈 시나리오', () {
      // 플레이어 생성 (포지션 순서: SB, BB, UTG, HIJACK, CO, DEALER)
      final players = [
        Player(name: 'SB', chips: 10000, hand: [], position: Position.smallBlind),
        Player(name: 'BB', chips: 10000, hand: [], position: Position.bigBlind),
        Player(name: 'UTG', chips: 25000, hand: [], position: Position.underTheGun),
        Player(name: 'HIJACK', chips: 7000, hand: [], position: Position.hijack),
        Player(name: 'CO', chips: 50000, hand: [], position: Position.cutoff),
        Player(name: 'DEALER', chips: 40000, hand: [], position: Position.dealer),
      ];
      final pot = Pot();

      // 블라인드 세팅 (1000/2000)
      players[0].chips -= 1000; // SB
      players[0].bet = 1000;
      players[1].chips -= 2000; // BB
      players[1].bet = 2000;
      pot.addBet(players[0], 1000);
      pot.addBet(players[1], 2000);

      final round = BettingRound(players: players, pot: pot);
      // UTG가 첫 액션
      round.currentPlayerIndex = 2;
      
      // UTG: 6000 레이즈 (콜 2000 + 레이즈 4000)
      round.performAction('raise', 6000);
      expect(players[2].bet, 6000);
      expect(round.currentBet, 6000);
      expect(round.lastValidRaiseAmount, 4000);
      
      // HIJACK: 7000 올인 (언더레이즈, 최소 레이즈는 6000+4000=10000)
      round.currentPlayerIndex = 3;
      round.performAction('allIn');
      expect(players[3].bet, 7000);
      expect(players[3].isAllIn, true);
      expect(round.currentBet, 7000);
      // 최소 레이즈 미만이므로 lastValidRaiseAmount는 그대로 4000
      expect(round.lastValidRaiseAmount, 4000);
      
      // CO: 15000 레이즈 (최소 레이즈 7000+4000=11000)
      round.currentPlayerIndex = 4;
      round.performAction('raise', 15000);
      expect(players[4].bet, 15000);
      expect(round.currentBet, 15000);
      // 레이즈 금액: 15000-7000=8000 > 최소 레이즈(4000) -> 유효 레이즈
      expect(round.lastValidRaiseAmount, 8000);
      
      // DEALER: 올인
      round.currentPlayerIndex = 5;
      round.performAction('allIn');
      expect(players[5].bet, 40000);
      expect(round.currentBet, 40000);
      // 레이즈 금액: 40000-15000=25000
      expect(round.lastValidRaiseAmount, 25000);
      
      // SB: 콜 (자금 부족하여 올인)
      round.currentPlayerIndex = 0;
      round.performAction('call');
      expect(players[0].isAllIn, true);
      expect(players[0].bet, 10000); // 원래 베팅 1000 + 남은 칩 9000
      expect(round.currentBet, 40000); // 현재 베팅은 여전히 DEALER의 올인 금액
      
      // BB: 폴드
      round.currentPlayerIndex = 1;
      round.performAction('fold');
      expect(players[1].isFolded, true);
      
      // UTG: 콜 (콜 금액 부족하여 올인)
      round.currentPlayerIndex = 2;
      round.performAction('call');
      expect(players[2].isAllIn, true);
      expect(players[2].bet, 25000); // 원래 베팅 6000 + 남은 칩 19000
      
      // CO에게 마지막 액션 기회 주기 (콜)
      round.currentPlayerIndex = 4;
      round.performAction('call');
      expect(players[4].bet, 40000);
      
      // 수동으로 라운드 완료 체크 호출
      round.checkRoundComplete();
      
      // 라운드가 완료되었는지 확인
      // 활성 플레이어가 남아있지 않거나, 모든 플레이어의 베팅이 동일해야 함
      bool allFoldedOrAllIn = players.every((p) => p.isFolded || p.isAllIn);
      bool allBetsEqual = players
          .where((p) => !p.isFolded)
          .every((p) => p.bet == round.currentBet || p.isAllIn);
          
      // 라운드 완료 여부 직접 확인
      expect(allFoldedOrAllIn || allBetsEqual, true);
      expect(round.isRoundComplete, true);
    });

    test('극단적 언더레이즈 시나리오', () {
      // 플레이어 생성 (포지션 순서: SB, BB, UTG, HIJACK, CO, DEALER)
      final players = [
        Player(name: 'SB', chips: 100000, hand: [], position: Position.smallBlind),
        Player(name: 'BB', chips: 100000, hand: [], position: Position.bigBlind),
        Player(name: 'UTG', chips: 100000, hand: [], position: Position.underTheGun),
        Player(name: 'HIJACK', chips: 500, hand: [], position: Position.hijack), // 극소량 칩
        Player(name: 'CO', chips: 100000, hand: [], position: Position.cutoff),
        Player(name: 'DEALER', chips: 100000, hand: [], position: Position.dealer),
      ];
      final pot = Pot();

      // 블라인드 세팅 (5000/10000)
      players[0].chips -= 5000; // SB
      players[0].bet = 5000;
      players[1].chips -= 10000; // BB
      players[1].bet = 10000;
      pot.addBet(players[0], 5000);
      pot.addBet(players[1], 10000);

      final round = BettingRound(players: players, pot: pot);
      print('\n=== 극단적 언더레이즈 시나리오 ===');
      print('SB: 베팅=${players[0].bet}, 칩=${players[0].chips}');
      print('BB: 베팅=${players[1].bet}, 칩=${players[1].chips}');
      print('UTG: 베팅=${players[2].bet}, 칩=${players[2].chips}');
      print('HIJACK: 베팅=${players[3].bet}, 칩=${players[3].chips}');
      print('초기 lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      
      // UTG가 첫 액션: 30000 레이즈 (콜 10000 + 레이즈 20000)
      round.currentPlayerIndex = 2;
      round.performAction('raise', 30000);
      print('UTG 30000 레이즈 후:');
      print('UTG: 베팅=${players[2].bet}, 칩=${players[2].chips}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      expect(players[2].bet, 30000);
      expect(round.currentBet, 30000);
      expect(round.lastValidRaiseAmount, 20000);
      
      // HIJACK: 500 올인 (극단적 언더레이즈)
      round.currentPlayerIndex = 3;
      round.performAction('allIn');
      print('HIJACK 500 올인 후:');
      print('HIJACK: 베팅=${players[3].bet}, 칩=${players[3].chips}, 올인=${players[3].isAllIn}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      expect(players[3].bet, 500);
      expect(players[3].isAllIn, true);
      expect(round.currentBet, 30000); // 현재 베팅은 UTG의 30000 유지
      // 극단적 언더레이즈이므로 lastValidRaiseAmount는 그대로 20000
      expect(round.lastValidRaiseAmount, 20000);
      
      // CO: 80000 레이즈 (최소 레이즈 30000+20000=50000)
      round.currentPlayerIndex = 4;
      round.performAction('raise', 80000);
      print('CO 80000 레이즈 후:');
      print('CO: 베팅=${players[4].bet}, 칩=${players[4].chips}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      expect(players[4].bet, 80000);
      expect(round.currentBet, 80000);
      // 레이즈 금액: 80000-30000=50000
      expect(round.lastValidRaiseAmount, 50000);
      
      // 극단적 언더레이즈가 최소 레이즈 규칙에 영향을 미치지 않았는지 확인
      expect(round.getMinimumRaise(), 130000); // 현재 베팅 80000 + 마지막 유효 레이즈 50000
    });
    
    test('연속 레이즈 시나리오', () {
      // 플레이어 생성 (포지션 순서: SB, BB, UTG, HIJACK, CO, DEALER)
      final players = [
        Player(name: 'SB', chips: 100000, hand: [], position: Position.smallBlind),
        Player(name: 'BB', chips: 100000, hand: [], position: Position.bigBlind),
        Player(name: 'UTG', chips: 100000, hand: [], position: Position.underTheGun),
        Player(name: 'HIJACK', chips: 100000, hand: [], position: Position.hijack),
        Player(name: 'CO', chips: 100000, hand: [], position: Position.cutoff),
        Player(name: 'DEALER', chips: 100000, hand: [], position: Position.dealer),
      ];
      final pot = Pot();

      // 블라인드 세팅 (500/1000)
      players[0].chips -= 500; // SB
      players[0].bet = 500;
      players[1].chips -= 1000; // BB
      players[1].bet = 1000;
      pot.addBet(players[0], 500);
      pot.addBet(players[1], 1000);

      final round = BettingRound(players: players, pot: pot);
      print('\n=== 연속 레이즈 시나리오 ===');
      print('초기 lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('초기 currentBet: ${round.currentBet}');
      
      // UTG: 3000 레이즈 (콜 1000 + 레이즈 2000)
      round.currentPlayerIndex = 2;
      round.performAction('raise', 3000);
      print('UTG 3000 레이즈 후:');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      expect(round.lastValidRaiseAmount, 2000);
      expect(round.currentBet, 3000);
      
      // HIJACK: 9000 레이즈 (콜 3000 + 레이즈 6000)
      round.currentPlayerIndex = 3;
      round.performAction('raise', 9000);
      print('HIJACK 9000 레이즈 후:');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      expect(round.lastValidRaiseAmount, 6000);
      expect(round.currentBet, 9000);
      
      // CO: 21000 레이즈 (콜 9000 + 레이즈 12000)
      round.currentPlayerIndex = 4;
      round.performAction('raise', 21000);
      print('CO 21000 레이즈 후:');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      expect(round.lastValidRaiseAmount, 12000);
      expect(round.currentBet, 21000);
      
      // DEALER: 45000 레이즈 (콜 21000 + 레이즈 24000)
      round.currentPlayerIndex = 5;
      round.performAction('raise', 45000);
      print('DEALER 45000 레이즈 후:');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      expect(round.lastValidRaiseAmount, 24000);
      expect(round.currentBet, 45000);
      
      // SB: 93000 레이즈 (콜 45000 + 레이즈 48000)
      round.currentPlayerIndex = 0;
      round.performAction('raise', 93000);
      print('SB 93000 레이즈 후:');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      expect(round.lastValidRaiseAmount, 48000);
      expect(round.currentBet, 93000);
      
      // 미니멈 레이즈가 93000 + 48000 = 141000인지 확인
      expect(round.getMinimumRaise(), 141000);
    });
    
    test('체크 및 자동 콜 시나리오', () {
      // 최소한의 플레이어로 테스트
      final players = [
        Player(name: 'SB', chips: 1000, hand: [], position: Position.smallBlind),
        Player(name: 'BB', chips: 1000, hand: [], position: Position.bigBlind),
        Player(name: 'UTG', chips: 1000, hand: [], position: Position.underTheGun),
        Player(name: 'HIJACK', chips: 1000, hand: [], position: Position.hijack),
      ];
      final pot = Pot();

      // 블라인드 세팅 (10/20)
      players[0].chips -= 10; // SB
      players[0].bet = 10;
      players[1].chips -= 20; // BB
      players[1].bet = 20;
      pot.addBet(players[0], 10);
      pot.addBet(players[1], 20);

      final round = BettingRound(players: players, pot: pot);
      print('\n=== 체크 및 자동 콜 시나리오 ===');
      
      // UTG: 콜 20
      round.currentPlayerIndex = 2;
      round.performAction('call');
      print('UTG 콜 후: bet=${players[2].bet}, chips=${players[2].chips}');
      expect(players[2].bet, 20);
      
      // HIJACK: 체크 불가능
      round.currentPlayerIndex = 3;
      expect(round.canCheck(), false);
      
      // HIJACK: 콜
      round.performAction('call');
      print('HIJACK 콜 후: bet=${players[3].bet}, chips=${players[3].chips}');
      expect(players[3].bet, 20);
      
      // SB: 콜 (이미 10 베팅했으므로 추가 10)
      round.currentPlayerIndex = 0;
      round.performAction('call');
      print('SB 콜 후: bet=${players[0].bet}, chips=${players[0].chips}');
      expect(players[0].bet, 20);
      
      // BB: 체크 (이미 최대 베팅함)
      round.currentPlayerIndex = 1;
      round.performAction('check');
      print('BB 체크 후: bet=${players[1].bet}, chips=${players[1].chips}');
      expect(players[1].bet, 20);
      
      // 이제 두 번째 베팅 라운드 시작
      
      // UTG: 체크 
      round.currentPlayerIndex = 2;
      expect(round.canCheck(), true);
      round.performAction('check');
      print('UTG 체크 후: bet=${players[2].bet}, chips=${players[2].chips}');
      
      // HIJACK: 베팅 50 (레이즈)
      round.currentPlayerIndex = 3;
      round.performAction('raise', 50);
      print('HIJACK 베팅 후: bet=${players[3].bet}, chips=${players[3].chips}');
      expect(players[3].bet, 50);
      expect(round.currentBet, 50);
      
      // SB: 콜 (이미 20 베팅했으므로 추가 30)
      round.currentPlayerIndex = 0;
      round.performAction('call');
      print('SB 콜 후: bet=${players[0].bet}, chips=${players[0].chips}');
      expect(players[0].bet, 50);
      
      // BB: 콜 (이미 20 베팅했으므로 추가 30) 
      round.currentPlayerIndex = 1;
      round.performAction('call');
      print('BB 콜 후: bet=${players[1].bet}, chips=${players[1].chips}');
      expect(players[1].bet, 50);
      
      // UTG: 콜 (이미 20 베팅했으므로 추가 30)
      round.currentPlayerIndex = 2;
      round.performAction('call');
      print('UTG 콜 후: bet=${players[2].bet}, chips=${players[2].chips}');
      expect(players[2].bet, 50);
      
      // 베팅 상태 확인
      print('모든 플레이어 베팅 현황:');
      for (int i = 0; i < players.length; i++) {
        print('${players[i].name}: 베팅=${players[i].bet}, 칩=${players[i].chips}');
      }
      
      // 총 팟 확인
      print('pot.total: ${pot.total}');
      expect(pot.total, 200, reason: '총 팟은 200이어야 합니다 (4명 x 50)');
      
      // 모든 플레이어의 베팅이 동일한지 확인
      for (final player in players) {
        expect(player.bet, 50, reason: '${player.name}의 베팅은 50이어야 합니다');
      }
    });
    
    test('언더레이즈 시나리오', () {
      // 간단한 플레이어 구성
      final players = [
        Player(name: 'SB', chips: 100, hand: [], position: Position.smallBlind),
        Player(name: 'BB', chips: 100, hand: [], position: Position.bigBlind),
        Player(name: 'UTG', chips: 100, hand: [], position: Position.underTheGun),
      ];
      final pot = Pot();

      print('\n=== 언더레이즈 시나리오 ===');
      
      // 블라인드 세팅 (10/20)
      players[0].chips -= 10; // SB
      players[0].bet = 10;
      players[1].chips -= 20; // BB
      players[1].bet = 20;
      pot.addBet(players[0], 10);
      pot.addBet(players[1], 20);
      
      final round = BettingRound(players: players, pot: pot);
      print('초기 lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('초기 currentBet: ${round.currentBet}');
      
      // BB 베팅이 기준
      expect(round.lastValidRaiseAmount, 20);
      expect(round.currentBet, 20);
      
      // UTG: 60 레이즈 (콜 20 + 레이즈 40)
      round.currentPlayerIndex = 2;
      round.performAction('raise', 60);
      print('UTG 60 레이즈 후:');
      print('UTG: 베팅=${players[2].bet}, 칩=${players[2].chips}');
      print('lastValidRaiseAmount: ${round.lastValidRaiseAmount}');
      print('currentBet: ${round.currentBet}');
      
      // 레이즈 검증
      expect(players[2].bet, 60);
      expect(round.currentBet, 60);
      expect(round.lastValidRaiseAmount, 40);
    });
  });
} 