import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide Card;
import '../models/card.dart' as poker;
import '../models/hand_rank.dart';
import '../models/low_hand_rank.dart';
import '../models/player.dart';
import '../models/score_system.dart';
import '../home_page.dart'; // AppLanguage를 사용하기 위해 추가

class HiLowGamePage extends StatefulWidget {
  const HiLowGamePage({super.key});

  @override
  _HiLowGamePageState createState() => _HiLowGamePageState();
}

class ReplayRound {
  final List<List<String>> playerHands;
  final List<String> communityCards;
  final int? selectedHighWinnerIndex;
  final int? actualHighWinnerIndex;
  final List<int> selectedLowWinnerIndices;
  final List<int> actualLowWinnerIndices;
  final String winnerText;
  final int numberOfPlayers;
  final int roundScore;

  ReplayRound({
    required this.playerHands,
    required this.communityCards,
    required this.selectedHighWinnerIndex,
    required this.actualHighWinnerIndex,
    required this.selectedLowWinnerIndices,
    required this.actualLowWinnerIndices,
    required this.winnerText,
    required this.numberOfPlayers,
    required this.roundScore,
  });
}

class _HiLowGamePageState extends State<HiLowGamePage> {
  final List<String> deck = [
    'AS', '2S', '3S', '4S', '5S', '6S', '7S', '8S', '9S', '10S', 'JS', 'QS', 'KS',
    'AH', '2H', '3H', '4H', '5H', '6H', '7H', '8H', '9H', '10H', 'JH', 'QH', 'KH',
    'AD', '2D', '3D', '4D', '5D', '6D', '7D', '8D', '9D', '10D', 'JD', 'QD', 'KD',
    'AC', '2C', '3C', '4C', '5C', '6C', '7C', '8C', '9C', '10C', 'JC', 'QC', 'KC'
  ];

  List<Player> players = [];
  List<String> communityCards = [];
  bool isGameStarted = false;
  int remainingTime = 60;
  Timer? gameTimer;
  ScoreSystem scoreSystem = ScoreSystem();
  int? selectedHighWinnerIndex;
  int? actualHighWinnerIndex;
  List<int> selectedLowWinnerIndices = [];
  List<int> actualLowWinnerIndices = [];
  int currentScore = 0;
  String winnerText = '';
  int numberOfPlayers = 3;
  String highHandInfo = '';
  String lowHandInfo = '';
  bool isLowHand = false; // 로우 핸드 존재 여부
  List<String> roundLogs = [];
  List<ReplayRound> replayRounds = [];
  ReplayRound? replayingRound;
  bool isSelectingHigh = true; // 현재 하이 핸드 선택 중인지 로우 핸드 선택 중인지 구분
  bool isReviewMode = false; // 리뷰 모드 상태 변수 추가
  int currentReviewIndex = 0; // 현재 리뷰 중인 라운드 인덱스

  // getText 함수를 추가하여 AppLanguage 클래스를 사용
  String getText(String key) => AppLanguage.getText(key);

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
      selectedHighWinnerIndex = null;
      selectedLowWinnerIndices = [];
      actualHighWinnerIndex = null;
      actualLowWinnerIndices = [];
      currentScore = 0;
      winnerText = '';
      highHandInfo = '';
      lowHandInfo = '';
      isSelectingHigh = true;

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
              
