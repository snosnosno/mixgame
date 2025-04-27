import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'home_page.dart';
import 'models/card.dart';
import 'models/hand_rank.dart';
import 'models/player.dart';
import 'models/score_system.dart';

enum Suit { spades, hearts, diamonds, clubs }

enum Position { dealer, smallBlind, bigBlind, underTheGun, hijack, cutoff }

enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace
}

class Card {
  final Rank rank;
  final Suit suit;

  Card(this.rank, this.suit);

  static Card fromString(String cardStr) {
    if (cardStr.length < 2) {
      throw Exception('Invalid card string length');
    }

    final rankStr = cardStr.substring(0, cardStr.length - 1);
    final suitStr = cardStr.substring(cardStr.length - 1);

    Rank rank;
    try {
      switch (rankStr) {
        case 'A':
          rank = Rank.ace;
          break;
        case 'K':
          rank = Rank.king;
          break;
        case 'Q':
          rank = Rank.queen;
          break;
        case 'J':
          rank = Rank.jack;
          break;
        case '10':
          rank = Rank.ten;
          break;
        default:
          final rankValue = int.parse(rankStr);
          if (rankValue < 2 || rankValue > 9) {
            throw Exception('Invalid rank value');
          }
          rank = Rank.values[rankValue - 2];
      }
    } catch (e) {
      throw Exception('Invalid rank format');
    }

    Suit suit;
    switch (suitStr) {
      case 'S':
        suit = Suit.spades;
        break;
      case 'H':
        suit = Suit.hearts;
        break;
      case 'D':
        suit = Suit.diamonds;
        break;
      case 'C':
        suit = Suit.clubs;
        break;
      default:
        throw Exception('Invalid suit');
    }

    return Card(rank, suit);
  }
}

class HandRank {
  final int value;
  final String name;
  final List<Card> cards;
  final int secondaryValue; // 같은 핸드 타입일 때 비교할 값

  HandRank(this.value, this.name, this.cards, this.secondaryValue);

  static HandRank evaluate(List<Card> cards) {
    if (cards.length != 5) throw Exception('Hand must contain exactly 5 cards');

    // 로열 스트레이트 플러시
    if (_isRoyalStraightFlush(cards)) {
      return HandRank(10, 'Royal Straight Flush', cards, 0);
    }

    // 스트레이트 플러시
    if (_isStraightFlush(cards)) {
      return HandRank(9, 'Straight Flush', cards, _getHighestRank(cards));
    }

    // 포카드
    if (_isFourOfAKind(cards)) {
      return HandRank(8, 'Four of a Kind', cards, _getFourOfAKindRank(cards));
    }

    // 풀하우스
    if (_isFullHouse(cards)) {
      return HandRank(7, 'Full House', cards, _getFullHouseRank(cards));
    }

    // 플러시
    if (_isFlush(cards)) {
      return HandRank(6, 'Flush', cards, _getHighestRank(cards));
    }

    // 스트레이트
    if (_isStraight(cards)) {
      return HandRank(5, 'Straight', cards, _getHighestRank(cards));
    }

    // 트리플
    if (_isThreeOfAKind(cards)) {
      return HandRank(4, 'Three of a Kind', cards, _getThreeOfAKindRank(cards));
    }

    // 투페어
    if (_isTwoPair(cards)) {
      return HandRank(3, 'Two Pair', cards, _getTwoPairRank(cards));
    }

    // 원페어
    if (_isOnePair(cards)) {
      return HandRank(2, 'One Pair', cards, _getOnePairRank(cards));
    }

    // 하이카드
    return HandRank(1, 'High Card', cards, _getHighestRank(cards));
  }

  static int _getHighestRank(List<Card> cards) {
    return cards.map((c) => c.rank.index).reduce(max);
  }

