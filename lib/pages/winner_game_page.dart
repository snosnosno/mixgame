import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide Card;
import '../models/card.dart' as poker;
import '../models/hand_rank.dart';
import '../models/player.dart';
import '../models/score_system.dart';
import '../home_page.dart'; // AppLanguage를 사용하기 위해 추가

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

  // getText 함수를 추가하여 AppLanguage 클래스를 사용
  String getText(String key) => AppLanguage.getText(key);

  // 오마하 보드 리딩 설명 다이얼로그를 표시하는 메서드
  void _showBoardReadingGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            getText('boardReadingGuide'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGuideSection(
                  AppLanguage.isKorean ? '딜러를 위한 PLO 핵심 규칙' : 'Key Rules for PLO Dealers',
                  AppLanguage.isKorean ? [
                    '• 각 플레이어는 반드시 4장의 홀 카드를 받습니다(홀덤의 2장과 다름).',
                    '• 커뮤니티 카드는 5장이며 모든 플레이어가 공유합니다.',
                    '• "정확히" 2장의 홀 카드와 "정확히" 3장의 커뮤니티 카드를 사용해야 합니다.',
                    '• 1장 또는 3장의 홀 카드 사용은 불가능합니다. 반드시 2장만 사용해야 합니다.',
                    '• 카드 평가 시 모든 가능한 조합을 확인하여 최고의 핸드를 찾아야 합니다.',
                  ] : [
                    '• Each player must receive exactly 4 hole cards (different from Hold\'em\'s 2 cards).',
                    '• There are 5 community cards shared by all players.',
                    '• Players MUST use EXACTLY 2 hole cards and EXACTLY 3 community cards.',
                    '• Using 1 or 3 hole cards is not allowed. Players must use exactly 2 hole cards.',
                    '• When evaluating hands, check all possible combinations to find the best hand.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildGuideSection(
                  AppLanguage.isKorean ? '핸드 판정 시 주의사항' : 'Important Notes for Hand Judging',
                  AppLanguage.isKorean ? [
                    '• 가능한 조합은 총 60가지입니다: 홀카드 2장 선택(6가지) × 커뮤니티카드 3장 선택(10가지)',
                    '• 플레이어가 "나는 이 2장만 쓸래요"라고 선언해도, 규칙상 최고의 핸드를 사용해야 합니다.',
                    '• 플레이어의 최적 핸드를 딜러가 찾아주어야 합니다(플레이어가 실수할 수 있음).',
                    '• 홀덤과 달리 플러시는 반드시 홀 카드 중 2장이 같은 무늬여야 가능합니다.',
                    '• 스트레이트도 홀 카드 중 2장이 반드시 사용되어야 합니다.',
                  ] : [
                    '• There are 60 possible combinations: choosing 2 from hole cards (6 ways) × choosing 3 from community cards (10 ways)',
                    '• Even if a player declares "I want to use just these 2 cards," the rules require using their best possible hand.',
                    '• Dealers must find the player\'s optimal hand (players may make mistakes).',
                    '• Unlike Hold\'em, a flush requires that 2 of the hole cards be of the same suit.',
                    '• Straights also require that 2 of the hole cards be used.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildGuideSection(
                  AppLanguage.isKorean ? '자주 헷갈리는 상황' : 'Common Confusing Situations',
                  AppLanguage.isKorean ? [
                    '• "플러시 보드": 커뮤니티에 같은 무늬 4장이 있어도, 홀 카드에 같은 무늬가 없다면 플러시 불가능',
                    '• "원페어 보드": 모든 플레이어가 해당 페어를 사용 가능하므로, 나머지 3장으로 승부 결정',
                    '• "쿼드 보드": 커뮤니티에 4장이 같은 숫자일 때, 모든 플레이어가 쿼드를 사용할 수 있음',
                    '• "로우 핸드": PLO Hi/Lo에서는 A-2-3-4-5가 최상의 로우 핸드입니다(PLO 하이에서는 무시)',
                    '• "이중 페어": 커뮤니티에 2쌍의 페어가 있을 때, 홀 카드의 더 높은 카드가 키커가 됨',
                  ] : [
                    '• "Flush board": Even with 4 cards of the same suit on the board, a flush is impossible without 2 matching suit cards in hand.',
                    '• "One pair board": Since all players can use this pair, the remaining 3 cards determine the winner.',
                    '• "Quads board": When 4 cards of the same rank are on the board, all players can use the quads.',
                    '• "Low hand": In PLO Hi/Lo, A-2-3-4-5 is the best low hand (ignored in PLO High).',
                    '• "Double paired board": When there are 2 pairs on the board, the higher card from hole cards becomes the kicker.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildGuideSection(
                  AppLanguage.isKorean ? '핸드 리딩 기술' : 'Hand Reading Skills',
                  AppLanguage.isKorean ? [
                    '• 보드의 텍스처(무늬 분포, 연결성, 페어 등)를 먼저 확인하세요.',
                    '• 가능한 너트(최강) 핸드가 무엇인지 항상 파악하세요.',
                    '• 각 플레이어의 베팅 패턴을 통해 핸드 범위를 좁혀나가세요.',
                    '• AAxx 형태의 포켓 에이스 페어는 홀덤보다 약하다는 점을 기억하세요.',
                    '• 더블 페어드 보드에서는 투 페어가 약하므로 풀하우스 가능성을 항상 체크하세요.',
                  ] : [
                    '• First check the board texture (suit distribution, connectivity, pairs, etc.).',
                    '• Always identify what the nuts (best possible hand) could be.',
                    '• Narrow down hand ranges through players\' betting patterns.',
                    '• Remember that AAxx pocket aces are weaker in Omaha than in Hold\'em.',
                    '• On double-paired boards, two pair is weak, so always check for full house possibilities.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildGuideSection(
                  AppLanguage.isKorean ? '이 앱의 게임 진행 방법' : 'How to Play This App',
                  AppLanguage.isKorean ? [
                    '• 보드 리딩 게임: 커뮤니티 카드와 각 플레이어의 홀 카드가 주어지면 승자를 맞추는 훈련',
                    '• 정답 선택: 가장 강한 핸드를 가진 플레이어를 선택하세요',
                    '• 60초 제한: 빠른 판단력을 기르기 위해 시간 제한이 있습니다',
                    '• 점수 획득: 정확한 판단 시 1점 획득, 최고 점수 기록 확인 가능',
                    '• 리뷰 기능: 잘못된 판단에 대해 정답과 함께 리뷰 가능',
                    '• 팟 리밋 게임: 팟 리밋 오마하에서의 베팅 계산을 연습하는 모드도 있습니다',
                  ] : [
                    '• Board Reading Game: Practice identifying winners given community cards and each player\'s hole cards.',
                    '• Selecting Answers: Choose the player with the strongest hand.',
                    '• 60-Second Limit: There\'s a time limit to develop quick decision-making skills.',
                    '• Scoring: Earn 1 point for each correct judgment, track your high score.',
                    '• Review Feature: Review incorrect judgments with the correct answer.',
                    '• Pot Limit Game: There\'s also a mode to practice betting calculations in Pot Limit Omaha.',
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Text(
                    AppLanguage.isKorean
                        ? '이 앱은 실제 오마하 포커 딜러와 플레이어를 위한 훈련 도구입니다. 빠른 핸드 판정과 정확한 팟 계산 능력을 향상시켜 실전에서의 딜링 스킬을 높이는 데 도움이 됩니다.'
                        : 'This app is a training tool for real Omaha poker dealers and players. It helps improve quick hand evaluation and accurate pot calculation skills to enhance your dealing abilities in real games.',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  // 가이드 섹션 위젯 빌더
  Widget _buildGuideSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withAlpha((0.5 * 255).round())),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: points.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(point),
            )).toList(),
          ),
        ),
      ],
    );
  }

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
                winnerText = '${getText("gameOver")}! ${getText("finalScore")}: $currentScore\n🎉 ${getText("congratulations")}! ${getText("newHighScore")}! 🎉';
              } else {
                winnerText = '${getText("gameOver")}! ${getText("finalScore")}: $currentScore\n(${getText("highScore")}: ${scoreSystem.getHighScore(numberOfPlayers)})';
              }
            } else {
              winnerText = '${getText("gameOver")}! ${getText("finalScore")}: $currentScore';
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
        winnerText = '${getText("correctAnswer")}$currentScore\n${getText("winningHand")}: $winnerHandInfo';
        roundLogs.add('${getText("round")} ${roundLogs.length + 1}: Player ${index + 1} ${getText("selected")} → ${getText("correct")}! (${getText("score")}: $currentScore)');
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
        winnerText = '${getText("wrongAnswer")}${getText("correctAnswerIs")} Player ${actualWinnerIndex! + 1}.\n${getText("winningHand")}: $winnerHandInfo';
        roundLogs.add('${getText("round")} ${roundLogs.length + 1}: Player ${index + 1} ${getText("selected")} → ${getText("wrong")}! (${getText("correct")}: Player ${actualWinnerIndex! + 1}, ${getText("score")}: $currentScore)');
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
        title: Text(getText('boardReading')),
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
                    if (!isGameStarted) ...[
                      Text('${getText("playerCount")} '),
                DropdownButton<int>(
                  value: numberOfPlayers,
                  items: [2, 3, 4, 5, 6].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value'),
                    );
                  }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              numberOfPlayers = newValue;
                              initializePlayers();
                            });
                          }
                        },
                ),
                    ],
              ],
            ),
            if (isGameStarted)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Text(
                     '${getText("remainingTime")} $remainingTime ${getText("seconds")}',
                  style: TextStyle(
                        fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: remainingTime <= 10 ? Colors.redAccent : Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withAlpha((0.3 * 255).round()),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            if (isGameStarted || replayingRound != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Text(
                     getText('communityCards'),
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
                            ? Colors.deepPurpleAccent.withAlpha(((0.18) * 255).round())
                            : Colors.white.withAlpha(((0.13) * 255).round()),
                            borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.18 * 255).round()),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: selIdx == index
                              ? Colors.deepPurpleAccent.withAlpha(((0.18) * 255).round())
                              : Colors.white.withAlpha(((0.18) * 255).round()),
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
                    label: Text(getText('endReplay')),
                  ),
                ),
            ],
            if (!isGameStarted && replayingRound == null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
                child: Column(
                  children: [
                    // 보드 리딩 설명 버튼
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 6,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _showBoardReadingGuide(context),
                      icon: const Icon(Icons.info_outline),
                      label: Text(getText('boardReadingHelp')),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 게임 시작 버튼
                    ElevatedButton(
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
                      child: Text(getText('startGame')),
                    ),
                  ],
                ),
              ),
            if (winnerText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0.7 * 255).round()),
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
              ],
                ),
              ),
            if (roundLogs.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.5 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                         '↓↓${getText("review")}↓↓',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                    Expanded(
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
                  ],
                      ),
                    ),
                  ),
          Positioned(
            right: 16,
            bottom: roundLogs.isNotEmpty ? 140 : 12,
            child: Text(
              'made by SNO',
              style: TextStyle(
                color: Colors.white.withAlpha((0.7 * 255).round()),
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
