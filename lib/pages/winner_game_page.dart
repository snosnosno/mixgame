import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../l10n/app_language.dart'; // AppLanguage를 사용하기 위해 추가
import '../models/card.dart' as poker;
import '../models/hand_rank.dart';
import '../models/player.dart';
import '../models/score_system.dart';
import '../home_page.dart'; // AppLanguage를 사용하기 위해 추가
import '../models/replay_round.dart';
import '../services/winner_game_service.dart';
import '../widgets/winner_game/winner_game_start_screen.dart';
import '../widgets/winner_game/winner_game_board.dart';
import '../widgets/winner_game/winner_game_overlay.dart';
import '../widgets/common/game_background.dart';

/// Winner 게임 페이지
///
/// PLO 포커의 승자 판별 게임을 구현한 페이지입니다.
class WinnerGamePage extends StatefulWidget {
  const WinnerGamePage({super.key});

  @override
  _WinnerGamePageState createState() => _WinnerGamePageState();
}

class _WinnerGamePageState extends State<WinnerGamePage> {
  // 게임 상태 변수들
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

  @override
  void initState() {
    super.initState();
    players = WinnerGameService.initializePlayers();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    gameTimer = null;
    super.dispose();
  }

  /// 새 게임을 시작합니다.
  void startNewGame() {
    setState(() {
      isGameStarted = true;
      remainingTime = 60;
      selectedWinnerIndex = null;
      actualWinnerIndex = null;
      currentScore = 0;
      winnerText = '';
      winnerHandInfo = '';

      // 카드 딜링
      final dealResult = WinnerGameService.dealNewGame(players, numberOfPlayers);
      communityCards = dealResult.communityCards;

      // 타이머 시작
      _startGameTimer();

      // 승자 평가
      _evaluateWinner();
    });
  }

  /// 새 라운드를 딜링합니다.
  void dealNewRound() {
    setState(() {
      selectedWinnerIndex = null;
      actualWinnerIndex = null;
      winnerText = '';

      // 카드 딜링
      final dealResult = WinnerGameService.dealNewGame(players, numberOfPlayers);
      communityCards = dealResult.communityCards;

      // 승자 평가
      _evaluateWinner();
    });
  }

  /// 승자를 선택합니다.
  void selectWinner(int index) {
    if (!isGameStarted || selectedWinnerIndex != null) return;

    setState(() {
      selectedWinnerIndex = index;
      scoreSystem.addAttempt(numberOfPlayers);

      if (selectedWinnerIndex == actualWinnerIndex) {
        // 정답
        currentScore++;
        winnerText = '${getText("correctAnswer")}$currentScore\n${getText("winningHand")}: $winnerHandInfo';
        roundLogs.add('${getText("round")} ${roundLogs.length + 1}: Player ${index + 1} ${getText("selected")} → ${getText("correct")}! (${getText("score")}: $currentScore)');
        _addReplayRound(index);
        
        Future.delayed(const Duration(seconds: 1), () {
          if (remainingTime > 0 && mounted) {
            dealNewRound();
          }
        });
      } else {
        // 오답
        winnerText = '${getText("wrongAnswer")}${getText("correctAnswerIs")} Player ${actualWinnerIndex! + 1}.\n${getText("winningHand")}: $winnerHandInfo';
        roundLogs.add('${getText("round")} ${roundLogs.length + 1}: Player ${index + 1} ${getText("selected")} → ${getText("wrong")}! (${getText("correct")}: Player ${actualWinnerIndex! + 1}, ${getText("score")}: $currentScore)');
        _addReplayRound(index);
        
        Future.delayed(const Duration(seconds: 1), () {
          if (remainingTime > 0 && mounted) {
            dealNewRound();
          }
        });
      }
    });
  }

  /// 플레이어 수를 변경합니다.
  void changePlayerCount(int newCount) {
    setState(() {
      numberOfPlayers = newCount;
      players = WinnerGameService.initializePlayers();
    });
  }

  /// 리플레이 라운드를 시작합니다.
  void startReplayRound(int index) {
    if (replayRounds.length > index) {
      setState(() {
        replayingRound = replayRounds[index];
      });
    }
  }

  /// 리플레이를 종료합니다.
  void exitReplay() {
    setState(() {
      replayingRound = null;
    });
  }

  /// 게임 타이머를 시작합니다.
  void _startGameTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTime > 0) {
          remainingTime--;
        } else {
          timer.cancel();
          isGameStarted = false;
          _handleGameEnd();
          gameTimer = null;
        }
      });
    });
  }

  /// 게임 종료를 처리합니다.
  void _handleGameEnd() {
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
  }

  /// 승자를 평가합니다.
  void _evaluateWinner() {
    final result = WinnerGameService.evaluateWinner(players, communityCards, numberOfPlayers);
    actualWinnerIndex = result.winnerIndex;
    winnerHandInfo = result.winnerHandInfo;
  }

  /// 리플레이 라운드를 추가합니다.
  void _addReplayRound(int selectedIndex) {
    replayRounds.add(ReplayRound(
      playerHands: players.take(numberOfPlayers).map((p) => List<String>.from(p.hand)).toList(),
      communityCards: List<String>.from(communityCards),
      selectedHighWinnerIndex: null,
      actualHighWinnerIndex: null,
      selectedLowWinnerIndices: const [],
      actualLowWinnerIndices: const [],
      winnerText: winnerText,
      numberOfPlayers: numberOfPlayers,
      roundScore: currentScore,
      selectedWinnerIndex: selectedIndex,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: GameBackground(
        child: Stack(
          children: [
            Column(
              children: [
                // 게임 시작 화면
                if (!isGameStarted && replayingRound == null)
                  WinnerGameStartScreen(
                    numberOfPlayers: numberOfPlayers,
                    scoreSystem: scoreSystem,
                    onPlayerCountChanged: changePlayerCount,
                    onStartGame: startNewGame,
                  ),

                // 게임 보드 (게임 중이거나 리플레이 중일 때)
                if (isGameStarted || replayingRound != null)
                  Expanded(
                    child: WinnerGameBoard(
                      communityCards: communityCards,
                      playerHands: players.take(numberOfPlayers).map((p) => p.hand).toList(),
                      numberOfPlayers: replayingRound?.numberOfPlayers ?? numberOfPlayers,
                      selectedWinnerIndex: selectedWinnerIndex,
                      replayingRound: replayingRound,
                      onPlayerTap: replayingRound == null ? selectWinner : null,
                      screenWidth: screenWidth,
                    ),
                  ),
              ],
                ),

            // 오버레이 (타이머, 결과 메시지, 리뷰 로그 등)
            WinnerGameOverlay(
              isGameStarted: isGameStarted,
              remainingTime: remainingTime,
              winnerText: winnerText,
              selectedWinnerIndex: selectedWinnerIndex,
              actualWinnerIndex: actualWinnerIndex,
              roundLogs: roundLogs,
              replayRounds: replayRounds,
              replayingRound: replayingRound,
              onReplayRoundTap: startReplayRound,
              onExitReplay: exitReplay,
              ),
          ],
              ),
      ),
    );
  }
}
