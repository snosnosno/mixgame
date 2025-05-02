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
    currentBet = lastRaiseAmount; // 현재 베팅도 BB 금액으로 초기화
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
    
    print("---- POT LIMIT 계산 ----");
    print("다른 플레이어 총 베팅: $potSize | 현재 플레이어 베팅: ${currentPlayer.bet}");
    print("현재 베팅: $callAmount");
    print("계산식: $potSize + ($callAmount * 2) = $potLimit");
    print("플레이어 최대 베팅 가능액: $maxPossibleBet");
    print("최종 팟 리밋: $finalPotLimit");
    
    return finalPotLimit;
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
          nextPlayer();
        }
        break;
      case 'raise':
        if (amount == null || amount <= currentBet) return;
        
        // 팟 리밋 계산 - 안전 확인
        int potLimit = calculatePotLimit();
        
        print("---- RAISE 액션 처리 ----");
        print("요청된 베팅 금액: $amount | 팟 리밋: $potLimit");
        print("현재 베팅: ${currentPlayer.bet} | 플레이어 칩: ${currentPlayer.chips}");
        
        // 플레이어가 실제로 베팅할 수 있는 총액 (현재 베팅 + 남은 칩)
        int maxBet = currentPlayer.chips + currentPlayer.bet;
        
        // 요청된 금액을 플레이어의 최대 가능 베팅과 팟 리밋 중 작은 값으로 제한
        int finalBet = min(amount, min(maxBet, potLimit));
        
        // 실제 레이즈 금액 계산 (최종 베팅 - 현재 베팅)
        int raiseAmount = finalBet - currentPlayer.bet;
        
        print("최종 베팅: $finalBet | 실제 레이즈 금액: $raiseAmount");
        
        if (raiseAmount <= 0) {
          print("유효하지 않은 레이즈 금액, 액션 무시");
          return;  // 유효한 레이즈가 아니면 무시
        }

        // 플레이어 상태 업데이트
        currentPlayer.chips -= raiseAmount;
        currentPlayer.bet = finalBet;
        currentBet = finalBet;
        pot.addBet(currentPlayer, raiseAmount);
        
        // 마지막 레이즈 금액 저장 (현재 베팅 - 이전 베팅)
        lastRaiseAmount = raiseAmount;
        
        // 올인 여부 체크
        if (currentPlayer.chips == 0) {
          currentPlayer.isAllIn = true;
          print("플레이어 올인 상태로 변경");
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
    // 팟 리밋 계산
    int potLimit = calculatePotLimit();
    
    // 올인 전 현재 베팅 저장
    int previousBet = currentPlayer.bet;
    
    // 올인 금액은 플레이어의 모든 칩 (팟 리밋 내에서)
    int allInAmount = min(currentPlayer.chips, potLimit - previousBet);
    int finalBet = previousBet + allInAmount;
    
    print("---- ALL-IN 액션 처리 ----");
    print("플레이어 칩: ${currentPlayer.chips} | 팟 리밋: $potLimit");
    print("이전 베팅: $previousBet | 올인 금액: $allInAmount");
    print("최종 베팅: $finalBet");
    
    // 플레이어 상태 업데이트
    currentPlayer.chips = 0;
    currentPlayer.bet = finalBet;
    currentPlayer.isAllIn = true;
    
    // 현재 베팅 업데이트 (올인 금액이 현재 최대 베팅보다 크면)
    if (finalBet > currentBet) {
      lastRaiseAmount = finalBet - currentBet;  // 레이즈 금액 저장
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