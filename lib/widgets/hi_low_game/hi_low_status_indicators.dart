import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';
import '../common/game_status_bar.dart';

/// Hi/Low 게임의 현재 선택 모드를 표시하는 위젯
class HiLowSelectionModeIndicator extends StatelessWidget {
  final bool isSelectingHigh;
  final bool isGameStarted;
  final int? selectedHighWinnerIndex;
  final List<int> selectedLowWinnerIndices;

  const HiLowSelectionModeIndicator({
    Key? key,
    required this.isSelectingHigh,
    required this.isGameStarted,
    this.selectedHighWinnerIndex,
    required this.selectedLowWinnerIndices,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 선택이 완료된 경우 표시하지 않음
    if (!isGameStarted || 
        (selectedHighWinnerIndex != null && selectedLowWinnerIndices.isNotEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelectingHigh 
            ? Colors.amber.withAlpha((0.7 * 255).round()) 
            : Colors.green.withAlpha((0.7 * 255).round()),
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
    );
  }
}

/// Low 핸드에 여러 승자가 있을 때 추가 선택 안내 위젯
class HiLowMultiSelectionGuide extends StatelessWidget {
  final bool isGameStarted;
  final bool isSelectingHigh;
  final List<int> actualLowWinnerIndices;
  final List<int> selectedLowWinnerIndices;

  const HiLowMultiSelectionGuide({
    Key? key,
    required this.isGameStarted,
    required this.isSelectingHigh,
    required this.actualLowWinnerIndices,
    required this.selectedLowWinnerIndices,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 조건에 맞지 않으면 표시하지 않음
    if (!isGameStarted || 
        isSelectingHigh || 
        actualLowWinnerIndices.length <= 1 ||
        selectedLowWinnerIndices.isEmpty ||
        selectedLowWinnerIndices.length >= actualLowWinnerIndices.length) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha((0.7 * 255).round()),
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
    );
  }
}

/// Hi/Low 게임 결과 메시지 위젯
class HiLowResultMessage extends StatelessWidget {
  final String winnerText;

  const HiLowResultMessage({
    Key? key,
    required this.winnerText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (winnerText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withAlpha((0.2 * 255).round()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            blurRadius: 4,
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
    );
  }
} 