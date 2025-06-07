import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';
import '../common/poker_card.dart';

/// Hi/Low 게임의 커뮤니티 카드 게임 보드 위젯
class HiLowGameBoard extends StatelessWidget {
  final List<String> communityCards;

  const HiLowGameBoard({
    Key? key,
    required this.communityCards,
  }) : super(key: key);

  String getText(String key) => AppLanguage.getText(key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            getText('communityCards'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: communityCards
                .map((card) => PokerCard(
                      card: card,
                      size: 50,
                      margin: 4,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
} 