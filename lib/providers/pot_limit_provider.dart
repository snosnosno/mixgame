import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/player.dart';
import '../models/pot.dart';
import '../models/betting_round.dart';
import '../home_page.dart';

/// 팟 리밋 게임 상태 관리 Provider
class PotLimitProvider extends ChangeNotifier {
  // 오디오 플레이어 인스턴스
  final AudioPlayer _audioPlayer = AudioPlayer();
  // 소리 활성화 여부 (설정에서 변경 가능)
  bool soundEnabled = true;
  
  int smallBlind = 100;
  int bigBlind = 200;
  bool isGameStarted = false;
  int currentScore = 0;
  BettingRound? bettingRound;
  Pot pot = Pot();

  List<Player> players = [];
  TextEditingController potGuessController = TextEditingController();
  bool isPotGuessing = false;
  String resultMessage = '';
  int numberOfPlayers = 6;
  bool showNextGameButton = false;

  final List<int> blindLevels = [100, 200, 400, 600, 1500, 3000];
  bool useRandomBlinds = true; // 랜덤 블라인드 사용 여부

  List<List<String>> playerActionHistory = [];

  Timer? gameTimer;

  // POT 액션 정보 저장
  int? potCorrectAnswer;
  int? potLastCurrentPot;
  int? potLastCallAmount;
  int? potLastLimit;

  int raiseCount = 0;

  List<int> chipsInitial = [];

  // POT 액션 애니메이션을 위한 변수 추가
  bool showPotAnimation = false;
  int potAnimationPlayerId = -1;
  bool isAnimating = false; // 애니메이션 진행 중 상태를 추적하는 변수 추가

  PotLimitProvider() {
    playerActionHistory = List.generate(6, (_) => []);
    // 오디오 초기화 비활성화
    // _initAudio();
  }

  /// 오디오 초기화
  void _initAudio() async {
    try {
      // 소리 볼륨 설정
      await _audioPlayer.setVolume(0.7);
      // 효과음 사운드 로드 비활성화
      // await _audioPlayer.setSource(AssetSource('sounds/pot_action.mp3'));
      debugPrint('오디오 플레이어 초기화 완료');
    } catch (e) {
      debugPrint('오디오 초기화 오류: $e');
    }
  }
  
  /// 효과음 재생
  void _playSound(String soundName) async {
    // 효과음 비활성화
    return; // 모든 효과음 재생 비활성화

    /*
    if (!soundEnabled) return;
    
    try {
      switch (soundName) {
        case 'pot':
          await _audioPlayer.stop(); // 이전 재생 중인 소리 중지
          await _audioPlayer.setSource(AssetSource('sounds/pot_action.mp3'));
          await _audioPlayer.resume();
          break;
        case 'correct':
          await _audioPlayer.stop();
          await _audioPlayer.setSource(AssetSource('sounds/correct_answer.mp3'));
          await _audioPlayer.resume();
          break;
        case 'wrong':
          await _audioPlayer.stop();
          await _audioPlayer.setSource(AssetSource('sounds/wrong_answer.mp3'));
          await _audioPlayer.resume();
          break;
      }
    } catch (e) {
      // 웹 환경에서 오디오 파일 로드 실패 시 조용히 오류 로깅만 수행
      debugPrint('효과음 재생 오류: $e');
      // 게임 플레이에 영향을 주지 않도록 아무 작업도 수행하지 않음
    }
    */
  }

  @override
  void dispose() {
    potGuessController.dispose();
    gameTimer?.cancel();
    gameTimer = null;
    _audioPlayer.dispose(); // 오디오 플레이어 자원 해제
    super.dispose();
  }

