import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';
import '../../models/score_system.dart';
import '../../models/replay_round.dart';

/// Hi/Low 게임의 시작 화면 위젯
class HiLowStartScreen extends StatelessWidget {
  final int numberOfPlayers;
  final Function(int) onPlayerCountChanged;
  final VoidCallback onStartGame;
  final VoidCallback? onStartReview;
  final ScoreSystem scoreSystem;
  final List<ReplayRound> replayRounds;

  const HiLowStartScreen({
    Key? key,
    required this.numberOfPlayers,
    required this.onPlayerCountChanged,
    required this.onStartGame,
    this.onStartReview,
    required this.scoreSystem,
    required this.replayRounds,
  }) : super(key: key);

  String getText(String key) => AppLanguage.getText(key);

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              getText('hiLowRuleDescription'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
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
                      onTap: () => onPlayerCountChanged(count),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: numberOfPlayers == count
                              ? Colors.amber
                              : Colors.white.withAlpha((0.2 * 255).round()),
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
            onPressed: onStartGame,
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
          if (replayRounds.isNotEmpty && onStartReview != null)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton.icon(
                onPressed: onStartReview,
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
} 