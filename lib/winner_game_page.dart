import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide Card;
import 'models/card.dart' as poker;
import 'models/hand_rank.dart';
import 'models/player.dart';
import 'models/score_system.dart';

class WinnerGamePage extends StatefulWidget {
  const WinnerGamePage({super.key});

  @override
  _WinnerGamePageState createState() => _WinnerGamePageState();
}

class ReplayRound {
  final List<List<String>> playerHands;
  final List<String> communityCards;
  final int? selectedWinnerIndex;
  final int? actualWinnerIndex;
  final String winnerText;
  final int numberOfPlayers;
  final int roundScore;

  ReplayRound({
    required this.playerHands,
    required this.communityCards,
    required this.selectedWinnerIndex,
    required this.actualWinnerIndex,
    required this.winnerText,
    required this.numberOfPlayers,
    required this.roundScore,
  });
}

class _WinnerGamePageState extends State<WinnerGamePage> {
  final List<String> deck = [
    'AS',
    '2S',
    '3S',
    '4S',
    '5S',
    '6S',
    '7S',
    '8S',
    '9S',
    '10S',
    'JS',
    'QS',
    'KS',
    'AH',
    '2H',
    '3H',
    '4H',
    '5H',
    '6H',
    '7H',
    '8H',
    '9H',
    '10H',
    'JH',
    'QH',
    'KH',
    'AD',
    '2D',
    '3D',
    '4D',
    '5D',
    '6D',
    '7D',
    '8D',
    '9D',
    '10D',
    'JD',
    'QD',
    'KD',
    'AC',
    '2C',
    '3C',
    '4C',
    '5C',
    '6C',
    '7C',
    '8C',
    '9C',
    '10C',
    'JC',
    'QC',
    'KC'
  ];

  List<Player> players = [];
  List<String> communityCards = [];
  bool isGameStarted = false;
  int remainingTime = 60;
  Timer? gameTimer;
  ScoreSystem scoreSystem = ScoreSystem();
  int? selectedWinnerIndex;
  int? actualWinnerIndex;
  int currentScore = 0;
  String winnerText = '';
  int numberOfPlayers = 3;
  String winnerHandInfo = '';
  List<String> roundLogs = [];
  List<ReplayRound> replayRounds = [];
  ReplayRound? replayingRound;

  @override
  void initState() {
    super.initState();
    initializePlayers();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    gameTimer = null;
    super.dispose();
  }

  void initializePlayers() {
    final random = Random();
    players = List.generate(
      6,
      (index) => Player(
        name: 'Player ${index + 1}',
        chips: (random.nextInt(4996) * 100) + 500,
        hand: [],
        position: Position.values[index % Position.values.length],
      ),
    );
  }