  /// 금액 형식화 함수
  String formatAmount(int amount) {
    debugPrint('원본 금액: $amount');
    
    // null이나 음수 처리
    if (amount < 0) {
      debugPrint('음수 금액을 0으로 조정: $amount → 0');
      return "0";
    }
    
    // 작은 입력값 처리 (숫자 입력 필드에서 입력할 때 사용될 수 있음)
    if (amount < 100) {
      debugPrint('POT 숫자 입력 필드 처리: $amount');
      return amount.toString();
    }
    
    int sb = smallBlind;
    debugPrint('스몰블라인드: $sb');
    
    // 단계별 금액 조정 설정
    int step = 0;
    if (sb >= 1500 && sb < 4000) {
      step = 500;
      debugPrint('500단위 반올림 적용');
    } else if (sb >= 4000) {
      step = 1000;
      debugPrint('1000단위 반올림 적용');
    } else {
      // 소액 블라인드일 경우 그대로 반환
      debugPrint('반올림 없이 그대로 반환');
      return amount.toString();
    }
    
    // 웹과 네이티브 환경 모두에서 일관되게 작동하는 반올림 로직
    if (amount % step == 0) {
      // 이미 단위에 맞는 값이면 그대로 반환
      debugPrint('이미 단위에 맞는 값: $amount');
      return amount.toString();
    }
    
    // 올림 처리 - step의 배수로 올림 (자바스크립트 호환성 확보)
    int quotient = (amount / step).floor(); // 명시적 floor 사용
    int roundedUp = (quotient + 1) * step;
    
    debugPrint('계산 과정: $amount / $step = $quotient → 올림 = ${quotient + 1} → 최종값 = $roundedUp');
    return roundedUp.toString();
  }

  /// 블라인드 직접 설정 함수
  void setCustomBlinds(int sb, int bb) {
    // 최소값 검증 (최소 10 이상)
    if (sb < 10) sb = 10;
    if (bb < 10) bb = 10;
    
    // SB는 BB보다 작아야 함
    if (sb >= bb) {
      // BB를 SB의 2배로 설정
      bb = sb * 2;
    }
    
    smallBlind = sb;
    bigBlind = bb;
    useRandomBlinds = false;
    notifyListeners();
  }

  /// 랜덤 블라인드 설정 모드로 변경
  void setRandomBlinds() {
    useRandomBlinds = true;
    notifyListeners();
  }

  /// 게임 상태 리셋
  void resetGame() {
    isGameStarted = false;
    isPotGuessing = false;
    resultMessage = '';
    showNextGameButton = false;
    raiseCount = 0;
    potGuessController.text = '';
    
    // POT 액션 정보 초기화
    potCorrectAnswer = null;
    potLastCurrentPot = null;
    potLastCallAmount = null;
    potLastLimit = null;
    
    // 애니메이션 상태 초기화
    showPotAnimation = false;
    potAnimationPlayerId = -1;
    isAnimating = false; // 애니메이션 상태 초기화
    
    gameTimer?.cancel();
    gameTimer = null;
    
    notifyListeners();
  }

  /// 플레이어 초기화
  void initializePlayers() {
    if (useRandomBlinds) {
      // 랜덤 블라인드 설정
      final random = Random();
      int blindIndex = random.nextInt(blindLevels.length);
      smallBlind = blindLevels[blindIndex];
      bigBlind = smallBlind * 2;
    }
    // 이미 설정된 smallBlind/bigBlind 사용

    final random = Random();
    players = List.generate(
      numberOfPlayers,
      (index) => Player(
        name: 'Player ${index + 1}',
        // 최소 칩을 smallBlind의 5배 이상으로 설정하여 음수가 되지 않도록 함
        chips: max((random.nextInt(599) * 500) + 500, smallBlind * 5),
        hand: [],
        position: Position.values[index % Position.values.length],
      ),
    );
    chipsInitial = players.map((p) => p.chips).toList();

    // SB, BB 포지션 인덱스 찾기
    int sbIdx = players.indexWhere((p) => p.position == Position.smallBlind);
    int bbIdx = players.indexWhere((p) => p.position == Position.bigBlind);
    
    // 플레이어의 칩이 충분한지 확인 후 블라인드 처리
    if (sbIdx != -1 && players[sbIdx].chips >= smallBlind) {
      players[sbIdx].chips -= smallBlind;
      players[sbIdx].bet = smallBlind;
      pot.addBet(players[sbIdx], smallBlind);
    }
    
    if (bbIdx != -1 && players[bbIdx].chips >= bigBlind) {
      players[bbIdx].chips -= bigBlind;
      players[bbIdx].bet = bigBlind;
      pot.addBet(players[bbIdx], bigBlind);
    }

    bettingRound = BettingRound(players: players, pot: pot);
    // UTG가 첫 액션을 하도록 currentPlayerIndex 설정
    int utgIdx = players.indexWhere((p) => p.position == Position.underTheGun);
    if (utgIdx != -1) bettingRound!.currentPlayerIndex = utgIdx;

    playerActionHistory = List.generate(numberOfPlayers, (_) => []);
    if (sbIdx != -1) playerActionHistory[sbIdx].add('SB: ${formatAmount(smallBlind)}');
    if (bbIdx != -1) playerActionHistory[bbIdx].add('BB: ${formatAmount(bigBlind)}');
    
    notifyListeners();
  }

