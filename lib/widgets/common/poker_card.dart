import 'package:flutter/material.dart';

/// 포커 카드 표시 위젯
///
/// 카드의 크기, 스타일, 표시 방식을 커스터마이징할 수 있습니다.
class PokerCard extends StatelessWidget {
  final String card;
  final double size;
  final double margin;
  final bool isNetworkImage;
  final bool isSelected;
  final VoidCallback? onTap;

  const PokerCard({
    Key? key,
    required this.card,
    this.size = 50,
    this.margin = 2,
    this.isNetworkImage = false,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = isNetworkImage 
        ? _buildNetworkCard() 
        : _buildTextCard();

    if (onTap != null) {
      cardWidget = GestureDetector(
        onTap: onTap,
        child: cardWidget,
      );
    }

    return Container(
      margin: EdgeInsets.all(margin),
      decoration: isSelected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.1 + 2),
              border: Border.all(
                color: Colors.amber,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            )
          : null,
      child: cardWidget,
    );
  }

  Widget _buildNetworkCard() {
    String convertedCard = card.replaceAll('10', '0');
    
    return Container(
      width: size,
      height: size * 1.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.1),
        child: Image.network(
          'https://deckofcardsapi.com/static/img/$convertedCard.png',
          width: size,
          height: size * 1.4,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // 네트워크 이미지 로드 실패 시 텍스트 카드로 대체
            return _buildTextCard();
          },
        ),
      ),
    );
  }

  Widget _buildTextCard() {
    final cardInfo = _parseCard(card);
    
    return Container(
      width: size,
      height: size * 1.4,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 왼쪽 상단 랭크
          Positioned(
            top: 2,
            left: 4,
            child: Text(
              cardInfo.rank,
              style: TextStyle(
                color: cardInfo.color,
                fontSize: size * 0.3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 중앙 수트 심볼
          Center(
            child: Text(
              cardInfo.suitSymbol,
              style: TextStyle(
                color: cardInfo.color,
                fontSize: size * 0.5,
              ),
            ),
          ),
          // 오른쪽 하단 랭크 (뒤집어서)
          Positioned(
            bottom: 2,
            right: 4,
            child: Transform.rotate(
              angle: 3.14159, // 180도 회전
              child: Text(
                cardInfo.rank,
                style: TextStyle(
                  color: cardInfo.color,
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  CardInfo _parseCard(String card) {
    if (card.isEmpty) {
      return CardInfo('', '', Colors.black, '');
    }

    String suit = card.substring(card.length - 1);
    String rank = card.substring(0, card.length - 1);
    
    Color suitColor;
    String suitSymbol;
    
    switch (suit.toUpperCase()) {
      case 'S':
        suitColor = Colors.black;
        suitSymbol = '♠';
        break;
      case 'H':
        suitColor = Colors.red;
        suitSymbol = '♥';
        break;
      case 'D':
        suitColor = Colors.red;
        suitSymbol = '♦';
        break;
      case 'C':
        suitColor = Colors.black;
        suitSymbol = '♣';
        break;
      default:
        suitColor = Colors.black;
        suitSymbol = '';
    }
    
    return CardInfo(rank, suit, suitColor, suitSymbol);
  }
}

/// 겹쳐진 카드들을 표시하는 위젯
class OverlappedCards extends StatelessWidget {
  final List<String> cards;
  final double cardSize;
  final double overlapRatio;
  final bool isNetworkImage;
  final Function(int)? onCardTap;

  const OverlappedCards({
    Key? key,
    required this.cards,
    this.cardSize = 50,
    this.overlapRatio = 0.5,
    this.isNetworkImage = false,
    this.onCardTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    
    final cardWidth = cardSize;
    final cardHeight = cardSize * 1.4;
    final totalWidth = cardWidth + (cards.length - 1) * cardWidth * overlapRatio;

    return SizedBox(
      width: totalWidth,
      height: cardHeight,
      child: Stack(
        children: [
          for (int i = 0; i < cards.length; i++)
            Positioned(
              left: i * cardWidth * overlapRatio,
              child: PokerCard(
                card: cards[i],
                size: cardSize,
                margin: 1,
                isNetworkImage: isNetworkImage,
                onTap: onCardTap != null ? () => onCardTap!(i) : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// 카드 정보를 담는 클래스
class CardInfo {
  final String rank;
  final String suit;
  final Color color;
  final String suitSymbol;

  CardInfo(this.rank, this.suit, this.color, this.suitSymbol);
} 