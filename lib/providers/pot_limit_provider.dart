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
    _initAudio();
  }

  /// 오디오 초기화
  void _initAudio() async {
    try {
      // 소리 볼륨 설정
      await _audioPlayer.setVolume(0.7);
      // 효과음 사운드 로드 (앱 시작 시 한 번만 로드)
      await _audioPlayer.setSource(AssetSource('sounds/pot_action.mp3'));
      debugPrint('오디오 플레이어 초기화 완료');
    } catch (e) {
      debugPrint('오디오 초기화 오류: $e');
    }
  }
  
  /// 효과음 재생
  void _playSound(String soundName) async {
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
      debugPrint('효과음 재생 오류: $e');
    }
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
    if (smallBlind == 1500) {
      return ((amount + 250) ~/ 500 * 500).toString();
    }
    return amount.toString();
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
        chips: (random.nextInt(599) * 500) + 500,
        hand: [],
        position: Position.values[index % Position.values.length],
      ),
    );
    chipsInitial = players.map((p) => p.chips).toList();

    // SB, BB 포지션 인덱스 찾기
    int sbIdx = players.indexWhere((p) => p.position == Position.smallBlind);
    int bbIdx = players.indexWhere((p) => p.position == Position.bigBlind);
    if (sbIdx != -1) {
      players[sbIdx].chips -= smallBlind;
      players[sbIdx].bet = smallBlind;
    }
    if (bbIdx != -1) {
      players[bbIdx].chips -= bigBlind;
      players[bbIdx].bet = bigBlind;
    }

    pot.addBet(players[sbIdx], smallBlind);
    pot.addBet(players[bbIdx], bigBlind);

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
    int callAmount = potLastCallAmount ?? (bettingRound!.currentPlayerIndex < players.length ? bettingRound!.currentBet : 0);
    int potLimit = potLastLimit ?? bettingRound!.calculatePotLimit();
    int currentPlayerIndex = bettingRound!.currentPlayerIndex;
    Player currentPlayer = players[currentPlayerIndex];
    
    String potDetailsStr;
    
    // 저장된 값이 있으면 확실하게 그 값을 사용하도록 확실히 함
    if (potLastCurrentPot != null && potLastCurrentPot! > 0) {
      currentPot = potLastCurrentPot!;
    
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
        return '${p.bet}$posName';
      }).join(' + ');
      
      if (bettingPlayersExceptCurrent.length > 1) {
        potDetailsStr += ' = $currentPot';
      } else if (bettingPlayersExceptCurrent.isEmpty) {
        potDetailsStr = '$currentPot'; // 빈 경우에도 저장된 값 표시
      }
    } else {
      // 저장된 값이 없으면 현재 베팅을 합산해서 사용 (현재 플레이어 제외)
      // 모든 플레이어의 베팅을 합산하되, 현재 POT!을 외친 플레이어는 제외
      currentPot = players.where((p) => p != currentPlayer).fold(0, (sum, p) => sum + p.bet);
      
      // 베팅한 모든 플레이어(현재 POT!을 외친 플레이어 제외, 폴드한 플레이어 포함)
      List<Player> bettingPlayersExceptCurrent = players.where((p) => p.bet > 0 && p != currentPlayer).toList();
      
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
        return '${p.bet}$posName';
      }).join(' + ');
      
      if (bettingPlayersExceptCurrent.length > 1) {
        potDetailsStr += ' = $currentPot';
      } else if (bettingPlayersExceptCurrent.isEmpty) {
        potDetailsStr = '0';
    }
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
    
    // 금액 단위 설정 (1500/3000 블라인드일 경우 500단위로 조정)
    int step = smallBlind == 1500 ? 500 : 100;
    int numSteps = ((maxRaise - minRaise) ~/ step) + 1;
    int raiseAmount = minRaise + (numSteps > 1 ? random.nextInt(numSteps) * step : 0);
    
    // 최종 레이즈 금액이 플레이어 칩보다 많으면 올인
    if (raiseAmount > player.chips) {
      debugPrint('Action: ALL-IN (부족한 칩) | Player: ${player.name} | 보유 칩: \$${player.chips} | potLimit: \$${potLimit}');
      bettingRound!.performAction('allIn');
      playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
      return true;
    }
    
    // 레이즈 후 바로 POT! 액션을 하지 않도록 액션 히스토리에는 레이즈만 기록
    // 정상적인 레이즈 실행
    debugPrint('Action: RAISE | Player: ${player.name} | raiseAmount: \$${raiseAmount}');
    bettingRound!.performAction('raise', raiseAmount);
    playerActionHistory[playerIndex].add('RAISE: ${formatAmount(raiseAmount)}');
    raiseCount++;
    return true;
  }
  
  /// 콜 액션 실행
  bool _performCallAction(Player player, int playerIndex) {
    int callAmount = bettingRound!.currentBet;
    
    if (callAmount > player.chips) {
      // 칩이 부족하면 올인
      debugPrint('Action: ALL-IN (콜 금액 부족) | Player: ${player.name} | 보유 칩: \$${player.chips} | 콜 금액: \$${callAmount}');
      bettingRound!.performAction('allIn');
      playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
    } else {
      debugPrint('Action: CALL | Player: ${player.name} | callAmount: \$${callAmount}');
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
    int potLimit = bettingRound!.calculatePotLimit();
    
    // 콜 금액 계산
    int callAmount = bettingRound!.currentBet;
    
    // 현재 팟 = 모든 플레이어의 베팅 합계에서 현재 플레이어의 베팅을 뺀 값
    int currentPot = players.where((p) => p != player).fold(0, (sum, p) => sum + p.bet);
    
    // 최종 POT 베팅은 플레이어의 최대 베팅 가능 금액과 팟 리밋 중 작은 값
    int totalPlayerChips = player.chips + player.bet;
    int potBet = min(potLimit, totalPlayerChips);
    
    // 1500/3000 블라인드일 경우 500단위로 조정
    if (smallBlind == 1500) {
      potBet = (potBet ~/ 500) * 500;
    }
    
    // POT 액션 정보 저장 - 확실하게 현재 값 저장
    potCorrectAnswer = potBet;
    potLastCurrentPot = currentPot; // 현재팟 저장(현재 플레이어 베팅 제외)
    potLastCallAmount = callAmount; // 콜 금액 저장
    potLastLimit = potLimit;
    
    debugPrint('------ POT! 계산 상세 ------');
    debugPrint('현재 팟: \$${currentPot} | 콜 금액: \$${callAmount}');
    debugPrint('플레이어 총 칩: \$${totalPlayerChips} | 팟 리밋: \$${potLimit}');
    debugPrint('최종 POT 베팅: \$${potBet}');
    debugPrint('Action: POT! | Player: ${player.name} | potBet: \$${potBet}');
    
    // POT 액션 수행 - 팟 리밋을 존중
    if (player.chips <= potLimit - player.bet) {
      // 칩이 부족하면 올인
      debugPrint('플레이어 칩이 부족하여 올인');
      bettingRound!.performAction('allIn');
    } else {
      bettingRound!.performAction('raise', potBet);
    }
    
    playerActionHistory[playerIndex].add('POT!');
    
    // POT 효과음 재생
    _playSound('pot');
    
    // 애니메이션 시작 전에 상태 변경
    isAnimating = true; // 애니메이션 진행 중으로 표시
    
    // POT 애니메이션 활성화
    showPotAnimation = true;
    potAnimationPlayerId = playerIndex;
    
    // 애니메이션 후 상태 변경을 위한 지연 설정
    Future.delayed(const Duration(milliseconds: 600), () {
      if (isGameStarted) { // 게임이 여전히 진행 중인지 확인
        showPotAnimation = false;
        isPotGuessing = true;
        isAnimating = false; // 애니메이션 완료 상태로 변경
        notifyListeners();
      }
    });
    
    isPotGuessing = false; // 애니메이션 동안은 guessing 상태 비활성화
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
    
    if (userGuess == correctPot) {
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