  /// 현재 팟 계산식 정보를 반환
  Map<String, dynamic> getPotCalculationDetails() {
    if (bettingRound == null) {
      return {
        'potLimit': 0,
        'currentPot': 0,
        'callAmount': 0,
        'explanation': AppLanguage.getText("gameNotStarted")
      };
    }
    
    // POT 액션 정보가 저장되어 있으면 해당 정보 사용 - 확실하게 저장된 값 우선 사용
    int currentPot = potLastCurrentPot ?? 0;
    int callAmount = potLastCallAmount ?? 0;
    
    // 저장된 값이 없으면 현재 상태에서 계산 (이 경우도 형식화된 값 사용)
    if (potLastCurrentPot == null || potLastCallAmount == null) {
      int currentPlayerIndex = bettingRound!.currentPlayerIndex; 
      Player currentPlayer = players[currentPlayerIndex];
      
      // 현재 팟 = 모든 플레이어의 베팅 합계에서 현재 플레이어의 베팅을 뺀 값
      int rawCurrentPot = players.where((p) => p != currentPlayer).fold(0, (sum, p) => sum + p.bet);
      
      // 현재 베팅 상태에서 가장 큰 베팅 찾기
      int maxBet = players.fold(0, (max, p) => p.bet > max ? p.bet : max);
      
      // 콜 금액 = 최대 베팅액 (팟 리밋 계산용)
      int rawCallAmount = maxBet;
      
      // 형식화된 값으로 변환
      String currentPotStr = formatAmount(rawCurrentPot);
      String callAmountStr = formatAmount(rawCallAmount);
      currentPot = int.tryParse(currentPotStr) ?? rawCurrentPot;
      callAmount = int.tryParse(callAmountStr) ?? rawCallAmount;
    }
    
    int potLimit = potLastLimit ?? (currentPot + callAmount * 2);
    int currentPlayerIndex = bettingRound!.currentPlayerIndex;
    Player currentPlayer = players[currentPlayerIndex];
    
    String potDetailsStr;
    
    // 베팅한 모든 플레이어(현재 POT!을 외친 플레이어 제외, 폴드한 플레이어 포함)
    List<Player> bettingPlayersExceptCurrent = players.where((p) => p.bet > 0 && p != currentPlayer).toList();
  
    // 저장된 현재팟 값이 있으면 그 값을 기반으로 표시
    potDetailsStr = bettingPlayersExceptCurrent.map((p) {
      String posName = '';
      switch(p.position) {
        case Position.smallBlind: posName = '(SB)'; break;
        case Position.bigBlind: posName = '(BB)'; break;
        case Position.underTheGun: posName = '(UTG)'; break;
        case Position.hijack: posName = '(HJ)'; break;
        case Position.cutoff: posName = '(CO)'; break;
        case Position.dealer: posName = '(DEALER)'; break;
        default: posName = '';
      }
      // 각 플레이어의 베팅도 형식화된 값으로 표시
      String betStr = formatAmount(p.bet);
      return '$betStr$posName';
    }).join(' + ');
    
    if (bettingPlayersExceptCurrent.length > 1) {
      potDetailsStr += ' = $currentPot';
    } else if (bettingPlayersExceptCurrent.isEmpty) {
      potDetailsStr = '$currentPot'; // 빈 경우에도 저장된 값 표시
    }
    
    // 계산식은 저장된 값 사용
    int calculatedPotLimit = currentPot + callAmount * 2;
    
    // 정답 값이 있는 경우 추가
    String correctAnswerText = '';
    int? correctAnswerValue = potCorrectAnswer;
    
    if (correctAnswerValue != null) {
      bool isAllIn = false;
      if (calculatedPotLimit > correctAnswerValue) {
        isAllIn = true;
      }
      
      if (isAllIn) {
        correctAnswerText = '${correctAnswerValue} (${AppLanguage.getText('allIn')})';
      } else {
        correctAnswerText = '$correctAnswerValue';
      }
    }
    
    // 개행 포맷을 사용하여 가독성 개선
    String explanation = '''
${AppLanguage.getText('currentPot')}:
$potDetailsStr

${AppLanguage.getText('callAmount')}:
$callAmount

${AppLanguage.getText('calculation')}:
$currentPot + ($callAmount × 2) = $calculatedPotLimit

${AppLanguage.getText('potBetting')}:
$calculatedPotLimit

${AppLanguage.getText('answer')}:
$correctAnswerText
''';
    
    return {
      'potLimit': potLimit,
      'currentPot': currentPot,
      'callAmount': callAmount,
      'correctAnswer': potCorrectAnswer,
      'explanation': explanation
    };
  }

