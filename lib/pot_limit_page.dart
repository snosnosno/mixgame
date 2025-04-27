import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'models/player.dart';
import 'models/pot.dart';
import 'models/betting_round.dart';

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
  bool isPotGuessing = false;
  String resultMessage = '';
  int numberOfPlayers = 6;
  bool showNextGameButton = false;

  final List<int> blindLevels = [100, 200, 400, 600, 1500, 3000];

  final TextEditingController _potController = TextEditingController();
  final TextEditingController _lastBetController = TextEditingController();
  final TextEditingController _alreadyBetController = TextEditingController();
  final TextEditingController _chipsController = TextEditingController();
  int _maxRaise = 0;

  List<List<String>> playerActionHistory = [];

  Timer? gameTimer;

  int? potCorrectAnswer;

  int raiseCount = 0;

  List<int> chipsInitial = [];

  @override
  void initState() {
    super.initState();
    playerActionHistory = List.generate(6, (_) => []);
  }

  @override
  void dispose() {
    _potController.dispose();
    _lastBetController.dispose();
    _alreadyBetController.dispose();
    _chipsController.dispose();
    potGuessController.dispose();
    gameTimer?.cancel();
    gameTimer = null;
    super.dispose();
  }

  void initializePlayers() {
    final random = Random();
    int blindIndex = random.nextInt(blindLevels.length);
    smallBlind = blindLevels[blindIndex];
    bigBlind = smallBlind * 2;

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
    if (sbIdx != -1) playerActionHistory[sbIdx].add('SB: $smallBlind');
    if (bbIdx != -1) playerActionHistory[bbIdx].add('BB: $bigBlind');
  }

  void performPlayerAction(int playerIndex) {
    if (isPotGuessing || bettingRound == null) return;

    var player = players[playerIndex];
    // 연속적으로 올인/폴드 상태면 계속 nextPlayer()
    while (player.isFolded || player.isAllIn) {
      bettingRound!.nextPlayer();
      player = players[bettingRound!.currentPlayerIndex];
    }

    print('--- Player Status ---');
    for (var p in players) {
      print('${p.name} | chips: \$${p.chips} | bet: \$${p.bet} | isAllIn: ${p.isAllIn} | isFolded: ${p.isFolded}');
    }
    print('lastRaiseAmount: \$${bettingRound?.lastRaiseAmount}');

    final random = Random();
    int action = random.nextInt(100);

    if (action < 50) {
      // 50% 확률로 "레이즈"
      int potLimit = bettingRound!.calculatePotLimit();
      int minRaise;
      int maxRaise = min(potLimit, player.chips);
      if (raiseCount == 0) {
        minRaise = bigBlind * 2;
      } else {
        // 최소 레이즈는 이전 베팅(콜) + 이전 레이즈 금액
        int lastRaise = bettingRound!.currentBet - (raiseCount == 1 ? bigBlind : 0);
        // lastRaiseAmount가 있다면 그 값을 사용
        if (bettingRound!.currentBet > 0 && bettingRound!.currentBet != bigBlind) {
          lastRaise = bettingRound!.currentBet - bettingRound!.currentBet; // fallback
        }
        minRaise = bettingRound!.currentBet + (bettingRound!.currentBet > 0 ? bettingRound!.currentBet : bigBlind);
        // 실제로는 lastRaiseAmount를 추적하는 변수가 필요할 수 있음
      }
      if (maxRaise < minRaise) {
        // 칩이 부족하면 무조건 올인
        int allInAmount = player.chips;
        player.chips = 0;
        player.bet += allInAmount;
        player.isAllIn = true;
        pot.addBet(player, allInAmount);
        playerActionHistory[playerIndex].add('ALL-IN: ${player.bet}');
        print('Action: ALL-IN | Player: ${player.name} | amount: \$${player.bet}');
        bettingRound!.nextPlayer();
        setState(() {});
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
        pot.addBet(player, allInAmount);
        playerActionHistory[playerIndex].add('ALL-IN: ${player.bet}');
        print('Action: ALL-IN | Player: ${player.name} | amount: \$${player.bet}');
        bettingRound!.nextPlayer();
        setState(() {});
        return;
      }
      print('Action: RAISE | Player: ${player.name} | raiseAmount: \$${raiseAmount}');
      bettingRound!.performAction('raise', raiseAmount);
      playerActionHistory[playerIndex].add('레이즈: $raiseAmount');
      raiseCount++;
      setState(() {});
    } else if (action < 70) {
      // 20% 확률로 "폴드"
      print('Action: FOLD | Player: ${player.name}');
      bettingRound!.performAction('fold');
      playerActionHistory[playerIndex].add('FOLD');
      setState(() {});
    } else {
      // 30% 확률로 "POT!" (항상 최대금액으로 베팅)
      int potLimit = bettingRound!.calculatePotLimit();
      int allInAmount = chipsInitial[playerIndex] + player.bet;
      int potBet = min(potLimit, allInAmount);
      potCorrectAnswer = potBet;
      print('Action: POT! | Player: ${player.name} | potLimit: \$${potLimit} | chips: \$${player.chips} | bet: \$${player.bet} | potBet: \$${potBet}');
      bettingRound!.performAction('raise', potBet);
      playerActionHistory[playerIndex].add('POT!');
      isPotGuessing = true;
      resultMessage = '';
      raiseCount++;
      setState(() {});
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
    print('--- CHECK POT GUESS ---');
    print('User guess: \$${userGuess} | Correct: \$${correctPot}');
    setState(() {
      if (userGuess == correctPot) {
        currentScore++;
        resultMessage = '정답입니다! +1점\n현재 점수: $currentScore점';
      } else {
        resultMessage = '틀렸습니다!\n정답은: $correctPot';
      }
      showNextGameButton = true;
      for (var p in players) {
        p.bet = 0;
      }
    });
    gameTimer?.cancel();
  }

  void _calculateMaxRaise() {
    int pot = int.tryParse(_potController.text) ?? 0;
    int lastBet = int.tryParse(_lastBetController.text) ?? 0;
    int alreadyBet = int.tryParse(_alreadyBetController.text) ?? 0;
    int chips = int.tryParse(_chipsController.text) ?? 0;

    // 3배 룰: (마지막 베팅 x 3) + 이전 팟
    int previousPot = pot - lastBet;
    int maxRaise = (lastBet * 3) + previousPot;

    // 현재 스트릿에서 이미 배팅한 금액 차감
    maxRaise -= alreadyBet;

    // 플레이어의 남은 칩과 비교하여 더 작은 값 선택
    maxRaise = maxRaise < chips ? maxRaise : chips;

    setState(() {
      _maxRaise = maxRaise;
    });
  }

  int getNextPlayerIndex(int currentIndex) {
    // 현재 플레이어의 포지션에 따라 다음 플레이어 결정
    Position currentPosition = players[currentIndex].position;
    Position nextPosition;
    
    switch (currentPosition) {
      case Position.underTheGun:
        nextPosition = Position.hijack;
        break;
      case Position.hijack:
        nextPosition = Position.cutoff;
        break;
      case Position.cutoff:
        nextPosition = Position.dealer;
        break;
      case Position.dealer:
        nextPosition = Position.smallBlind;
        break;
      case Position.smallBlind:
        nextPosition = Position.bigBlind;
        break;
      case Position.bigBlind:
        nextPosition = Position.underTheGun;
        break;
      default:
        nextPosition = Position.underTheGun;
    }
    
    // 다음 포지션을 가진 플레이어 찾기
    int nextIndex = players.indexWhere((p) => p.position == nextPosition);
    if (nextIndex == -1) {
      // 다음 포지션을 가진 플레이어가 없으면 첫 번째 플레이어로
      nextIndex = 0;
    }
    
    return nextIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pot Limit 계산'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          return SingleChildScrollView(
            child: SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF388E3C),
                          Color(0xFF1B5E20),
                          Color(0xFF43A047),
                        ],
                      ),
                    ),
                  ),
                  if (isGameStarted)
                    ...List.generate(numberOfPlayers, (index) {
                      if (index >= players.length) {
                        return Container();
                      }
                      final angle = (index * 60 - 90) * (3.14159 / 180);
                      final radius = screenWidth * 0.35;
                      final x = screenWidth / 2 + radius * cos(angle);
                      final y = screenHeight * 0.48 + radius * sin(angle);

                      return Positioned(
                        left: x - 80,
                        top: y - 80,
                        child: Container(
                          width: screenWidth < 500 ? 120 : 170,
                          height: screenWidth < 500 ? 140 : 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(
                              color: index == 0
                                  ? Colors.yellowAccent
                                  : index == 1
                                      ? Colors.redAccent
                                      : Colors.white.withOpacity(0.25),
                              width: index == 0 || index == 1 ? 2.5 : 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Player ${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth < 500 ? 14 : 20,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Montserrat',
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                players[index].positionName,
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: screenWidth < 500 ? 11 : 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'chips: ${chipsInitial[index]}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth < 500 ? 12 : 17,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'RobotoMono',
                                ),
                              ),
                              if (players[index].isAllIn)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'ALL-IN',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (playerActionHistory[index].isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                                          fontSize: screenWidth < 500 ? 10 : 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  if (isPotGuessing)
                    Positioned(
                      left: MediaQuery.of(context).size.width / 2 - 150,
                      top: MediaQuery.of(context).size.height / 2 - 30,
                      child: Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: potGuessController,
                          decoration: const InputDecoration(
                            hintText: 'POT! 금액을 입력하세요',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          onSubmitted: (value) {
                            checkPotGuess();
                          },
                        ),
                      ),
                    ),
                  if (!isGameStarted)
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.65,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 8,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          onPressed: startNewGame,
                          child: const Text('게임 시작'),
                        ),
                      ),
                    ),
                  if (resultMessage.isNotEmpty)
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.25,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          resultMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (showNextGameButton)
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.65,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 8,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          onPressed: startNewGame,
                          child: const Text('다음 게임 시작'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
