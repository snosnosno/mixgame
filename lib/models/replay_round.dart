/// Hi/Low 게임의 리플레이 라운드 정보를 저장하는 모델
class ReplayRound {
  final List<List<String>> playerHands;
  final List<String> communityCards;
  final int? selectedHighWinnerIndex;
  final int? actualHighWinnerIndex;
  final List<int> selectedLowWinnerIndices;
  final List<int> actualLowWinnerIndices;
  final String winnerText;
  final int numberOfPlayers;
  final int roundScore;
  final int? selectedWinnerIndex;

  ReplayRound({
    required this.playerHands,
    required this.communityCards,
    required this.selectedHighWinnerIndex,
    required this.actualHighWinnerIndex,
    required this.selectedLowWinnerIndices,
    required this.actualLowWinnerIndices,
    required this.winnerText,
    required this.numberOfPlayers,
    required this.roundScore,
    this.selectedWinnerIndex,
  });
} 