  /// 플레이어 액션 실행
  void performPlayerAction(int playerIndex) {
    // 이미 POT 액션으로 사용자 입력 대기 중이거나 베팅 라운드가 없으면 실행 안함
    if (isPotGuessing || bettingRound == null) return;

    // 애니메이션 중이면 액션 수행 안함
    if (isAnimating) return;

    var player = players[playerIndex];
    
    // 1. 현재 플레이어가 액션 불가능한 상태인지 (올인 또는 폴드) 확인하고 다음 플레이어로 이동
    if (_checkAndMoveToNextActivePlayer()) return;
    
    // 2. 현재 플레이어로 게임 상태 로깅
    _logPlayerStatus();
    
    // 3. 랜덤 액션 결정 및 실행
    _performRandomAction(playerIndex);
  }
  
  /// 액션 가능한 다음 플레이어를 찾아 이동 (모든 플레이어가 액션 불가능하면 다음 게임 시작)
  /// 리턴값: 다음 게임으로 진행하거나 모든 플레이어 확인 후 종료되었으면 true
  bool _checkAndMoveToNextActivePlayer() {
    // 연속적으로 올인/폴드 상태면 계속 nextPlayer()
    int loopCount = 0;
    var player = players[bettingRound!.currentPlayerIndex];
    
    while (player.isFolded || player.isAllIn) {
      // 무한 루프 방지
      loopCount++;
      if (loopCount > players.length) {
        // 모든 플레이어를 확인했는데도 액션 가능한 플레이어가 없음
        break;
      }
      
      bettingRound!.nextPlayer();
      player = players[bettingRound!.currentPlayerIndex];
    }
    
    // 모든 플레이어의 상태 확인
    bool allPlayersInactive = true;
    for (var p in players) {
      if (!p.isFolded && !p.isAllIn) {
        allPlayersInactive = false;
        break;
      }
    }
    
    // 모든 플레이어가 폴드 또는 올인 상태인 경우 다음 게임으로 진행
    if (allPlayersInactive) {
      debugPrint('모든 플레이어가 폴드 또는 올인 상태입니다. 다음 게임으로 진행합니다.');
      Future.delayed(const Duration(seconds: 2), () {
        startNewGame();
      });
      return true;
    }
    
    return false;
  }
  
  /// 현재 게임 상태 로깅
  void _logPlayerStatus() {
    debugPrint('--- Player Status ---');
    for (var p in players) {
      debugPrint('${p.name} | chips: \$${p.chips} | bet: \$${p.bet} | isAllIn: ${p.isAllIn} | isFolded: ${p.isFolded}');
    }
    debugPrint('lastRaiseAmount: \$${bettingRound?.lastRaiseAmount}');
  }
  
