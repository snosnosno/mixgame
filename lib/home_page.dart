import 'package:flutter/material.dart';
import 'pages/winner_game_page.dart';
import 'pages/pot_limit_page.dart';
import 'pages/pot_limit_calculator_page.dart';
import 'pages/hi_low_game_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart'; // APP_VERSION 상수 사용을 위해 추가

// 앱 전체에서 공유할 언어 설정
class AppLanguage {
  static bool isKorean = true;
  
  static void setLanguage(bool korean) {
    isKorean = korean;
  }
  
  // getText 메서드 추가
  static String getText(String key) {
    // 'language' 키는 항상 영어로 반환
    if (key == 'language') return 'Language';
    final Map<String, String> texts = isKorean ? ko : en;
    return texts[key] ?? key;
  }
  
  // 한국어 텍스트
  static const Map<String, String> ko = {
    'appTitle': 'PL OMAHA 연습',
    'boardReading': '보드 리딩',
    'hiLowBoardReading': 'Hi/Low 보드리딩',
    'potLimitCalculation': '팟 리밋 계산',
    'potLimitCalculator': '팟 리밋 계산기',
    'donate': '후원하기',
    'gameDescription': '게임설명',
    'confirm': '확인',
    'language': '언어',
    'madeBy': 'made by SNO',
    'boardReadingDescription': '이 게임은 오마하 포커의 보드 리딩 능력을 향상시키는 훈련입니다. 다양한 핸드와 커뮤니티 카드를 분석하여 승자를 맞추는 연습을 할 수 있습니다.',
    'hiLowBoardReadingDescription': '이 게임은 오마하 Hi/Low 포커의 보드 리딩 능력을 향상시키는 훈련입니다. 하이 핸드와 로우 핸드를 모두 고려하여 승자를 판별하는 연습을 할 수 있습니다.',
    'potLimitDescription': '오마하 포커에서 중요한 팟 리밋 베팅 금액을 계산하는 연습입니다. 다양한 상황에서 정확한 팟 리밋 금액을 빠르게 계산하는 능력을 키울 수 있습니다.',
    'boardReadingGuide': '오마하 포커 보드 리딩 가이드',
    'startGame': '게임 시작',
    'nextGame': '다음 게임',
    'correctAnswer': '정답! +1점\n현재 점수: ',
    'wrongAnswer': '오답!\n정답: ',
    'enterPotAmount': 'POT! 금액 입력',
    'submit': '제출',
    'smallBlind': 'SB',
    'bigBlind': 'BB',
    'allIn': 'ALL-IN',
    'fold': 'FOLD',
    'call': 'CALL',
    'raise': 'RAISE',
    'pot': 'POT!',
    'gameOver': '게임 종료',
    'finalScore': '최종 점수',
    'highScore': '최고 점수',
    'congratulations': '축하합니다',
    'newHighScore': '새로운 최고 점수',
    'winningHand': '이긴 패',
    'correctAnswerIs': '정답은',
    'endReplay': '다시보기 종료 (현재 라운드로 돌아가기)',
    'communityCards': '커뮤니티 카드',
    'remainingTime': '남은 시간',
    'seconds': '초',
    'playerCount': '플레이어 수',
    'round': '라운드',
    'selected': '선택',
    'correct': '정답',
    'wrong': '오답',
    'score': '점수',
    'review': '리뷰',
    'boardReadingHelp': '보드 리딩 설명',
    'viewCalculation': '계산식 보기',
    'potCalculation': 'POT! 계산식',
    'currentPot': '현재 팟',
    'callAmount': '콜 금액',
    'calculation': '계산식',
    'potBetting': 'POT! 베팅',
    'answer': '정답',
    'applyBlinds': '블라인드 적용',
    'customBlinds': '블라인드 설정',
    'useRandomBlinds': '랜덤 블라인드 사용',
    'gameNotStarted': '게임이 시작되지 않았습니다.',
    'potLimitGuide': '팟 리밋 계산법',
    'potLimitRule': '팟 리밋 오마하에서 최대 베팅 금액은:',
    'step1': '1. 현재 팟(pot) 크기 계산',
    'step2': '2. 콜 금액 계산',
    'step3': '3. 최대 베팅 = 현재 팟 + 콜 금액 + 콜 금액',
    'potEquation': 'POT! = 현재 팟 + 콜 금액 x 2',
    'example': '예시:',
    'examplePot': '• 현재 팟: 1000',
    'exampleCall': '• 콜 금액: 300',
    'exampleCalc': '• POT! 베팅 = 1000 + 300 x 2 = 1600',
    'exampleResult': '즉, 플레이어는 최대 1600까지 베팅할 수 있습니다.',
    'manualBlindSetting': '직접 설정',
    'invalidNumberError': '유효한 숫자를 입력해주세요.',
    'potLimitCalculatorDescription': '팟 리밋 금액을 빠르게 계산할 수 있는 간단한 계산기입니다. 현재 팟과 콜 금액을 입력하면 즉시 최대 베팅 가능한 금액을 알려줍니다.',
  };

