import 'package:flutter/material.dart';
import '../../models/player.dart';
import 'dart:math';

/// 플레이어 카드 위젯
/// 
/// 각 플레이어의 정보와 액션 히스토리를 표시하는 위젯입니다.
class PlayerCardWidget extends StatefulWidget {
  final Player player;
  final int index;
  final List<String> actionHistory;
  final int initialChips;
  final double screenWidth;
  final double screenHeight;
  final double boxWidth;
  final double boxHeight;
  final bool isSmallScreen;
  final double fontScale;
  final String Function(int) formatAmount;
  final bool showPotAnimation;
  final int potAnimationPlayerId;

  const PlayerCardWidget({
    Key? key,
    required this.player,
    required this.index,
    required this.actionHistory,
    required this.initialChips,
    required this.screenWidth,
    required this.screenHeight,
    required this.boxWidth,
    required this.boxHeight,
    required this.isSmallScreen,
    required this.fontScale,
    required this.formatAmount,
    this.showPotAnimation = false,
    this.potAnimationPlayerId = -1,
  }) : super(key: key);

  @override
  State<PlayerCardWidget> createState() => _PlayerCardWidgetState();
}

class _PlayerCardWidgetState extends State<PlayerCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -0.05), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: -0.05, end: 0), weight: 60),
    ]).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    
    _colorAnimation = ColorTween(
      begin: Colors.white.withOpacity(0.10),
      end: Colors.amber.withOpacity(0.50),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(PlayerCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 이 플레이어가 POT 액션을 수행했고 애니메이션이 활성화되었을 때만 재생
    if (widget.showPotAnimation && widget.potAnimationPlayerId == widget.index && 
        (!oldWidget.showPotAnimation || oldWidget.potAnimationPlayerId != widget.index)) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarHeight = AppBar().preferredSize.height;
    final safeTop = MediaQuery.of(context).padding.top;
    final minY = appBarHeight + safeTop + widget.boxHeight / 2;
    final maxY = widget.screenHeight - widget.boxHeight / 2;
    
    final numberOfPlayers = 6; // TODO: 파라미터로 받도록 수정
    final angleOffset = numberOfPlayers == 5 ? 90 : 90;
    final radius = widget.screenWidth * 0.35;
    final adjAngle = (widget.index * (360 / numberOfPlayers) + angleOffset) * (3.14159 / 180);
    final adjRadius = radius * 1.15;
    final adjX = widget.screenWidth / 2 + adjRadius * cos(adjAngle);
    final adjY = (widget.screenHeight * 0.3) + appBarHeight + adjRadius * sin(adjAngle) * 0.9;
    
    final maxX = widget.screenWidth - 1;
    final clampedX = adjX.clamp(1.0, maxX - 1);
    final clampedY = adjY.clamp(minY, maxY);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          left: clampedX - widget.boxWidth / 2,
          top: clampedY - widget.boxHeight / 2,
          child: Transform.scale(
            scale: widget.showPotAnimation && widget.potAnimationPlayerId == widget.index 
                ? _scaleAnimation.value 
                : 1.0,
            child: Transform.rotate(
              angle: widget.showPotAnimation && widget.potAnimationPlayerId == widget.index 
                  ? _rotateAnimation.value 
                  : 0.0,
              child: Container(
                width: widget.boxWidth,
                height: widget.boxHeight,
                decoration: BoxDecoration(
                  color: widget.showPotAnimation && widget.potAnimationPlayerId == widget.index 
                      ? _colorAnimation.value 
                      : Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.showPotAnimation && widget.potAnimationPlayerId == widget.index
                          ? Colors.amber.withOpacity(0.5)
                          : Colors.black.withOpacity(0.18),
                      blurRadius: widget.showPotAnimation && widget.potAnimationPlayerId == widget.index
                          ? 18
                          : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: widget.showPotAnimation && widget.potAnimationPlayerId == widget.index
                        ? Colors.amber.withOpacity(0.8)
                        : Colors.transparent,
                    width: widget.showPotAnimation && widget.potAnimationPlayerId == widget.index
                        ? 2
                        : 0,
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.player.positionName,
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: widget.screenWidth * (widget.isSmallScreen ? 0.025 : (widget.screenWidth < 500 ? 0.03 : 0.04)) * widget.fontScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.formatAmount(widget.initialChips),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.screenWidth * (widget.isSmallScreen ? 0.03 : (widget.screenWidth < 500 ? 0.035 : 0.045)) * widget.fontScale,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      if (widget.player.isAllIn)
                        _buildActionBadge('ALL-IN', Colors.yellow.withOpacity(0.8), Colors.black),
                      if (widget.actionHistory.isNotEmpty)
                        _buildActionHistoryContainer(),
                      // POT 애니메이션 활성화 시 추가 효과
                      if (widget.showPotAnimation && widget.potAnimationPlayerId == widget.index)
                        _buildPotAnimationEffect(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// POT 애니메이션 효과
  Widget _buildPotAnimationEffect() {
    return Container(
      margin: EdgeInsets.only(top: widget.isSmallScreen ? 4 : 8),
      padding: EdgeInsets.symmetric(
        horizontal: widget.isSmallScreen ? 8 : 12, 
        vertical: widget.isSmallScreen ? 4 : 6
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        'POT!',
        style: TextStyle(
          color: Colors.black,
          fontSize: widget.screenWidth * (widget.isSmallScreen ? 0.036 : 0.042) * widget.fontScale,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// 액션 배지 위젯 (ALL-IN 등)
  Widget _buildActionBadge(String text, Color bgColor, Color textColor) {
    return Container(
      margin: EdgeInsets.only(top: widget.isSmallScreen ? 4 : 8),
      padding: EdgeInsets.symmetric(
        horizontal: widget.isSmallScreen ? 6 : 10, 
        vertical: widget.isSmallScreen ? 3 : 5
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: widget.screenWidth * (widget.isSmallScreen ? 0.025 : 0.03) * widget.fontScale,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 액션 히스토리 컨테이너
  Widget _buildActionHistoryContainer() {
    return Container(
      margin: EdgeInsets.only(top: widget.isSmallScreen ? 4 : 8),
      padding: EdgeInsets.symmetric(
        horizontal: widget.isSmallScreen ? 6 : 10, 
        vertical: widget.isSmallScreen ? 3 : 5
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: widget.actionHistory.map((action) {
          return Text(
            action,
            style: TextStyle(
              color: action.contains('FOLD')
                  ? Colors.redAccent
                  : action.contains('POT!')
                      ? Colors.amber
                      : Colors.lightGreenAccent,
              fontSize: widget.screenWidth * (widget.isSmallScreen ? 0.022 : (widget.screenWidth < 500 ? 0.025 : 0.03)) * widget.fontScale,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
      ),
    );
  }
} 