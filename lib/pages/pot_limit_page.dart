import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_language.dart';
import '../providers/pot_limit_provider.dart';
import '../widgets/pot_limit/player_card_widget.dart';
import '../widgets/pot_limit/pot_input_dialog.dart';
import '../widgets/pot_limit/pot_limit_start_screen.dart';
import '../widgets/pot_limit/pot_limit_game_overlay.dart';
import '../widgets/common/game_background.dart';
import '../widgets/pot_limit/pot_limit_copyright.dart';

/// 팟 리밋 계산 페이지
///
/// 팟 리밋 계산 게임 화면을 구현한 페이지입니다.
class PotLimitPage extends StatefulWidget {
  const PotLimitPage({super.key});

  @override
  _PotLimitPageState createState() => _PotLimitPageState();
}

class _PotLimitPageState extends State<PotLimitPage> {
  // 블라인드 설정용 컨트롤러
  final TextEditingController _sbController = TextEditingController(text: '100');
  final TextEditingController _bbController = TextEditingController(text: '200');

  @override
  void dispose() {
    _sbController.dispose();
    _bbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PotLimitProvider(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(AppLanguage.getText('potLimitCalculation')),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Consumer<PotLimitProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (provider.isGameStarted) {
                    provider.resetGame();
                  } else {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E7D32),
                  Color(0xFF1B5E20),
                  Color(0xFF388E3C),
                ],
              ),
            ),
          ),
        ),
        body: GameBackground(
          child: _PotLimitGameContent(
            sbController: _sbController,
            bbController: _bbController,
          ),
        ),
      ),
    );
  }
}

/// 팟 리밋 게임 콘텐츠 위젯
///
/// 팟 리밋 계산 게임의 주요 UI를 구현합니다.
class _PotLimitGameContent extends StatelessWidget {
  final TextEditingController sbController;
  final TextEditingController bbController;

  const _PotLimitGameContent({
    Key? key,
    required this.sbController,
    required this.bbController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PotLimitProvider>(
      builder: (context, provider, child) {
        return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;
                final isSmallScreen = screenWidth < 360;
                final boxW = screenWidth * (isSmallScreen ? 0.22 : (screenWidth < 500 ? 0.25 : 0.35));
            final boxH = boxW * 1.1;
                final fontScale = isSmallScreen ? 0.8 : 1.0;
                
            return Stack(
                      children: [
                // 게임 시작 화면 (블라인드 설정)
                if (!provider.isGameStarted)
                  PotLimitStartScreen(
                    provider: provider,
                    sbController: sbController,
                    bbController: bbController,
                    isSmallScreen: isSmallScreen,
                        ),
                        
                        // 플레이어 카드 위젯들
                        if (provider.isGameStarted)
                          ...List.generate(provider.numberOfPlayers, (index) {
                            if (index >= provider.players.length) {
                              return Container();
                            }
                            
                            return PlayerCardWidget(
                              player: provider.players[index],
                              index: index,
                              actionHistory: provider.playerActionHistory[index],
                              initialChips: provider.chipsInitial[index],
                              screenWidth: screenWidth,
                              screenHeight: screenHeight,
                              boxWidth: boxW,
                              boxHeight: boxH,
                              isSmallScreen: isSmallScreen,
                              fontScale: fontScale,
                              formatAmount: provider.formatAmount,
                              showPotAnimation: provider.showPotAnimation,
                              potAnimationPlayerId: provider.potAnimationPlayerId,
                            );
                          }),
                          
                        // POT 입력 대화상자 위젯
                        if (provider.isPotGuessing)
                          PotInputDialog(
                            controller: provider.potGuessController,
                            onSubmit: () => provider.checkPotGuess(),
                            screenWidth: screenWidth,
                            screenHeight: screenHeight,
                            isSmallScreen: isSmallScreen,
                          ),
                          
                // 게임 오버레이 (결과 메시지, 다음 게임 버튼, 블라인드 표시)
                PotLimitGameOverlay(
                  provider: provider,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  isSmallScreen: isSmallScreen,
            ),
            
            // 하단 저작권 표시
                const PotLimitCopyright(),
              ],
            );
          },
        );
      },
    );
  }
} 