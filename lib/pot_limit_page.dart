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

  String formatAmount(int amount) {
    // 스몰 블라인드 크기에 따라 화면에 표시되는 금액을 적절한 단위로 반올림
    int step;
    
    if ([1500, 2000, 2500, 3000].contains(smallBlind)) {
      // SB가 1500, 2000, 2500, 3000일 때는 500단위로 표시
      step = 500;
    } else if (smallBlind >= 4000) {
      // SB가 4000, 5000, 6000, 8000, 10000 이상일 때는 1000단위로 표시
      step = 1000;
    } else {
      // 그 외의 경우는 100단위로 표시
      step = 100;
    }
    
    // 100 이하의 블라인드 금액은 정확히 표시
    if (amount <= 100 || amount == smallBlind || amount == bigBlind) {
      return amount.toString();
    }
    
    // 단위에 맞게 반올림 처리 (표시 용도로만 사용)
    int roundedAmount = ((amount + (step ~/ 2)) ~/ step) * step;
    return roundedAmount.toString();
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
    if (sbIdx != -1) playerActionHistory[sbIdx].add('SB: ${formatAmount(smallBlind)}');
    if (bbIdx != -1) playerActionHistory[bbIdx].add('BB: ${formatAmount(bigBlind)}');
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
      print('${p.name} | chips: \$${formatAmount(p.chips)} | bet: \$${formatAmount(p.bet)} | isAllIn: ${p.isAllIn} | isFolded: ${p.isFolded}');
    }
    print('lastRaiseAmount: \$${formatAmount(bettingRound?.lastRaiseAmount ?? 0)}');

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
        print('Action: ALL-IN (부족한 칩) | Player: ${player.name} | 보유 칩: \$${formatAmount(player.chips)} | potLimit: \$${formatAmount(potLimit)}');
        bettingRound!.performAction('allIn');
        // 실제 베팅된 금액을 기준으로 표시
        playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
        stateChanged = true;
        return;
      }
      
      // 베팅 금액 범위 계산
      int numSteps = ((maxRaise - minRaise) ~/ 100) + 1;
      int raiseAmount = minRaise + (numSteps > 1 ? random.nextInt(numSteps) * 100 : 0);
      
      // 금액 표시용 문자열과 실제 금액 계산용 값을 분리
      // 화면에 표시할 때는 실제 베팅된 금액을 formatAmount로 표시 (UI와 로그 일치)
      print('Action: RAISE | Player: ${player.name} | raiseAmount: \$${formatAmount(raiseAmount)}');
      
      // 액션 중복 표시 해결을 위해 playerActionHistory 초기화
      playerActionHistory[playerIndex].clear();
      
      // 실제 베팅 실행
      bettingRound!.performAction('raise', raiseAmount);
      
      // 베팅 실행 후 실제 적용된 금액을 표시 (UI와 로그 일치)
      playerActionHistory[playerIndex].add('RAISE: ${formatAmount(player.bet)}');
      raiseCount++;
      stateChanged = true;
    } else if (action < 50) {
      // 20% 확률로 "콜"
      // BettingRound 클래스의 getCallAmount 메서드가 이미 금액을 적절히 조정함
      int callAmount = bettingRound!.getCallAmount();
      
      if (callAmount > player.chips) {
        // 칩이 부족하면 올인
        print('Action: ALL-IN (콜 금액 부족) | Player: ${player.name} | 보유 칩: \$${formatAmount(player.chips)} | 콜 금액: \$${formatAmount(callAmount)}');
        bettingRound!.performAction('allIn');
        // 실제 베팅된 금액을 기준으로 표시
        playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
      } else {
        print('Action: CALL | Player: ${player.name} | callAmount: \$${formatAmount(callAmount)}');
        
        // 액션 표시 전에 초기화
        if (player.position != Position.bigBlind && player.position != Position.smallBlind) {
          playerActionHistory[playerIndex].clear();
        }
        
        bettingRound!.performAction('call');
        
        // 모든 경우에 대해 실제 베팅 후 금액을 표시
        playerActionHistory[playerIndex].clear(); // 기존 모든 표시 제거
        playerActionHistory[playerIndex].add('CALL: ${formatAmount(player.bet)}');
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
      int potLimit = bettingRound!.calculatePotLimit();
      
      // 콜 금액 계산
      int callAmount = bettingRound!.getCallAmount();
      
      // 모든 플레이어의 베팅 합계 (현재 팟)
      int currentPot = players.fold(0, (sum, p) => sum + p.bet);
      
      // 최종 POT 베팅은 플레이어의 최대 베팅 가능 금액과 팟 리밋 중 작은 값
      int totalPlayerChips = player.chips + player.bet;
      int potBet = min(potLimit, totalPlayerChips);
      
      // BettingRound 클래스의 adjustAmountByBlindSize 메서드를 통해 
      // POT 베팅 금액을 적절히 조정하므로 별도 처리 없이 바로 사용
      
      // 베팅 금액을 저장 (퀴즈용) - 정확한 계산값 저장
      potCorrectAnswer = potBet;
      
      print('------ POT! 계산 상세 ------');
      print('현재 팟: \$${formatAmount(currentPot)} | 콜 금액: \$${formatAmount(callAmount)}');
      print('플레이어 총 칩: \$${formatAmount(totalPlayerChips)} | 팟 리밋: \$${formatAmount(potLimit)}');
      print('최종 POT 베팅: \$${formatAmount(potBet)}');
      print('Action: POT! | Player: ${player.name} | potBet: \$${formatAmount(potBet)}');
      
      // POT 액션 수행 - 팟 리밋을 존중
      playerActionHistory[playerIndex].clear(); // 액션 전에 초기화
      
      if (player.chips <= potLimit - player.bet) {
        // 칩이 부족하면 올인
        print('Action: ALL-IN (부족한 칩) | Player: ${player.name} | 보유 칩: \$${formatAmount(player.chips)} | potLimit: \$${formatAmount(potLimit)}');
        playerActionHistory[playerIndex].clear(); // 액션 전에 초기화
        bettingRound!.performAction('allIn');
        // 실제 베팅된 금액을 기준으로 표시
        playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
        stateChanged = true;
        return;
      } else {
        bettingRound!.performAction('raise', potBet);
        // POT 베팅 후에는 실제 베팅 금액을 표시 - POT! 표시만 하고 금액은 표시 안함
        playerActionHistory[playerIndex].add('POT!');
      }
      
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
    print('Current pot: \$${currentPot} | Last action amount: \$${lastActionAmount}');
    
    setState(() {
      if (userGuess == correctPot) {
        currentScore++;
        resultMessage = '${getText("correctAnswer")}$currentScore';
      } else {
        // 계산식 표시를 위한 반올림된 금액들
        String formattedCurrentPot = formatAmount(currentPot);
        String formattedLastAmount = formatAmount(lastActionAmount);
        String formattedTotal = formatAmount(correctPot);
        
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
                      formatAmount(chipsInitial[index]),
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
