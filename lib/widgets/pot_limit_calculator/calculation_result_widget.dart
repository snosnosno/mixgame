import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';

/// 계산 결과 위젯
///
/// 팟 리밋 계산 결과와 계산 과정을 표시합니다.
class CalculationResultWidget extends StatelessWidget {
  final String calculationExplanation;
  final int calculatedPotLimit;

  const CalculationResultWidget({
    Key? key,
    required this.calculationExplanation,
    required this.calculatedPotLimit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.amber.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              AppLanguage.getText('potCalculation'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${AppLanguage.getText('calculation')}:\n$calculationExplanation',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${AppLanguage.getText('potBetting')}: $calculatedPotLimit',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 