  void startNewGame() {
    setState(() {
      isGameStarted = true;
      remainingTime = 60;
      selectedWinnerIndex = null;
      actualWinnerIndex = null;
      currentScore = 0;
      winnerText = '';
      winnerHandInfo = '';

      final random = Random();
      deck.shuffle(random);

      communityCards = deck.sublist(0, 5);

      for (int i = 0; i < players.length; i++) {
        players[i].hand = deck.sublist(5 + i * 4, 5 + (i + 1) * 4);
      }

      gameTimer?.cancel();
      gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (remainingTime > 0) {
            remainingTime--;
          } else {
            timer.cancel();
            isGameStarted = false;
            if (currentScore > 0) {
              bool isNewHighScore = scoreSystem.addScore(numberOfPlayers, currentScore);
              if (isNewHighScore) {
                winnerText = '게임 종료! 최종 점수: $currentScore점\n🎉 축하합니다! 새로운 최고 점수를 달성했습니다! 🎉';
              } else {
                winnerText = '게임 종료! 최종 점수: $currentScore점\n(최고 점수: ${scoreSystem.getHighScore(numberOfPlayers)}점)';
              }
            } else {
              winnerText = '게임 종료! 최종 점수: $currentScore점';
            }
            // 타이머 정리
            gameTimer = null;
          }
        });
      });

      evaluateActualWinner();
    });
  }

  void dealNewRound() {
    setState(() {
      selectedWinnerIndex = null;
      actualWinnerIndex = null;
      winnerText = '';

      final random = Random();
      deck.shuffle(random);

      communityCards = deck.sublist(0, 5);

      for (int i = 0; i < numberOfPlayers; i++) {
        players[i].hand = deck.sublist(5 + i * 4, 5 + (i + 1) * 4);
      }

      evaluateActualWinner();
    });
  }

  void selectWinner(int index) {
    if (!isGameStarted || selectedWinnerIndex != null) return;

    setState(() {
      selectedWinnerIndex = index;
      scoreSystem.addAttempt(numberOfPlayers);

      if (selectedWinnerIndex == actualWinnerIndex) {
        currentScore++;
        winnerText = '정답입니다!\n현재 점수: $currentScore점\n승자의 패: $winnerHandInfo';
        roundLogs.add('라운드 ${roundLogs.length + 1}: Player ${index + 1} 선택 → 정답! (점수: $currentScore)');
        replayRounds.add(ReplayRound(
          playerHands: players.take(numberOfPlayers).map((p) => List<String>.from(p.hand)).toList(),
          communityCards: List<String>.from(communityCards),
          selectedWinnerIndex: index,
          actualWinnerIndex: actualWinnerIndex,
          winnerText: winnerText,
          numberOfPlayers: numberOfPlayers,
          roundScore: currentScore,
        ));
        Future.delayed(const Duration(seconds: 1), () {
          if (remainingTime > 0 && mounted) {
            dealNewRound();
          }
        });
      } else {
        winnerText = '틀렸습니다.\n정답은 Player ${actualWinnerIndex! + 1}입니다.\n승자의 패: $winnerHandInfo';
        roundLogs.add('라운드 ${roundLogs.length + 1}: Player ${index + 1} 선택 → 오답! (정답: Player ${actualWinnerIndex! + 1}, 점수: $currentScore)');
        replayRounds.add(ReplayRound(
          playerHands: players.take(numberOfPlayers).map((p) => List<String>.from(p.hand)).toList(),
          communityCards: List<String>.from(communityCards),
          selectedWinnerIndex: index,
          actualWinnerIndex: actualWinnerIndex,
          winnerText: winnerText,
          numberOfPlayers: numberOfPlayers,
          roundScore: currentScore,
        ));
        Future.delayed(const Duration(seconds: 1), () {
          if (remainingTime > 0 && mounted) {
            dealNewRound();
          }
        });
      }
    });
  }

  void evaluateActualWinner() {
    List<List<String>> playerHands =
        players.take(numberOfPlayers).map((p) => p.hand).toList();
    String bestHand = '';
    int highestRank = 0;
    int highestSecondaryRank = 0;
    actualWinnerIndex = -1;
    String winningHandDescription = '';

    for (int i = 0; i < playerHands.length; i++) {
      var hands = generatePLOCombinations(playerHands[i], communityCards);
      String currentBestHand = '';
      int currentRank = 0;
      int currentSecondaryRank = 0;
      List<poker.Card> bestHandCards = [];

      for (var hand in hands) {
        var cards = hand.map((card) => poker.Card.fromString(card)).toList();
        var handRankObj = HandRank.evaluate(cards);

        if (handRankObj.value > currentRank ||
            (handRankObj.value == currentRank &&
                handRankObj.secondaryValue > currentSecondaryRank)) {
          currentRank = handRankObj.value;
          currentSecondaryRank = handRankObj.secondaryValue;
          currentBestHand = handRankObj.name;
          bestHandCards = cards;
        }
      }

      if (currentRank > highestRank ||
          (currentRank == highestRank &&
              currentSecondaryRank > highestSecondaryRank)) {
        highestRank = currentRank;
        highestSecondaryRank = currentSecondaryRank;
        actualWinnerIndex = i;
        bestHand = currentBestHand;
        winningHandDescription = _getHandDescription(bestHandCards);
      }
    }

    winnerHandInfo = '$bestHand\n$winningHandDescription';
  }

  String _getHandDescription(List<poker.Card> cards) {
    cards.sort((a, b) => b.rank.index.compareTo(a.rank.index));
    List<String> cardStrs = cards.map((card) {
      String rankStr = _getRankString(card.rank);
      String suitStr = _getSuitString(card.suit);
      return '$rankStr$suitStr';
    }).toList();
    return cardStrs.join(' ');
  }

  String _getRankString(poker.Rank rank) {
    switch (rank) {
      case poker.Rank.ace:
        return 'A';
      case poker.Rank.king:
        return 'K';
      case poker.Rank.queen:
        return 'Q';
      case poker.Rank.jack:
        return 'J';
      case poker.Rank.ten:
        return '10';
      default:
        return (rank.index + 2).toString();
    }
  }

  String _getSuitString(poker.Suit suit) {
    switch (suit) {
      case poker.Suit.spades:
        return '♠';
      case poker.Suit.hearts:
        return '♥';
      case poker.Suit.diamonds:
        return '♦';
      case poker.Suit.clubs:
        return '♣';
    }
  }

  List<List<String>> generatePLOCombinations(
      List<String> holeCards, List<String> communityCards) {
    final holeComb = combinations(holeCards, 2);
    final communityComb = combinations(communityCards, 3);
    List<List<String>> allHands = [];

    for (var h in holeComb) {
      for (var c in communityComb) {
        var hand = [...h, ...c];
        hand.sort((a, b) {
          var rankA = poker.Card.fromString(a).rank.index;
          var rankB = poker.Card.fromString(b).rank.index;
          return rankA.compareTo(rankB);
        });
        allHands.add(hand);
      }
    }
    return allHands;
  }

  List<List<T>> combinations<T>(List<T> items, int r) {
    if (r == 0) return [[]];
    if (items.isEmpty) return [];

    List<List<T>> result = [];
    for (int i = 0; i <= items.length - r; i++) {
      var head = items[i];
      var tailCombos = combinations(items.sublist(i + 1), r - 1);
      for (var tailCombo in tailCombos) {
        result.add([head, ...tailCombo]);
      }
    }
    return result;
  }

  String convertCard(String card) {
    return card.replaceAll('10', '0');
  }

  Widget buildOverlappedCards(List<String> cards, double cardWidth, double cardHeight, double overlapRatio) {
    return SizedBox(
      width: cardWidth + (cards.length - 1) * cardWidth * overlapRatio,
      height: cardHeight,
      child: Stack(
        children: [
          for (int i = 0; i < cards.length; i++)
            Positioned(
              left: i * cardWidth * overlapRatio,
              child: buildCardImageWithSize(cards[i], cardWidth, cardHeight),
            ),
        ],
      ),
    );
  }

  Widget buildCardImageWithSize(String card, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Image.network(
        'https://deckofcardsapi.com/static/img/${convertCard(card)}.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 따라 카드 크기와 겹침 비율 동적 계산
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    // 그리드 설정
    int crossAxisCount = 2;
    double aspectRatio = isMobile ? 1.35 : 1.9;
    if (numberOfPlayers <= 4) {
      crossAxisCount = 2; // 2x2
      aspectRatio = isMobile ? 1.35 : 1.9;
    } else {
      crossAxisCount = 2; // 2x3
      aspectRatio = isMobile ? 1.35 : 1.75;
    }
    // 셀 가로폭 계산
    double horizontalPadding = 16 * 2; // GridView 좌우 패딩
    double crossAxisSpacing = 16.0;
    double cellWidth = (screenWidth - horizontalPadding - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
    // 카드 겹침 비율
    double overlapRatio = 0.5;
    int cardCount = 4;
    // 카드 크기 계산 (겹침 포함 최대)
    double cardWidth = cellWidth / (1 + (cardCount - 1) * overlapRatio);
    double cardHeight = cardWidth * 1.4;
    // 모바일에서 너무 크면 제한
    if (isMobile && cardWidth > 60) cardWidth = 60;
    if (isMobile && cardHeight > 84) cardHeight = 84;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Winner Guessing Game'),
        centerTitle: true,
        backgroundColor: const Color(0xFF388E3C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (isGameStarted || replayingRound != null) {
              setState(() {
                isGameStarted = false;
                replayingRound = null;
                selectedWinnerIndex = null;
                actualWinnerIndex = null;
                winnerText = '';
                winnerHandInfo = '';
                // 로그와 복기 데이터는 그대로 둠
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Stack(
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
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Number of Players: ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    DropdownButton<int>(
                      value: numberOfPlayers,
                      dropdownColor: const Color(0xFF2E7D32),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      items: [2, 3, 4, 5, 6].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value'),
                        );
                      }).toList(),
                      onChanged: !isGameStarted
                          ? (int? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  numberOfPlayers = newValue;
                                  initializePlayers();
                                });
                              }
                            }
                          : null,
                    ),
                  ],
                ),
                if (isGameStarted)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      'Time Left: $remainingTime s',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: remainingTime <= 10 ? Colors.redAccent : Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isGameStarted || replayingRound != null) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                    child: Text(
                      'Community Cards',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: (replayingRound != null
                        ? replayingRound!.communityCards
                        : communityCards)
                        .map((card) => buildOverlappedCards([card], cardWidth, cardHeight, overlapRatio)).toList(),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    fit: FlexFit.loose,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 4,
                      ),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: replayingRound?.numberOfPlayers ?? numberOfPlayers,
                      itemBuilder: (context, index) {
                        final isReplay = replayingRound != null;
                        final hands = isReplay
                            ? replayingRound!.playerHands
                            : players.map((p) => p.hand).toList();
                        final selIdx = isReplay
                            ? replayingRound!.selectedWinnerIndex
                            : selectedWinnerIndex;
                        final cardWidget = AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: selIdx == index
                                ? Colors.deepPurpleAccent.withOpacity(0.18)
                                : Colors.white.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: selIdx == index
                                  ? Colors.deepPurpleAccent
                                  : Colors.white.withOpacity(0.18),
                              width: selIdx == index ? 2.5 : 1.2,
                            ),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Player ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              const SizedBox(height: 2),
                              buildOverlappedCards(hands[index], cardWidth, cardHeight, overlapRatio),
                            ],
                          ),
                        );
                        if (!isReplay) {
                          return GestureDetector(
                            onTap: () => selectWinner(index),
                            child: cardWidget,
                          );
                        } else {
                          return cardWidget;
                        }
                      },
                    ),
                  ),
                  if (replayingRound != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 6,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          setState(() {
                            replayingRound = null;
                          });
                        },
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('복기 종료 (현재 라운드로 돌아가기)'),
                      ),
                    ),
                ],
                if (!isGameStarted && replayingRound == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
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
                      child: const Text('Start Game'),
                    ),
                  ),
                if (winnerText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        winnerText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: selectedWinnerIndex == actualWinnerIndex
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (roundLogs.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            '↓↓Review↓↓',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            reverse: true,
                            itemCount: roundLogs.length,
                            itemBuilder: (context, idx) {
                              final log = roundLogs[roundLogs.length - 1 - idx];
                              return InkWell(
                                onTap: () {
                                  if (replayRounds.length > (roundLogs.length - 1 - idx)) {
                                    setState(() {
                                      replayingRound = replayRounds[roundLogs.length - 1 - idx];
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                  child: Text(
                                    log,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, decoration: TextDecoration.underline),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: Text(
              'made by SNO',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
