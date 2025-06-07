import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../common/poker_card.dart';
import '../common/game_background.dart';

/// Hi/Low 게임의 플레이어 카드 그리드 위젯
class HiLowPlayerGrid extends StatelessWidget {
  final List<Player> players;
  final int numberOfPlayers;
  final bool isSelectingHigh;
  final int? selectedHighWinnerIndex;
  final List<int> selectedLowWinnerIndices;
  final int? actualHighWinnerIndex;
  final Function(int) onHighWinnerTap;
  final Function(int) onLowWinnerTap;

  const HiLowPlayerGrid({
    Key? key,
    required this.players,
    required this.numberOfPlayers,
    required this.isSelectingHigh,
    this.selectedHighWinnerIndex,
    required this.selectedLowWinnerIndices,
    this.actualHighWinnerIndex,
    required this.onHighWinnerTap,
    required this.onLowWinnerTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
          
          bool isSelected = false;
          bool isCorrect = false;
          bool isWrong = false;
          
          if (isSelectingHigh) {
            isSelected = isHighSelected;
            isCorrect = isHighCorrect;
          } else {
            isSelected = isLowSelected;
          }
          
          return PlayerCardContainer(
            isSelected: isSelected,
            isCorrect: isCorrect,
            isWrong: isWrong,
            onTap: () {
              if (isSelectingHigh) {
                onHighWinnerTap(index);
              } else {
                onLowWinnerTap(index);
              }
            },
            child: Stack(
              children: [
                Column(
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
                          .map((card) => PokerCard(
                                card: card,
                                size: 36,
                                margin: 0,
                              ))
                          .toList(),
                    ),
                  ],
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
    );
  }
} 