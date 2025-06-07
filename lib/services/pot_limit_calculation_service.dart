/// 팟 리밋 계산 서비스
///
/// 팟 리밋 오마하 포커의 베팅 계산 로직을 담당하는 서비스 클래스입니다.
class PotLimitCalculationService {
  /// 팟 리밋 베팅 금액을 계산합니다.
  ///
  /// [currentPot] 현재 팟 크기
  /// [callAmount] 콜 금액
  /// 
  /// Returns: 최대 베팅 가능한 POT! 금액
  static int calculatePotLimit(int currentPot, int callAmount) {
    return currentPot + (callAmount * 2);
  }

  /// 팟 계산 상세 설명을 생성합니다.
  ///
  /// [currentPot] 현재 팟 크기
  /// [callAmount] 콜 금액
  /// [isKorean] 한국어 여부
  ///
  /// Returns: 계산 과정의 상세 설명
  static Map<String, String> getPotCalculationDetails(
    int currentPot, 
    int callAmount, 
    bool isKorean
  ) {
    final potLimit = calculatePotLimit(currentPot, callAmount);
    
    if (isKorean) {
      return {
        'explanation': '''현재 팟: $currentPot
콜 금액: $callAmount

계산식:
POT! = 현재 팟 + (콜 금액 × 2)
POT! = $currentPot + ($callAmount × 2)
POT! = $currentPot + ${callAmount * 2}
POT! = $potLimit

따라서 최대 베팅 가능한 금액은 $potLimit입니다.''',
        'result': potLimit.toString(),
      };
    } else {
      return {
        'explanation': '''Current Pot: $currentPot
Call Amount: $callAmount

Calculation:
POT! = Current Pot + (Call Amount × 2)
POT! = $currentPot + ($callAmount × 2)
POT! = $currentPot + ${callAmount * 2}
POT! = $potLimit

Therefore, the maximum betting amount is $potLimit.''',
        'result': potLimit.toString(),
      };
    }
  }

  /// 프리플랍 팟 리밋을 계산합니다.
  ///
  /// [sb] 스몰 블라인드
  /// [bb] 빅 블라인드 
  /// [preflopBets] 추가 베팅 리스트
  /// [additionalBet] 현재 입력 중인 베팅
  ///
  /// Returns: 계산 결과와 설명
  static CalculationResult calculatePreflopPotLimit(
    int sb, 
    int bb, 
    List<int> preflopBets, 
    int additionalBet
  ) {
    // 현재 팟 계산: SB + BB + 추가된 모든 베팅
    int currentPot = sb + bb + preflopBets.fold(0, (sum, bet) => sum + bet);
    
    // 콜 금액 = BB (프리플랍에서는 일반적으로 BB가 콜 금액)
    int callAmount = bb;
    
    // 추가 베팅이 있으면 마지막 베팅이 콜 금액
    if (preflopBets.isNotEmpty) {
      callAmount = preflopBets.last;
    }
    
    // 현재 입력된 베팅도 있으면 처리
    if (additionalBet > 0) {
      callAmount = additionalBet;
      currentPot += additionalBet;
    }
    
    // POT! 리밋 계산
    final potLimit = calculatePotLimit(currentPot, callAmount);
    
    // 계산 과정 설명
    String potExplanation = '$sb(SB) + $bb(BB)';
    
    // 추가 베팅이 있으면 표시
    if (preflopBets.isNotEmpty) {
      for (int bet in preflopBets) {
        potExplanation += ' + $bet(베팅)';
      }
    }
    
    // 현재 입력 중인 베팅도 있으면 표시
    if (additionalBet > 0) {
      potExplanation += ' + $additionalBet(베팅)';
    }
    
    potExplanation += ' = $currentPot';
    
    final calculationExplanation = '$potExplanation + ($callAmount × 2) = $potLimit';
    
    return CalculationResult(
      potLimit: potLimit,
      explanation: calculationExplanation,
    );
  }

  /// 포스트플랍 팟 리밋을 계산합니다.
  ///
  /// [currentPot] 기본 팟 크기
  /// [postflopBets] 추가 베팅 리스트
  /// [additionalBet] 현재 입력 중인 베팅
  ///
  /// Returns: 계산 결과와 설명
  static CalculationResult calculatePostflopPotLimit(
    int currentPot, 
    List<int> postflopBets, 
    int additionalBet
  ) {
    // 기본 팟에 추가된 모든 베팅을 더함
    int totalPot = currentPot + postflopBets.fold(0, (sum, bet) => sum + bet);
    
    // 콜 금액 (마지막 베팅 또는 현재 입력 중인 베팅)
    int callAmount = 0;
    
    // 추가 베팅이 있으면 마지막 베팅이 콜 금액
    if (postflopBets.isNotEmpty) {
      callAmount = postflopBets.last;
    }
    
    // 현재 입력된 베팅도 있으면 처리
    if (additionalBet > 0) {
      callAmount = additionalBet;
      totalPot += additionalBet;
    }
    
    // POT! 리밋 계산
    final potLimit = calculatePotLimit(totalPot, callAmount);
    
    // 계산 과정 설명
    String potExplanation = '$currentPot(기본 팟)';
    
    // 추가 베팅이 있으면 표시
    if (postflopBets.isNotEmpty) {
      for (int bet in postflopBets) {
        potExplanation += ' + $bet(베팅)';
      }
    }
    
    // 현재 입력 중인 베팅도 있으면 표시
    if (additionalBet > 0) {
      potExplanation += ' + $additionalBet(베팅)';
    }
    
    if (totalPot != currentPot) {
      potExplanation += ' = $totalPot';
    }
    
    final calculationExplanation = '$potExplanation + ($callAmount × 2) = $potLimit';
    
    return CalculationResult(
      potLimit: potLimit,
      explanation: calculationExplanation,
    );
  }

  /// 랜덤 블라인드 값을 생성합니다.
  ///
  /// Returns: [smallBlind, bigBlind] 쌍
  static List<int> generateRandomBlinds() {
    final blindLevels = [
      [50, 100],
      [100, 200],
      [150, 300],
      [200, 400],
      [250, 500],
      [300, 600],
      [400, 800],
      [500, 1000],
      [600, 1200],
      [750, 1500],
      [1000, 2000],
    ];
    
    final random = DateTime.now().millisecondsSinceEpoch % blindLevels.length;
    return blindLevels[random];
  }

  /// 금액을 포맷팅합니다.
  ///
  /// [amount] 포맷팅할 금액
  /// 
  /// Returns: 천 단위 구분자가 적용된 문자열
  static String formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// 블라인드 값이 유효한지 검증합니다.
  ///
  /// [smallBlind] 스몰 블라인드
  /// [bigBlind] 빅 블라인드
  ///
  /// Returns: 유효하면 true, 그렇지 않으면 false
  static bool validateBlinds(int smallBlind, int bigBlind) {
    if (smallBlind <= 0 || bigBlind <= 0) return false;
    if (bigBlind <= smallBlind) return false;
    if (smallBlind > 10000 || bigBlind > 20000) return false;
    return true;
  }

  /// 입력값이 유효한지 검증합니다.
  ///
  /// [input] 검증할 문자열
  ///
  /// Returns: 유효하면 정수값, 그렇지 않으면 null
  static int? validateInput(String input) {
    if (input.trim().isEmpty) return null;
    try {
      final value = int.parse(input.trim());
      return value >= 0 ? value : null;
    } catch (e) {
      return null;
    }
  }
} 

/// 계산 결과 클래스
class CalculationResult {
  final int potLimit;
  final String explanation;

  CalculationResult({
    required this.potLimit,
    required this.explanation,
  });
} 