  /// 현재 플레이어의 랜덤 액션을 결정하고 실행
  void _performRandomAction(int playerIndex) {
    final random = Random();
    var player = players[bettingRound!.currentPlayerIndex];
    
    // 음수 칩스 체크 및 수정
    for (var p in players) {
      if (p.chips < 0) {
        debugPrint('음수 칩스 감지 및 수정: ${p.name}의 칩스가 ${p.chips}에서 0으로 조정됨');
        p.chips = 0;
      }
    }
    
    bool stateChanged = false;
    
    // 마지막 액션인지 확인 (다음 모든 플레이어가 폴드 또는 올인 상태인 경우)
    bool isLastActionPlayer = true;
    int nextPlayerIndex = (bettingRound!.currentPlayerIndex + 1) % players.length;
    int checkCount = 0;
    
    // 다음 플레이어들을 확인하여 액션 가능한 플레이어가 있는지 확인
    while (checkCount < players.length - 1) {
      if (nextPlayerIndex == bettingRound!.currentPlayerIndex) {
        break; // 모든 플레이어 확인 완료
      }
      
      Player nextPlayer = players[nextPlayerIndex];
      // 다음 플레이어가 액션 가능한 상태이면(폴드도 아니고 올인도 아님) 마지막 액션 플레이어가 아님
      if (!nextPlayer.isFolded && !nextPlayer.isAllIn) {
        isLastActionPlayer = false;
        break;
      }
      
      nextPlayerIndex = (nextPlayerIndex + 1) % players.length;
      checkCount++;
    }
    
    // BB 포지션 플레이어이거나 마지막 액션 플레이어이면 POT! 액션 강제 실행
    if (player.position == Position.bigBlind || isLastActionPlayer) {
      // POT! 액션 실행
      stateChanged = _performPotAction(player, playerIndex);
    } else {
      // 일반적인 랜덤 액션 결정
      int action = random.nextInt(100);

    if (action < 30) {
      // 30% 확률로 "레이즈"
      stateChanged = _performRaiseAction(player, playerIndex, random);
    } else if (action < 50) {
      // 20% 확률로 "콜"
      stateChanged = _performCallAction(player, playerIndex);
    } else if (action < 70) {
      // 20% 확률로 "폴드"
      debugPrint('Action: FOLD | Player: ${player.name}');
      bettingRound!.performAction('fold');
      playerActionHistory[playerIndex].add('FOLD');
      stateChanged = true;
    } else {
      // 30% 확률로 "POT!" (항상 최대금액으로 베팅)
      stateChanged = _performPotAction(player, playerIndex);
      }
    }
    
    if (stateChanged) {
      notifyListeners();
      
      // 액션 후에도 모든 플레이어의 상태 다시 확인
      bool allInactiveAfterAction = true;
      for (var p in players) {
        if (!p.isFolded && !p.isAllIn) {
          allInactiveAfterAction = false;
          break;
        }
      }
      
      // 모든 플레이어가 폴드 또는 올인 상태인 경우 다음 게임으로 진행
      if (allInactiveAfterAction && !isPotGuessing) {
        debugPrint('액션 후 모든 플레이어가 폴드 또는 올인 상태입니다. 다음 게임으로 진행합니다.');
        Future.delayed(const Duration(seconds: 2), () {
          startNewGame();
        });
      }
    }
  }
  
  /// 레이즈 액션 실행
  bool _performRaiseAction(Player player, int playerIndex, Random random) {
    int potLimit = bettingRound!.calculatePotLimit();
    int minRaise;
    int maxRaise = min(potLimit, player.chips);
    
    if (raiseCount == 0) {
      // 첫 레이즈도 getMinimumRaise()로 처리
      minRaise = bettingRound!.getMinimumRaise();
    } else {
      minRaise = bettingRound!.getMinimumRaise();
    }
    
    // 최소 레이즈 금액이 플레이어 칩보다 많으면 올인
    if (maxRaise < minRaise) {
      debugPrint('Action: ALL-IN (부족한 칩) | Player: ${player.name} | 보유 칩: \$${player.chips} | potLimit: \$${potLimit}');
      bettingRound!.performAction('allIn');
      playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
      return true;
    }
    
    // 금액 단위 설정 (1500-4000 블라인드일 경우 500단위, 4000 이상은 1000단위로)
    int step;
    if (smallBlind >= 1500 && smallBlind < 4000) {
      step = 500;
    } else if (smallBlind >= 4000) {
      step = 1000;
    } else {
      step = 100;
    }
    
    int numSteps = ((maxRaise - minRaise) ~/ step) + 1;
    int raiseAmount = minRaise + (numSteps > 1 ? random.nextInt(numSteps) * step : 0);
    
    // 금액을 형식화하여 표시용 값과 계산용 값 생성
    String formattedAmount = formatAmount(raiseAmount);
    int displayRaiseAmount = int.parse(formattedAmount);
    
    // 최종 레이즈 금액이 플레이어 칩보다 많으면 올인
    if (displayRaiseAmount > player.chips) {
      debugPrint('Action: ALL-IN (부족한 칩) | Player: ${player.name} | 보유 칩: \$${player.chips} | potLimit: \$${potLimit}');
      bettingRound!.performAction('allIn');
      playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
      return true;
    }
    
    // 레이즈 후 바로 POT! 액션을 하지 않도록 액션 히스토리에는 레이즈만 기록
    // 정상적인 레이즈 실행 - 여기서 형식화된 값(displayRaiseAmount)을 사용
    debugPrint('Action: RAISE | Player: ${player.name} | raiseAmount: \$${displayRaiseAmount}');
    bettingRound!.performAction('raise', displayRaiseAmount);
    playerActionHistory[playerIndex].add('RAISE: $formattedAmount');
    raiseCount++;
    return true;
  }
  
