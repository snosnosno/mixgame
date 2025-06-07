import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_language.dart';
import 'bet_list_widget.dart';

/// 포스트플랍 계산기 위젯
///
/// 플랍 이후의 팟 계산을 관리하는 계산기입니다.
class PostflopCalculatorWidget extends StatelessWidget {
  final TextEditingController flopPotController;
  final TextEditingController flopBetController;
  final List<int> postflopBets;
  final VoidCallback onAddBet;
  final Function(int) onRemoveBet;
  final VoidCallback onCalculate;

  const PostflopCalculatorWidget({
    Key? key,
    required this.flopPotController,
    required this.flopBetController,
    required this.postflopBets,
    required this.onAddBet,
    required this.onRemoveBet,
    required this.onCalculate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCalculatorCard(),
          ],
        ),
      ),
    );
  }

  /// 계산기 카드를 빌드합니다.
  Widget _buildCalculatorCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                AppLanguage.isKorean ? '포스트플랍 계산기' : 'Postflop Calculator',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 현재 팟 금액 입력
            _buildPotInput(),
            
            const SizedBox(height: 16),
            
            // 베팅/레이즈 금액 입력
            _buildBetInput(),
            
            // 추가된 베팅 목록
            if (postflopBets.isNotEmpty) ...[
              const SizedBox(height: 16),
              BetListWidget(
                title: AppLanguage.isKorean ? '추가된 베팅:' : 'Added Bets:',
                bets: postflopBets,
                onRemoveBet: onRemoveBet,
              ),
            ],
            
            const SizedBox(height: 20),
            _buildCalculateButton(),
          ],
        ),
      ),
    );
  }

  /// 팟 금액 입력 필드를 빌드합니다.
  Widget _buildPotInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.isKorean ? '현재 팟 금액:' : 'Current Pot:',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: flopPotController,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: AppLanguage.isKorean ? '예: 5000' : 'Ex: 5000',
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  /// 베팅 입력 필드를 빌드합니다.
  Widget _buildBetInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.isKorean ? '베팅/레이즈 금액:' : 'Bet/Raise Amount:',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: flopBetController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: AppLanguage.isKorean ? '예: 2500 (베팅)' : 'Ex: 2500 (bet)',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAddBet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withAlpha((0.9 * 255).round()),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    AppLanguage.isKorean ? '추가' : 'Add',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 계산 버튼을 빌드합니다.
  Widget _buildCalculateButton() {
    return Center(
      child: ElevatedButton(
        onPressed: onCalculate,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          AppLanguage.getText('submit'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 