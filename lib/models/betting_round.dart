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
    int nextOrderIdx = (currentOrderIdx + 1) % actionOrder.length;
    for (int i = 0; i < players.length; i++) {
      // 순서대로 다음 포지션을 가진 플레이어를 찾음
      Position nextPosition = actionOrder[nextOrderIdx];
      int foundIdx = players.indexWhere((p) => p.position == nextPosition && !p.isFolded && !p.isAllIn);
      if (foundIdx != -1) {
        currentPlayerIndex = foundIdx;
        return;
      }
      nextOrderIdx = (nextOrderIdx + 1) % actionOrder.length;
    }
    // 모두 폴드/올인일 경우 기존 방식 fallback
    do {
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    } while (players[currentPlayerIndex].isFolded || players[currentPlayerIndex].isAllIn);
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
    // 현재 스트릿에서 이미 베팅한 금액 차감은 불필요 (이미 합산에서 제외됨)
    return min(potLimit, currentPlayer.chips);
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