  /// 콜 액션 실행
  bool _performCallAction(Player player, int playerIndex) {
    // 현재 베팅 상태에서 가장 큰 베팅 찾기
    int maxBet = players.fold(0, (max, p) => p.bet > max ? p.bet : max);
    
    // 콜 금액 = 최대 베팅액 (팟 리밋 계산용)
    int callAmount = maxBet;
    
    // 플레이어가 추가로 내야 하는 금액 (실제 베팅에 사용)
    int playerCallDifference = max(0, maxBet - player.bet);
    
    if (playerCallDifference > player.chips) {
      // 칩이 부족하면 올인
      debugPrint('Action: ALL-IN (콜 금액 부족) | Player: ${player.name} | 보유 칩: \$${player.chips} | 콜 금액: \$${callAmount} | 실제 추가 베팅: \$${playerCallDifference}');
      bettingRound!.performAction('allIn');
      playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
    } else {
      debugPrint('Action: CALL | Player: ${player.name} | callAmount: \$${callAmount} | 실제 추가 베팅: \$${playerCallDifference}');
      bettingRound!.performAction('call');
      
      // 포지션이 BB 또는 SB인 경우 이미 블라인드를 냈으므로 총액 표시
      if (player.position == Position.bigBlind || player.position == Position.smallBlind) {
        // 총 베팅액을 CALL 액션으로 표시
        playerActionHistory[playerIndex].clear(); // 기존 SB/BB 표시 제거
        playerActionHistory[playerIndex].add('CALL: ${formatAmount(player.bet)}');
      } else {
        playerActionHistory[playerIndex].add('CALL: ${formatAmount(callAmount)}');
      }
    }
    return true;
  }
  
  /// POT 액션 실행
  bool _performPotAction(Player player, int playerIndex) {
    // 플레이어 칩스가 음수인지 확인하고 조정
    if (player.chips < 0) {
      player.chips = 0;
      debugPrint('음수 칩스 감지. Player ${player.name}의 칩을 0으로 조정');
    }
    
    // 현재 베팅 상태에서 가장 큰 베팅 찾기
    int maxBet = players.fold(0, (max, p) => p.bet > max ? p.bet : max);
    
    // 콜 금액 = 최대 베팅액 (팟 리밋 계산용)
    int callAmount = maxBet;
    
    // 플레이어가 추가로 내야하는 금액 (실제 베팅에 사용)
    int playerCallDifference = max(0, maxBet - player.bet);
    
    // 현재 팟 계산 - 현재 플레이어의 베팅을 제외한 모든 베팅 합계
    int currentPot = 0;
    for (Player p in players) {
      if (p != player) {
        currentPot += p.bet;
      }
    }
    
    // 값 형식화 - 문자열 변환 후 다시 정수로
    String callAmountStr = formatAmount(callAmount);
    String currentPotStr = formatAmount(currentPot);
    
    // 변환된 값으로 안전하게 형변환
    int formattedCallAmount = int.tryParse(callAmountStr) ?? callAmount;
    int formattedCurrentPot = int.tryParse(currentPotStr) ?? currentPot;
    
    // 팟 리밋 계산 - 명시적 괄호 사용
    int formattedPotLimit = formattedCurrentPot + (formattedCallAmount * 2);
    
    // 최종 POT 베팅 계산 - 명시적 if/else 사용
    int totalPlayerChips = player.chips + player.bet;
    int potBet;
    
    if (totalPlayerChips <= formattedPotLimit) {
      potBet = totalPlayerChips;
    } else {
      potBet = formattedPotLimit;
    }
    
    // POT 액션 정보 저장
    potCorrectAnswer = potBet;
    potLastCurrentPot = formattedCurrentPot;
    potLastCallAmount = formattedCallAmount;
    potLastLimit = formattedPotLimit;
    
    debugPrint('------ POT! 계산 상세 ------');
    debugPrint('현재 팟: \$${formattedCurrentPot} | 콜 금액: \$${formattedCallAmount}');
    debugPrint('플레이어 총 칩: \$${totalPlayerChips} | 팟 리밋: \$${formattedPotLimit}');
    debugPrint('최종 POT 베팅: \$${potBet}');
    debugPrint('Action: POT! | Player: ${player.name} | potBet: \$${potBet}');
    
    // POT 액션 수행
    if (player.chips <= formattedPotLimit - player.bet) {
      // 칩이 부족하면 올인
      debugPrint('플레이어 칩이 부족하여 올인');
      bettingRound!.performAction('allIn');
    } else {
      bettingRound!.performAction('raise', potBet);
    }
    
    playerActionHistory[playerIndex].add('POT!');
    
    // POT 효과음 재생
    _playSound('pot');
    
    // 애니메이션 상태 처리
    isAnimating = true;
    showPotAnimation = true;
    potAnimationPlayerId = playerIndex;
    
    // 애니메이션 후 처리
    Future.delayed(const Duration(milliseconds: 600), () {
      if (isGameStarted) {
        showPotAnimation = false;
        isPotGuessing = true;
        isAnimating = false;
        notifyListeners();
      }
    });
    
    isPotGuessing = false;
    resultMessage = '';
    raiseCount++;
    return true;
  }

