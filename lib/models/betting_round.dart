import 'dart:math';
import 'player.dart';
import 'pot.dart';

class BettingRound {
  final List<Player> players;
  final Pot pot;
  int currentPlayerIndex = 0;
  int currentBet = 0;
  bool isRoundComplete = false;
  int lastRaiseAmount = 0; // 직전 실제 레이즈(언더레이즈 포함)
  int lastValidRaiseAmount = 0; // 직전 유효 레이즈(최소 레이즈 이상)

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
    lastValidRaiseAmount = lastRaiseAmount;
    currentBet = lastRaiseAmount; // 현재 베팅도 BB 금액으로 초기화
  }

  // 블라인드 크기에 따라 적절한 단위로 금액을 조정하는 메서드
  int adjustAmountByBlindSize(int amount) {
    int smallBlind = getSmallBlindAmount();
    int step;
    
    if ([1500, 2000, 2500, 3000].contains(smallBlind)) {
      // SB가 1500, 2000, 2500, 3000일 때는 500단위로 조정
      step = 500;
    } else if (smallBlind >= 4000) {
      // SB가 4000, 5000, 6000, 8000, 10000 이상일 때는 1000단위로 조정
      step = 1000;
    } else {
      // 그 외의 경우는 100단위로 조정
      step = 100;
    }
    
    // 단위에 맞게 내림 처리
    return (amount ~/ step) * step;
  }
  
  // 현재 게임의 스몰 블라인드 금액 구하기
  int getSmallBlindAmount() {
    int sbIdx = players.indexWhere((p) => p.position == Position.smallBlind);
    int bbIdx = players.indexWhere((p) => p.position == Position.bigBlind);
    
    if (sbIdx != -1 && bbIdx != -1) {
      // SB와 BB 둘 다 있는 경우, SB 베팅 금액 반환
      return players[sbIdx].bet;
    } else if (bbIdx != -1) {
      // BB만 있는 경우, BB 베팅 금액의 절반 반환
      return players[bbIdx].bet ~/ 2;
    } else {
      // 둘 다 없는 경우 기본값 100 반환
      return 100;
    }
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
    int rawCallAmount = currentBet - currentPlayer.bet;
    
    // 콜 금액도 블라인드 크기에 맞게 조정
    // (전체 베팅 금액을 조정한 후 현재 베팅을 뺌)
    return adjustAmountByBlindSize(currentPlayer.bet + rawCallAmount) - currentPlayer.bet;
  }

  int calculatePotLimit() {
    // 현재 팟 크기 계산 (현재 플레이어를 제외한 다른 플레이어들의 베팅 합)
    int potSize = players.where((p) => p != currentPlayer).fold(0, (sum, p) => sum + p.bet);
    
    // 현재 베팅 금액을 콜 금액으로 사용 (마지막 레이즈 금액 아님)
    int callAmount = currentBet;
    
    // 팟 리밋 계산: 현재 팟 + (현재 베팅 * 2)
    int potLimit = potSize + (callAmount * 2);
    
    // 최대 가능 베팅액 (플레이어의 칩 + 이미 베팅한 금액)
    int maxPossibleBet = currentPlayer.chips + currentPlayer.bet;
    
    // 최종 팟 리밋 (플레이어의 최대 가능 베팅액과 비교하여 더 작은 값 반환)
    int finalPotLimit = min(potLimit, maxPossibleBet);
    
    return finalPotLimit;
  }

  // 미니멈 레이즈 계산 (언더레이즈 규칙 반영 및 적절한 단위로 조정)
  int getMinimumRaise() {
    int minRaise = currentBet + lastValidRaiseAmount;
    
    // 블라인드 크기에 맞게 미니멈 레이즈 금액 조정
    return adjustAmountByBlindSize(minRaise);
  }

  void performAction(String action, [int? amount]) {
    switch (action) {
      case 'check':
        if (!canCheck()) return;
        nextPlayer();
        break;
      case 'call':
        // getCallAmount 내에서 이미 조정된 콜 금액 가져오기
        int callAmount = getCallAmount();
        
        if (callAmount > currentPlayer.chips) {
          allIn();
        } else {
          currentPlayer.chips -= callAmount;
          currentPlayer.bet += callAmount;
          pot.addBet(currentPlayer, callAmount);
          nextPlayer();
        }
        break;
      case 'raise':
        if (amount == null || amount <= currentBet) return;
        int potLimit = calculatePotLimit();
        int maxBet = currentPlayer.chips + currentPlayer.bet;
        
        // 입력 받은 amount 값을 블라인드 크기에 따라 적절한 단위로 조정
        int adjustedAmount = adjustAmountByBlindSize(amount);
        
        // 조정된 금액 사용
        int finalBet = min(adjustedAmount, min(maxBet, potLimit));
        
        int raiseAmount = finalBet - currentPlayer.bet;
        int minimumRaise = getMinimumRaise();
        
        if (finalBet < minimumRaise) {
          // 언더레이즈(최소 미만 레이즈)는 올인만 허용
          if (finalBet == maxBet) {
            // 올인 언더레이즈: lastValidRaiseAmount는 갱신하지 않음
            lastRaiseAmount = finalBet - currentBet;
          } else {
            // 유효하지 않은 레이즈
            return;
          }
        } else {
          // 정상 레이즈: lastValidRaiseAmount 갱신
          // 순수 레이즈 금액 계산 (현재 베팅 - 이전 베팅)
          int pureRaiseAmount = finalBet - currentBet;
          lastRaiseAmount = pureRaiseAmount;
          lastValidRaiseAmount = pureRaiseAmount;
        }

        currentPlayer.chips -= raiseAmount;
        currentPlayer.bet = finalBet;
        currentBet = finalBet;
        pot.addBet(currentPlayer, raiseAmount);
        if (currentPlayer.chips == 0) {
          currentPlayer.isAllIn = true;
        }
        nextPlayer();
        break;
      case 'fold':
        currentPlayer.isFolded = true;
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
    int potLimit = calculatePotLimit();
    int previousBet = currentPlayer.bet;
    int allInAmount = min(currentPlayer.chips, potLimit - previousBet);
    
    // 올인 금액도 블라인드 크기에 따라 조정
    allInAmount = adjustAmountByBlindSize(allInAmount + previousBet) - previousBet;
    
    int finalBet = previousBet + allInAmount;
    
    // 올인 언더레이즈 체크
    int minimumRaise = getMinimumRaise();
    
    if (finalBet >= minimumRaise) {
      // 올인이 미니멈 레이즈 이상이면 유효 레이즈로 간주
      // 순수 레이즈 금액 계산 (finalBet - currentBet)
      int pureRaiseAmount = finalBet - currentBet;
      lastRaiseAmount = pureRaiseAmount;
      lastValidRaiseAmount = pureRaiseAmount;
    } else {
      // 언더레이즈: lastValidRaiseAmount는 유지
      int pureRaiseAmount = finalBet - currentBet;
      lastRaiseAmount = pureRaiseAmount;
    }
    
    currentPlayer.chips = 0;
    currentPlayer.bet = finalBet;
    currentPlayer.isAllIn = true;
    if (finalBet > currentBet) {
      currentBet = finalBet;
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