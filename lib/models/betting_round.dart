import 'dart:math';
import 'player.dart';
import 'pot.dart';

class BettingRound {
  final List<Player> players;
  final Pot pot;
  int currentPlayerIndex = 0;
  int currentBet = 0;
  bool isRoundComplete = false;
  int lastRaiseAmount = 0;

  static const List<Position> actionOrder = [
    Position.underTheGun,
    Position.hijack,
    Position.cutoff,
    Position.dealer,
    Position.smallBlind,
    Position.bigBlind,
  ];

  BettingRound({
    required this.players,
    required this.pot,
  }) {
    // BB 금액으로 초기화
    int bbIdx = players.indexWhere((p) => p.position == Position.bigBlind);
    lastRaiseAmount = (bbIdx != -1) ? players[bbIdx].bet : 0;
  }

  Player get currentPlayer => players[currentPlayerIndex];

  void nextPlayer() {
    // 현재 플레이어의 포지션을 찾음
    Position currentPosition = players[currentPlayerIndex].position;
    int currentOrderIdx = actionOrder.indexOf(currentPosition);
    
    // 다음 플레이어를 찾는 로직
    for (int i = 0; i < players.length; i++) {
      // 다음 포지션 순서 계산
      int nextOrderIdx = (currentOrderIdx + 1 + i) % actionOrder.length;
      Position nextPosition = actionOrder[nextOrderIdx];
      
      // 해당 포지션을 가진 활성 플레이어 찾기
      int nextPlayerIndex = players.indexWhere(
        (p) => p.position == nextPosition && !p.isFolded && !p.isAllIn
      );
      
      if (nextPlayerIndex != -1) {
        currentPlayerIndex = nextPlayerIndex;
        return;
      }
    }
    
    // 모든 플레이어가 폴드/올인인 경우, 첫 번째 활성 플레이어를 찾음
    int firstActiveIndex = players.indexWhere((p) => !p.isFolded && !p.isAllIn);
    if (firstActiveIndex != -1) {
      currentPlayerIndex = firstActiveIndex;
    }
  }

  bool canCheck() {
    return currentBet == 0 || currentPlayer.bet == currentBet;
  }

  int getCallAmount() {
    return currentBet - currentPlayer.bet;
  }

  int calculatePotLimit() {
    // 폴드하지 않은 모든 플레이어의 베팅 합(현재 플레이어는 제외)
    int totalBets = players.where((p) => !p.isFolded && p != currentPlayer).fold(0, (sum, p) => sum + p.bet);
    int lastBet = lastRaiseAmount;
    int potLimit = totalBets + (lastBet * 2);
    // chips + bet과 비교하여 더 작은 값 반환
    return min(potLimit, currentPlayer.chips + currentPlayer.bet);
  }

  void performAction(String action, [int? amount]) {
    switch (action) {
      case 'check':
        if (!canCheck()) return;
        nextPlayer();
        break;
      case 'call':
        int callAmount = getCallAmount();
        if (callAmount > currentPlayer.chips) {
          allIn();
        } else {
          currentPlayer.chips -= callAmount;
          currentPlayer.bet += callAmount;
          pot.addBet(currentPlayer, callAmount);
          lastRaiseAmount = callAmount;
          nextPlayer();
        }
        break;
      case 'raise':
        if (amount == null || amount <= currentBet) return;
        // 팟 리밋 체크
        int maxPossible = currentPlayer.chips + currentPlayer.bet;
        int raiseTo = amount > maxPossible ? maxPossible : amount;
        int raiseAmount = raiseTo - currentPlayer.bet;

        currentPlayer.chips -= raiseAmount;
        currentPlayer.bet = raiseTo;
        currentBet = currentPlayer.bet;
        pot.addBet(currentPlayer, raiseAmount);
        lastRaiseAmount = raiseAmount;
        if (currentPlayer.chips == 0) {
          allIn();
          return;
        }
        nextPlayer();
        break;
      case 'fold':
        currentPlayer.isFolded = true;
        currentPlayer.bet = 0;
        nextPlayer();
        break;
      case 'allIn':
        allIn();
        break;
    }

    // 라운드 완료 체크
    checkRoundComplete();
  }

  void allIn() {
    int allInAmount = currentPlayer.chips;
    currentPlayer.chips = 0;
    currentPlayer.bet += allInAmount;
    currentPlayer.isAllIn = true;
    if (currentPlayer.bet > currentBet) {
      currentBet = currentPlayer.bet;
    }
    pot.addBet(currentPlayer, allInAmount);
    nextPlayer();
  }

  void checkRoundComplete() {
    // 모든 플레이어가 폴드했거나 올인했는지 체크
    bool allFoldedOrAllIn = players.every((p) => p.isFolded || p.isAllIn);

    // 모든 플레이어의 베팅이 동일한지 체크
    bool allBetsEqual = players
        .where((p) => !p.isFolded)
        .every((p) => p.bet == currentBet || p.isAllIn);

    isRoundComplete = allFoldedOrAllIn || allBetsEqual;
  }
} 