  static int _getOnePairRank(List<Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in Rank.values.reversed) {
      // ace부터 시작
      if (ranks.where((r) => r == rank).length == 2) {
        return rank.index;
      }
    }
    return 0;
  }

  static int _getTwoPairRank(List<Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    List<int> pairRanks = [];
    
    // 모든 페어 찾기
    for (var rank in Rank.values.reversed) {
      if (ranks.where((r) => r == rank).length == 2) {
        pairRanks.add(rank.index);
      }
    }
    
    // 두 개의 페어가 있는 경우
    if (pairRanks.length >= 2) {
      // 가장 높은 페어의 랭크를 반환
      return pairRanks[0];
    }
    
    return 0;
  }

  static int _getThreeOfAKindRank(List<Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in Rank.values.reversed) {
      if (ranks.where((r) => r == rank).length == 3) {
        return rank.index;
      }
    }
    return 0;
  }

  static int _getFourOfAKindRank(List<Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in Rank.values.reversed) {
      if (ranks.where((r) => r == rank).length == 4) {
        return rank.index;
      }
    }
    return 0;
  }

  static int _getFullHouseRank(List<Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in Rank.values.reversed) {
      if (ranks.where((r) => r == rank).length == 3) {
        return rank.index;
      }
    }
    return 0;
  }

  static bool _isRoyalStraightFlush(List<Card> cards) {
    return _isStraightFlush(cards) &&
        cards.any((card) => card.rank == Rank.ace);
  }

  static bool _isStraightFlush(List<Card> cards) {
    return _isFlush(cards) && _isStraight(cards);
  }

  static bool _isFourOfAKind(List<Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in Rank.values) {
      if (ranks.where((r) => r == rank).length == 4) return true;
    }
    return false;
  }

  static bool _isFullHouse(List<Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    bool hasThree = false;
    bool hasPair = false;
    for (var rank in Rank.values) {
      var count = ranks.where((r) => r == rank).length;
      if (count == 3) hasThree = true;
      if (count == 2) hasPair = true;
    }
    return hasThree && hasPair;
  }

  static bool _isFlush(List<Card> cards) {
    var suit = cards[0].suit;
    return cards.every((card) => card.suit == suit);
  }

  static bool _isStraight(List<Card> cards) {
    // 카드를 랭크 순으로 정렬
    var sortedCards = List<Card>.from(cards)
      ..sort((a, b) => a.rank.index.compareTo(b.rank.index));
    var ranks = sortedCards.map((c) => c.rank.index).toList();

    // 일반적인 스트레이트 체크
    bool isNormalStraight = true;
    for (int i = 1; i < ranks.length; i++) {
      if (ranks[i] != ranks[i - 1] + 1) {
        isNormalStraight = false;
        break;
      }
    }

    // A-2-3-4-5 스트레이트 체크
    bool isWheelStraight = false;
    if (ranks.contains(Rank.ace.index) &&
        ranks.contains(Rank.two.index) &&
        ranks.contains(Rank.three.index) &&
        ranks.contains(Rank.four.index) &&
        ranks.contains(Rank.five.index)) {
      isWheelStraight = true;
    }

    return isNormalStraight || isWheelStraight;
  }

  static bool _isThreeOfAKind(List<Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in Rank.values) {
      if (ranks.where((r) => r == rank).length == 3) return true;
    }
    return false;
  }

  static bool _isTwoPair(List<Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    int pairs = 0;
    for (var rank in Rank.values) {
      if (ranks.where((r) => r == rank).length == 2) pairs++;
    }
    return pairs == 2;
  }

  static bool _isOnePair(List<Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in Rank.values) {
      if (ranks.where((r) => r == rank).length == 2) return true;
    }
    return false;
  }
}

class Player {
  String name;
  int chips;
  List<String> hand;
  bool isFolded;
  bool isAllIn;
  int bet;
  Position position;

  Player({
    required this.name,
    required this.chips,
    required this.hand,
    required this.position,
    this.isFolded = false,
    this.isAllIn = false,
    this.bet = 0,
  });
}

class Pot {
  int total = 0;
  Map<Player, int> allInAmounts = {};

  void addBet(Player player, int amount) {
    total += amount;
    if (player.isAllIn) {
      allInAmounts[player] = amount;
    }
  }
}

class BettingRound {
  final List<Player> players;
  final Pot pot;
  int currentPlayerIndex = 0;
  int currentBet = 0;
  bool isRoundComplete = false;

  BettingRound({
    required this.players,
    required this.pot,
  });

