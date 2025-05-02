import 'package:flutter/material.dart';
import 'card_widget.dart';

class ReplayRound {
  final List<List<String>> playerHands;
  final List<String> communityCards;
  final int? selectedWinnerIndex;
  final int? actualWinnerIndex;
  final String winnerText;
  final int numberOfPlayers;
  final int roundScore;

  ReplayRound({
    required this.playerHands,
    required this.communityCards,
    required this.selectedWinnerIndex,
    required this.actualWinnerIndex,
    required this.winnerText,
    required this.numberOfPlayers,
    required this.roundScore,
  });
}

class ReplayRoundWidget extends StatelessWidget {
  final ReplayRound replayRound;
  final VoidCallback onExitReplay;

  const ReplayRoundWidget({
    Key? key,
    required this.replayRound,
    required this.onExitReplay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Replay Mode',
          style: TextStyle(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        // Community cards
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: replayRound.communityCards
              .map((card) => CardWidget(card: card))
              .toList(),
        ),
        SizedBox(height: 12),
        // Winner info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            replayRound.winnerText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: replayRound.selectedWinnerIndex == replayRound.actualWinnerIndex
                  ? Colors.greenAccent
                  : Colors.redAccent,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 6,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: onExitReplay,
          icon: const Icon(Icons.exit_to_app),
          label: const Text('End Replay (Return to Current Round)'),
        ),
      ],
    );
  }
}

class ReplayLogWidget extends StatelessWidget {
  final List<String> roundLogs;
  final Function(int) onReplaySelected;

  const ReplayLogWidget({
    Key? key,
    required this.roundLogs,
    required this.onReplaySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                '↓↓Review↓↓',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: roundLogs.length,
              itemBuilder: (context, idx) {
                final log = roundLogs[roundLogs.length - 1 - idx];
                return InkWell(
                  onTap: () => onReplaySelected(roundLogs.length - 1 - idx),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    child: Text(
                      log,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 14, 
                        decoration: TextDecoration.underline
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 