import 'dart:math';
import 'package:random_card/models/player.dart';
import 'package:random_card/models/pot.dart';
import 'package:random_card/models/betting_round.dart';

class PlayerActionManager {
  final Random random = Random();
  
  void performPlayerAction(
    int playerIndex,
    List<Player> players,
    BettingRound bettingRound,
    List<List<String>> playerActionHistory,
    Function(int) setPotCorrectAnswer,
    int raiseCount,
    Function(bool) setIsPotGuessing,
  ) {
    if (bettingRound == null) return;

    var player = players[playerIndex];
    // 연속적으로 올인/폴드 상태면 계속 nextPlayer()
    while (player.isFolded || player.isAllIn) {
      bettingRound.nextPlayer();
      player = players[bettingRound.currentPlayerIndex];
    }

    int action = random.nextInt(100);

    if (action < 50) {
      // 50% 확률로 "레이즈"
      int potLimit = bettingRound.calculatePotLimit();
      int minRaise;
      int bigBlind = _findBigBlindAmount(players);
      int maxRaise = min(potLimit, player.chips);
      
      if (raiseCount == 0) {
        minRaise = bigBlind * 2;
      } else {
        // 최소 레이즈는 이전 베팅(콜) + 이전 레이즈 금액
        int lastRaise = bettingRound.currentBet - (raiseCount == 1 ? bigBlind : 0);
        minRaise = bettingRound.currentBet + (bettingRound.currentBet > 0 ? bettingRound.currentBet : bigBlind);
      }
      
      if (maxRaise < minRaise) {
        // 칩이 부족하면 무조건 올인
        int allInAmount = player.chips;
        player.chips = 0;
        player.bet += allInAmount;
        player.isAllIn = true;
        bettingRound.pot.addBet(player, allInAmount);
        playerActionHistory[playerIndex].add('ALL-IN: ${player.bet}');
        bettingRound.nextPlayer();
        return;
      }
      
      // 100단위 랜덤 베팅
      int numSteps = ((maxRaise - minRaise) ~/ 100) + 1;
      int raiseAmount = minRaise + (numSteps > 1 ? random.nextInt(numSteps) * 100 : 0);
      
      if (raiseAmount > player.chips) {
        // 칩이 부족하면 무조건 올인
        int allInAmount = player.chips;
        player.chips = 0;
        player.bet += allInAmount;
        player.isAllIn = true;
        bettingRound.pot.addBet(player, allInAmount);
        playerActionHistory[playerIndex].add('ALL-IN: ${player.bet}');
        bettingRound.nextPlayer();
        return;
      }
      
      bettingRound.performAction('raise', raiseAmount);
      playerActionHistory[playerIndex].add('RAISE: $raiseAmount');
    } 
    else if (action < 70) {
      // 20% 확률로 "폴드"
      bettingRound.performAction('fold');
      playerActionHistory[playerIndex].add('FOLD');
    } 
    else {
      // 30% 확률로 "POT!" (항상 최대금액으로 베팅)
      int potLimit = bettingRound.calculatePotLimit();
      int allInAmount = players[playerIndex].chips + players[playerIndex].bet;
      int potBet = potLimit >= allInAmount ? allInAmount : potLimit;
      
      setPotCorrectAnswer(potBet);
      bettingRound.performAction('raise', potBet);
      playerActionHistory[playerIndex].add('POT!');
      setIsPotGuessing(true);
    }
  }

  int _findBigBlindAmount(List<Player> players) {
    // BB 포지션의 플레이어 찾기
    Player? bbPlayer = players.firstWhere(
      (p) => p.position == Position.bigBlind,
      orElse: () => players[0],
    );
    
    // BB 금액 (기본값: 200)
    return bbPlayer.bet > 0 ? bbPlayer.bet : 200;
  }
} 