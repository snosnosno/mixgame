import 'package:flutter/material.dart';

/// 베팅 목록 위젯
///
/// 추가된 베팅들을 목록으로 표시하고 삭제 기능을 제공합니다.
class BetListWidget extends StatelessWidget {
  final String title;
  final List<int> bets;
  final Function(int) onRemoveBet;

  const BetListWidget({
    Key? key,
    required this.title,
    required this.bets,
    required this.onRemoveBet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: bets.length,
            itemBuilder: (context, index) {
              return _buildBetItem(index, bets[index]);
            },
          ),
        ),
      ],
    );
  }

  /// 베팅 아이템을 빌드합니다.
  Widget _buildBetItem(int index, int bet) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        '${index + 1}. $bet',
        style: const TextStyle(fontSize: 16),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, color: Colors.red, size: 20),
        onPressed: () => onRemoveBet(index),
      ),
    );
  }
} 