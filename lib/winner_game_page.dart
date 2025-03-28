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

  @override
  void initState() {
    super.initState();
    initializePlayers();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
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
              bool isNewHighScore =
                  scoreSystem.addScore(numberOfPlayers, currentScore);
              if (isNewHighScore) {
                winnerText =
                    '게임 종료! 최종 점수: $currentScore점\n🎉 축하합니다! 새로운 최고 점수를 달성했습니다! 🎉';
              } else {
                winnerText =
                    '게임 종료! 최종 점수: $currentScore점\n(최고 점수: ${scoreSystem.getHighScore(numberOfPlayers)}점)';
              }
            } else {
              winnerText = '게임 종료! 최종 점수: $currentScore점';
            }
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
        Future.delayed(const Duration(seconds: 1), () {
          if (remainingTime > 0) {
            dealNewRound();
          }
        });
      } else {
        winnerText =
            '틀렸습니다.\n정답은 Player ${actualWinnerIndex! + 1}입니다.\n승자의 패: $winnerHandInfo';
        Future.delayed(const Duration(seconds: 1), () {
          if (remainingTime > 0) {
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
      String suitStr = _getSuitSymbol(card.suit);
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

  String _getSuitSymbol(poker.Suit suit) {
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

  Widget buildCardImage(String card) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Image.network(
        'https://deckofcardsapi.com/static/img/${convertCard(card)}.png',
        width: 50,
        height: 70,
        fit: BoxFit.contain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('승자 맞추기 게임'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('플레이어 수: '),
              DropdownButton<int>(
                value: numberOfPlayers,
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
            Text(
              '남은 시간: $remainingTime초',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: remainingTime <= 10 ? Colors.red : Colors.black,
              ),
            ),
          if (!isGameStarted)
            ElevatedButton(
              onPressed: startNewGame,
              child: const Text('게임 시작'),
            ),
          if (isGameStarted) ...[
            const Text(
              '커뮤니티 카드',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  communityCards.map((card) => buildCardImage(card)).toList(),
            ),
          ],
          if (isGameStarted)
            Expanded(
              child: ListView.builder(
                itemCount: numberOfPlayers,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => selectWinner(index),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedWinnerIndex == index
                              ? Colors.blue
                              : Colors.grey,
                          width: selectedWinnerIndex == index ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Player ${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: players[index]
                                .hand
                                .map((card) => buildCardImage(card))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (winnerText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                winnerText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: selectedWinnerIndex == actualWinnerIndex
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
