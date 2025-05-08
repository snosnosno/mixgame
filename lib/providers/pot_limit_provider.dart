import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/pot.dart';
import '../models/betting_round.dart';
import '../home_page.dart';

/// 팟 리밋 게임 상태 관리 Provider
class PotLimitProvider extends ChangeNotifier {
  int smallBlind = 100;
  int bigBlind = 200;
  bool isGameStarted = false;
  int currentScore = 0;
  BettingRound? bettingRound;
  Pot pot = Pot();

  List<Player> players = [];
  TextEditingController potGuessController = TextEditingController();
  bool isPotGuessing = false;
  String resultMessage = '';
  int numberOfPlayers = 6;
  bool showNextGameButton = false;

  final List<int> blindLevels = [100, 200, 400, 600, 1500, 3000];
  bool useRandomBlinds = true; // 랜덤 블라인드 사용 여부

  List<List<String>> playerActionHistory = [];

  Timer? gameTimer;

  // POT 액션 정보 저장
  int? potCorrectAnswer;
  int? potLastCurrentPot;
  int? potLastCallAmount;
  int? potLastLimit;

  int raiseCount = 0;

  List<int> chipsInitial = [];

  PotLimitProvider() {
    playerActionHistory = List.generate(6, (_) => []);
  }

  @override
  void dispose() {
    potGuessController.dispose();
    gameTimer?.cancel();
    gameTimer = null;
    super.dispose();
  }

  /// 금액 형식화 함수
  String formatAmount(int amount) {
    if (smallBlind == 1500) {
      return ((amount + 250) ~/ 500 * 500).toString();
    }
    return amount.toString();
  }

  /// 블라인드 직접 설정 함수
  void setCustomBlinds(int sb, int bb) {
    smallBlind = sb;
    bigBlind = bb;
    useRandomBlinds = false;
    notifyListeners();
  }

  /// 랜덤 블라인드 설정 모드로 변경
  void setRandomBlinds() {
    useRandomBlinds = true;
    notifyListeners();
  }

  /// 게임 상태 리셋
  void resetGame() {
    isGameStarted = false;
    isPotGuessing = false;
    resultMessage = '';
    showNextGameButton = false;
    raiseCount = 0;
    potGuessController.text = '';
    
    // POT 액션 정보 초기화
    potCorrectAnswer = null;
    potLastCurrentPot = null;
    potLastCallAmount = null;
    potLastLimit = null;
    
    gameTimer?.cancel();
    gameTimer = null;
    
    notifyListeners();
  }

  /// 플레이어 초기화
  void initializePlayers() {
    if (useRandomBlinds) {
      // 랜덤 블라인드 설정
      final random = Random();
      int blindIndex = random.nextInt(blindLevels.length);
      smallBlind = blindLevels[blindIndex];
      bigBlind = smallBlind * 2;
    }
    // 이미 설정된 smallBlind/bigBlind 사용

    final random = Random();
    players = List.generate(
      numberOfPlayers,
      (index) => Player(
        name: 'Player ${index + 1}',
        chips: (random.nextInt(599) * 500) + 500,
        hand: [],
        position: Position.values[index % Position.values.length],
      ),
    );
    chipsInitial = players.map((p) => p.chips).toList();

    // SB, BB 포지션 인덱스 찾기
    int sbIdx = players.indexWhere((p) => p.position == Position.smallBlind);
    int bbIdx = players.indexWhere((p) => p.position == Position.bigBlind);
    if (sbIdx != -1) {
      players[sbIdx].chips -= smallBlind;
      players[sbIdx].bet = smallBlind;
    }
    if (bbIdx != -1) {
      players[bbIdx].chips -= bigBlind;
      players[bbIdx].bet = bigBlind;
    }

    pot.addBet(players[sbIdx], smallBlind);
    pot.addBet(players[bbIdx], bigBlind);

    bettingRound = BettingRound(players: players, pot: pot);
    // UTG가 첫 액션을 하도록 currentPlayerIndex 설정
    int utgIdx = players.indexWhere((p) => p.position == Position.underTheGun);
    if (utgIdx != -1) bettingRound!.currentPlayerIndex = utgIdx;

    playerActionHistory = List.generate(numberOfPlayers, (_) => []);
    if (sbIdx != -1) playerActionHistory[sbIdx].add('SB: ${formatAmount(smallBlind)}');
    if (bbIdx != -1) playerActionHistory[bbIdx].add('BB: ${formatAmount(bigBlind)}');
    
    notifyListeners();
  }

