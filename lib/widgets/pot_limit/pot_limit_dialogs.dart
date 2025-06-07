import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';
import '../../providers/pot_limit_provider.dart';

/// 팟 리밋 관련 다이얼로그 위젯들
class PotLimitDialogs {
  /// 계산법 보기 다이얼로그를 표시하는 함수
  static void showCalculationMethodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLanguage.getText('potLimitGuide'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLanguage.getText('potLimitRule'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withAlpha((0.5 * 255).round())),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLanguage.getText('step1')),
                      Text(AppLanguage.getText('step2')),
                      Text(AppLanguage.getText('step3')),
                      const SizedBox(height: 8),
                      Text(AppLanguage.getText('potEquation'), 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLanguage.getText('example'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withAlpha((0.5 * 255).round())),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLanguage.getText('examplePot')),
                      Text(AppLanguage.getText('exampleCall')),
                      Text(AppLanguage.getText('exampleCalc')),
                      const SizedBox(height: 8),
                      Text(AppLanguage.getText('exampleResult'), 
                        style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLanguage.getText('confirm'),
                style: const TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  /// 팟 계산식 다이얼로그를 표시하는 함수
  static void showPotCalculationDialog(BuildContext context, PotLimitProvider provider) {
    final details = provider.getPotCalculationDetails();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLanguage.getText('potCalculation'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withAlpha((0.5 * 255).round()), width: 2),
                  ),
                  child: Text(
                    details['explanation'],
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLanguage.isKorean
                      ? '* ${AppLanguage.getText('potBetting')}은 ${AppLanguage.getText('currentPot')} + (${AppLanguage.getText('callAmount')} × 2)로 계산됩니다.'
                      : '* ${AppLanguage.getText('potBetting')} = ${AppLanguage.getText('currentPot')} + (${AppLanguage.getText('callAmount')} × 2)',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLanguage.getText('confirm'),
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }
} 