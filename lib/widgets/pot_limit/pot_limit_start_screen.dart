import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';
import '../../providers/pot_limit_provider.dart';
import 'pot_limit_dialogs.dart';

/// 팟 리밋 게임 시작 화면 위젯
///
/// 블라인드 설정 및 게임 시작 기능을 제공합니다.
class PotLimitStartScreen extends StatelessWidget {
  final PotLimitProvider provider;
  final TextEditingController sbController;
  final TextEditingController bbController;
  final bool isSmallScreen;

  const PotLimitStartScreen({
    Key? key,
    required this.provider,
    required this.sbController,
    required this.bbController,
    required this.isSmallScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 블라인드 설정 영역
          _buildBlindsSettingSection(),
          const SizedBox(height: 8),
          // 계산법 보기 버튼
          _buildCalculationGuideButton(context),
          const SizedBox(height: 8),
          // 게임 시작 버튼
          _buildStartGameButton(),
        ],
      ),
    );
  }

  /// 블라인드 설정 섹션을 빌드합니다.
  Widget _buildBlindsSettingSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            AppLanguage.getText('customBlinds'),
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // 랜덤 블라인드 설정 버튼
          _buildRandomBlindsButton(),
          const SizedBox(height: 6),
          // 수동 블라인드 설정
          _buildManualBlindsSection(),
          const SizedBox(height: 6),
          // 블라인드 적용 버튼
          _buildApplyBlindsButton(),
        ],
      ),
    );
  }

  /// 랜덤 블라인드 설정 버튼을 빌드합니다.
  Widget _buildRandomBlindsButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: provider.useRandomBlinds 
          ? Colors.amber 
          : Colors.black.withAlpha((0.5 * 255).round()),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12, 
          vertical: 8
        ),
      ),
      onPressed: () {
        provider.setRandomBlinds();
      },
      icon: const Icon(Icons.shuffle),
      label: Text(AppLanguage.getText('useRandomBlinds')),
    );
  }

  /// 수동 블라인드 설정 섹션을 빌드합니다.
  Widget _buildManualBlindsSection() {
    return Column(
      children: [
        Text(
          AppLanguage.getText('manualBlindSetting'),
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
        const SizedBox(height: 4),
        // SB / BB 입력
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SB 입력
            _buildBlindInput(sbController, 'SB'),
            const SizedBox(width: 8),
            const Text(
              '/',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // BB 입력
            _buildBlindInput(bbController, 'BB'),
          ],
        ),
      ],
    );
  }

  /// 블라인드 입력 필드를 빌드합니다.
  Widget _buildBlindInput(TextEditingController controller, String label) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }

  /// 블라인드 적용 버튼을 빌드합니다.
  Widget _buildApplyBlindsButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: !provider.useRandomBlinds 
          ? Colors.amber 
          : Colors.black.withAlpha((0.5 * 255).round()),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12, 
          vertical: 6
        ),
      ),
      onPressed: () {
        int sb = int.tryParse(sbController.text) ?? 100;
        int bb = int.tryParse(bbController.text) ?? 200;
        provider.setCustomBlinds(sb, bb);
      },
      child: Text(AppLanguage.getText('applyBlinds')),
    );
  }

  /// 계산법 가이드 버튼을 빌드합니다.
  Widget _buildCalculationGuideButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.withAlpha((0.7 * 255).round()),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 6,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 18, 
          vertical: isSmallScreen ? 8 : 10
        ),
        textStyle: TextStyle(
          fontSize: isSmallScreen ? 13 : 15, 
          fontWeight: FontWeight.bold
        ),
      ),
      onPressed: () => PotLimitDialogs.showCalculationMethodDialog(context),
      icon: const Icon(Icons.calculate),
      label: Text(AppLanguage.getText('viewCalculation')),
    );
  }

  /// 게임 시작 버튼을 빌드합니다.
  Widget _buildStartGameButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent.withAlpha((0.65 * 255).round()),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 8,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 18 : 24, 
          vertical: isSmallScreen ? 10 : 12
        ),
        textStyle: TextStyle(
          fontSize: isSmallScreen ? 15 : 17, 
          fontWeight: FontWeight.bold
        ),
      ),
      onPressed: () => provider.startNewGame(),
      child: Text(AppLanguage.getText('startGame')),
    );
  }
} 