  /// 현재 팟 계산식 정보를 반환
  Map<String, dynamic> getPotCalculationDetails() {
    if (bettingRound == null) {
      return {
        'potLimit': 0,
        'currentPot': 0,
        'callAmount': 0,
        'explanation': AppLanguage.getText("gameNotStarted")
      };
    }
    
    // POT 액션 정보가 저장되어 있으면 해당 정보 사용
    int currentPot = potLastCurrentPot ?? players.fold(0, (sum, p) => sum + p.bet);
    int callAmount = potLastCallAmount ?? (bettingRound!.currentPlayerIndex < players.length ? bettingRound!.getCallAmount() : 0);
    int potLimit = potLastLimit ?? bettingRound!.calculatePotLimit();

    StringBuffer potDetails = StringBuffer();
    
    // 0보다 큰 베팅을 한 플레이어만 추출
    List<Player> bettingPlayers = players.where((p) => p.bet > 0).toList();
    
    // 각 플레이어의 베팅 표시
    for (int i = 0; i < bettingPlayers.length; i++) {
      Player player = bettingPlayers[i];
      
      // 플레이어 베팅 정보 추가
      potDetails.write('${player.bet}');
      
      // 마지막 플레이어가 아니면 '+' 추가
      if (i < bettingPlayers.length - 1) {
        potDetails.write(' + ');
      }
    }
    
    // 합계 표시
    if (bettingPlayers.length > 1) {
      potDetails.write(' = $currentPot');
    }
    
    // 정답 값이 있는 경우 추가
    String correctAnswerText = '';
    
    // 계산된 원래 팟 리밋 금액 (현재 팟 + 콜 금액 × 2)
    int calculatedPotLimit = currentPot + callAmount * 2;
    
    // null 안전한 방식으로 처리
    int? correctAnswerValue = potCorrectAnswer;
    if (correctAnswerValue != null) {
      // 올인 여부 확인 - null 비교 없이 처리
      bool isAllIn = false;
      if (calculatedPotLimit > correctAnswerValue) {
        isAllIn = true;
      }
      
      if (isAllIn) {
        correctAnswerText = '\n${AppLanguage.getText('answer')}: $correctAnswerValue (${AppLanguage.getText('allIn')})';
      } else {
        correctAnswerText = '\n${AppLanguage.getText('answer')}: $correctAnswerValue';
      }
    }
    
    // 현재 팟 내역이 비어있는 경우 처리
    String potDetailsStr = potDetails.toString().isEmpty 
      ? '$currentPot'
      : potDetails.toString();
    
    String explanation = '''
${AppLanguage.getText('currentPot')}: $potDetailsStr

${AppLanguage.getText('callAmount')}: $callAmount

${AppLanguage.getText('calculation')}: $currentPot + ($callAmount × 2) = $calculatedPotLimit

${AppLanguage.getText('potBetting')} = $calculatedPotLimit$correctAnswerText
''';
    
    return {
      'potLimit': potLimit,
      'currentPot': currentPot,
      'callAmount': callAmount,
      'correctAnswer': potCorrectAnswer,
      'explanation': explanation
    };
  }

