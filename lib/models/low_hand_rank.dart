import 'card.dart';

class LowHandRank {
  final int value;
  final String name;
  final List<int> rankValues;
  
  LowHandRank({
    required this.value,
    required this.name,
    required this.rankValues,
  });
  
  /// 로우 핸드 평가 (8-or-better 룰 적용)
  /// 8-or-better: 8 이하의 카드 5장으로 구성된 로우 핸드만 유효
  /// A-2-3-4-5가 최고의 로우 핸드
  /// 중복 카드는 최고 랭크만 고려됨(페어가 있으면 로우 없음)
  /// 반환값: 로우 핸드가 없으면 null, 있으면 LowHandRank 객체 반환
  static LowHandRank? evaluate(List<Card> cards) {
    if (cards.length != 5) {
      throw ArgumentError('로우 핸드 평가를 위해 정확히 5장의 카드가 필요합니다.');
    }
    
    // 8보다 큰 카드가 있으면 로우 핸드가 아님 (8-or-better 룰)
    bool hasCardOver8 = cards.any((card) {
      int rankValue = _getLowRankValue(card.rank);
      return rankValue > 8;
    });
    
    if (hasCardOver8) {
      return null; // 로우 핸드 없음
    }
    
    // 각 랭크의 카드 개수 계산
    Map<int, int> rankCounts = {};
    for (var card in cards) {
      int rankValue = _getLowRankValue(card.rank);
      rankCounts[rankValue] = (rankCounts[rankValue] ?? 0) + 1;
    }
    
    // 페어가 있으면 로우 핸드 없음
    if (rankCounts.values.any((count) => count > 1)) {
      return null;
    }
    
    // 로우 랭크 값을 오름차순으로 정렬
    List<int> rankValues = rankCounts.keys.toList()..sort();
    
    return LowHandRank(
      value: _calculateLowValue(rankValues),
      name: _getLowHandName(rankValues),
      rankValues: rankValues,
    );
  }
  
  // 로우 핸드 계산을 위한 랭크 값 변환
  // 에이스는 로우에서 1로 취급
  static int _getLowRankValue(Rank rank) {
    switch (rank) {
      case Rank.ace:
        return 1; // 에이스는 로우에서 1로 계산
      case Rank.two:
        return 2;
      case Rank.three:
        return 3;
      case Rank.four:
        return 4;
      case Rank.five:
        return 5;
      case Rank.six:
        return 6;
      case Rank.seven:
        return 7;
      case Rank.eight:
        return 8;
      case Rank.nine:
        return 9;
      case Rank.ten:
        return 10;
      case Rank.jack:
        return 11;
      case Rank.queen:
        return 12;
      case Rank.king:
        return 13;
      default:
        return 0;
    }
  }
  
  // 로우 핸드 값 계산 (낮을수록 좋음)
  // 최상위 카드부터 순차적으로 계산
  static int _calculateLowValue(List<int> rankValues) {
    if (rankValues.length != 5) {
      return 0; // 유효하지 않은 로우 핸드
    }
    
    // 오름차순 정렬된 리스트를 내림차순으로 재정렬 (높은 카드부터 비교하기 위함)
    List<int> sortedDesc = List.from(rankValues)..sort((a, b) => b.compareTo(a));
    
    // 디지털 형식으로 값 계산: 높은 자릿수가 더 중요
    // 예: 7,5,4,3,2 = 07050403002 (가장 높은 카드부터 비교, 낮을수록 좋음)
    int value = 0;
    for (int i = 0; i < sortedDesc.length; i++) {
      // 두 자리 숫자로 패딩하여 각 자리가 명확히 구분되게 함
      value = value * 100 + sortedDesc[i];
    }
    
    return value;
  }
  
  // 로우 핸드 이름 결정
  static String _getLowHandName(List<int> rankValues) {
    if (rankValues.isEmpty) return "로우 없음";
    
    // 오름차순으로 정렬된 rankValues를 그대로 사용
    List<String> rankNames = rankValues.map((value) {
      switch (value) {
        case 1:
          return 'A';
        case 10:
          return 'T';
        case 11:
          return 'J';
        case 12:
          return 'Q';
        case 13:
          return 'K';
        default:
          return value.toString();
      }
    }).toList();
    
    return rankNames.join('-');
  }
  
  // 두 로우 핸드 비교 (값이 낮을수록 좋음)
  static int compare(LowHandRank? a, LowHandRank? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;  // b가 더 좋음
    if (b == null) return -1; // a가 더 좋음
    
    // 각 카드 랭크를 하나씩 직접 비교
    List<int> valuesA = List.from(a.rankValues)..sort((a, b) => b.compareTo(a)); // 내림차순 정렬
    List<int> valuesB = List.from(b.rankValues)..sort((a, b) => b.compareTo(a)); // 내림차순 정렬
    
    // 가장 높은 카드부터 하나씩 비교
    for (int i = 0; i < valuesA.length && i < valuesB.length; i++) {
      int compareResult = valuesA[i].compareTo(valuesB[i]);
      if (compareResult != 0) {
        return compareResult; // 다른 값이 있으면 바로 결과 반환 (낮은 쪽이 이김)
      }
    }
    
    // 모든 카드가 동일하면 동점
    return 0;
  }
} 