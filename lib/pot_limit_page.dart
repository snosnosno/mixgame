import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'models/player.dart';

class PotLimitPage extends StatefulWidget {
  const PotLimitPage({super.key});

  @override
  _PotLimitPageState createState() => _PotLimitPageState();
}

class _PotLimitPageState extends State<PotLimitPage> {
  int smallBlind = 100;
  int bigBlind = 200;
  bool isGameStarted = false;
  int remainingTime = 60;
  Timer? gameTimer;
  int currentScore = 0;
  int lastRaiseAmount = 0;
  int currentBet = 0;

  List<Player> players = [];
  int potAmount = 0;
  TextEditingController potGuessController = TextEditingController();
  List<String?> playerActions = [];
  bool isPotGuessing = false;
  String resultMessage = '';

  int numberOfPlayers = 6;

  void initializePlayers() {
    final random = Random();
    // SB와 BB 설정
    smallBlind = (random.nextInt(5) + 1) * 100; // 100~500
    bigBlind = smallBlind * 2;

    players = List.generate(
      numberOfPlayers,
      (index) => Player(
        name: 'Player ${index + 1}',
        chips: (random.nextInt(599) * 500) + 500, // 500~300,000
        hand: [],
      ),
    );
    playerActions = List.filled(numberOfPlayers, null);
    currentBet = 0;
    lastRaiseAmount = 0;
    potAmount = 0;
  }

  void performPlayerAction(int playerIndex) {
    if (isPotGuessing) return;

    // 폴드한 플레이어는 건너뛰기
    if (players[playerIndex].isFolded) {
      return;
    }

    final random = Random();
    int action = random.nextInt(100);

    if (action < 50) {
      // 50% 확률로 "레이즈"
      int raiseAmount;
      if (lastRaiseAmount == 0) {
        // 첫 레이즈는 BB의 2배
        raiseAmount = bigBlind * 2;
      } else {
        // 이후 레이즈는 이전 레이즈의 2배
        raiseAmount = lastRaiseAmount * 2;
      }

      // 100단위로 반올림
      raiseAmount = (raiseAmount ~/ 100) * 100;

      // 플레이어의 남은 칩이 레이즈 금액보다 작으면 올인
      if (raiseAmount > players[playerIndex].chips) {
        raiseAmount = players[playerIndex].chips;
        playerActions[playerIndex] = '올인: $raiseAmount';
      } else {
        playerActions[playerIndex] = '레이즈: $raiseAmount';
      }

      players[playerIndex].chips -= raiseAmount;
      potAmount += raiseAmount;
      currentBet = raiseAmount;
      lastRaiseAmount = raiseAmount;
    } else if (action < 70) {
      // 20% 확률로 "폴드"
      players[playerIndex].isFolded = true;
      playerActions[playerIndex] = 'FOLD';
    } else {
      // 30% 확률로 "POT!"
      int potGuessAmount = random.nextInt(300001) + 500;
      potAmount += potGuessAmount;
      playerActions[playerIndex] = 'POT!';
      isPotGuessing = true;
      resultMessage = '';
    }

    setState(() {});
  }

  // 다음 플레이어 인덱스를 반환하는 함수
  int getNextPlayerIndex(int currentIndex) {
    int nextIndex = (currentIndex + 1) % players.length;
    // 폴드한 플레이어는 건너뛰기
    while (players[nextIndex].isFolded && nextIndex != currentIndex) {
      nextIndex = (nextIndex + 1) % players.length;
    }
    return nextIndex;
  }

  void startNewGame() {
    setState(() {
      isGameStarted = true;
      remainingTime = 60;
      initializePlayers();
      isPotGuessing = false;
      resultMessage = '';

      gameTimer?.cancel();
      gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (remainingTime > 0) {
            remainingTime--;
            if (players.length > 2) {
              int currentPlayerIndex =
                  (2 + (60 - remainingTime) ~/ 1) % players.length;
              // 폴드한 플레이어는 건너뛰기
              if (!players[currentPlayerIndex].isFolded) {
                performPlayerAction(currentPlayerIndex);
              }
            }
          } else {
            timer.cancel();
            isGameStarted = false;
          }
        });
      });
    });
  }

  void checkPotGuess() {
    int userGuess = int.tryParse(potGuessController.text) ?? 0;
    setState(() {
      if (userGuess == potAmount) {
        currentScore++;
        resultMessage = '정답입니다! +1점\n현재 점수: $currentScore점';
      } else {
        resultMessage = '틀렸습니다!\n정답은: $potAmount';
      }
    });

    // 결과 메시지를 표시하고 1초 후에 게임 재개
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        potGuessController.clear();
        isPotGuessing = false;
        resultMessage = '';
        // 게임 상태 초기화
        potAmount = 0;
        lastRaiseAmount = 0;
        playerActions = List.filled(numberOfPlayers, null);
        initializePlayers();

        // 게임 타이머 재설정 (플레이어 3부터 시작)
        int startTime = remainingTime;
        gameTimer?.cancel();
        gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (remainingTime > 0) {
              remainingTime--;
              if (players.length > 2) {
                int currentPlayerIndex = 2; // 항상 플레이어 3부터 시작
                int elapsedTime = startTime - remainingTime;
                currentPlayerIndex = (2 + elapsedTime) % players.length;
                // 폴드한 플레이어는 건너뛰기
                if (!players[currentPlayerIndex].isFolded) {
                  performPlayerAction(currentPlayerIndex);
                }
              }
            } else {
              timer.cancel();
              isGameStarted = false;
            }
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pot Limit 계산'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2E7D32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          if (isGameStarted)
            Positioned(
              top: 20,
              left: 20,
              child: Text(
                '남은 시간: $remainingTime초',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          if (isGameStarted)
            ...List.generate(players.length, (index) {
              final angle = (2 * pi * index / players.length) - (pi / 2);
              final radius = MediaQuery.of(context).size.width * 0.4;
              final x =
                  MediaQuery.of(context).size.width / 2 + radius * cos(angle);
              final y =
                  MediaQuery.of(context).size.height / 2 + radius * sin(angle);

              return Positioned(
                left: x - 50,
                top: y - 50,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Player ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${players[index].chips}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    if (index == 0)
                      Text(
                        'SB: $smallBlind',
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 14,
                        ),
                      ),
                    if (index == 1)
                      Text(
                        'BB: $bigBlind',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    if (playerActions[index] != null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          playerActions[index]!,
                          style: TextStyle(
                            color: playerActions[index]!.contains('FOLD')
                                ? Colors.red
                                : playerActions[index]!.contains('POT!')
                                    ? Colors.yellow
                                    : Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
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
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: startNewGame,
                  child: const Text('게임 시작'),
                ),
              ),
            ),
          if (resultMessage.isNotEmpty)
            Positioned(
              bottom: 20,
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
        ],
      ),
    );
  }
}
