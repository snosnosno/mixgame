import 'dart:math';
import 'package:flutter/material.dart';
import 'package:random_card/models/player.dart';

class PlayerPositionWidget extends StatelessWidget {
  final Player player;
  final int index;
  final int smallBlind;
  final int bigBlind;
  final List<String> actionHistory;
  final int initialChips;
  final double screenWidth;

  const PlayerPositionWidget({
    Key? key,
    required this.player,
    required this.index,
    required this.smallBlind,
    required this.bigBlind,
    required this.actionHistory,
    required this.initialChips,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final angle = (index * 60 - 90) * (pi / 180);
    final radius = MediaQuery.of(context).size.width * 0.35;
    final x = MediaQuery.of(context).size.width / 2 + radius * cos(angle);
    final y = MediaQuery.of(context).size.height / 2 + radius * sin(angle);

    return Positioned(
      left: x - 80,
      top: y - 80,
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: player.isFolded 
              ? Colors.black.withOpacity(0.3) 
              : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: _getBorderColor(),
            width: index == 0 || index == 1 ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Player ${index + 1}',
              style: TextStyle(
                color: player.isFolded ? Colors.white.withOpacity(0.5) : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              player.positionName,
              style: TextStyle(
                color: Colors.amber,
                fontSize: screenWidth * (screenWidth < 500 ? 0.03 : 0.04),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              initialChips.toString(),
              style: TextStyle(
                color: player.isFolded ? Colors.white.withOpacity(0.5) : Colors.white,
                fontSize: screenWidth * (screenWidth < 500 ? 0.035 : 0.045),
                fontWeight: FontWeight.bold,
                fontFamily: 'RobotoMono',
              ),
            ),
            _buildPositionInfo(),
            if (player.isAllIn) _buildAllInTag(),
            if (actionHistory.isNotEmpty) _buildActionHistory(),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    if (index == 0) return Colors.yellow;
    if (index == 1) return Colors.red;
    return Colors.white.withOpacity(0.3);
  }

  Widget _buildPositionInfo() {
    if (index == 0) {
      return Text(
        'SB: $smallBlind',
        style: const TextStyle(color: Colors.yellow),
      );
    } else if (index == 1) {
      return Text(
        'BB: $bigBlind',
        style: const TextStyle(color: Colors.red),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAllInTag() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'ALL-IN',
        style: TextStyle(
          color: Colors.black,
          fontSize: screenWidth * 0.03,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionHistory() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: actionHistory.map((action) {
          return Text(
            action,
            style: TextStyle(
              color: _getActionColor(action),
              fontSize: screenWidth * (screenWidth < 500 ? 0.025 : 0.03),
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getActionColor(String action) {
    if (action.contains('FOLD')) return Colors.redAccent;
    if (action.contains('POT!')) return Colors.amber;
    return Colors.lightGreenAccent;
  }
} 