  // 영어 텍스트
  static const Map<String, String> en = {
    'appTitle': 'PL OMAHA Practice',
    'boardReading': 'Board Reading',
    'hiLowBoardReading': 'Hi/Low Board Reading',
    'potLimitCalculation': 'Pot Limit Calculation',
    'potLimitCalculator': 'Pot Limit Calculator',
    'donate': 'Donate',
    'gameDescription': 'Game Info',
    'confirm': 'OK',
    'language': 'Language',
    'madeBy': 'made by SNO',
    'boardReadingDescription': 'This game helps you improve your board reading skills in Omaha Poker. Practice analyzing various hands and community cards to find the winner.',
    'hiLowBoardReadingDescription': 'This game helps you improve your board reading skills in Omaha Hi/Low Poker. Practice analyzing both high hands and low hands to determine the winners.',
    'potLimitDescription': 'Practice calculating pot limit betting amounts in Omaha Poker. Develop your ability to quickly calculate accurate pot limit amounts in various situations.',
    'boardReadingGuide': 'Omaha Poker Board Reading Guide',
    'startGame': 'Start Game',
    'nextGame': 'Next Game',
    'correctAnswer': 'Correct! +1 point\nCurrent score: ',
    'wrongAnswer': 'Wrong!\nCorrect answer: ',
    'enterPotAmount': 'Enter POT! amount',
    'submit': 'Submit',
    'smallBlind': 'SB',
    'bigBlind': 'BB',
    'allIn': 'ALL-IN',
    'fold': 'FOLD',
    'call': 'CALL',
    'raise': 'RAISE',
    'pot': 'POT!',
    'gameOver': 'Game Over',
    'finalScore': 'Final Score',
    'highScore': 'High Score',
    'congratulations': 'Congratulations',
    'newHighScore': 'New High Score',
    'winningHand': 'Winning Hand',
    'correctAnswerIs': 'Correct answer is',
    'endReplay': 'End Replay (Return to Current Round)',
    'communityCards': 'Community Cards',
    'remainingTime': 'Remaining Time',
    'seconds': 'sec',
    'playerCount': 'Player Count',
    'round': 'Round',
    'selected': 'selected',
    'correct': 'correct',
    'wrong': 'wrong',
    'score': 'score',
    'review': 'Review',
    'boardReadingHelp': 'Board Reading Guide',
    'viewCalculation': 'View Calculation',
    'potCalculation': 'POT! Calculation',
    'currentPot': 'Current Pot',
    'callAmount': 'Call Amount',
    'calculation': 'Calculation',
    'potBetting': 'POT! Betting',
    'answer': 'Answer',
    'applyBlinds': 'Apply Blinds',
    'customBlinds': 'Custom Blinds',
    'useRandomBlinds': 'Use Random Blinds',
    'gameNotStarted': 'Game has not started yet.',
    'potLimitGuide': 'Pot Limit Guide',
    'potLimitRule': 'Maximum betting amount in Pot Limit Omaha:',
    'step1': '1. Calculate current pot size',
    'step2': '2. Calculate call amount',
    'step3': '3. Maximum bet = Current pot + Call amount + Call amount',
    'potEquation': 'POT! = Current pot + Call amount x 2',
    'example': 'Example:',
    'examplePot': '• Current pot: 1000',
    'exampleCall': '• Call amount: 300',
    'exampleCalc': '• POT! betting = 1000 + 300 x 2 = 1600',
    'exampleResult': 'Thus, a player can bet up to 1600 maximum.',
    'manualBlindSetting': 'Manual Setting',
    'invalidNumberError': 'Please enter a valid number.',
    
    // PLO Board Reading Guide section titles and content
    'ploKeyRules': 'Key Rules for PLO Dealers',
    'keyRule1': '• Each player must receive exactly 4 hole cards (different from Hold\'em\'s 2 cards).',
    'keyRule2': '• There are 5 community cards shared by all players.',
    'keyRule3': '• Players MUST use EXACTLY 2 hole cards and EXACTLY 3 community cards.',
    'keyRule4': '• Using 1 or 3 hole cards is not allowed. Players must use exactly 2 hole cards.',
    'keyRule5': '• When evaluating hands, check all possible combinations to find the best hand.',
    
    'handJudgingNotes': 'Important Notes for Hand Judging',
    'handNote1': '• There are 60 possible combinations: choosing 2 from hole cards (6 ways) × choosing 3 from community cards (10 ways)',
    'handNote2': '• Even if a player declares "I want to use just these 2 cards," the rules require using their best possible hand.',
    'handNote3': '• Dealers must find the player\'s optimal hand (players may make mistakes).',
    'handNote4': '• Unlike Hold\'em, a flush requires that 2 of the hole cards be of the same suit.',
    'handNote5': '• Straights also require that 2 of the hole cards be used.',
    
    'confusingSituations': 'Common Confusing Situations',
    'confuse1': '• "Flush board": Even with 4 cards of the same suit on the board, a flush is impossible without 2 matching suit cards in hand.',
    'confuse2': '• "One pair board": Since all players can use this pair, the remaining 3 cards determine the winner.',
    'confuse3': '• "Quads board": When 4 cards of the same rank are on the board, all players can use the quads.',
    'confuse4': '• "Low hand": In PLO Hi/Lo, A-2-3-4-5 is the best low hand (ignored in PLO High).',
    'confuse5': '• "Double paired board": When there are 2 pairs on the board, the higher card from hole cards becomes the kicker.',
    
    'handReadingSkills': 'Hand Reading Skills',
    'skill1': '• First check the board texture (suit distribution, connectivity, pairs, etc.).',
    'skill2': '• Always identify what the nuts (best possible hand) could be.',
    'skill3': '• Narrow down hand ranges through players\' betting patterns.',
    'skill4': '• Remember that AAxx pocket aces are weaker in Omaha than in Hold\'em.',
    'skill5': '• On double-paired boards, two pair is weak, so always check for full house possibilities.',
    
    'appGameInstructions': 'How to Play This App',
    'instruct1': '• Board Reading Game: Practice identifying winners given community cards and each player\'s hole cards.',
    'instruct2': '• Selecting Answers: Choose the player with the strongest hand.',
    'instruct3': '• 60-Second Limit: There\'s a time limit to develop quick decision-making skills.',
    'instruct4': '• Scoring: Earn 1 point for each correct judgment, track your high score.',
    'instruct5': '• Review Feature: Review incorrect judgments with the correct answer.',
    'instruct6': '• Pot Limit Game: There\'s also a mode to practice betting calculations in Pot Limit Omaha.',
    
    'appPurpose': 'This app is a training tool for real Omaha poker dealers and players. It helps improve quick hand evaluation and accurate pot calculation skills to enhance your dealing abilities in real games.',
    'potLimitCalculatorDescription': 'A simple calculator to quickly calculate pot limit amounts. Just enter the current pot and call amount to instantly get the maximum possible bet.',
  };
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // getText 함수를 AppLanguage에서 가져옵니다
  String getText(String key) => AppLanguage.getText(key);