  /// 새 게임 시작
  void startNewGame() {
    // 이미 게임이 시작된 상태면 타이머 정리
    if (isGameStarted) {
      gameTimer?.cancel();
      gameTimer = null;
    }
    
    // 상태 초기화
    isGameStarted = true;
    pot = Pot();
    isPotGuessing = false;
    resultMessage = '';
    showNextGameButton = false;
    raiseCount = 0;
    potGuessController.text = '';
    isAnimating = false; // 애니메이션 상태 초기화
    
    // POT 액션 정보 초기화
    potCorrectAnswer = null;
    potLastCurrentPot = null;
    potLastCallAmount = null;
    potLastLimit = null;
    
    // 플레이어 초기화 (별도 함수이지만 내부에서 notifyListeners 호출하므로 여기서는 호출 안함)
    initializePlayers();
    
    // 게임 타이머 시작 (1초마다 한 번씩 액션)
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 게임이 아직 진행 중인지 확인
      if (!isGameStarted || isPotGuessing || isAnimating || players.length <= 2 || bettingRound == null) {
        // 타이머를 취소하지 않고, 현재 틱만 건너뜁니다.
        return;
      }
      
      // 현재 플레이어 액션 실행
      int currentPlayerIndex = bettingRound!.currentPlayerIndex;
      performPlayerAction(currentPlayerIndex);
    });
    
    // 이미 initializePlayers에서 호출했으므로 여기서는 추가로 호출할 필요 없음
    // notifyListeners();
  }

  /// POT 금액 추측 확인
  void checkPotGuess() {
    // 이미 화면이 전환 중인지 확인 (중복 호출 방지)
    if (showNextGameButton) return;
    
    // 확실히 키보드 숨기기
    FocusManager.instance.primaryFocus?.unfocus();
    
    // 입력값 유효성 검사
    int userGuess = 0;
    try {
      userGuess = int.parse(potGuessController.text.trim());
      if (userGuess < 0) throw FormatException('음수는 허용되지 않습니다.');
    } catch (e) {
      // 숫자가 아니거나 음수인 경우 오류 메시지 표시
      resultMessage = AppLanguage.getText('invalidNumberError');
      notifyListeners();
      return;
    }
    
    int correctPot = potCorrectAnswer ?? 0;
    debugPrint('--- CHECK POT GUESS ---');
    debugPrint('User guess: \$${userGuess} | Correct: \$${correctPot}');
    
    // 정확한 값 또는 95% 이상 정확한 근사치도 정답으로 인정
    if (userGuess == correctPot || 
        (correctPot > 0 && (userGuess >= correctPot * 0.95 && userGuess <= correctPot * 1.05))) {
      currentScore++;
      resultMessage = AppLanguage.getText('correctAnswer') + currentScore.toString();
      _playSound('correct'); // 정답 효과음
    } else {
      resultMessage = AppLanguage.getText('wrongAnswer') + AppLanguage.getText('correctAnswerIs') + ' ' + formatAmount(correctPot);
      _playSound('wrong'); // 오답 효과음
    }
    showNextGameButton = true;
    for (var p in players) {
      p.bet = 0;
    }
    
    gameTimer?.cancel();
    notifyListeners();
  }
} 