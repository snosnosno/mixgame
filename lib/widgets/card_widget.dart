import 'package:flutter/material.dart';

class CardWidget extends StatelessWidget {
  final String card;
  final double width;
  final double height;

  const CardWidget({
    Key? key,
    required this.card,
    this.width = 50,
    this.height = 70,
  }) : super(key: key);

  String _convertCard(String card) {
    return card.replaceAll('10', '0');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Image.network(
        'https://deckofcardsapi.com/static/img/${_convertCard(card)}.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}

class OverlappedCards extends StatelessWidget {
  final List<String> cards;
  final double cardWidth;
  final double cardHeight;
  final double overlapRatio;

  const OverlappedCards({
    Key? key,
    required this.cards,
    required this.cardWidth,
    required this.cardHeight,
    this.overlapRatio = 0.4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(cards.length, (index) {
        return Positioned(
          left: index * (cardWidth * overlapRatio),
          child: CardWidget(
            card: cards[index],
            width: cardWidth,
            height: cardHeight,
          ),
        );
      }),
    );
  }
} 