              // 마지막 라운드 정보 표시
              if (highHandInfo.isNotEmpty) {
                winnerText += '\n\nHi ${getText("winningHand")}: $highHandInfo';
              }
              if (lowHandInfo.isNotEmpty && isLowHand) {
                winnerText += '\nLow ${getText("winningHand")}: $lowHandInfo';
              }
            } else {
              winnerText = '${getText("gameOver")}! ${getText("finalScore")}: $currentScore';
            }
            // 타이머 정리
            gameTimer = null;
          }
        });
      });

      evaluateActualWinners();
    });
  }

  void dealNewRound() {
    setState(() {
      selectedHighWinnerIndex = null;
      selectedLowWinnerIndices = [];
      actualHighWinnerIndex = null;
      actualLowWinnerIndices = [];
      winnerText = '';
      isSelectingHigh = true;

      final random = Random();
      deck.shuffle(random);

      communityCards = deck.sublist(0, 5);

      for (int i = 0; i < numberOfPlayers; i++) {
        players[i].hand = deck.sublist(5 + i * 4, 5 + (i + 1) * 4);
      }

      evaluateActualWinners();
    });
  }

  void selectHighWinner(int index) {
    if (!isGameStarted || selectedHighWinnerIndex != null || !isSelectingHigh) return;

    setState(() {
      selectedHighWinnerIndex = index;
      scoreSystem.addAttempt(numberOfPlayers);

      if (selectedHighWinnerIndex == actualHighWinnerIndex) {
        // 하이 핸드 정답
        currentScore++;
        winnerText = '${getText("correctAnswer")}$currentScore\nHi ${getText("winningHand")}: $highHandInfo';
        
        // Low 핸드가 있으면 Low 핸드 선택 단계로 넘어가기
        if (isLowHand) {
          isSelectingHigh = false;
          winnerText += '\n이제 Low 핸드 승자를 선택하세요';
        } else {
          // Low 핸드 없음 메시지 추가
          winnerText += '\n로우 핸드가 없습니다';
          
          // Low 핸드 없으면 다음 라운드로
          roundLogs.add('${getText("round")} ${roundLogs.length + 1}: High: Player ${index + 1} ${getText("selected")} → ${getText("correct")}! (${getText("score")}: $currentScore)');
          replayRounds.add(ReplayRound(
            playerHands: players.take(numberOfPlayers).map((p) => List<String>.from(p.hand)).toList(),
            communityCards: List<String>.from(communityCards),
            selectedHighWinnerIndex: index,
            actualHighWinnerIndex: actualHighWinnerIndex,
            selectedLowWinnerIndices: [],
            actualLowWinnerIndices: [],
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
      } else {
        // 하이 핸드 오답
        winnerText = '${getText("wrongAnswer")}${getText("correctAnswerIs")} Player ${actualHighWinnerIndex! + 1}.\nHi ${getText("winningHand")}: $highHandInfo';
        
        // Low 핸드가 있으면 Low 핸드 선택 단계로 넘어가기
        if (isLowHand) {
          isSelectingHigh = false;
          winnerText += '\n이제 Low 핸드 승자를 선택하세요';
          
        } else {
          // Low 핸드 없음 메시지 추가
          winnerText += '\n로우 핸드가 없습니다';
          
          // Low 핸드 없으면 다음 라운드로
          roundLogs.add('${getText("round")} ${roundLogs.length + 1}: High: Player ${index + 1} ${getText("selected")} → ${getText("wrong")}! (${getText("correct")}: Player ${actualHighWinnerIndex! + 1}, ${getText("score")}: $currentScore)');
          replayRounds.add(ReplayRound(
            playerHands: players.take(numberOfPlayers).map((p) => List<String>.from(p.hand)).toList(),
            communityCards: List<String>.from(communityCards),
            selectedHighWinnerIndex: index,
            actualHighWinnerIndex: actualHighWinnerIndex,
            selectedLowWinnerIndices: [],
            actualLowWinnerIndices: [],
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
      }
    });
  }

  void selectLowWinner(int index) {
    if (!isGameStarted || isSelectingHigh || !isLowHand) return;
    
    // 이미 선택된 플레이어는 선택 취소 가능하게 함
    if (selectedLowWinnerIndices.contains(index)) {
      setState(() {
        selectedLowWinnerIndices.remove(index);
      });
      return;
    }

    setState(() {
      selectedLowWinnerIndices.add(index);
      
      // 선택한 플레이어가 정답인지 확인
      bool isCorrect = actualLowWinnerIndices.contains(index);
      
      // 모든 정답을 선택했는지 확인
      bool allCorrectSelected = actualLowWinnerIndices.every((winnerIndex) => 
        selectedLowWinnerIndices.contains(winnerIndex));
      
      // 오답을 선택했는지 확인
      bool anyWrongSelected = selectedLowWinnerIndices.any((selectedIndex) => 
        !actualLowWinnerIndices.contains(selectedIndex));

      if (isCorrect && !anyWrongSelected) {
        // 정답 선택 - 아직 모든 승자를 선택하지 않았으면 계속 선택 가능
        if (allCorrectSelected) {
          // 모든 승자를 선택했으면 점수 부여 및 다음 라운드로
          currentScore++;
          winnerText = '${getText("correctAnswer")}$currentScore\nHi ${getText("winningHand")}: $highHandInfo\nLow ${getText("winningHand")}: $lowHandInfo';
          
          // 라운드 로그 및 리플레이 정보 저장
          String winnerListText = actualLowWinnerIndices.map((i) => 'Player ${i + 1}').join(', ');
          roundLogs.add('${getText("round")} ${roundLogs.length + 1}: High: Player ${selectedHighWinnerIndex! + 1}, '
              'Low: ${selectedLowWinnerIndices.map((i) => 'Player ${i + 1}').join('+')} ${getText("selected")} → '
              '${getText("correct")}! (${getText("score")}: $currentScore)');
          
          replayRounds.add(ReplayRound(
            playerHands: players.take(numberOfPlayers).map((p) => List<String>.from(p.hand)).toList(),
            communityCards: List<String>.from(communityCards),
            selectedHighWinnerIndex: selectedHighWinnerIndex,
            actualHighWinnerIndex: actualHighWinnerIndex,
            selectedLowWinnerIndices: List<int>.from(selectedLowWinnerIndices),
            actualLowWinnerIndices: List<int>.from(actualLowWinnerIndices),
            winnerText: winnerText,
            numberOfPlayers: numberOfPlayers,
            roundScore: currentScore,
          ));
          
          // 다음 라운드로
          Future.delayed(const Duration(seconds: 1), () {
            if (remainingTime > 0 && mounted) {
              dealNewRound();
            }
          });
        } else {
          // 일부 승자만 선택했으면 계속해서 나머지 승자를 고르도록 함
          winnerText = '정답! 다른 승자도 선택하세요.';
        }
      } else if (anyWrongSelected) {
        // 오답 선택
        String correctWinners = actualLowWinnerIndices.map((i) => 'Player ${i + 1}').join(', ');
        winnerText = '${getText("wrongAnswer")}Low ${getText("correctAnswerIs")} $correctWinners\nHi ${getText("winningHand")}: $highHandInfo\nLow ${getText("winningHand")}: $lowHandInfo';
        
        roundLogs.add('${getText("round")} ${roundLogs.length + 1}: High: Player ${selectedHighWinnerIndex! + 1}, '
            'Low: ${selectedLowWinnerIndices.map((i) => 'Player ${i + 1}').join('+')} ${getText("selected")} → '
            '${getText("wrong")}! (${getText("correct")}: $correctWinners, ${getText("score")}: $currentScore)');
        
        replayRounds.add(ReplayRound(
          playerHands: players.take(numberOfPlayers).map((p) => List<String>.from(p.hand)).toList(),
          communityCards: List<String>.from(communityCards),
          selectedHighWinnerIndex: selectedHighWinnerIndex,
          actualHighWinnerIndex: actualHighWinnerIndex,
          selectedLowWinnerIndices: List<int>.from(selectedLowWinnerIndices),
          actualLowWinnerIndices: List<int>.from(actualLowWinnerIndices),
          winnerText: winnerText,
          numberOfPlayers: numberOfPlayers,
          roundScore: currentScore,
        ));
        
        // 다음 라운드로
        Future.delayed(const Duration(seconds: 1), () {
          if (remainingTime > 0 && mounted) {
            dealNewRound();
          }
        });
      }
    });
  }

  void evaluateActualWinners() {
    // 하이 핸드 계산
    evaluateHighHand();
    
    // 로우 핸드 계산
    evaluateLowHand();
  }
  
  void evaluateHighHand() {
    List<List<String>> playerHands = players.take(numberOfPlayers).map((p) => p.hand).toList();
    String bestHand = '';
    int highestRank = 0;
    int highestSecondaryRank = 0;
    actualHighWinnerIndex = -1;
    String winningHandDescription = '';
    String handTypeName = '';

    for (int i = 0; i < playerHands.length; i++) {
      var hands = generatePLOCombinations(playerHands[i], communityCards);
      String currentBestHand = '';
      int currentRank = 0;
      int currentSecondaryRank = 0;
      List<poker.Card> bestHandCards = [];
      String currentHandTypeName = '';

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
          currentHandTypeName = handRankObj.name;
        }
      }

      if (currentRank > highestRank ||
          (currentRank == highestRank &&
              currentSecondaryRank > highestSecondaryRank)) {
        highestRank = currentRank;
        highestSecondaryRank = currentSecondaryRank;
        actualHighWinnerIndex = i;
        bestHand = currentBestHand;
        winningHandDescription = _getHandDescription(bestHandCards);
        handTypeName = currentHandTypeName;
      }
    }

    highHandInfo = '$handTypeName\n$winningHandDescription';
  }
  
  void evaluateLowHand() {
    List<List<String>> playerHands = players.take(numberOfPlayers).map((p) => p.hand).toList();
    List<LowHandRank?> playerLowRanks = List.filled(playerHands.length, null);
    actualLowWinnerIndices = [];
    isLowHand = false;
    
    // 각 플레이어의 최고 로우 핸드 찾기
    for (int i = 0; i < playerHands.length; i++) {
      var hands = generatePLOCombinations(playerHands[i], communityCards);
      LowHandRank? bestLowHand;
      List<poker.Card>? bestLowHandCards;
      
      for (var hand in hands) {
        var cards = hand.map((card) => poker.Card.fromString(card)).toList();
        var lowHandRank = LowHandRank.evaluate(cards);
        
        // 더 좋은 로우 핸드인지 확인 (로우는 값이 낮을수록 좋음)
        if (lowHandRank != null && (bestLowHand == null || 
            LowHandRank.compare(lowHandRank, bestLowHand) < 0)) {
          bestLowHand = lowHandRank;
          bestLowHandCards = cards;
        }
      }
      
      playerLowRanks[i] = bestLowHand;
      
      // 로우 핸드가 있는 플레이어가 있으면 isLowHand를 true로 설정
      if (bestLowHand != null) {
        isLowHand = true;
      }
    }
    
    // 디버깅 출력 - 각 플레이어의 로우 핸드 정보
    for (int i = 0; i < playerLowRanks.length; i++) {
      if (playerLowRanks[i] != null) {
        print('Player ${i+1} 로우 핸드: ${playerLowRanks[i]!.name}, 값: ${playerLowRanks[i]!.value}');
      }
    }
    
    // 로우 핸드가 있으면 승자 결정 (동점자 모두 승자로 추가)
    if (isLowHand) {
      // 최고의 로우 핸드 찾기
      LowHandRank? bestLowHandRank;
      int bestPlayerIndex = -1;
      
      for (int i = 0; i < playerLowRanks.length; i++) {
        var lowRank = playerLowRanks[i];
        if (lowRank != null && (bestLowHandRank == null || 
            LowHandRank.compare(lowRank, bestLowHandRank) < 0)) {
          bestLowHandRank = lowRank;
          bestPlayerIndex = i;
        }
      }
      
      // 최고 로우 핸드와 동일한 랭크를 가진 모든 플레이어를 승자로 지정
      if (bestLowHandRank != null) {
        for (int i = 0; i < playerLowRanks.length; i++) {
          var lowRank = playerLowRanks[i];
          if (lowRank != null && LowHandRank.compare(lowRank, bestLowHandRank) == 0) {
            actualLowWinnerIndices.add(i);
          }
        }
        
        // 로우 핸드 정보 업데이트
        if (actualLowWinnerIndices.isNotEmpty) {
          // 내림차순으로 정렬된 카드 순서로 표시 (높은 카드부터)
          List<int> sortedRanks = List.from(bestLowHandRank.rankValues)..sort((a, b) => b.compareTo(a));
          String rankDisplay = sortedRanks.map((r) => r == 1 ? 'A' : r.toString()).join('-');
          lowHandInfo = '$rankDisplay';
          
          // 여러 승자가 있으면 플레이어 번호 추가
          if (actualLowWinnerIndices.length > 1) {
            lowHandInfo += '\n(스플릿: ${actualLowWinnerIndices.map((i) => 'Player ${i + 1}').join(', ')})';
          }
        }
      }
    } else {
      lowHandInfo = "로우 핸드 없음";
    }
  }

  // PLO 조합 생성 (2장의 핸드 카드 + 3장의 커뮤니티 카드)
  List<List<String>> generatePLOCombinations(List<String> hand, List<String> community) {
    List<List<String>> result = [];
    
    // 핸드에서 2장 선택하는 모든 조합
    for (int i = 0; i < hand.length; i++) {
      for (int j = i + 1; j < hand.length; j++) {
        // 커뮤니티에서 3장 선택하는 모든 조합
        for (int k = 0; k < community.length; k++) {
          for (int l = k + 1; l < community.length; l++) {
            for (int m = l + 1; m < community.length; m++) {
              result.add([hand[i], hand[j], community[k], community[l], community[m]]);
            }
          }
        }
      }
    }
    
    return result;
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
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi/Low 보드리딩', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1B5E20),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // 게임 진행 중이면 게임을 중단하고 시작 화면으로 돌아가기
            if (isGameStarted) {
              setState(() {
                isGameStarted = false;
                gameTimer?.cancel();
                gameTimer = null;
              });
            } else if (isReviewMode) {
              // 리뷰 모드라면 리뷰 모드 종료
              endReviewMode();
            } else {
              // 그 외에는 이전 화면으로 돌아가기
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          // 리뷰 버튼 추가 - 게임 종료 후나 라운드가 있을 때 표시
          if (!isReviewMode && replayRounds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: ElevatedButton.icon(
                onPressed: startReviewMode,
                icon: Icon(Icons.history, color: Colors.white),
                label: Text(
                  getText('review'),
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF4CAF50),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 점수 및 타이머 표시 - 리뷰 모드일 때는 제거 (리뷰 UI에 통합됨)
              if (!isReviewMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${getText("score")}: $currentScore',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isGameStarted)
                        Text(
                          '${getText("remainingTime")}: $remainingTime ${getText("seconds")}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              
              // 게임 영역
              Expanded(
                child: isReviewMode
                    ? _buildReviewMode()
                    : !isGameStarted
                        ? _buildStartScreen()
                        : _buildGamePlayArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hi/Low 보드리딩 게임',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          
          // 플레이어 수 선택
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getText('playerCount'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [3, 4, 5, 6].map((count) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          numberOfPlayers = count;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: numberOfPlayers == count
                              ? Colors.amber
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            color: numberOfPlayers == count ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 40),
          
          // 게임 시작 버튼
          ElevatedButton(
            onPressed: startNewGame,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              getText('startGame'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // 최고 점수 표시
          Text(
            '${getText("highScore")}: ${scoreSystem.getHighScore(numberOfPlayers)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          
          // 이전 게임의 라운드 로그가 있으면 리뷰 버튼 표시
          if (replayRounds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton.icon(
                onPressed: startReviewMode,
                icon: Icon(Icons.history),
                label: Text(getText('review')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGamePlayArea() {
    return Column(
      children: [
        // 커뮤니티 카드 영역
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                getText('communityCards'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: communityCards
                    .map((card) => _buildCard(card, margin: 4))
                    .toList(),
              ),
            ],
          ),
        ),
        
        // 현재 선택 모드 표시
        if (isGameStarted && selectedHighWinnerIndex == null && selectedLowWinnerIndices.isEmpty)
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelectingHigh ? Colors.amber.withOpacity(0.7) : Colors.green.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isSelectingHigh ? "High 핸드 승자 선택" : "Low 핸드 승자 선택",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        
        // 선택 인스트럭션 표시 (로우 핸드에 여러 승자가 있을 경우)
        if (isGameStarted && !isSelectingHigh && actualLowWinnerIndices.length > 1 && 
            selectedLowWinnerIndices.isNotEmpty && selectedLowWinnerIndices.length < actualLowWinnerIndices.length)
          Container(
            margin: EdgeInsets.symmetric(vertical: 4),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "여러 승자가 있습니다. 모든 승자를 선택하세요.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        
        // 결과 메시지 영역
        if (winnerText.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              winnerText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        
        // 플레이어 카드 영역
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: numberOfPlayers,
            itemBuilder: (context, index) {
              bool isHighSelected = selectedHighWinnerIndex == index;
              bool isLowSelected = selectedLowWinnerIndices.contains(index);
              bool isHighCorrect = actualHighWinnerIndex == index && selectedHighWinnerIndex != null;
              
              Color borderColor = Colors.transparent;
              if (isHighSelected && isSelectingHigh) {
                borderColor = Colors.amber;
              } else if (isLowSelected && !isSelectingHigh) {
                borderColor = Colors.green;
              } else if (isHighCorrect && isSelectingHigh) {
                borderColor = Colors.blue;
              }
              
              return GestureDetector(
                onTap: () {
                  if (isSelectingHigh) {
                    selectHighWinner(index);
                  } else {
                    selectLowWinner(index);
                  }
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: borderColor,
                          width: borderColor != Colors.transparent ? 3 : 0,
                        ),
                      ),
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Player ${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            runSpacing: 4,
                            children: players[index]
                                .hand
                                .map((card) => _buildCard(card, size: 36))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    
                    // High 핸드 승자 표시 (선택 후에만)
                    if (isHighCorrect && selectedHighWinnerIndex != null)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'High',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    
                    // Low 핸드 선택 표시 (여러 개 선택 가능한 경우)
                    if (!isSelectingHigh && isLowSelected)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(String card, {double size = 50, double margin = 0}) {
    String suit = card.substring(card.length - 1);
    String rank = card.substring(0, card.length - 1);
    
    Color suitColor;
    String suitSymbol;
    
    switch (suit) {
      case 'S':
        suitColor = Colors.black;
        suitSymbol = '♠';
        break;
      case 'H':
        suitColor = Colors.red;
        suitSymbol = '♥';
        break;
      case 'D':
        suitColor = Colors.red;
        suitSymbol = '♦';
        break;
      case 'C':
        suitColor = Colors.black;
        suitSymbol = '♣';
        break;
      default:
        suitColor = Colors.black;
        suitSymbol = '';
    }
    
    return Container(
      width: size,
      height: size * 1.4,
      margin: EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 2,
            left: 4,
            child: Text(
              rank,
              style: TextStyle(
                color: suitColor,
                fontSize: size * 0.3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Text(
              suitSymbol,
              style: TextStyle(
                color: suitColor,
                fontSize: size * 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 리뷰 모드 시작 함수 추가
  void startReviewMode() {
    if (replayRounds.isEmpty) return;
    
    setState(() {
      isReviewMode = true;
      currentReviewIndex = replayRounds.length - 1; // 마지막 라운드부터 시작
      showReplayRound(currentReviewIndex);
    });
  }
  
  // 리뷰 모드 종료 함수 추가
  void endReviewMode() {
    setState(() {
      isReviewMode = false;
      replayingRound = null;
    });
  }
  
  // 특정 라운드 리플레이 표시
  void showReplayRound(int index) {
    if (index < 0 || index >= replayRounds.length) return;
    
    setState(() {
      replayingRound = replayRounds[index];
      winnerText = replayingRound!.winnerText;
    });
  }
  
  // 다음 리뷰 라운드로 이동
  void nextReviewRound() {
    if (currentReviewIndex < replayRounds.length - 1) {
      setState(() {
        currentReviewIndex++;
        showReplayRound(currentReviewIndex);
      });
    }
  }
  
  // 이전 리뷰 라운드로 이동
  void previousReviewRound() {
    if (currentReviewIndex > 0) {
      setState(() {
        currentReviewIndex--;
        showReplayRound(currentReviewIndex);
      });
    }
  }

  // 리뷰 모드 UI에서 여러 Low 핸드 승자 표시 로직 수정
  Widget _buildReviewMode() {
    if (replayingRound == null) return Container();
    
    return Column(
      children: [
        // 리뷰 정보와 라운드 탐색 버튼을 하나의 행으로 통합
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 리뷰 정보
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${getText("review")}: ${currentReviewIndex + 1}/${replayRounds.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              // 라운드 탐색 컨트롤
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: currentReviewIndex > 0 ? previousReviewRound : null,
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                    Text(
                      '${getText("round")} ${currentReviewIndex + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onPressed: currentReviewIndex < replayRounds.length - 1 ? nextReviewRound : null,
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // 커뮤니티 카드 영역
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  getText('communityCards'),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: replayingRound!.communityCards
                    .map((card) => _buildCard(card, margin: 2))
                    .toList(),
              ),
            ],
          ),
        ),
        
        // 결과 메시지 영역
        if (replayingRound!.winnerText.isNotEmpty)
          Container(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Text(
              replayingRound!.winnerText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        
        // 플레이어 카드 영역
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: replayingRound!.numberOfPlayers,
            itemBuilder: (context, index) {
              bool isHighSelected = replayingRound!.selectedHighWinnerIndex == index;
              bool isLowSelected = replayingRound!.selectedLowWinnerIndices.contains(index);
              bool isHighCorrect = replayingRound!.actualHighWinnerIndex == index;
              bool isLowCorrect = replayingRound!.actualLowWinnerIndices.contains(index);
              
              // High 핸드 선택 상태
              String highStatus = '';
              Color highStatusColor = Colors.transparent;
              IconData? highIcon;
              
              if (isHighSelected) {
                if (isHighCorrect) {
                  highStatus = 'High: 정답';
                  highStatusColor = Colors.green.shade300;
                  highIcon = Icons.check_circle;
                } else {
                  highStatus = 'High: 오답';
                  highStatusColor = Colors.red.shade300;
                  highIcon = Icons.cancel;
                }
              } else if (isHighCorrect) {
                highStatus = 'High: 정답';
                highStatusColor = Colors.blue.shade300;
                highIcon = Icons.check_circle_outline;
              }
              
              // Low 핸드 선택 상태
              String lowStatus = '';
              Color lowStatusColor = Colors.transparent;
              IconData? lowIcon;
              
              if (isLowSelected) {
                if (isLowCorrect) {
                  lowStatus = 'Low: 정답';
                  lowStatusColor = Colors.green.shade300;
                  lowIcon = Icons.check_circle;
                } else {
                  lowStatus = 'Low: 오답';
                  lowStatusColor = Colors.red.shade300;
                  lowIcon = Icons.cancel;
                }
              } else if (isLowCorrect) {
                // 선택하지 않은 정답 플레이어 (다른 정답 플레이어를 선택한 경우)
                if (replayingRound!.selectedLowWinnerIndices.isNotEmpty && 
                    replayingRound!.actualLowWinnerIndices.any((i) => 
                        replayingRound!.selectedLowWinnerIndices.contains(i))) {
                  lowStatus = 'Low: 미선택 정답';
                  lowStatusColor = Colors.blue.shade300;
                  lowIcon = Icons.check_circle_outline;
                } else {
                  lowStatus = 'Low: 정답';
                  lowStatusColor = Colors.teal.shade300;
                  lowIcon = Icons.check_circle_outline;
                }
              }
              
              // 플레이어 카드 컨테이너 색상 결정
              Color containerColor = Colors.white.withOpacity(0.15);
              if (isHighCorrect || isLowCorrect) {
                containerColor = Colors.white.withOpacity(0.25);
              }
              
              // 여러 Low 핸드 승자가 있는 경우 표시
              String multiWinnerLabel = '';
              if (isLowCorrect && replayingRound!.actualLowWinnerIndices.length > 1) {
                multiWinnerLabel = 'Low 스플릿';
              }
              
              return Container(
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: (isHighCorrect || isLowCorrect) ? 
                           Colors.amber.withOpacity(0.5) : 
                           Colors.transparent,
                    width: 2,
                  ),
                ),
                padding: EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      'Player ${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: replayingRound!.playerHands[index]
                          .map((card) => _buildCard(card, size: 36))
                          .toList(),
                    ),
                    Spacer(),
                    
                    // 여러 로우 핸드 승자 표시
                    if (multiWinnerLabel.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(bottom: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          multiWinnerLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    
                    // High 및 Low 상태 표시
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // High 핸드 정답/오답 표시
                        if (highStatus.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: highStatusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (highIcon != null)
                                  Icon(highIcon, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  highStatus,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Low 핸드 정답/오답 표시
                        if (lowStatus.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(left: highStatus.isNotEmpty ? 4 : 0),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: lowStatusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (lowIcon != null)
                                  Icon(lowIcon, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  lowStatus,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // 리뷰 종료 버튼 - 하단 여백 최소화
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ElevatedButton.icon(
            onPressed: endReviewMode,
            icon: Icon(Icons.arrow_back, size: 16),
            label: Text(getText('endReplay')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF1B5E20),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: Size(120, 36),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }
} 