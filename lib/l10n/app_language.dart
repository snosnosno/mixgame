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
    'score': '점수',
    'remainingTime': '남은 시간',
    'playerCount': '플레이어 수',
    'seconds': '초',
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
    'selected': '선택',
    'correct': '정답',
    'wrong': '오답',
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
    'hiLowRuleDescription': 'PLO Hi/Low는 하이(가장 강한 패)와 로우(8 이하 5장, 페어 없이 가장 낮은 패)로 승자를 가립니다. 각 플레이어는 반드시 4장의 홀카드를 받고, 2장의 홀카드와 3장의 커뮤니티 카드를 조합해 하이/로우 핸드를 만듭니다. 로우 핸드는 8-or-better(8 이하 5장, 페어 불가)만 인정되며, A-2-3-4-5가 최강입니다. 하이와 로우가 동점일 경우 팟을 나눕니다.',
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
    'score': 'score',
    'remainingTime': 'Remaining Time',
    'playerCount': 'Player Count',
    'seconds': 'sec',
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
    'selected': 'selected',
    'correct': 'correct',
    'wrong': 'wrong',
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
    'hiLowRuleDescription': 'PLO Hi/Low determines winners for both High (strongest hand) and Low (five cards 8 or lower, no pairs, lowest possible hand). Each player receives 4 hole cards and must use exactly 2 hole cards and 3 community cards to make both High and Low hands. Only 8-or-better (five cards 8 or lower, no pairs) qualify for Low, with A-2-3-4-5 being the best. If High and Low are tied, the pot is split.',
  };
} 