  void _toggleLanguage() {
    setState(() {
      AppLanguage.setLanguage(!AppLanguage.isKorean);
    });
  }

  void _showLanguageSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(getText('language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('한국어'),
                onTap: () {
                  setState(() => AppLanguage.setLanguage(true));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('English'),
                onTap: () {
                  setState(() => AppLanguage.setLanguage(false));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGameDescription(BuildContext context, String gameKey) {
    String descriptionKey = '';
    if (gameKey == 'boardReading') {
      descriptionKey = 'boardReadingDescription';
    } else if (gameKey == 'hiLowBoardReading') {
      descriptionKey = 'hiLowBoardReadingDescription';
    } else if (gameKey == 'potLimitCalculation') {
      descriptionKey = 'potLimitDescription';
    } else if (gameKey == 'potLimitCalculator') {
      descriptionKey = 'potLimitCalculatorDescription';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            getText(gameKey),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          content: Text(
            getText(descriptionKey),
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF4CAF50),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 카카오페이 후원 버튼
            Positioned(
              left: 16,
              top: 48,
              child: Transform.scale(
                scale: 0.6,
                alignment: Alignment.topLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final url = Uri.parse('https://qr.kakaopay.com/Ej7oKLuOO');
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  icon: Image.asset(
                    'assets/kakao_pay.jpg',
                    height: 24,
                  ),
                  label: Text(
                    getText('donate'),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: Colors.yellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            // 언어 선택 버튼
            Positioned(
              right: 16,
              top: 48,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.amber.withOpacity(0.8),
                child: InkWell(
                  onTap: () => _showLanguageSelector(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.language,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          getText('language'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getText('appTitle'),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 20 : 40),
                      _buildGameButton(
                        context,
                        'boardReading',
                        const WinnerGamePage(),
                        isMobile,
                        isTablet,
                        isDesktop,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _buildGameButton(
                        context,
                        'hiLowBoardReading',
                        const HiLowGamePage(),
                        isMobile,
                        isTablet,
                        isDesktop,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _buildGameButton(
                        context,
                        'potLimitCalculation',
                        const PotLimitPage(),
                        isMobile,
                        isTablet,
                        isDesktop,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _buildGameButton(
                        context,
                        'potLimitCalculator',
                        const PotLimitCalculatorPage(),
                        isMobile,
                        isTablet,
                        isDesktop,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        color: Colors.black.withOpacity(0.2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getText('madeBy'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.3 (${BUILD_TIMESTAMP})',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameButton(
    BuildContext context,
    String textKey,
    Widget page,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final double buttonWidth = isMobile
        ? double.infinity
        : isTablet
            ? 500.0
            : 600.0;

    return Stack(
      children: [
        Container(
          width: buttonWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B5E20),
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 16 : 20,
                horizontal: isMobile ? 40 : 50,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    getText(textKey),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: const Color(0xFF1B5E20),
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 20 : 22,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 80),
              ],
            ),
          ),
        ),
        // 설명 버튼 추가
        Positioned(
          top: 5,
          right: 5,
          child: InkWell(
            onTap: () => _showGameDescription(context, textKey),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: isMobile ? 12 : 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    getText('gameDescription'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
