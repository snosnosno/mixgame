import 'dart:math';
import '../models/card.dart' as poker;
import '../models/hand_rank.dart';
import '../models/low_hand_rank.dart';
import '../models/player.dart';

/// Hi/Low 게임의 핵심 로직을 처리하는 서비스 클래스
class HiLowGameService {
  // 카드 덱
  static const List<String> deck = [
    'AS', '2S', '3S', '4S', '5S', '6S', '7S', '8S', '9S', '10S', 'JS', 'QS', 'KS',
    'AH', '2H', '3H', '4H', '5H', '6H', '7H', '8H', '9H', '10H', 'JH', 'QH', 'KH',
    'AD', '2D', '3D', '4D', '5D', '6D', '7D', '8D', '9D', '10D', 'JD', 'QD', 'KD',
    'AC', '2C', '3C', '4C', '5C', '6C', '7C', '8C', '9C', '10C', 'JC', 'QC', 'KC'
  ];

  /// 새 게임을 위한 카드 딜링
  static GameDealResult dealNewGame(List<Player> players, int numberOfPlayers) {
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

  /// Hi/Low 핸드 승자 평가
  static GameEvaluationResult evaluateWinners(
    List<Player> players, 
    List<String> communityCards, 
    int numberOfPlayers
  ) {
    final highResult = _evaluateHighHand(players, communityCards, numberOfPlayers);
    final lowResult = _evaluateLowHand(players, communityCards, numberOfPlayers);

    return GameEvaluationResult(
      actualHighWinnerIndex: highResult.winnerIndex,
      highHandInfo: highResult.handInfo,
      actualLowWinnerIndices: lowResult.winnerIndices,
      lowHandInfo: lowResult.handInfo,
      isLowHand: lowResult.isLowHand,
    );
  }

  /// 하이 핸드 평가
  static _HighHandResult _evaluateHighHand(
    List<Player> players, 
    List<String> communityCards, 
    int numberOfPlayers
  ) {
    List<List<String>> playerHands = players.take(numberOfPlayers).map((p) => p.hand).toList();
    String bestHand = '';
    int highestRank = 0;
    int highestSecondaryRank = 0;
    int actualHighWinnerIndex = -1;
    String winningHandDescription = '';
    String handTypeName = '';

    for (int i = 0; i < playerHands.length; i++) {
      var hands = generatePLOCombinations(playerHands[i], communityCards);
      String currentBestHand = '';
      int currentRank = 0;
      int currentSecondaryRank = 0;
      List<poker.Card> bestHandCards = [];
      String currentHandTypeName = '';

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
          currentHandTypeName = handRankObj.name;
        }
      }

      if (currentRank > highestRank ||
          (currentRank == highestRank &&
              currentSecondaryRank > highestSecondaryRank)) {
        highestRank = currentRank;
        highestSecondaryRank = currentSecondaryRank;
        actualHighWinnerIndex = i;
        bestHand = currentBestHand;
        winningHandDescription = getHandDescription(bestHandCards);
        handTypeName = currentHandTypeName;
      }
    }

    String highHandInfo = '$handTypeName\n$winningHandDescription';
    