  Player get currentPlayer => players[currentPlayerIndex];

  void nextPlayer() {
    do {
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    } while (players[currentPlayerIndex].isFolded ||
        players[currentPlayerIndex].isAllIn);
  }

  bool canCheck() {
    return currentBet == 0 || currentPlayer.bet == currentBet;
  }

  int getCallAmount() {
    return currentBet - currentPlayer.bet;
  }

  int calculatePotLimit() {
    // 현재 스트릿에서 플레이어가 이미 배팅한 금액
    int alreadyBet = currentPlayer.bet;

    // 3배 룰: (마지막 베팅 x 3) + 이전 팟
    int lastBet = currentBet;
    int previousPot = pot.total - currentBet;
    int maxRaise = (lastBet * 3) + previousPot;

    // 현재 스트릿에서 이미 배팅한 금액 차감
    maxRaise -= alreadyBet;

    // 플레이어의 남은 칩과 비교하여 더 작은 값 반환
    return min(maxRaise, currentPlayer.chips);
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
        // 팟 리밋 체크
        int maxRaise = calculatePotLimit();
        int raiseAmount = min(amount - currentPlayer.bet, maxRaise);

        if (raiseAmount > currentPlayer.chips) {
          allIn();
        } else {
          currentPlayer.chips -= raiseAmount;
          currentPlayer.bet += raiseAmount;
          currentBet = currentPlayer.bet;
          pot.addBet(currentPlayer, raiseAmount);
          nextPlayer();
        }
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

class ScoreSystem {
  Map<int, int> scores = {
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 0,
  };

  Map<int, int> highScores = {
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 0,
  };

  // 총 시도 횟수를 저장
  Map<int, int> attempts = {
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 0,
  };

  bool addScore(int playerCount, int score) {
    if (scores.containsKey(playerCount)) {
      scores[playerCount] = scores[playerCount]! + 1;

      // 최고 점수 갱신 확인
      if (score > (highScores[playerCount] ?? 0)) {
        highScores[playerCount] = score;
        return true;
      }
    }
    return false;
  }

  void addAttempt(int playerCount) {
    if (attempts.containsKey(playerCount)) {
      attempts[playerCount] = attempts[playerCount]! + 1;
    }
  }

  int getScore(int playerCount) {
    return scores[playerCount] ?? 0;
  }

  int getHighScore(int playerCount) {
    return highScores[playerCount] ?? 0;
  }

  double getAccuracy(int playerCount) {
    int totalAttempts = attempts[playerCount] ?? 0;
    if (totalAttempts == 0) return 0.0;
    int correctAnswers = getScore(playerCount);
    return (correctAnswers / totalAttempts) * 100;
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '포커 게임',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

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
        // 500부터 500,000까지 100단위로 랜덤 스택 설정
        chips: (random.nextInt(4996) * 100) + 500,
        hand: [],
        position: Position.values[index % Position.values.length],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('승자 맞추기 게임'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            gameTimer?.cancel();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // 점수 표시
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // 현재 게임 점수
                if (isGameStarted)
                  Text(
                    '현재 점수: $currentScore점',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                const SizedBox(height: 8),
                // 전체 게임 기록
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [2, 3, 4, 5, 6].map((count) {
                    double accuracy = scoreSystem.getAccuracy(count);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          Text(
                            '$count인: ${scoreSystem.getScore(count)}회',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            '최고: ${scoreSystem.getHighScore(count)}점',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '정답률: ${accuracy.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          // 플레이어 수 선택
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
          // 타이머
          if (isGameStarted)
            Text(
              '남은 시간: $remainingTime초',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: remainingTime <= 10 ? Colors.red : Colors.black,
              ),
            ),
          // 게임 시작 버튼
          if (!isGameStarted)
            ElevatedButton(
              onPressed: startNewGame,
              child: const Text('게임 시작'),
            ),
          // 커뮤니티 카드
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
          // 플레이어 핸드
          if (isGameStarted)
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
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
          // 결과 텍스트
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

      // 커뮤니티 카드 5장 배분
      communityCards = deck.sublist(0, 5);

      // 각 플레이어에게 4장씩 카드 배분
      for (int i = 0; i < players.length; i++) {
        players[i].hand = deck.sublist(5 + i * 4, 5 + (i + 1) * 4);
      }

      // 타이머 시작
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

      // 실제 승자 계산
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

      // 커뮤니티 카드 5장 배분
      communityCards = deck.sublist(0, 5);

      // 각 플레이어에게 4장씩 카드 배분
      for (int i = 0; i < players.length; i++) {
        players[i].hand = deck.sublist(5 + i * 4, 5 + (i + 1) * 4);
      }

      // 실제 승자 계산
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

  String winnerHandInfo = '';

  void evaluateActualWinner() {
    List<List<String>> playerHands = players.map((p) => p.hand).toList();
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
      List<Card> bestHandCards = [];

      for (var hand in hands) {
        var cards = hand.map((card) => Card.fromString(card)).toList();
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

  String _getHandDescription(List<Card> cards) {
    cards.sort((a, b) => b.rank.index.compareTo(a.rank.index));
    List<String> cardStrs = cards.map((card) {
      String rankStr = _getRankString(card.rank);
      String suitStr = _getSuitSymbol(card.suit);
      return '$rankStr$suitStr';
    }).toList();
    return cardStrs.join(' ');
  }

  String _getRankString(Rank rank) {
    switch (rank) {
      case Rank.ace:
        return 'A';
      case Rank.king:
        return 'K';
      case Rank.queen:
        return 'Q';
      case Rank.jack:
        return 'J';
      case Rank.ten:
        return '10';
      default:
        return (rank.index + 2).toString();
    }
  }

  String _getSuitSymbol(Suit suit) {
    switch (suit) {
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
    }
  }

  List<List<String>> generatePLOCombinations(
      List<String> holeCards, List<String> communityCards) {
    // PLO 규칙: 반드시 홀카드 2장과 커뮤니티카드 3장을 사용해야 함
    final holeComb = combinations(holeCards, 2); // 홀카드 중 2장 선택
    final communityComb = combinations(communityCards, 3); // 커뮤니티 카드 중 3장 선택
    List<List<String>> allHands = [];

    // 모든 가능한 조합 생성
    for (var h in holeComb) {
      for (var c in communityComb) {
        var hand = [...h, ...c];
        // 정렬하여 스트레이트 체크를 쉽게 함
        hand.sort((a, b) {
          var rankA = Card.fromString(a).rank.index;
          var rankB = Card.fromString(b).rank.index;
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
}

class PokerTablePage extends StatefulWidget {
  const PokerTablePage({super.key});

  @override
  _PokerTablePageState createState() => _PokerTablePageState();
}

class _PokerTablePageState extends State<PokerTablePage> {
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
        position: Position.values[index % Position.values.length],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            gameTimer?.cancel();
            Navigator.pop(context);
          },
        ),
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
          ...List.generate(numberOfPlayers, (index) {
            if (index >= players.length) {
              return Container();
            }
            final angle = (index * 60 - 90) * (3.14159 / 180);
            final radius = MediaQuery.of(context).size.width * 0.35;
            final x =
                MediaQuery.of(context).size.width / 2 + radius * cos(angle);
            final y =
                MediaQuery.of(context).size.height / 2 + radius * sin(angle);

            return Positioned(
              left: x - 80,
              top: y - 80,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: index == 0
                        ? Colors.yellow
                        : index == 1
                            ? Colors.red
                            : Colors.white.withOpacity(0.3),
                    width: index == 0 || index == 1 ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Player ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (index == 0)
                      Text(
                        'SB: $smallBlind',
                        style: const TextStyle(color: Colors.yellow),
                      ),
                    if (index == 1)
                      Text(
                        'BB: $bigBlind',
                        style: const TextStyle(color: Colors.red),
                      ),
                    Text(
                      '${players[index].chips}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
              left: MediaQuery.of(context).size.width / 2 - 150,
              top: MediaQuery.of(context).size.height / 2 - 100,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resultMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (isGameStarted)
            Positioned(
              top: 60,
              right: 20,
              child: Text(
                '현재 점수: $currentScore점',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
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
        ],
      ),
    );
  }
}

