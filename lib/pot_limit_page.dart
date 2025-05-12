import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'models/player.dart';
import 'models/pot.dart';
import 'models/betting_round.dart';
import 'home_page.dart'; // AppLanguage를 사용하기 위해 추가

class PotLimitPage extends StatefulWidget {
  const PotLimitPage({super.key});

  @override
  _PotLimitPageState createState() => _PotLimitPageState();
}

class _PotLimitPageState extends State<PotLimitPage> {
  int smallBlind = 100;
  int bigBlind = 200;
  bool isGameStarted = false;
  int currentScore = 0;
  BettingRound? bettingRound;
  Pot pot = Pot();

  List<Player> players = [];
  TextEditingController potGuessController = TextEditingController();
  TextEditingController sbController = TextEditingController(text: '100');
  TextEditingController bbController = TextEditingController(text: '200');
  bool isPotGuessing = false;
  String resultMessage = '';
  int numberOfPlayers = 6;
  bool showNextGameButton = false;

  final List<int> blindLevels = [100, 200, 400, 600, 1500, 3000];

  List<List<String>> playerActionHistory = [];

  Timer? gameTimer;

  int? potCorrectAnswer;

  int raiseCount = 0;

  List<int> chipsInitial = [];

  // getText 함수를 추가하여 AppLanguage 클래스를 사용
  String getText(String key) => AppLanguage.getText(key);

  @override
  void initState() {
    super.initState();
    playerActionHistory = List.generate(6, (_) => []);
    sbController.text = smallBlind.toString();
    bbController.text = bigBlind.toString();
  }

  @override
  void dispose() {
    potGuessController.dispose();
    sbController.dispose();
    bbController.dispose();
    gameTimer?.cancel();
    gameTimer = null;
    super.dispose();
  }

  int formatAmount(int amount) {
    // 블라인드 관련 금액은 그대로 보존
    if (amount <= 100 || amount == smallBlind || amount == bigBlind) {
      return amount;
    }
    int sb = smallBlind;
    int step;
    if (sb >= 1500 && sb < 4000) {
      step = 500;
    } else if (sb >= 4000) {
      step = 1000;
    } else {
      step = 100;
    }
    // 가장 가까운 단위로 반올림 - 정확하게 step 단위로 맞추기
    return ((amount + (step ~/ 2)) ~/ step) * step;
  }

  String formatAmountString(int amount) {
    // 금액을 문자열로 변환
    return formatAmount(amount).toString();
  }

  void initializePlayers() {
    final random = Random();
    int blindIndex = random.nextInt(blindLevels.length);
    smallBlind = blindLevels[blindIndex];
    bigBlind = smallBlind * 2;
    
    // 텍스트 필드 업데이트
    sbController.text = smallBlind.toString();
    bbController.text = bigBlind.toString();

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
    if (sbIdx != -1) playerActionHistory[sbIdx].add('SB: ${formatAmountString(smallBlind)}');
    if (bbIdx != -1) playerActionHistory[bbIdx].add('BB: ${formatAmountString(bigBlind)}');
  }