  /// 플레이어 액션 실행
  void performPlayerAction(int playerIndex) {
    if (isPotGuessing || bettingRound == null) return;

    var player = players[playerIndex];
    // 연속적으로 올인/폴드 상태면 계속 nextPlayer()
    bool allPlayersInactive = true;
    int loopCount = 0;
    while (player.isFolded || player.isAllIn) {
      // 무한 루프 방지
      loopCount++;
      if (loopCount > players.length) {
        // 모든 플레이어를 확인했는데도 액션 가능한 플레이어가 없음
        // 이는 모든 플레이어가 폴드 또는 올인 상태임을 의미
        break;
      }
      
      bettingRound!.nextPlayer();
      player = players[bettingRound!.currentPlayerIndex];
    }
    
    // 모든 플레이어의 상태 확인
    allPlayersInactive = true;
    for (var p in players) {
      if (!p.isFolded && !p.isAllIn) {
        allPlayersInactive = false;
        break;
      }
    }
    
    // 모든 플레이어가 폴드 또는 올인 상태인 경우 다음 게임으로 진행
    if (allPlayersInactive) {
      debugPrint('모든 플레이어가 폴드 또는 올인 상태입니다. 다음 게임으로 진행합니다.');
      Future.delayed(const Duration(seconds: 2), () {
        startNewGame();
      });
      return;
    }

    debugPrint('--- Player Status ---');
    for (var p in players) {
      debugPrint('${p.name} | chips: \$${p.chips} | bet: \$${p.bet} | isAllIn: ${p.isAllIn} | isFolded: ${p.isFolded}');
    }
    debugPrint('lastRaiseAmount: \$${bettingRound?.lastRaiseAmount}');

    final random = Random();
    int action = random.nextInt(100);
    bool stateChanged = false;

    if (action < 30) {
      // 30% 확률로 "레이즈"
      int potLimit = bettingRound!.calculatePotLimit();
      int minRaise;
      int maxRaise = min(potLimit, player.chips);
      
      if (raiseCount == 0) {
        // 첫 레이즈도 getMinimumRaise()로 처리
        minRaise = bettingRound!.getMinimumRaise();
      } else {
        minRaise = bettingRound!.getMinimumRaise();
      }
      
      if (maxRaise < minRaise) {
        // 칩이 부족하면 팟 리밋 내에서 올인
        debugPrint('Action: ALL-IN (부족한 칩) | Player: ${player.name} | 보유 칩: \$${player.chips} | potLimit: \$${potLimit}');
        bettingRound!.performAction('allIn');
        playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
        stateChanged = true;
        notifyListeners();
        return;
      }
      
      // 100단위 랜덤 베팅 (1500/3000 블라인드일 경우 500단위로 조정)
      int step = smallBlind == 1500 ? 500 : 100;
      int numSteps = ((maxRaise - minRaise) ~/ step) + 1;
      int raiseAmount = minRaise + (numSteps > 1 ? random.nextInt(numSteps) * step : 0);
      
      if (raiseAmount > player.chips) {
        // 칩이 부족하면 올인
        debugPrint('Action: ALL-IN (부족한 칩) | Player: ${player.name} | 보유 칩: \$${player.chips} | potLimit: \$${potLimit}');
        bettingRound!.performAction('allIn');
        playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
        stateChanged = true;
        notifyListeners();
        return;
      }
      
      debugPrint('Action: RAISE | Player: ${player.name} | raiseAmount: \$${raiseAmount}');
      bettingRound!.performAction('raise', raiseAmount);
      playerActionHistory[playerIndex].add('RAISE: ${formatAmount(raiseAmount)}');
      raiseCount++;
      stateChanged = true;
    } else if (action < 50) {
      // 20% 확률로 "콜"
      int callAmount = bettingRound!.getCallAmount();
      
      if (callAmount > player.chips) {
        // 칩이 부족하면 올인
        debugPrint('Action: ALL-IN (콜 금액 부족) | Player: ${player.name} | 보유 칩: \$${player.chips} | 콜 금액: \$${callAmount}');
        bettingRound!.performAction('allIn');
        playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
      } else {
        debugPrint('Action: CALL | Player: ${player.name} | callAmount: \$${callAmount}');
        bettingRound!.performAction('call');
        
        // 포지션이 BB 또는 SB인 경우 이미 블라인드를 냈으므로 총액 표시
        if (player.position == Position.bigBlind || player.position == Position.smallBlind) {
          // 총 베팅액을 CALL 액션으로 표시
          playerActionHistory[playerIndex].clear(); // 기존 SB/BB 표시 제거
          playerActionHistory[playerIndex].add('CALL: ${formatAmount(player.bet)}');
        } else {
          playerActionHistory[playerIndex].add('CALL: ${formatAmount(callAmount)}');
        }
      }
      stateChanged = true;
    } else if (action < 70) {
      // 20% 확률로 "폴드"
      debugPrint('Action: FOLD | Player: ${player.name}');
      bettingRound!.performAction('fold');
      playerActionHistory[playerIndex].add('FOLD');
      stateChanged = true;
    } else {
      // 30% 확률로 "POT!" (항상 최대금액으로 베팅)
      int potLimit = bettingRound!.calculatePotLimit();
      
      // 콜 금액 계산
      int callAmount = bettingRound!.getCallAmount();
      
      // 모든 플레이어의 베팅 합계 (현재 팟)
      int currentPot = players.fold(0, (sum, p) => sum + p.bet);
      
      // 최종 POT 베팅은 플레이어의 최대 베팅 가능 금액과 팟 리밋 중 작은 값
      int totalPlayerChips = player.chips + player.bet;
      int potBet = min(potLimit, totalPlayerChips);
      
      // 1500/3000 블라인드일 경우 500단위로 조정
      if (smallBlind == 1500) {
        potBet = (potBet ~/ 500) * 500;
      }
      
      // POT 액션 정보 저장
      potCorrectAnswer = potBet;
      potLastCurrentPot = currentPot;
      potLastCallAmount = callAmount;
      potLastLimit = potLimit;
      
      debugPrint('------ POT! 계산 상세 ------');
      debugPrint('현재 팟: \$${currentPot} | 콜 금액: \$${callAmount}');
      debugPrint('플레이어 총 칩: \$${totalPlayerChips} | 팟 리밋: \$${potLimit}');
      debugPrint('최종 POT 베팅: \$${potBet}');
      debugPrint('Action: POT! | Player: ${player.name} | potBet: \$${potBet}');
      
      // POT 액션 수행 - 팟 리밋을 존중
      if (player.chips <= potLimit - player.bet) {
        // 칩이 부족하면 올인
        debugPrint('플레이어 칩이 부족하여 올인');
        bettingRound!.performAction('allIn');
      } else {
        bettingRound!.performAction('raise', potBet);
      }
      
      playerActionHistory[playerIndex].add('POT!');
      isPotGuessing = true;
      resultMessage = '';
      raiseCount++;
      stateChanged = true;
    }
    
    if (stateChanged) {
      notifyListeners();
      
      // 액션 후에도 모든 플레이어의 상태 다시 확인
      bool allInactiveAfterAction = true;
      for (var p in players) {
        if (!p.isFolded && !p.isAllIn) {
          allInactiveAfterAction = false;
          break;
        }
      }
      
      // 모든 플레이어가 폴드 또는 올인 상태인 경우 다음 게임으로 진행
      if (allInactiveAfterAction && !isPotGuessing) {
        debugPrint('액션 후 모든 플레이어가 폴드 또는 올인 상태입니다. 다음 게임으로 진행합니다.');
        Future.delayed(const Duration(seconds: 2), () {
          startNewGame();
        });
      }
    }
  }

