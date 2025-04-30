import 'dart:math';
import 'card.dart' as poker;

class HandRank {
  final int value;
  final String name;
  final List<poker.Card> cards;
  final int secondaryValue;

  HandRank(this.value, this.name, this.cards, this.secondaryValue);

  static HandRank evaluate(List<poker.Card> cards) {
    if (cards.length != 5) throw Exception('Hand must contain exactly 5 cards');

    if (_isRoyalStraightFlush(cards)) {
      return HandRank(10, 'Royal Straight Flush', cards, 0);
    }

    if (_isStraightFlush(cards)) {
      return HandRank(9, 'Straight Flush', cards, _getHighestRank(cards));
    }

    if (_isFourOfAKind(cards)) {
      return HandRank(8, 'Four of a Kind', cards, _getFourOfAKindRank(cards));
    }

    if (_isFullHouse(cards)) {
      return HandRank(7, 'Full House', cards, _getFullHouseRank(cards));
    }

    if (_isFlush(cards)) {
      return HandRank(6, 'Flush', cards, _getHighestRank(cards));
    }

    if (_isStraight(cards)) {
      return HandRank(5, 'Straight', cards, _getHighestRank(cards));
    }

    if (_isThreeOfAKind(cards)) {
      return HandRank(4, 'Three of a Kind', cards, _getThreeOfAKindRank(cards));
    }

    if (_isTwoPair(cards)) {
      return HandRank(3, 'Two Pair', cards, _getTwoPairRank(cards));
    }

    if (_isOnePair(cards)) {
      return HandRank(2, 'One Pair', cards, _getOnePairRank(cards));
    }

    return HandRank(1, 'High Card', cards, _getHighestRank(cards));
  }

  static int _getHighestRank(List<poker.Card> cards) {
    return cards.map((c) => c.rank.index).reduce((a, b) => a > b ? a : b);
  }

  static int _getOnePairRank(List<poker.Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in poker.Rank.values.reversed) {
      if (ranks.where((r) => r == rank).length == 2) {
        return rank.index;
      }
    }
    return 0;
  }

  static int _getTwoPairRank(List<poker.Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    int highestPairRank = 0;
    for (var rank in poker.Rank.values.reversed) {
      if (ranks.where((r) => r == rank).length == 2) {
        highestPairRank = rank.index;
        break;
      }
    }
    return highestPairRank;
  }

  static int _getThreeOfAKindRank(List<poker.Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in poker.Rank.values.reversed) {
      if (ranks.where((r) => r == rank).length == 3) {
        return rank.index;
      }
    }
    return 0;
  }

  static int _getFourOfAKindRank(List<poker.Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in poker.Rank.values.reversed) {
      if (ranks.where((r) => r == rank).length == 4) {
        return rank.index;
      }
    }
    return 0;
  }

  static int _getFullHouseRank(List<poker.Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in poker.Rank.values.reversed) {
      if (ranks.where((r) => r == rank).length == 3) {
        return rank.index;
      }
    }
    return 0;
  }

  static bool _isRoyalStraightFlush(List<poker.Card> cards) {
    return _isStraightFlush(cards) &&
        cards.any((card) => card.rank == poker.Rank.ace);
  }

  static bool _isStraightFlush(List<poker.Card> cards) {
    return _isFlush(cards) && _isStraight(cards);
  }

  static bool _isFourOfAKind(List<poker.Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in poker.Rank.values) {
      if (ranks.where((r) => r == rank).length == 4) return true;
    }
    return false;
  }

  static bool _isFullHouse(List<poker.Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    bool hasThree = false;
    bool hasPair = false;
    for (var rank in poker.Rank.values) {
      var count = ranks.where((r) => r == rank).length;
      if (count == 3) hasThree = true;
      if (count == 2) hasPair = true;
    }
    return hasThree && hasPair;
  }

  static bool _isFlush(List<poker.Card> cards) {
    var suit = cards[0].suit;
    return cards.every((card) => card.suit == suit);
  }

  static bool _isStraight(List<poker.Card> cards) {
    var sortedCards = List<poker.Card>.from(cards)
      ..sort((a, b) => a.rank.index.compareTo(b.rank.index));
    var ranks = sortedCards.map((c) => c.rank.index).toList();

    bool isNormalStraight = true;
    for (int i = 0; i < ranks.length - 1; i++) {
      if (ranks[i + 1] - ranks[i] != 1) {
        isNormalStraight = false;
        break;
      }
    }
    if (isNormalStraight) return true;

    if (ranks.contains(poker.Rank.ace.index)) {
      var lowStraight = [
        poker.Rank.two.index,
        poker.Rank.three.index,
        poker.Rank.four.index,
        poker.Rank.five.index
      ];
      var containsLowStraight =
          lowStraight.every((rank) => ranks.contains(rank));
      if (containsLowStraight) return true;
    }

    if (ranks.contains(poker.Rank.ace.index)) {
      var highStraight = [
        poker.Rank.ten.index,
        poker.Rank.jack.index,
        poker.Rank.queen.index,
        poker.Rank.king.index
      ];
      var containsHighStraight =
          highStraight.every((rank) => ranks.contains(rank));
      if (containsHighStraight) return true;
    }

    return false;
  }

  static bool _isThreeOfAKind(List<poker.Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in poker.Rank.values) {
      if (ranks.where((r) => r == rank).length == 3) return true;
    }
    return false;
  }

  static bool _isTwoPair(List<poker.Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    int pairs = 0;
    for (var rank in poker.Rank.values) {
      if (ranks.where((r) => r == rank).length == 2) pairs++;
    }
    return pairs == 2;
  }

  static bool _isOnePair(List<poker.Card> cards) {
    var ranks = cards.map((c) => c.rank).toList();
    for (var rank in poker.Rank.values) {
      if (ranks.where((r) => r == rank).length == 2) return true;
    }
    return false;
  }
}
