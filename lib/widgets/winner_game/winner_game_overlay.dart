import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';
import '../../models/replay_round.dart';

/// Winner 게임 오버레이 위젯
///
/// 타이머, 결과 메시지, 리뷰 로그, 저작권 등을 표시합니다.
class WinnerGameOverlay extends StatelessWidget {
  final bool isGameStarted;
  final int remainingTime;
  final String winnerText;
  final int? selectedWinnerIndex;
  final int? actualWinnerIndex;
  final List<String> roundLogs;
  final List<ReplayRound> replayRounds;
  final ReplayRound? replayingRound;
  final Function(int) onReplayRoundTap;
  final VoidCallback onExitReplay;

  const WinnerGameOverlay({
    Key? key,
    required this.isGameStarted,
    required this.remainingTime,
    required this.winnerText,
    this.selectedWinnerIndex,
    this.actualWinnerIndex,
    required this.roundLogs,
    required this.replayRounds,
    this.replayingRound,
    required this.onReplayRoundTap,
    required this.onExitReplay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 게임 타이머 (게임 진행 중일 때)
        if (isGameStarted)
          _buildGameTimer(),
        
        // 결과 메시지
        if (winnerText.isNotEmpty)
          _buildWinnerMessage(),
          
        // 리플레이 종료 버튼
        if (replayingRound != null)
          _buildExitReplayButton(),
          
        // 리뷰 로그 (하단)
        if (roundLogs.isNotEmpty)
          _buildReviewLog(),
          
        // 저작권 표시
        _buildCopyright(),
      ],
    );
  }

  /// 게임 타이머를 빌드합니다.
  Widget _buildGameTimer() {
    return Positioned(
      top: 8,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((0.4 * 255).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withAlpha((0.2 * 255).round()),
            width: 1,
          ),
        ),
        child: Text(
          '${AppLanguage.getText("remainingTime")} $remainingTime ${AppLanguage.getText("seconds")}',
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
    );
  }

  /// 승자 메시지를 빌드합니다.
  Widget _buildWinnerMessage() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: roundLogs.isNotEmpty ? 140 : 60,
      child: Padding(
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
    );
  }

  /// 리플레이 종료 버튼을 빌드합니다.
  Widget _buildExitReplayButton() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: roundLogs.isNotEmpty ? 140 : 60,
      child: Center(
        child: Padding(
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
            onPressed: onExitReplay,
            icon: const Icon(Icons.exit_to_app),
            label: Text(AppLanguage.getText('endReplay')),
          ),
        ),
      ),
    );
  }

  /// 리뷰 로그를 빌드합니다.
  Widget _buildReviewLog() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 140,
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
                  '↓↓${AppLanguage.getText("review")}↓↓',
                  style: const TextStyle(
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
                  String handInfo = '';
                  if (replayRounds.length > (roundLogs.length - 1 - idx)) {
                    final rr = replayRounds[roundLogs.length - 1 - idx];
                    if (rr.winnerText.isNotEmpty) {
                      handInfo = '\n${AppLanguage.getText("winningHand")}: ' + rr.winnerText.split('\n').last;
                    }
                  }
                  return InkWell(
                    onTap: () {
                      if (replayRounds.length > (roundLogs.length - 1 - idx)) {
                        onReplayRoundTap(roundLogs.length - 1 - idx);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                      child: Text(
                        log + handInfo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 저작권 표시를 빌드합니다.
  Widget _buildCopyright() {
    return Positioned(
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
    );
  }
} 