import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';
import '../../providers/pot_limit_provider.dart';
import 'pot_limit_dialogs.dart';

/// 팟 리밋 게임 오버레이 위젯들
///
/// 게임 중 표시되는 결과 메시지, 다음 게임 버튼, 블라인드 정보 등을 담당합니다.
class PotLimitGameOverlay extends StatelessWidget {
  final PotLimitProvider provider;
  final double screenWidth;
  final double screenHeight;
  final bool isSmallScreen;

  const PotLimitGameOverlay({
    Key? key,
    required this.provider,
    required this.screenWidth,
    required this.screenHeight,
    required this.isSmallScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 결과 메시지
        if (provider.resultMessage.isNotEmpty)
          _buildResultMessage(),
        
        // 다음 게임 버튼
        if (provider.showNextGameButton)
          _buildNextGameButtons(context),
        
        // 현재 블라인드 표시 (게임 시작 후)
        if (provider.isGameStarted)
          _buildBlindsDisplay(),
      ],
    );
  }

  /// 결과 메시지를 빌드합니다.
  Widget _buildResultMessage() {
    return Positioned(
      top: screenHeight * 0.25,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((0.7 * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withAlpha((0.3 * 255).round()),
              width: 1,
            ),
          ),
          child: Text(
            provider.resultMessage,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// 다음 게임 버튼들을 빌드합니다.
  Widget _buildNextGameButtons(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: screenHeight * (isSmallScreen ? 0.12 : 0.15),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 계산식 보기 버튼
            _buildCalculationButton(context),
            const SizedBox(width: 10),
            // 다음 게임 버튼
            _buildNextGameButton(),
          ],
        ),
      ),
    );
  }

  /// 계산식 보기 버튼을 빌드합니다.
  Widget _buildCalculationButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha((0.65 * 255).round()),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 14 : 20, 
            vertical: isSmallScreen ? 12 : 16
          ),
          textStyle: TextStyle(
            fontSize: isSmallScreen ? 13 : 15, 
            fontWeight: FontWeight.bold
          ),
        ),
        onPressed: () => PotLimitDialogs.showPotCalculationDialog(context, provider),
        child: Text(AppLanguage.getText('viewCalculation')),
      ),
    );
  }

  /// 다음 게임 버튼을 빌드합니다.
  Widget _buildNextGameButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent.withAlpha((0.65 * 255).round()),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 18 : 24, 
            vertical: isSmallScreen ? 12 : 16
          ),
          textStyle: TextStyle(
            fontSize: isSmallScreen ? 14 : 16, 
            fontWeight: FontWeight.bold
          ),
        ),
        onPressed: () => provider.startNewGame(),
        child: Text(AppLanguage.getText('nextGame')),
      ),
    );
  }

  /// 블라인드 표시를 빌드합니다.
  Widget _buildBlindsDisplay() {
    return Positioned(
      top: 8,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((0.4 * 255).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withAlpha((0.2 * 255).round()),
            width: 1,
          ),
        ),
        child: Text(
          '${AppLanguage.getText('smallBlind')}: ${provider.smallBlind}/${provider.bigBlind}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
} 