import 'dart:math';
import 'package:random_card/models/card.dart';
import 'package:random_card/models/hand_rank.dart';

class HandEvaluator {
  static String evaluateWinner(
    List<List<String>> playerHands,
    List<String> communityCards,
  ) {
    int bestHandRank = 0;
    int bestSecondaryRank = 0;
    int winnerIndex = -1;
    String winnerHandDescription = '';
    String bestHandName = '';

    for (int i = 0; i < playerHands.length; i++) {
      var hands = generatePLOCombinations(playerHands[i], communityCards);
      String currentBestHand = '';
      int currentRank = 0;
      int currentSecondaryRank = 0;
      List<Card> bestHandCards = [];

      for (var hand in hands) {
        var cards = hand.map((card) => Card.fromString(card)).toList();
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

      if (currentRank > bestHandRank ||
          (currentRank == bestHandRank &&
              currentSecondaryRank > bestSecondaryRank)) {
        bestHandRank = currentRank;
        bestSecondaryRank = currentSecondaryRank;
        winnerIndex = i;
        bestHandName = currentBestHand;
        winningHandDescription = getHandDescription(bestHandCards);
      }
    }

    return '$bestHandName\n$winningHandDescription';
  }

  static String getHandDescription(List<Card> cards) {
    cards.sort((a, b) => b.rank.index.compareTo(a.rank.index));
    List<String> cardStrs = cards.map((card) {
      String rankStr = getRankString(card.rank);
      String suitStr = getSuitSymbol(card.suit);
      return '$rankStr$suitStr';
    }).toList();
    return cardStrs.join(' ');
  }

  static String getRankString(Rank rank) {
    switch (rank) {
      case Rank.ace:
        return 'A';
      case Rank.king:
        return 'K';
      case Rank.queen:
        return 'Q';
      case Rank.jack:
        return 'J';
      case Rank.ten:
        return '10';
      default:
        return (rank.index + 2).toString();
    }
  }

  static String getSuitSymbol(Suit suit) {
    switch (suit) {
      case Suit.spades:
        return '♠';
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
    }
  }

  static List<List<String>> generatePLOCombinations(
      List<String> holeCards, List<String> communityCards) {
    // PLO 규칙: 반드시 홀카드 2장과 커뮤니티카드 3장을 사용해야 함
    final holeComb = combinations(holeCards, 2); // 홀카드 중 2장 선택
    final communityComb = combinations(communityCards, 3); // 커뮤니티 카드 중 3장 선택
    List<List<String>> allHands = [];

    // 모든 가능한 조합 생성
    for (var h in holeComb) {
      for (var c in communityComb) {
        var hand = [...h, ...c];
        // 정렬하여 스트레이트 체크를 쉽게 함
        hand.sort((a, b) {
          var rankA = Card.fromString(a).rank.index;
          var rankB = Card.fromString(b).rank.index;
          return rankA.compareTo(rankB);
        });
        allHands.add(hand);
      }
    }
    return allHands;
  }

  static List<List<T>> combinations<T>(List<T> items, int r) {
    if (r == 0) return [[]];
    if (items.isEmpty) return [];

    List<List<T>> result = [];
    for (int i = 0; i <= items.length - r; i++) {
      var head = items[i];
      var tailCombos = combinations(items.sublist(i + 1), r - 1);
      for (var tailCombo in tailCombos) {
        result.add([head, ...tailCombo]);
      }
    }
    return result;
  }
} 