    return _HighHandResult(
      winnerIndex: actualHighWinnerIndex,
      handInfo: highHandInfo,
    );
  }

  /// 로우 핸드 평가
  static _LowHandResult _evaluateLowHand(
    List<Player> players, 
    List<String> communityCards, 
    int numberOfPlayers
  ) {
    List<List<String>> playerHands = players.take(numberOfPlayers).map((p) => p.hand).toList();
    List<LowHandRank?> playerLowRanks = List.filled(playerHands.length, null);
    List<int> actualLowWinnerIndices = [];
    bool isLowHand = false;
    
    // 각 플레이어의 최고 로우 핸드 찾기
    for (int i = 0; i < playerHands.length; i++) {
      var hands = generatePLOCombinations(playerHands[i], communityCards);
      LowHandRank? bestLowHand;
      
      for (var hand in hands) {
        var cards = hand.map((card) => poker.Card.fromString(card)).toList();
        var lowHandRank = LowHandRank.evaluate(cards);
        
        // 더 좋은 로우 핸드인지 확인 (로우는 값이 낮을수록 좋음)
        if (lowHandRank != null && (bestLowHand == null || 
            LowHandRank.compare(lowHandRank, bestLowHand) < 0)) {
          bestLowHand = lowHandRank;
        }
      }
      
      playerLowRanks[i] = bestLowHand;
      
      // 로우 핸드가 있는 플레이어가 있으면 isLowHand를 true로 설정
      if (bestLowHand != null) {
        isLowHand = true;
      }
    }
    
    String lowHandInfo = "로우 핸드 없음";
    
    // 로우 핸드가 있으면 승자 결정 (동점자 모두 승자로 추가)
    if (isLowHand) {
      // 최고의 로우 핸드 찾기
      LowHandRank? bestLowHandRank;
      
      for (int i = 0; i < playerLowRanks.length; i++) {
        var lowRank = playerLowRanks[i];
        if (lowRank != null && (bestLowHandRank == null || 
            LowHandRank.compare(lowRank, bestLowHandRank) < 0)) {
          bestLowHandRank = lowRank;
        }
      }
      
      // 최고 로우 핸드와 동일한 랭크를 가진 모든 플레이어를 승자로 지정
      if (bestLowHandRank != null) {
        for (int i = 0; i < playerLowRanks.length; i++) {
          var lowRank = playerLowRanks[i];
          if (lowRank != null && LowHandRank.compare(lowRank, bestLowHandRank) == 0) {
            actualLowWinnerIndices.add(i);
          }
        }
        
        // 로우 핸드 정보 업데이트
        if (actualLowWinnerIndices.isNotEmpty) {
          // 내림차순으로 정렬된 카드 순서로 표시 (높은 카드부터)
          List<int> sortedRanks = List.from(bestLowHandRank.rankValues)..sort((a, b) => b.compareTo(a));
          String rankDisplay = sortedRanks.map((r) => r == 1 ? 'A' : r.toString()).join('-');
          lowHandInfo = rankDisplay;
          
          // 여러 승자가 있으면 플레이어 번호 추가
          if (actualLowWinnerIndices.length > 1) {
            lowHandInfo += '\n(스플릿: ${actualLowWinnerIndices.map((i) => 'Player ${i + 1}').join(', ')})';
          }
        }
      }
    }

    return _LowHandResult(
      winnerIndices: actualLowWinnerIndices,
      handInfo: lowHandInfo,
      isLowHand: isLowHand,
    );
  }

  /// PLO 조합 생성 (2장의 핸드 카드 + 3장의 커뮤니티 카드)
  static List<List<String>> generatePLOCombinations(List<String> hand, List<String> community) {
    List<List<String>> result = [];
    
    // 핸드에서 2장 선택하는 모든 조합
    for (int i = 0; i < hand.length; i++) {
      for (int j = i + 1; j < hand.length; j++) {
        // 커뮤니티에서 3장 선택하는 모든 조합
        for (int k = 0; k < community.length; k++) {
          for (int l = k + 1; l < community.length; l++) {
            for (int m = l + 1; m < community.length; m++) {
              result.add([hand[i], hand[j], community[k], community[l], community[m]]);
            }
          }
        }
      }
    }
    
    return result;
  }

  /// 핸드 설명 텍스트 생성
  static String getHandDescription(List<poker.Card> cards) {
    cards.sort((a, b) => b.rank.index.compareTo(a.rank.index));
    List<String> cardStrs = cards.map((card) {
      String rankStr = getRankString(card.rank);
      String suitStr = getSuitString(card.suit);
      return '$rankStr$suitStr';
    }).toList();
    return cardStrs.join(' ');
  }

  /// 랭크를 문자열로 변환
  static String getRankString(poker.Rank rank) {
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
  static String getSuitString(poker.Suit suit) {
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

/// 딜링 결과를 담는 클래스
class GameDealResult {
  final List<String> communityCards;
  final List<Player> players;

  GameDealResult({
    required this.communityCards,
    required this.players,
  });
}

/// 게임 평가 결과를 담는 클래스
class GameEvaluationResult {
  final int actualHighWinnerIndex;
  final String highHandInfo;
  final List<int> actualLowWinnerIndices;
  final String lowHandInfo;
  final bool isLowHand;

  GameEvaluationResult({
    required this.actualHighWinnerIndex,
    required this.highHandInfo,
    required this.actualLowWinnerIndices,
    required this.lowHandInfo,
    required this.isLowHand,
  });
}

/// 하이 핸드 평가 결과 (내부용)
class _HighHandResult {
  final int winnerIndex;
  final String handInfo;

  _HighHandResult({
    required this.winnerIndex,
    required this.handInfo,
  });
}

/// 로우 핸드 평가 결과 (내부용)
class _LowHandResult {
  final List<int> winnerIndices;
  final String handInfo;
  final bool isLowHand;

  _LowHandResult({
    required this.winnerIndices,
    required this.handInfo,
    required this.isLowHand,
  });
} 