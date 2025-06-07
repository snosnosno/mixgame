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

    // 모든 카드를 rank.index 기준으로 내림차순 정렬 (높은 카드부터)
    // suit는 족보 결정에만 사용하고, rank 값으로 hand 비교
    var sortedCards = List<poker.Card>.from(cards);
    sortedCards.sort((a, b) => b.rank.index.compareTo(a.rank.index));

    if (_isRoyalStraightFlush(sortedCards)) {
      // 로열 스트레이트 플러시는 secondaryValue가 필요 없음 (유일무이)
      return HandRank(10, 'Royal Straight Flush', sortedCards, 0);
    }

    if (_isStraightFlush(sortedCards)) {
      // 스트레이트 플러시는 가장 높은 카드로 비교 (A-5는 5가 가장 높음)
      return HandRank(9, 'Straight Flush', sortedCards, _getStraightRankValue(sortedCards));
    }

    if (_isFourOfAKind(sortedCards)) {
      return HandRank(8, 'Four of a Kind', sortedCards, _getFourOfAKindRankValue(sortedCards));
    }

    if (_isFullHouse(sortedCards)) {
      return HandRank(7, 'Full House', sortedCards, _getFullHouseRankValue(sortedCards));
    }

    if (_isFlush(sortedCards)) {
      // 플러시는 5장의 카드를 높은 순서대로 비교
      return HandRank(6, 'Flush', sortedCards, _getHighCardRankValue(sortedCards));
    }

    if (_isStraight(sortedCards)) {
      // 스트레이트는 가장 높은 카드로 비교 (A-5는 5가 가장 높음)
      // UI 표시용 이름 생성
      String straightName = 'Straight';
      var ranks = sortedCards.map((c) => c.rank.index).toList();
      if (ranks.contains(poker.Rank.ace.index) &&
          ranks.contains(poker.Rank.five.index) &&
          ranks.contains(poker.Rank.four.index) &&
          ranks.contains(poker.Rank.three.index) &&
          ranks.contains(poker.Rank.two.index)) {
        straightName = '5-high Straight'; // A-5 wheel
      } else {
        String highCardName;
        int highestCardIndexInStraight = _getStraightRankValue(sortedCards); // 실제 스트레이트의 탑 카드
        // Rank enum의 index를 실제 카드 숫자로 변환 (Ace는 14, King은 13 등으로 가정)
        // 또는 Rank enum에 displayName 같은 것을 추가하는 것이 더 좋음
        if (highestCardIndexInStraight == poker.Rank.ace.index) highCardName = 'A';
        else if (highestCardIndexInStraight == poker.Rank.king.index) highCardName = 'K';
        else if (highestCardIndexInStraight == poker.Rank.queen.index) highCardName = 'Q';
        else if (highestCardIndexInStraight == poker.Rank.jack.index) highCardName = 'J';
        else if (highestCardIndexInStraight == poker.Rank.ten.index) highCardName = 'T';
        else highCardName = (highestCardIndexInStraight + 2).toString(); // 2는 two.index + 2
        
        straightName = '$highCardName-high Straight';
      }
      return HandRank(5, straightName, sortedCards, _getStraightRankValue(sortedCards));
    }

    if (_isThreeOfAKind(sortedCards)) {
      return HandRank(4, 'Three of a Kind', sortedCards, _getThreeOfAKindRankValue(sortedCards));
    }

    if (_isTwoPair(sortedCards)) {
      return HandRank(3, 'Two Pair', sortedCards, _getTwoPairRankValue(sortedCards));
    }

    if (_isOnePair(sortedCards)) {
      return HandRank(2, 'One Pair', sortedCards, _getOnePairRankValue(sortedCards));
    }
    // 하이카드
    return HandRank(1, 'High Card', sortedCards, _getHighCardRankValue(sortedCards));
  }

  // Helper to create a weighted rank value from a list of card ranks (up to 5)
  static int _calculateWeightedRank(List<int> ranks) {
    final int base = poker.Rank.values.length; // 13
    int value = 0;
    for (int i = 0; i < ranks.length; i++) {
      value += ranks[i] * pow(base, (ranks.length - 1 - i)).toInt();
    }
    return value;
  }

  static int _getHighCardRankValue(List<poker.Card> sortedCards) {
    // 5장의 카드를 높은 순서대로 값으로 사용
    var ranks = sortedCards.map((c) => c.rank.index).toList();
    return _calculateWeightedRank(ranks);
  }
  
  static int _getStraightRankValue(List<poker.Card> sortedCards) {
    var ranks = sortedCards.map((c) => c.rank.index).toList();
    // A-5 스트레이트 (Wheel)의 경우, Ace는 낮은 것으로 간주되므로, 5가 가장 높은 카드
      bool isWheel = ranks.contains(poker.Rank.ace.index) &&
                   ranks.contains(poker.Rank.five.index) &&
                   ranks.contains(poker.Rank.four.index) &&
                      ranks.contains(poker.Rank.three.index) &&
                   ranks.contains(poker.Rank.two.index);
    if (isWheel) {
      return poker.Rank.five.index; // 휠 스트레이트의 탑은 5
    }
    // 그 외 스트레이트는 가장 높은 카드의 랭크 반환
    return ranks[0]; // 이미 sortedCards는 내림차순 정렬됨
  }

  static int _getOnePairRankValue(List<poker.Card> sortedCards) {
    var ranks = sortedCards.map((c) => c.rank.index).toList(); // 이미 내림차순 정렬
    int pairRank = -1;
    List<int> kickers = [];

    Map<int, int> counts = {};
    for (var rank in ranks) {
      counts[rank] = (counts[rank] ?? 0) + 1;
    }

    for (var rank_val in ranks.toSet().toList()..sort((a, b) => b.compareTo(a))) {
      if (counts[rank_val] == 2) {
        pairRank = rank_val;
        break;
      }
    }

    List<int> tempRanks = List.from(ranks);
    if (pairRank != -1) {
      tempRanks.remove(pairRank);
      tempRanks.remove(pairRank);
      kickers = tempRanks.take(3).toList();
    } else { return 0; }
    
    List<int> comparisonRanks = [pairRank] + kickers;
    return _calculateWeightedRank(comparisonRanks);
  }

  static int _getTwoPairRankValue(List<poker.Card> sortedCards) {
    var ranks = sortedCards.map((c) => c.rank.index).toList(); // 이미 내림차순 정렬
    List<int> pairRanks = [];
    Map<int, int> counts = {};
    for (var rank in ranks) {
      counts[rank] = (counts[rank] ?? 0) + 1;
    }

    for (var rank_val in ranks.toSet().toList()..sort((a, b) => b.compareTo(a))) {
      if (counts[rank_val] == 2) {
        pairRanks.add(rank_val);
      }
    }
    
    if (pairRanks.length < 2) { return 0; }

    int highPairRank = pairRanks[0];
    int lowPairRank = pairRanks[1];
    
    int kickerRank = -1;
    List<int> tempRanks = List.from(ranks);
    tempRanks.remove(highPairRank); tempRanks.remove(highPairRank);
    tempRanks.remove(lowPairRank); tempRanks.remove(lowPairRank);
    
    if (tempRanks.isNotEmpty) {
      kickerRank = tempRanks[0];
    } else { return 0; }

    List<int> comparisonRanks = [highPairRank, lowPairRank, kickerRank];
    return _calculateWeightedRank(comparisonRanks);
  }

  static int _getThreeOfAKindRankValue(List<poker.Card> sortedCards) {
    var ranks = sortedCards.map((c) => c.rank.index).toList(); // 이미 내림차순 정렬
    int tripleRank = -1;
    List<int> kickers = [];
    Map<int, int> counts = {};
    for (var rank in ranks) {
      counts[rank] = (counts[rank] ?? 0) + 1;
    }

    for (var rank_val in ranks.toSet().toList()..sort((a, b) => b.compareTo(a))) {
      if (counts[rank_val] == 3) {
        tripleRank = rank_val;
        break;
      }
    }

    List<int> tempRanks = List.from(ranks);
    if (tripleRank != -1) {
      tempRanks.remove(tripleRank); tempRanks.remove(tripleRank); tempRanks.remove(tripleRank);
      kickers = tempRanks.take(2).toList();
    } else { return 0; }
    
    List<int> comparisonRanks = [tripleRank] + kickers;
    return _calculateWeightedRank(comparisonRanks);
  }

  static int _getFourOfAKindRankValue(List<poker.Card> sortedCards) {
    var ranks = sortedCards.map((c) => c.rank.index).toList(); // 이미 내림차순 정렬
    int quadRank = -1;
    int kickerRank = -1;
    Map<int, int> counts = {};
    for (var rank in ranks) {
      counts[rank] = (counts[rank] ?? 0) + 1;
  }

    for (var rank_val in ranks.toSet().toList()..sort((a, b) => b.compareTo(a))) {
      if (counts[rank_val] == 4) {
        quadRank = rank_val;
        break;
      }
    }
    
    List<int> tempRanks = List.from(ranks);
    if (quadRank != -1) {
      tempRanks.remove(quadRank);tempRanks.remove(quadRank);tempRanks.remove(quadRank);tempRanks.remove(quadRank);
      if (tempRanks.isNotEmpty) kickerRank = tempRanks[0]; else return 0; // Should not happen in 5 card hand
    } else { return 0; }

    List<int> comparisonRanks = [quadRank, kickerRank];
    return _calculateWeightedRank(comparisonRanks);
  }

  static int _getFullHouseRankValue(List<poker.Card> sortedCards) {
    var ranks = sortedCards.map((c) => c.rank.index).toList(); // 이미 내림차순 정렬
    int tripleRank = -1;
    int pairRank = -1;
    Map<int, int> counts = {};
    for (var rank in ranks) {
      counts[rank] = (counts[rank] ?? 0) + 1;
    }

    // 트리플 찾기
    for (var rank_val in ranks.toSet().toList()..sort((a, b) => b.compareTo(a))) {
      if (counts[rank_val] == 3) {
        tripleRank = rank_val;
        break;
      }
    }
    // 페어 찾기 (트리플과 다른 랭크여야 함)
    for (var rank_val in ranks.toSet().toList()..sort((a, b) => b.compareTo(a))) {
      if (counts[rank_val] == 2 && rank_val != tripleRank) {
        pairRank = rank_val;
        break;
      }
    }

    if (tripleRank != -1 && pairRank != -1) {
      List<int> comparisonRanks = [tripleRank, pairRank];
      return _calculateWeightedRank(comparisonRanks);
    }
    return 0; // 풀하우스가 아님
  }

  // _is... helper functions remain largely the same, but should operate on sortedCards
  // For brevity, only showing changes to _isStraight, others are assumed to be correct
  // or adjusted slightly to use sortedCards if they weren't already.

  static bool _isRoyalStraightFlush(List<poker.Card> sortedCards) {
    return _isStraightFlush(sortedCards) &&
        sortedCards[0].rank == poker.Rank.ace; // Sorted: A, K, Q, J, T
  }

  static bool _isStraightFlush(List<poker.Card> sortedCards) {
    return _isFlush(sortedCards) && _isStraight(sortedCards);
  }

  static bool _isFourOfAKind(List<poker.Card> sortedCards) {
    var counts = _getRankCounts(sortedCards);
    return counts.values.any((count) => count == 4);
  }

  static bool _isFullHouse(List<poker.Card> sortedCards) {
    var counts = _getRankCounts(sortedCards);
    return counts.values.any((count) => count == 3) && counts.values.any((count) => count == 2);
  }

  static bool _isFlush(List<poker.Card> sortedCards) {
    var suit = sortedCards[0].suit;
    return sortedCards.every((card) => card.suit == suit);
  }

  static bool _isStraight(List<poker.Card> sortedCards) {
    var ranks = sortedCards.map((c) => c.rank.index).toList(); // Already sorted by rank desc

    // Check for normal straight (e.g., K-Q-J-T-9)
    bool normalStraight = true;
    for (int i = 0; i < ranks.length - 1; i++) {
      if (ranks[i] - ranks[i+1] != 1) {
        normalStraight = false;
        break;
      }
    }
    if (normalStraight) return true;

    // Check for A-2-3-4-5 (wheel)
    // Ranks will be [Ace, 5, 4, 3, 2] if sorted descending
    if (ranks[0] == poker.Rank.ace.index &&
        ranks[1] == poker.Rank.five.index &&
        ranks[2] == poker.Rank.four.index &&
        ranks[3] == poker.Rank.three.index &&
        ranks[4] == poker.Rank.two.index) {
      return true;
    }
    return false;
  }

  static bool _isThreeOfAKind(List<poker.Card> sortedCards) {
    var counts = _getRankCounts(sortedCards);
    return counts.values.any((count) => count == 3);
  }

  static bool _isTwoPair(List<poker.Card> sortedCards) {
    var counts = _getRankCounts(sortedCards);
    return counts.values.where((count) => count == 2).length == 2;
  }

  static bool _isOnePair(List<poker.Card> sortedCards) {
    var counts = _getRankCounts(sortedCards);
    return counts.values.any((count) => count == 2);
  }
  
  static Map<poker.Rank, int> _getRankCounts(List<poker.Card> cards) {
    var counts = <poker.Rank, int>{};
    for (var card in cards) {
      counts[card.rank] = (counts[card.rank] ?? 0) + 1;
    }
    return counts;
  }
}
