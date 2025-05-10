import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pot_limit_provider.dart';
import '../widgets/pot_limit/player_card_widget.dart';
import '../widgets/pot_limit/pot_input_dialog.dart';
import '../home_page.dart'; // AppLanguage를 사용하기 위해

/// 팟 리밋 계산 페이지
///
/// 팟 리밋 계산 게임 화면을 구현한 페이지입니다.
class PotLimitPage extends StatefulWidget {
  const PotLimitPage({super.key});

  @override
  _PotLimitPageState createState() => _PotLimitPageState();
}

class _PotLimitPageState extends State<PotLimitPage> {
  // getText 함수를 추가하여 AppLanguage 클래스를 사용
  String getText(String key) => AppLanguage.getText(key);

  // 블라인드 설정용 컨트롤러
  final TextEditingController _sbController = TextEditingController(text: '100');
  final TextEditingController _bbController = TextEditingController(text: '200');

  @override
  void dispose() {
    _sbController.dispose();
    _bbController.dispose();
    // PotLimitProvider의 dispose는 Provider 프레임워크에서 자동으로 호출됨
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider 패턴을 적용하여 상태 관리
    return ChangeNotifierProvider(
      create: (context) => PotLimitProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(getText('potLimitCalculation')),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Consumer<PotLimitProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (provider.isGameStarted) {
                    // 게임이 진행 중이라면, 게임을 종료하고 블라인드 설정 화면으로 돌아감
                    provider.resetGame();
                  } else {
                    // 블라인드 설정 화면에서는 홈으로 돌아감
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
        body: const _PotLimitGameContent(),
      ),
    );
  }
}

/// 팟 리밋 게임 콘텐츠 위젯
///
/// 팟 리밋 계산 게임의 주요 UI를 구현합니다.
class _PotLimitGameContent extends StatelessWidget {
  const _PotLimitGameContent({Key? key}) : super(key: key);

  // getText 함수를 추가하여 AppLanguage 클래스를 사용
  String getText(String key) => AppLanguage.getText(key);

  // 계산법 보기 다이얼로그를 표시하는 함수
  void _showCalculationMethodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            getText('potLimitGuide'),
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
                  getText('potLimitRule'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(getText('step1')),
                      Text(getText('step2')),
                      Text(getText('step3')),
                      const SizedBox(height: 8),
                      Text(getText('potEquation'), 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  getText('example'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(getText('examplePot')),
                      Text(getText('exampleCall')),
                      Text(getText('exampleCalc')),
                      const SizedBox(height: 8),
                      Text(getText('exampleResult'), 
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
                getText('confirm'),
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

  // 팟 계산식 다이얼로그를 표시하는 함수
  void _showPotCalculationDialog(BuildContext context, PotLimitProvider provider) {
    final details = provider.getPotCalculationDetails();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            getText('potCalculation'),
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
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
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
                      ? '* ${getText('potBetting')}은 ${getText('currentPot')} + (${getText('callAmount')} × 2)로 계산됩니다.'
                      : '* ${getText('potBetting')} = ${getText('currentPot')} + (${getText('callAmount')} × 2)',
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
                getText('confirm'),
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

  @override
  Widget build(BuildContext context) {
    // 상위 위젯의 컨트롤러 접근
    final _PotLimitPageState parent = context.findAncestorStateOfType<_PotLimitPageState>()!;
    final TextEditingController sbController = parent._sbController;
    final TextEditingController bbController = parent._bbController;

    return Consumer<PotLimitProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final screenHeight = constraints.maxHeight;
                final isSmallScreen = screenWidth < 360;
                // 화면 크기에 비례하여 상자 크기 계산 (가장 먼저 선언)
                final boxW = screenWidth * (isSmallScreen ? 0.22 : (screenWidth < 500 ? 0.25 : 0.35));
                final boxH = boxW * 1.1; // 가로 대비 세로 비율 유지
                
                // 폰트 사이즈 스케일 팩터
                final fontScale = isSmallScreen ? 0.8 : 1.0;
                
                return SingleChildScrollView(
                  child: SizedBox(
                    width: screenWidth,
                    height: screenHeight,
                    child: Stack(
                      children: [
                        // 배경 그라데이션
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF388E3C),
                                Color(0xFF1B5E20),
                                Color(0xFF43A047),
                              ],
                            ),
                          ),
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
                          
                        // 게임 시작 버튼 및 블라인드 설정
                        if (!provider.isGameStarted)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 블라인드 설정 영역
                                Container(
                                  margin: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        getText('customBlinds'),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 18 : 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // 랜덤 블라인드 설정
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: provider.useRandomBlinds 
                                            ? Colors.amber 
                                            : Colors.black.withOpacity(0.5),
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
                                        label: Text(getText('useRandomBlinds')),
                                      ),
                                      const SizedBox(height: 6),
                                      // 수동 블라인드 설정
                                      Text(
                                        getText('manualBlindSetting'),
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
                                          Container(
                                            width: 80,
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: TextField(
                                              controller: sbController,
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              decoration: const InputDecoration(
                                                labelText: 'SB',
                                                labelStyle: TextStyle(color: Colors.white70),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
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
                                          Container(
                                            width: 80,
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: TextField(
                                              controller: bbController,
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              decoration: const InputDecoration(
                                                labelText: 'BB',
                                                labelStyle: TextStyle(color: Colors.white70),
                                                border: InputBorder.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // 블라인드 적용 버튼
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: !provider.useRandomBlinds 
                                            ? Colors.amber 
                                            : Colors.black.withOpacity(0.5),
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
                                        child: Text(getText('applyBlinds')),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 계산법 보기 버튼
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.withOpacity(0.7),
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
                                  onPressed: () => _showCalculationMethodDialog(context),
                                  icon: const Icon(Icons.calculate),
                                  label: Text(getText('viewCalculation')),
                                ),
                                const SizedBox(height: 8),
                                // 게임 시작 버튼
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurpleAccent,
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
                                  child: Text(getText('startGame')),
                                ),
                              ],
                            ),
                          ),
                          
                        // 결과 메시지
                        if (provider.resultMessage.isNotEmpty)
                          Positioned(
                            top: screenHeight * 0.25,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                provider.resultMessage,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          
                        // 다음 게임 버튼
                        if (provider.showNextGameButton)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: screenHeight * (isSmallScreen ? 0.12 : 0.15),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 계산식 보기 버튼
                                  Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.65),
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
                                      onPressed: () => _showPotCalculationDialog(context, provider),
                                      child: Text(getText('viewCalculation')),
                                    ),
                                  ),
                                  
                                  // 다음 게임 버튼
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurpleAccent.withOpacity(0.65),
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
                                      child: Text(getText('nextGame')),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                        // 현재 블라인드 표시 (게임 시작 후)
                        if (provider.isGameStarted)
                          Positioned(
                            top: 8,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${getText('smallBlind')}: ${provider.smallBlind}/${provider.bigBlind}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // 하단 저작권 표시
            const Positioned(
              right: 16,
              bottom: 12,
              child: _CopyrightText(),
            ),
          ],
        );
      },
    );
  }
}

/// 저작권 텍스트 위젯
class _CopyrightText extends StatelessWidget {
  const _CopyrightText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      'made by SNO',
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 17,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    );
  }
} 