  int getStep(int sb) {
    if (sb >= 1500 && sb < 4000) return 500;
    if (sb >= 4000) return 1000;
    return 100;
  }

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
      print('모든 플레이어가 폴드 또는 올인 상태입니다. 다음 게임으로 진행합니다.');
      Future.delayed(const Duration(seconds: 2), () {
        startNewGame();
      });
      return;
    }

    print('--- Player Status ---');
    for (var p in players) {
      print('${p.name} | chips: \$${formatAmountString(p.chips)} | bet: \$${formatAmountString(p.bet)} | isAllIn: ${p.isAllIn} | isFolded: ${p.isFolded}');
    }
    print('lastRaiseAmount: \$${formatAmountString(bettingRound?.lastRaiseAmount ?? 0)}');

    final random = Random();
    int action = random.nextInt(100);
    bool stateChanged = false;

    if (action < 30) {
      // 30% 확률로 "레이즈"
      // 현재 테이블의 최대 베팅액을 찾습니다
      int maxTableBet = 0;
      for (var p in players) {
        if (!p.isFolded && p.bet > maxTableBet) {
          maxTableBet = p.bet;
        }
      }
      
      int step = getStep(smallBlind);
      int totalPot = players.fold(0, (sum, p) => sum + p.bet);
      
      // 1. 콜 금액 계산
      int callAmount = maxTableBet - player.bet;
      
      // 2. 최소 레이즈 금액 계산
      int minRaiseAmount = bettingRound!.lastValidRaiseAmount;
      int minRaiseBet = maxTableBet + minRaiseAmount;  // 최소 레이즈 총액
      
      // 3. 최대 레이즈 금액 계산 (팟 리밋)
      int potLimit = bettingRound!.calculatePotLimit();
      int maxRaiseBet = min(potLimit, player.chips + player.bet);
      
      // 4. 최소/최대 레이즈를 step 단위로 조정
      minRaiseBet = ((minRaiseBet + step - 1) ~/ step) * step;
      maxRaiseBet = (maxRaiseBet ~/ step) * step;
      
      // 만약 최소 레이즈가 최대 레이즈보다 크면 최대값으로 설정
      if (minRaiseBet > maxRaiseBet) minRaiseBet = maxRaiseBet;
      
      // 5. 랜덤 레이즈 금액 선택
      int rangeBets = (maxRaiseBet - minRaiseBet) ~/ step + 1;
      int selectedBet;
      
      if (rangeBets <= 1) {
        selectedBet = minRaiseBet;
      } else {
        int randomSteps = random.nextInt(rangeBets);
        selectedBet = minRaiseBet + (randomSteps * step);
      }
      
      // 6. 실제 레이즈 금액 계산 (총액 기준)
      int actualRaiseAmount = selectedBet - maxTableBet;  // 순수 레이즈 금액
      
      // 7. 최종 타겟 베팅 금액
      int targetBet = selectedBet;
      
      print('레이즈 계산 상세 -----');
      print('최대 테이블 베팅: $maxTableBet, 콜 금액: $callAmount, 팟 금액: $totalPot');
      print('최소 레이즈 금액: $minRaiseAmount, 최소 레이즈 베팅: $minRaiseBet');
      print('최대 가능 베팅: $maxRaiseBet, 레이즈 범위: $rangeBets');
      print('선택된 베팅: $selectedBet, 순수 레이즈 금액: $actualRaiseAmount, targetBet: $targetBet');
      
      // UI는 플레이어 액션 이후에 업데이트합니다 (로그 먼저, UI 나중에)
      print('Action: RAISE | Player: ${player.name} | raiseAmount: $actualRaiseAmount');
      
      // 이전 베팅 기록 삭제
      playerActionHistory[playerIndex].clear();
      
      // 베팅 실행 (액션을 먼저 수행하고 결과를 UI에 표시)
      int prevBet = player.bet;
      bettingRound!.performAction('setBet', targetBet);
      
      // 실제 처리된 금액 (레이즈 금액) 가져오기
      int actualBet = player.bet;
      int finalRaiseAmount = actualBet - prevBet;
      
      print('베팅 후 실제 액션: ${player.name} | 이전 베팅: $prevBet | 최종 베팅: $actualBet | 순수 레이즈: $finalRaiseAmount');
      
      // 로그에서 확인한 실제 처리된 금액을 UI에 표시
      playerActionHistory[playerIndex].add('RAISE: ${finalRaiseAmount}');
      
      raiseCount++;
      stateChanged = true;
    } else if (action < 50) {
      // 20% 확률로 "콜"
      // 현재 테이블의 최대 베팅액을 찾습니다
      int maxTableBet = 0;
      for (var p in players) {
        if (!p.isFolded && p.bet > maxTableBet) {
          maxTableBet = p.bet;
        }
      }
      
      // 실제 콜해야 할 금액 계산
      int callAmount = maxTableBet - player.bet;
      
      int step = getStep(smallBlind);
      
      print('콜 계산 - 최대 테이블 베팅: $maxTableBet, 현재 플레이어 베팅: ${player.bet}, 콜 금액: $callAmount');
      
      if (callAmount > 0) {
        int prevBet = player.bet;
        if (callAmount > player.chips) {
          // 올인 케이스
          print('Action: ALL-IN (콜 금액 부족) | Player: ${player.name} | 보유 칩: ${player.chips} | 콜 금액: $callAmount');
          
          int targetBet = prevBet + player.chips;
          // 이전 베팅 기록 삭제
          playerActionHistory[playerIndex].clear();
          
          // 베팅 실행
          bettingRound!.performAction('setBet', targetBet);
          
          // 실제 금액으로 UI 업데이트 (플레이어의 모든 칩을 사용)
          playerActionHistory[playerIndex].add('ALL-IN: ${player.bet}');
        } else {
          // 정상 콜 케이스
          int targetBet = maxTableBet;
          print('액션: CALL | 플레이어: ${player.name} | 금액: $callAmount | 타겟 베팅: $targetBet');
          
          if (player.position != Position.bigBlind && player.position != Position.smallBlind) {
            playerActionHistory[playerIndex].clear();
          }
          
          // 베팅 실행
          bettingRound!.performAction('setBet', targetBet);
          
          // 실제 콜 금액 계산 (최종 베팅 - 이전 베팅)
          int actualCallAmount = player.bet - prevBet;
          playerActionHistory[playerIndex].add('CALL: ${actualCallAmount}');
        }
      } else {
        // 체크 케이스
        bettingRound!.performAction('check');
        playerActionHistory[playerIndex].clear();
        playerActionHistory[playerIndex].add('CHECK');
      }
      
      stateChanged = true;
    } else if (action < 70) {
      // 20% 확률로 "폴드"
      print('Action: FOLD | Player: ${player.name}');
      bettingRound!.performAction('fold');
      playerActionHistory[playerIndex].add('FOLD');
      stateChanged = true;
    } else {
      // 30% 확률로 "POT!" (항상 최대금액으로 베팅)
      // 현재 테이블의 최대 베팅액을 찾습니다
      int maxTableBet = 0;
      for (var p in players) {
        if (!p.isFolded && p.bet > maxTableBet) {
          maxTableBet = p.bet;
        }
      }
      
      // 콜 금액은 최고 베팅과의 차이로 계산
      int callAmount = maxTableBet - player.bet;
      
      // 현재 팟 크기 계산
      int currentPot = players.fold(0, (sum, p) => sum + p.bet);
      int totalPlayerChips = player.chips + player.bet;
      
      // 실제 POT 사이즈 계산: 현재 팟 + 콜 금액 (2배)
      int potSize = currentPot + callAmount;
      int potBet = potSize + callAmount; // POT 베팅 = 현재 팟 + 콜 금액*2
      
      // 최종 POT 베팅 금액은 플레이어 칩 수량과 팟 베팅 중 작은 값
      potBet = min(potBet, totalPlayerChips);
      
      int step = getStep(smallBlind);
      
      // 베팅 금액을 step 단위로 조정
      int roundedPotBet = ((potBet + step - 1) ~/ step) * step;
      
      // 최종 POT 베팅 금액 = 조정된 금액과 플레이어 칩 중 더 작은 값
      roundedPotBet = min(roundedPotBet, player.chips + player.bet);
      
      print('------ POT! 계산 상세 ------');
      print('현재 팟: $currentPot | 콜 금액: $callAmount');
      print('플레이어 총 칩: $totalPlayerChips | 일반 팟 베팅: $potBet');
      print('최종 POT 베팅(조정): $roundedPotBet, 스텝: $step');
      
      // 예상되는 실제 베팅 금액 계산
      int prevBet = player.bet;
      int targetBet = roundedPotBet;
      
      // 이미 베팅한 금액 제외한 순수 베팅 금액
      int actualPotRaise = targetBet - prevBet;
      
      print('Action: POT! | Player: ${player.name} | potBet: $targetBet');
      
      // 이전 액션 기록 삭제
      playerActionHistory[playerIndex].clear();
      
      // 베팅 실행 - 처리 후 실제 값을 기반으로 UI 업데이트
      bettingRound!.performAction('setBet', targetBet);
      
      // 실제 베팅 후 정답 설정
      potCorrectAnswer = player.bet; // 실제 베팅된 최종 금액
      
      // 실제 베팅 금액과 레이즈 금액 계산
      int finalBet = player.bet;
      int finalRaiseAmount = finalBet - prevBet;
      
      // UI에 실제 레이즈 금액 표시
      playerActionHistory[playerIndex].add('POT! (${finalRaiseAmount})');
      
      isPotGuessing = true;
      resultMessage = '';
      raiseCount++;
      stateChanged = true;
    }
    
    if (stateChanged) {
      setState(() {});
      
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
        print('액션 후 모든 플레이어가 폴드 또는 올인 상태입니다. 다음 게임으로 진행합니다.');
        Future.delayed(const Duration(seconds: 2), () {
          startNewGame();
        });
      }
    }
  }

  void startNewGame() {
    setState(() {
      isGameStarted = true;
      pot = Pot();
      initializePlayers();
      isPotGuessing = false;
      resultMessage = '';
      showNextGameButton = false;
      raiseCount = 0;
      potGuessController.text = '';
    });
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
  }

  void checkPotGuess() {
    int userGuess = int.tryParse(potGuessController.text) ?? 0;
    int correctPot = potCorrectAnswer ?? 0;
    
    // 현재 팟 금액 계산 (현재 모든 플레이어의 베팅 합계)
    int currentPot = 0;
    for (var p in players) {
      if (!p.isFolded) {
        currentPot += p.bet;
      }
    }
    
    // 마지막 콜/레이즈 금액 계산
    int lastActionAmount = 0;
    for (int i = 0; i < players.length; i++) {
      if (playerActionHistory[i].isNotEmpty) {
        String lastAction = playerActionHistory[i].last;
        if (lastAction.contains('RAISE:')) {
          lastActionAmount = int.tryParse(lastAction.split(':')[1].trim()) ?? 0;
          break;
        }
      }
    }
    
    print('--- CHECK POT GUESS ---');
    print('User guess: \$${userGuess} | Correct: \$${correctPot}');
    print('Current pot: \$${formatAmountString(currentPot)} | Last action amount: \$${formatAmountString(lastActionAmount)}');
    
    setState(() {
      if (userGuess == correctPot) {
        currentScore++;
        resultMessage = '${getText("correctAnswer")}$currentScore';
      } else {
        // 계산식 표시를 위한 반올림된 금액들
        String formattedCurrentPot = formatAmountString(currentPot);
        String formattedLastAmount = formatAmountString(lastActionAmount);
        String formattedTotal = formatAmountString(correctPot);
        
        resultMessage = '${getText("wrongAnswer")}${formattedTotal}';
      }
      showNextGameButton = true;
      for (var p in players) {
        p.bet = 0;
      }
    });
    gameTimer?.cancel();
  }

  void _showPotCalculationGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            getText('potLimitGuide'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getText('potLimitRule'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Text(getText('step1')),
                const SizedBox(height: 8),
                Text(getText('step2')),
                const SizedBox(height: 8),
                Text(getText('step3')),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    getText('potEquation'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  getText('example'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(getText('examplePot')),
                Text(getText('exampleCall')),
                Text(getText('exampleCalc')),
                const SizedBox(height: 8),
                Text(
                  getText('exampleResult'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                getText('confirm'),
                style: const TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 10,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      appBar: AppBar(
        title: const Text('팟 리밋 계산', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: !isGameStarted
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // 게임 시작 버튼 - 최상단으로 이동
                  Container(
                    width: 250,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextButton(
                      onPressed: startNewGame,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        '게임 시작',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 블라인드 설정 박스
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '블라인드 설정',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 랜덤 블라인드 사용 버튼
                        Container(
                          width: 200,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TextButton(
                            onPressed: () {
                              initializePlayers();
                              setState(() {});
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            child: const Text(
                              '랜덤 블라인드 사용',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '직접 설정',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // SB/BB 입력 영역
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'SB',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8.0),
                                    color: Colors.white.withOpacity(0.1),
                                    child: Center(
                                      child: Text(
                                        '100',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '/',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'BB',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8.0),
                                    color: Colors.white.withOpacity(0.1),
                                    child: Center(
                                      child: Text(
                                        '200',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 블라인드 적용 버튼
                        Container(
                          width: 150,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                int? sb = int.tryParse(sbController.text);
                                int? bb = int.tryParse(bbController.text);
                                
                                if (sb != null && bb != null && sb > 0 && bb > 0) {
                                  smallBlind = sb;
                                  bigBlind = bb;
                                } else {
                                  sbController.text = smallBlind.toString();
                                  bbController.text = bigBlind.toString();
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(getText('invalidNumberError')),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              '블라인드 적용',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(), // 중간 공간 확보
                  
                  // 계산식 보기 버튼
                  Container(
                    width: 250,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextButton(
                      onPressed: () => _showPotCalculationGuide(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        '계산식 보기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Made by SNO 텍스트
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'made by SNO',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _buildGameUI(),
    );
  }

  Widget _buildGameUI() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final boxW = screenWidth * (isSmallScreen ? 0.22 : (screenWidth < 500 ? 0.25 : 0.35));
    final boxH = boxW * 1.1;
    final fontScale = isSmallScreen ? 0.8 : 1.0;
    
    return Stack(
      children: [
        ...List.generate(numberOfPlayers, (index) {
          if (index >= players.length) {
            return Container();
          }
          
          final angle = (index * 60 - 90) * (3.14159 / 180);
          final radius = screenWidth * 0.35;
          final safeTop = MediaQuery.of(context).padding.top;
          final appBarHeight = AppBar().preferredSize.height;
          final minY = appBarHeight + safeTop + boxH / 2;
          final maxY = screenHeight - boxH / 2;
          final angleOffset = numberOfPlayers == 5 ? 90 : 90;
          final adjAngle = (index * (360 / numberOfPlayers) + angleOffset) * (3.14159 / 180);
          final adjRadius = radius * 1.15;
          final adjX = screenWidth / 2 + adjRadius * cos(adjAngle);
          final adjY = (screenHeight * 0.3) + adjRadius * sin(adjAngle) * 0.9;
          final maxX = screenWidth - 1;
          final clampedX = adjX.clamp(1, maxX - 1);
          final clampedY = adjY.clamp(minY, maxY);

          return Positioned(
            left: clampedX - boxW / 2,
            top: clampedY - boxH / 2,
            child: Container(
              width: boxW,
              height: boxH,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.transparent,
                  width: 0,
                ),
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      players[index].positionName,
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: screenWidth * (isSmallScreen ? 0.025 : (screenWidth < 500 ? 0.03 : 0.04)) * fontScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatAmountString(chipsInitial[index]),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * (isSmallScreen ? 0.03 : (screenWidth < 500 ? 0.035 : 0.045)) * fontScale,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'RobotoMono',
                      ),
                    ),
                    if (players[index].isAllIn)
                      Container(
                        margin: EdgeInsets.only(top: isSmallScreen ? 4 : 8),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 10, 
                          vertical: isSmallScreen ? 3 : 5
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ALL-IN',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * (isSmallScreen ? 0.025 : 0.03) * fontScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (playerActionHistory[index].isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: isSmallScreen ? 4 : 8),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 10, 
                          vertical: isSmallScreen ? 3 : 5
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: playerActionHistory[index].map((action) {
                            return Text(
                              action,
                              style: TextStyle(
                                color: action.contains('FOLD')
                                    ? Colors.redAccent
                                    : action.contains('POT!')
                                        ? Colors.amber
                                        : Colors.lightGreenAccent,
                                fontSize: screenWidth * (isSmallScreen ? 0.022 : (screenWidth < 500 ? 0.025 : 0.03)) * fontScale,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        
        if (isPotGuessing)
          Center(
            child: Container(
              width: isSmallScreen ? 250 : 300,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'POT! 금액 입력',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 16 : 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: potGuessController,
                      decoration: InputDecoration(
                        hintText: getText('enterPotAmount'),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.4),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, 
                          vertical: isSmallScreen ? 8 : 12
                        ),
                      ),
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 16 : 18,
                      ),
                      keyboardType: TextInputType.number,
                      onSubmitted: (value) {
                        checkPotGuess();
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 8 : 12
                          ),
                          textStyle: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        onPressed: checkPotGuess,
                        child: Text(getText('submit')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
        if (resultMessage.isNotEmpty)
          Positioned(
            top: screenHeight * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                resultMessage,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
        if (showNextGameButton)
          Positioned(
            bottom: screenHeight * 0.1,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 24 : 32, 
                      vertical: isSmallScreen ? 14 : 18
                    ),
                    textStyle: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  onPressed: startNewGame,
                  child: Text(getText('nextGame')),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