  /// 새 게임 시작
  void startNewGame() {
    isGameStarted = true;
    pot = Pot();
    initializePlayers();
    isPotGuessing = false;
    resultMessage = '';
    showNextGameButton = false;
    raiseCount = 0;
    potGuessController.text = '';
    
    // POT 액션 정보 초기화
    potCorrectAnswer = null;
    potLastCurrentPot = null;
    potLastCallAmount = null;
    potLastLimit = null;
    
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPotGuessing && isGameStarted && players.length > 2 && bettingRound != null) {
        int currentPlayerIndex = bettingRound!.currentPlayerIndex;
        performPlayerAction(currentPlayerIndex);
      }
      if (!isGameStarted || isPotGuessing) {
        timer.cancel();
      }
    });
    
    notifyListeners();
  }

  /// POT 금액 추측 확인
  void checkPotGuess() {
    int userGuess = int.tryParse(potGuessController.text) ?? 0;
    int correctPot = potCorrectAnswer ?? 0;
    debugPrint('--- CHECK POT GUESS ---');
    debugPrint('User guess: \$${userGuess} | Correct: \$${correctPot}');
    
    if (userGuess == correctPot) {
      currentScore++;
      resultMessage = '정답! +1점\n현재 점수: $currentScore';
    } else {
      resultMessage = '오답!\n정답: ${formatAmount(correctPot)}';
    }
    showNextGameButton = true;
    for (var p in players) {
      p.bet = 0;
    }
    
    gameTimer?.cancel();
    notifyListeners();
  }
} 