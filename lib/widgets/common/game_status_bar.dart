import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';

/// 게임 상태 정보를 표시하는 위젯
///
/// 스코어, 타이머, 플레이어 수 등의 정보를 일관된 스타일로 표시합니다.
class GameStatusBar extends StatelessWidget {
  final int? score;
  final int? remainingTime;
  final int? playerCount;
  final String? customStatus;
  final bool isSmallScreen;
  final Color textColor;
  final MainAxisAlignment alignment;

  const GameStatusBar({
    Key? key,
    this.score,
    this.remainingTime,
    this.playerCount,
    this.customStatus,
    this.isSmallScreen = false,
    this.textColor = Colors.white,
    this.alignment = MainAxisAlignment.spaceBetween,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontSize = isSmallScreen ? 16.0 : 18.0;
    final List<Widget> statusItems = [];

    // 스코어 표시
    if (score != null) {
      statusItems.add(
        _buildStatusItem(
          '${AppLanguage.getText("score")}: $score',
          fontSize,
        ),
      );
    }

    // 플레이어 수 표시
    if (playerCount != null) {
      statusItems.add(
        _buildStatusItem(
          '${AppLanguage.getText("playerCount")}: $playerCount',
          fontSize,
        ),
      );
    }

    // 커스텀 상태 표시
    if (customStatus != null) {
      statusItems.add(
        _buildStatusItem(
          customStatus!,
          fontSize,
        ),
      );
    }

    // 타이머 표시 (맨 오른쪽에 배치)
    if (remainingTime != null) {
      final isUrgent = remainingTime! <= 10;
      statusItems.add(
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildStatusItem(
              '${AppLanguage.getText("remainingTime")}: $remainingTime ${AppLanguage.getText("seconds")}',
              fontSize,
              color: isUrgent ? Colors.redAccent : textColor,
              hasWarning: isUrgent,
            ),
          ),
        ),
      );
    }

    if (statusItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: statusItems,
      ),
    );
  }

  Widget _buildStatusItem(
    String text,
    double fontSize, {
    Color? color,
    bool hasWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasWarning 
            ? Colors.red.withOpacity(0.2)
            : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: hasWarning 
            ? Border.all(color: Colors.redAccent, width: 1)
            : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: hasWarning ? [] : [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// 게임 진행 단계를 표시하는 위젯
class GameProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final Color progressColor;
  final Color backgroundColor;
  final bool isSmallScreen;

  const GameProgressBar({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels = const [],
    this.progressColor = Colors.amber,
    this.backgroundColor = Colors.grey,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 진행률 바
          Container(
            height: isSmallScreen ? 6 : 8,
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: currentStep / totalSteps,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          
          // 단계 표시
          Text(
            '$currentStep / $totalSteps',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // 단계 라벨 표시 (옵션)
          if (stepLabels.isNotEmpty && currentStep <= stepLabels.length)
            Text(
              stepLabels[currentStep - 1],
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: isSmallScreen ? 10 : 12,
              ),
            ),
        ],
      ),
    );
  }
}

/// 게임 결과 메시지를 표시하는 위젯
class GameResultMessage extends StatelessWidget {
  final String message;
  final GameResultType type;
  final bool isSmallScreen;
  final VoidCallback? onDismiss;

  const GameResultMessage({
    Key? key,
    required this.message,
    required this.type,
    this.isSmallScreen = false,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    switch (type) {
      case GameResultType.success:
        backgroundColor = Colors.green.withOpacity(0.9);
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case GameResultType.error:
        backgroundColor = Colors.red.withOpacity(0.9);
        textColor = Colors.white;
        icon = Icons.cancel;
        break;
      case GameResultType.warning:
        backgroundColor = Colors.orange.withOpacity(0.9);
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      case GameResultType.info:
        backgroundColor = Colors.blue.withOpacity(0.9);
        textColor = Colors.white;
        icon = Icons.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: textColor,
              size: isSmallScreen ? 20 : 24,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: textColor,
                size: isSmallScreen ? 18 : 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 게임 결과 타입 열거형
enum GameResultType {
  success,
  error,
  warning,
  info,
} 