import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';
import '../../models/replay_round.dart';
import '../../services/winner_game_service.dart';

/// Winner 게임 보드 위젯
///
/// 커뮤니티 카드와 플레이어 카드를 표시하는 게임 보드입니다.
class WinnerGameBoard extends StatelessWidget {
  final List<String> communityCards;
  final List<List<String>> playerHands;
  final int numberOfPlayers;
  final int? selectedWinnerIndex;
  final ReplayRound? replayingRound;
  final Function(int)? onPlayerTap;
  final double screenWidth;

  const WinnerGameBoard({
    Key? key,
    required this.communityCards,
    required this.playerHands,
    required this.numberOfPlayers,
    this.selectedWinnerIndex,
    this.replayingRound,
    this.onPlayerTap,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 화면 크기에 따른 반응형 설정
    final isMobile = screenWidth < 600;
    int crossAxisCount = 2;
    double aspectRatio = isMobile ? 1.35 : 1.9;
    
    if (numberOfPlayers <= 4) {
      crossAxisCount = 2; // 2x2
      aspectRatio = isMobile ? 1.35 : 1.9;
    } else {
      crossAxisCount = 2; // 2x3
      aspectRatio = isMobile ? 1.35 : 1.75;
    }

    // 카드 크기 계산
    final cardSizes = _calculateCardSizes(screenWidth, crossAxisCount, isMobile);

    return Column(
      children: [
        // 커뮤니티 카드 영역
        _buildCommunityCards(cardSizes),
        
        const SizedBox(height: 8),
        
        // 플레이어 그리드
        Flexible(
          fit: FlexFit.loose,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 16,
              mainAxisSpacing: 4,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: numberOfPlayers,
            itemBuilder: (context, index) {
              return _buildPlayerCard(index, cardSizes);
            },
          ),
        ),
      ],
    );
  }

  /// 커뮤니티 카드 영역을 빌드합니다.
  Widget _buildCommunityCards(CardSizes cardSizes) {
    final cards = replayingRound != null 
        ? replayingRound!.communityCards 
        : communityCards;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Column(
        children: [
          Text(
            AppLanguage.getText('communityCards'),
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: Colors.amber
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: cards
                .map((card) => _buildOverlappedCards(
                      [card], 
                      cardSizes.width, 
                      cardSizes.height, 
                      cardSizes.overlapRatio
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// 플레이어 카드를 빌드합니다.
  Widget _buildPlayerCard(int index, CardSizes cardSizes) {
    final isReplay = replayingRound != null;
    final hands = isReplay ? replayingRound!.playerHands : playerHands;
    final selIdx = isReplay 
        ? replayingRound!.selectedWinnerIndex 
        : selectedWinnerIndex;

    final cardWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: selIdx == index
            ? Colors.deepPurpleAccent.withAlpha((0.18 * 255).round())
            : Colors.white.withAlpha((0.13 * 255).round()),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.18 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: selIdx == index
              ? Colors.deepPurpleAccent.withAlpha((0.8 * 255).round())
              : Colors.white.withAlpha((0.18 * 255).round()),
          width: selIdx == index ? 2.5 : 1.2,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'Player ${index + 1}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 2),
          _buildOverlappedCards(
            hands[index], 
            cardSizes.width, 
            cardSizes.height, 
            cardSizes.overlapRatio
          ),
        ],
      ),
    );

    if (!isReplay && onPlayerTap != null) {
      return GestureDetector(
        onTap: () => onPlayerTap!(index),
        child: cardWidget,
      );
    } else {
      return cardWidget;
    }
  }

  /// 겹쳐진 카드들을 빌드합니다.
  Widget _buildOverlappedCards(
    List<String> cards, 
    double cardWidth, 
    double cardHeight, 
    double overlapRatio
  ) {
    return SizedBox(
      width: cardWidth + (cards.length - 1) * cardWidth * overlapRatio,
      height: cardHeight,
      child: Stack(
        children: [
          for (int i = 0; i < cards.length; i++)
            Positioned(
              left: i * cardWidth * overlapRatio,
              child: _buildCardImageWithSize(cards[i], cardWidth, cardHeight),
            ),
        ],
      ),
    );
  }

  /// 카드 이미지를 빌드합니다.
  Widget _buildCardImageWithSize(String card, double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Image.network(
        'https://deckofcardsapi.com/static/img/${WinnerGameService.convertCardForImage(card)}.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // 네트워크 이미지 로드 실패 시 플레이스홀더
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: Text(
                card,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 카드 크기를 계산합니다.
  CardSizes _calculateCardSizes(double screenWidth, int crossAxisCount, bool isMobile) {
    double horizontalPadding = 16 * 2; // GridView 좌우 패딩
    double crossAxisSpacing = 16.0;
    double cellWidth = (screenWidth - horizontalPadding - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
    
    double overlapRatio = 0.5;
    int cardCount = 4;
    
    double cardWidth = cellWidth / (1 + (cardCount - 1) * overlapRatio);
    double cardHeight = cardWidth * 1.4;
    
    // 모바일에서 너무 크면 제한
    if (isMobile && cardWidth > 60) cardWidth = 60;
    if (isMobile && cardHeight > 84) cardHeight = 84;

    return CardSizes(
      width: cardWidth,
      height: cardHeight,
      overlapRatio: overlapRatio,
    );
  }
}

/// 카드 크기 정보
class CardSizes {
  final double width;
  final double height;
  final double overlapRatio;

  CardSizes({
    required this.width,
    required this.height,
    required this.overlapRatio,
  });
} 