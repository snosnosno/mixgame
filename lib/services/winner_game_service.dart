import 'dart:math';
import '../models/card.dart' as poker;
import '../models/hand_rank.dart';
import '../models/player.dart';

/// Winner 게임의 승자 판별 서비스
///
/// PLO 포커 게임에서 승자를 판별하고 핸드를 평가하는 로직을 담당합니다.
class WinnerGameService {
  /// PLO 조합 생성 (2장의 홀 카드 + 3장의 커뮤니티 카드)
  static List<List<String>> generatePLOCombinations(
    List<String> holeCards, 
    List<String> communityCards
  ) {
    final holeComb = _combinations(holeCards, 2);
    final communityComb = _combinations(communityCards, 3);
    List<List<String>> allHands = [];

    for (var h in holeComb) {
      for (var c in communityComb) {
        var hand = [...h, ...c];
        hand.sort((a, b) {
          var rankA = poker.Card.fromString(a).rank.index;
          var rankB = poker.Card.fromString(b).rank.index;
          return rankA.compareTo(rankB);
        });
        allHands.add(hand);
      }
    }
    return allHands;
  }

  /// 주어진 플레이어들과 커뮤니티 카드로 승자를 평가
  static WinnerEvaluationResult evaluateWinner(
    List<Player> players, 
    List<String> communityCards, 
    int numberOfPlayers
  ) {
    List<List<String>> playerHands = 
        players.take(numberOfPlayers).map((p) => p.hand).toList();
    
    String bestHand = '';
    int highestRank = 0;
    int highestSecondaryRank = 0;
    int winnerIndex = -1;
    String winningHandDescription = '';

    for (int i = 0; i < playerHands.length; i++) {
      var hands = generatePLOCombinations(playerHands[i], communityCards);
      String currentBestHand = '';
      int currentRank = 0;
      int currentSecondaryRank = 0;
      List<poker.Card> bestHandCards = [];

      for (var hand in hands) {
        var cards = hand.map((card) => poker.Card.fromString(card)).toList();
        var handRankObj = HandRank.evaluate(cards);

        if (handRankObj.value > currentRank ||
            (handRankObj.value == currentRank &&
                handRankObj.secondaryValue > currentSecondaryRank)) {
          currentRank = handRankObj.value;
          currentSecondaryRank = handRankObj.secondaryValue;
          currentBestHand = handRankObj.name;
          bestHandCards = cards;
        }
      }

      if (currentRank > highestRank ||
          (currentRank == highestRank &&
              currentSecondaryRank > highestSecondaryRank)) {
        highestRank = currentRank;
        highestSecondaryRank = currentSecondaryRank;
        winnerIndex = i;
        bestHand = currentBestHand;
        winningHandDescription = _getHandDescription(bestHandCards);
      }
    }

    return WinnerEvaluationResult(
      winnerIndex: winnerIndex,
      handName: bestHand,
      handDescription: winningHandDescription,
      winnerHandInfo: '$bestHand\n$winningHandDescription',
    );
  }

  /// 새 게임을 위한 카드 딜링
  static GameDealResult dealNewGame(List<Player> players, int numberOfPlayers) {
    const deck = [
      'AS', '2S', '3S', '4S', '5S', '6S', '7S', '8S', '9S', '10S', 'JS', 'QS', 'KS',
      'AH', '2H', '3H', '4H', '5H', '6H', '7H', '8H', '9H', '10H', 'JH', 'QH', 'KH',
      'AD', '2D', '3D', '4D', '5D', '6D', '7D', '8D', '9D', '10D', 'JD', 'QD', 'KD',
      'AC', '2C', '3C', '4C', '5C', '6C', '7C', '8C', '9C', '10C', 'JC', 'QC', 'KC'
    ];

    final random = Random();
    final shuffledDeck = List<String>.from(deck)..shuffle(random);

    final communityCards = shuffledDeck.sublist(0, 5);
    
    for (int i = 0; i < numberOfPlayers; i++) {
      players[i].hand = shuffledDeck.sublist(5 + i * 4, 5 + (i + 1) * 4);
    }

    return GameDealResult(
      communityCards: communityCards,
      players: players,
    );
  }

  /// 플레이어 초기화
  static List<Player> initializePlayers() {
    final random = Random();
    return List.generate(
      6,
      (index) => Player(
        name: 'Player ${index + 1}',
        chips: (random.nextInt(4996) * 100) + 500,
        hand: [],
        position: Position.values[index % Position.values.length],
      ),
    );
  }

  /// 카드를 이미지 API 형식으로 변환
  static String convertCardForImage(String card) {
    return card.replaceAll('10', '0');
  }

  /// 조합 생성 함수 (내부용)
  static List<List<T>> _combinations<T>(List<T> items, int r) {
    if (r == 0) return [[]];
    if (items.isEmpty) return [];

    List<List<T>> result = [];
    for (int i = 0; i <= items.length - r; i++) {
      var head = items[i];
      var tailCombos = _combinations(items.sublist(i + 1), r - 1);
      for (var tailCombo in tailCombos) {
        result.add([head, ...tailCombo]);
      }
    }
    return result;
  }

  /// 핸드 설명 생성
  static String _getHandDescription(List<poker.Card> cards) {
    cards.sort((a, b) => b.rank.index.compareTo(a.rank.index));
    List<String> cardStrs = cards.map((card) {
      String rankStr = _getRankString(card.rank);
      String suitStr = _getSuitString(card.suit);
      return '$rankStr$suitStr';
    }).toList();
    return cardStrs.join(' ');
  }

  /// 랭크를 문자열로 변환
  static String _getRankString(poker.Rank rank) {
    switch (rank) {
      case poker.Rank.ace:
        return 'A';
      case poker.Rank.king:
        return 'K';
      case poker.Rank.queen:
        return 'Q';
      case poker.Rank.jack:
        return 'J';
      case poker.Rank.ten:
        return '10';
      default:
        return (rank.index + 2).toString();
    }
  }

  /// 슈트를 문자열로 변환
  static String _getSuitString(poker.Suit suit) {
    switch (suit) {
      case poker.Suit.spades:
        return '♠';
      case poker.Suit.hearts:
        return '♥';
      case poker.Suit.diamonds:
        return '♦';
      case poker.Suit.clubs:
        return '♣';
      default:
        return '';
    }
  }
}

/// 승자 평가 결과
class WinnerEvaluationResult {
  final int winnerIndex;
  final String handName;
  final String handDescription;
  final String winnerHandInfo;

  WinnerEvaluationResult({
    required this.winnerIndex,
    required this.handName,
    required this.handDescription,
    required this.winnerHandInfo,
  });
}

/// 게임 딜링 결과
class GameDealResult {
  final List<String> communityCards;
  final List<Player> players;

  GameDealResult({
    required this.communityCards,
    required this.players,
  });
} 