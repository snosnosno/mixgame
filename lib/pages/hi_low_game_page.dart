import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../models/player.dart';
import '../models/score_system.dart';
import '../models/replay_round.dart';
import '../services/hi_low_game_service.dart';
import '../widgets/hi_low_game/hi_low_start_screen.dart';
import '../widgets/hi_low_game/hi_low_game_board.dart';
import '../widgets/hi_low_game/hi_low_player_grid.dart';
import '../widgets/hi_low_game/hi_low_status_indicators.dart';
import '../widgets/hi_low_game/hi_low_review_mode.dart';
import '../widgets/common/game_status_bar.dart';
import '../widgets/common/game_background.dart';
import '../models/card.dart' as poker;
import '../models/hand_rank.dart';
import '../models/low_hand_rank.dart';

class HiLowGamePage extends StatefulWidget {
  const HiLowGamePage({super.key});

  @override
  _HiLowGamePageState createState() => _HiLowGamePageState();
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
    _initializePlayers();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    gameTimer = null;
    super.dispose();
  }

  void _initializePlayers() {
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

  void _startNewGame() {
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

      _evaluateActualWinners();
    });
  }

  void _dealNewRound() {
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

      _evaluateActualWinners();
    });
  }

  void _selectHighWinner(int index) {
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
              _dealNewRound();
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
              _dealNewRound();
            }
          });
        }
      }
    });
  }

  void _selectLowWinner(int index) {
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
              _dealNewRound();
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
            _dealNewRound();
          }
        });
      }
    });
  }

  void _evaluateActualWinners() {
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
              _endReviewMode();
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
                onPressed: _startReviewMode,
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
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 상단 점수 및 타이머 표시 - 리뷰 모드일 때는 제거 (리뷰 UI에 통합됨)
              if (!isReviewMode)
                GameStatusBar(
                  score: currentScore,
                  remainingTime: isGameStarted ? remainingTime : null,
                ),
              
              // 게임 영역
              Expanded(
                child: isReviewMode
                    ? HiLowReviewMode(
                        replayingRound: replayingRound,
                        currentReviewIndex: currentReviewIndex,
                        totalRounds: replayRounds.length,
                        onPreviousRound: _previousReviewRound,
                        onNextRound: _nextReviewRound,
                        onEndReview: _endReviewMode,
                      )
                    : !isGameStarted
                        ? HiLowStartScreen(
                            numberOfPlayers: numberOfPlayers,
                            onPlayerCountChanged: (count) {
                              setState(() {
                                numberOfPlayers = count;
                              });
                            },
                            onStartGame: _startNewGame,
                            onStartReview: replayRounds.isNotEmpty ? _startReviewMode : null,
                            scoreSystem: scoreSystem,
                            replayRounds: replayRounds,
                          )
                        : _buildGamePlayArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamePlayArea() {
    return Column(
      children: [
        // 커뮤니티 카드 영역
        HiLowGameBoard(communityCards: communityCards),
        
        // 현재 선택 모드 표시
        HiLowSelectionModeIndicator(
          isSelectingHigh: isSelectingHigh,
          isGameStarted: isGameStarted,
          selectedHighWinnerIndex: selectedHighWinnerIndex,
          selectedLowWinnerIndices: selectedLowWinnerIndices,
        ),
        
        // 선택 인스트럭션 표시 (로우 핸드에 여러 승자가 있을 경우)
        HiLowMultiSelectionGuide(
          isGameStarted: isGameStarted,
          isSelectingHigh: isSelectingHigh,
          actualLowWinnerIndices: actualLowWinnerIndices,
          selectedLowWinnerIndices: selectedLowWinnerIndices,
        ),
        
        // 결과 메시지 영역
        HiLowResultMessage(winnerText: winnerText),
        
        // 플레이어 카드 영역
        HiLowPlayerGrid(
          players: players,
          numberOfPlayers: numberOfPlayers,
          isSelectingHigh: isSelectingHigh,
          selectedHighWinnerIndex: selectedHighWinnerIndex,
          selectedLowWinnerIndices: selectedLowWinnerIndices,
          actualHighWinnerIndex: actualHighWinnerIndex,
          onHighWinnerTap: _selectHighWinner,
          onLowWinnerTap: _selectLowWinner,
        ),
      ],
    );
  }

  // 리뷰 모드 시작 함수 추가
  void _startReviewMode() {
    if (replayRounds.isEmpty) return;
    
    setState(() {
      isReviewMode = true;
      currentReviewIndex = replayRounds.length - 1; // 마지막 라운드부터 시작
      _showReplayRound(currentReviewIndex);
    });
  }
  
  // 리뷰 모드 종료 함수 추가
  void _endReviewMode() {
    setState(() {
      isReviewMode = false;
      replayingRound = null;
    });
  }
  
  // 특정 라운드 리플레이 표시
  void _showReplayRound(int index) {
    if (index < 0 || index >= replayRounds.length) return;
    
    setState(() {
      replayingRound = replayRounds[index];
      winnerText = replayingRound!.winnerText;
    });
  }
  
  // 다음 리뷰 라운드로 이동
  void _nextReviewRound() {
    if (currentReviewIndex < replayRounds.length - 1) {
      setState(() {
        currentReviewIndex++;
        _showReplayRound(currentReviewIndex);
      });
    }
  }
  
  // 이전 리뷰 라운드로 이동
  void _previousReviewRound() {
    if (currentReviewIndex > 0) {
      setState(() {
        currentReviewIndex--;
        _showReplayRound(currentReviewIndex);
      });
    }
  }
} 