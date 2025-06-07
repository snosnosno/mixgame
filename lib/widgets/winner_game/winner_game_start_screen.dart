import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';
import '../../models/score_system.dart';
import 'board_reading_guide.dart';

/// Winner 게임 시작 화면 위젯
///
/// 플레이어 수 선택, 게임 시작, 보드 리딩 가이드 버튼을 제공합니다.
class WinnerGameStartScreen extends StatelessWidget {
  final int numberOfPlayers;
  final ScoreSystem scoreSystem;
  final Function(int) onPlayerCountChanged;
  final VoidCallback onStartGame;

  const WinnerGameStartScreen({
    Key? key,
    required this.numberOfPlayers,
    required this.scoreSystem,
    required this.onPlayerCountChanged,
    required this.onStartGame,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        
        // 플레이어 수 선택
        _buildPlayerCountSelector(),
        
        const SizedBox(height: 24),
        
        // 최고 점수 표시
        _buildHighScoreDisplay(),
        
        const SizedBox(height: 20),
        
        // 보드 리딩 설명 버튼
        _buildBoardReadingGuideButton(context),
        
        const SizedBox(height: 16),
        
        // 게임 시작 버튼
        _buildStartGameButton(),
      ],
    );
  }

  /// 플레이어 수 선택기를 빌드합니다.
  Widget _buildPlayerCountSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${AppLanguage.getText("playerCount")} ',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.2 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: numberOfPlayers,
            dropdownColor: const Color(0xFF2E7D32),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: Container(),
            items: [2, 3, 4, 5, 6].map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
            onChanged: (int? newValue) {
              if (newValue != null) {
                onPlayerCountChanged(newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  /// 최고 점수 표시를 빌드합니다.
  Widget _buildHighScoreDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.3 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withAlpha((0.5 * 255).round()),
          width: 1,
        ),
      ),
      child: Text(
        '${AppLanguage.getText("highScore")}: ${scoreSystem.getHighScore(numberOfPlayers)}',
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 보드 리딩 가이드 버튼을 빌드합니다.
  Widget _buildBoardReadingGuideButton(BuildContext context) {
    return ElevatedButton.icon(
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
      onPressed: () => BoardReadingGuide.showBoardReadingGuide(context),
      icon: const Icon(Icons.info_outline),
      label: Text(AppLanguage.getText('boardReadingHelp')),
    );
  }

  /// 게임 시작 버튼을 빌드합니다.
  Widget _buildStartGameButton() {
    return ElevatedButton(
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
      onPressed: onStartGame,
      child: Text(AppLanguage.getText('startGame')),
    );
  }
} 