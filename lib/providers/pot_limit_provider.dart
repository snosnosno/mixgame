import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../models/player.dart';
import '../models/pot.dart';
import '../models/betting_round.dart';
import '../services/pot_limit_calculation_service.dart';

/// 최적화된 팟 리밋 게임 상태 관리 Provider
/// 
/// 성능 최적화와 메모리 효율성을 개선한 버전입니다.
class PotLimitProvider extends ChangeNotifier {
  // === 핵심 게임 상태 ===
  bool _isGameStarted = false;
  bool _isPotGuessing = false;
  bool _isAnimating = false;
  bool _showNextGameButton = false;
  
  // === 게임 설정 ===
  int _smallBlind = 100;
  int _bigBlind = 200;
  int _numberOfPlayers = 6;
  bool _useRandomBlinds = true;
  bool _soundEnabled = true;
  
  // === 게임 데이터 ===
  int _currentScore = 0;
  int _raiseCount = 0;
  String _resultMessage = '';
  BettingRound? _bettingRound;
  Pot _pot = Pot();

  // === 플레이어 관련 ===
  List<Player> _players = [];
  List<List<String>> _playerActionHistory = [];
  List<int> _chipsInitial = [];

  // === POT 액션 정보 ===
  int? _potCorrectAnswer;
  int? _potLastCurrentPot;
  int? _potLastCallAmount;
  int? _potLastLimit;

  // === 애니메이션 상태 ===
  bool _showPotAnimation = false;
  int _potAnimationPlayerId = -1;
  
  // === 컨트롤러 및 타이머 ===
  late final TextEditingController _potGuessController;
  Timer? _gameTimer;
  
  // === 상수 ===
  static const List<int> _blindLevels = [100, 200, 400, 600, 1500, 3000];
  static const Duration _animationDuration = Duration(milliseconds: 600);
  static const Duration _actionInterval = Duration(seconds: 1);
  static const Duration _nextGameDelay = Duration(seconds: 2);

  // === 생성자 ===
  PotLimitProvider() {
    _potGuessController = TextEditingController();
    _initializePlayerActionHistory();
  }

  // === Getters (읽기 전용) ===
  bool get isGameStarted => _isGameStarted;
  bool get isPotGuessing => _isPotGuessing;
  bool get isAnimating => _isAnimating;
  bool get showNextGameButton => _showNextGameButton;
  bool get showPotAnimation => _showPotAnimation;
  
  int get smallBlind => _smallBlind;
  int get bigBlind => _bigBlind;
  int get numberOfPlayers => _numberOfPlayers;
  int get currentScore => _currentScore;
  int get raiseCount => _raiseCount;
  int get potAnimationPlayerId => _potAnimationPlayerId;
  int? get potCorrectAnswer => _potCorrectAnswer;
  
  bool get useRandomBlinds => _useRandomBlinds;
  bool get soundEnabled => _soundEnabled;
  
  String get resultMessage => _resultMessage;
  
  List<Player> get players => List.unmodifiable(_players);
  List<List<String>> get playerActionHistory => List.unmodifiable(_playerActionHistory);
  
  BettingRound? get bettingRound => _bettingRound;
  Pot get pot => _pot;
  
  TextEditingController get potGuessController => _potGuessController;

  List<int> get chipsInitial => List.unmodifiable(_chipsInitial);

  // === 초기화 메서드 ===
  void _initializePlayerActionHistory() {
    _playerActionHistory = List.generate(6, (_) => <String>[]);
  }

  // === 게임 설정 메서드 ===
  
  /// 커스텀 블라인드 설정
  void setCustomBlinds(int sb, int bb) {
    if (sb < 10) sb = 10;
    if (bb < 10) bb = 10;
    if (sb >= bb) bb = sb * 2;
    
    final changed = _smallBlind != sb || _bigBlind != bb || _useRandomBlinds;
    
    _smallBlind = sb;
    _bigBlind = bb;
    _useRandomBlinds = false;
    
    if (changed) notifyListeners();
  }

  /// 랜덤 블라인드 모드 설정
  void setRandomBlinds() {
    if (!_useRandomBlinds) {
      _useRandomBlinds = true;
      notifyListeners();
    }
  }

  /// 플레이어 수 설정
  void setNumberOfPlayers(int count) {
    if (count != _numberOfPlayers && count >= 2 && count <= 6) {
      _numberOfPlayers = count;
      _initializePlayerActionHistory();
      notifyListeners();
    }
  }

  /// 사운드 설정
  void setSoundEnabled(bool enabled) {
    if (_soundEnabled != enabled) {
      _soundEnabled = enabled;
      notifyListeners();
    }
  }

  // === 게임 제어 메서드 ===
  
  /// 게임 리셋
  void resetGame() {
    _cancelGameTimer();
    
    _isGameStarted = false;
    _isPotGuessing = false;
    _isAnimating = false;
    _showNextGameButton = false;
    _resultMessage = '';
    _raiseCount = 0;
    
    _potCorrectAnswer = null;
    _potLastCurrentPot = null;
    _potLastCallAmount = null;
    _potLastLimit = null;
    
    _showPotAnimation = false;
    _potAnimationPlayerId = -1;
    
    _potGuessController.clear();
    
    notifyListeners();
  }

  /// 새 게임 시작
  void startNewGame() {
    _cancelGameTimer();
    
    _isGameStarted = true;
    _pot = Pot();
    _isPotGuessing = false;
    _resultMessage = '';
    _showNextGameButton = false;
    _raiseCount = 0;
    _isAnimating = false;
    
    _potCorrectAnswer = null;
    _potLastCurrentPot = null;
    _potLastCallAmount = null;
    _potLastLimit = null;
    
    _potGuessController.clear();
    
    _initializePlayers();
    _startGameTimer();
    
    notifyListeners();
  }

  /// 플레이어 초기화
  void initializePlayers() {
    if (_useRandomBlinds) {
      _generateRandomBlinds();
    }

    final random = Random();
    _players = List.generate(
      _numberOfPlayers,
      (index) => Player(
        name: 'Player ${index + 1}',
        chips: max((random.nextInt(599) * 500) + 500, _smallBlind * 5),
        hand: [],
        position: Position.values[index % Position.values.length],
      ),
    );
    
    _chipsInitial = _players.map((p) => p.chips).toList();
    _setupInitialBets();
    _initializeBettingRound();
    _initializePlayerActionHistory();
  }

  /// 플레이어 초기화 (내부용)
  void _initializePlayers() {
    initializePlayers();
  }

  /// 랜덤 블라인드 생성
  void _generateRandomBlinds() {
    final random = Random();
    final blindIndex = random.nextInt(_blindLevels.length);
    _smallBlind = _blindLevels[blindIndex];
    _bigBlind = _smallBlind * 2;
  }

  /// 초기 베팅 설정 (SB, BB)
  void _setupInitialBets() {
    final sbIdx = _players.indexWhere((p) => p.position == Position.smallBlind);
    final bbIdx = _players.indexWhere((p) => p.position == Position.bigBlind);
    
    if (sbIdx != -1 && _players[sbIdx].chips >= _smallBlind) {
      _players[sbIdx].chips -= _smallBlind;
      _players[sbIdx].bet = _smallBlind;
      _pot.addBet(_players[sbIdx], _smallBlind);
      _playerActionHistory[sbIdx].add('SB: ${formatAmount(_smallBlind)}');
    }
    
    if (bbIdx != -1 && _players[bbIdx].chips >= _bigBlind) {
      _players[bbIdx].chips -= _bigBlind;
      _players[bbIdx].bet = _bigBlind;
      _pot.addBet(_players[bbIdx], _bigBlind);
      _playerActionHistory[bbIdx].add('BB: ${formatAmount(_bigBlind)}');
    }
  }

  /// 베팅 라운드 초기화
  void _initializeBettingRound() {
    _bettingRound = BettingRound(players: _players, pot: _pot);
    final utgIdx = _players.indexWhere((p) => p.position == Position.underTheGun);
    if (utgIdx != -1) _bettingRound!.currentPlayerIndex = utgIdx;
  }

  // === 타이머 관리 ===
  
  /// 게임 타이머 시작
  void _startGameTimer() {
    _gameTimer = Timer.periodic(_actionInterval, (timer) {
      if (!_isGameStarted || _isPotGuessing || _isAnimating || 
          _players.length <= 2 || _bettingRound == null) {
        return;
    }
    
      final currentPlayerIndex = _bettingRound!.currentPlayerIndex;
      performPlayerAction(currentPlayerIndex);
    });
  }

  /// 게임 타이머 취소
  void _cancelGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  // === 유틸리티 메서드 ===
  
  /// 금액 포맷팅 (최적화: 서비스 위임)
  String formatAmount(int amount) {
    return PotLimitCalculationService.formatAmount(amount);
  }

  /// 효과음 재생 (최적화: 조건부 실행)
  void _playSound(String soundName) {
    if (!_soundEnabled) return;
    // 실제 사운드 재생 로직은 별도 서비스로 분리 예정
    debugPrint('Playing sound: $soundName');
  }

  // === 게임 액션 메서드 ===
  
  /// 플레이어 액션 실행 (배치 업데이트 적용)
  void performPlayerAction(int playerIndex) {
    if (_isPotGuessing || _bettingRound == null || _isAnimating) return;

    if (_checkAndMoveToNextActivePlayer()) return;
    
    _logPlayerStatus();
    final stateChanged = _performRandomAction(playerIndex);
    
    if (stateChanged == true) {
      // 배치 업데이트: 한 번만 notifyListeners 호출
      notifyListeners();
      _checkForGameEnd();
    }
  }
  
  /// 다음 활성 플레이어로 이동
  bool _checkAndMoveToNextActivePlayer() {
    int loopCount = 0;
    var player = _players[_bettingRound!.currentPlayerIndex];
    
    while ((player.isFolded || player.isAllIn) && loopCount <= _players.length) {
      loopCount++;
      _bettingRound!.nextPlayer();
      player = _players[_bettingRound!.currentPlayerIndex];
    }
    
    final allPlayersInactive = _players.every((p) => p.isFolded || p.isAllIn);
    
    if (allPlayersInactive) {
      debugPrint('모든 플레이어가 비활성 상태. 다음 게임으로 진행.');
      Timer(_nextGameDelay, startNewGame);
      return true;
    }
    
    return false;
  }
  
  /// 게임 종료 체크
  void _checkForGameEnd() {
    if (_isPotGuessing) return;
    
    final allInactiveAfterAction = _players.every((p) => p.isFolded || p.isAllIn);
    
    if (allInactiveAfterAction) {
      debugPrint('액션 후 모든 플레이어 비활성 상태. 다음 게임으로 진행.');
      Timer(_nextGameDelay, startNewGame);
    }
  }

  /// 플레이어 상태 로깅
  void _logPlayerStatus() {
    if (kDebugMode) {
    debugPrint('--- Player Status ---');
      for (var p in _players) {
        debugPrint('${p.name} | chips: \$${p.chips} | bet: \$${p.bet} | '
                  'isAllIn: ${p.isAllIn} | isFolded: ${p.isFolded}');
    }
    }
  }
  
  /// 랜덤 액션 수행
  bool _performRandomAction(int playerIndex) {
    final random = Random();
    final player = _players[_bettingRound!.currentPlayerIndex];
    
    // 음수 칩스 보정
    _fixNegativeChips();
    
    final isLastActionPlayer = _isLastActionPlayer();
    
    // BB 포지션이거나 마지막 액션 플레이어는 POT! 강제 실행
    if (player.position == Position.bigBlind || isLastActionPlayer) {
      return _performPotAction(player, playerIndex);
    }
    
    // 일반 랜덤 액션
    final action = random.nextInt(100);
    
    if (action < 30) {
      return _performRaiseAction(player, playerIndex, random);
    } else if (action < 50) {
      return _performCallAction(player, playerIndex);
    } else if (action < 70) {
      return _performFoldAction(player, playerIndex);
    } else {
      return _performPotAction(player, playerIndex);
    }
  }

  /// 음수 칩스 보정
  void _fixNegativeChips() {
    for (var p in _players) {
      if (p.chips < 0) {
        debugPrint('음수 칩스 감지 및 수정: ${p.name}의 칩스가 ${p.chips}에서 0으로 조정');
        p.chips = 0;
      }
    }
    }
    
  /// 마지막 액션 플레이어인지 확인
  bool _isLastActionPlayer() {
    int nextPlayerIndex = (_bettingRound!.currentPlayerIndex + 1) % _players.length;
    int checkCount = 0;
    
    while (checkCount < _players.length - 1) {
      if (nextPlayerIndex == _bettingRound!.currentPlayerIndex) break;
      
      final nextPlayer = _players[nextPlayerIndex];
      if (!nextPlayer.isFolded && !nextPlayer.isAllIn) {
        return false;
      }
      
      nextPlayerIndex = (nextPlayerIndex + 1) % _players.length;
      checkCount++;
    }
    
    return true;
  }

  /// 폴드 액션 수행
  bool _performFoldAction(Player player, int playerIndex) {
      debugPrint('Action: FOLD | Player: ${player.name}');
    _bettingRound!.performAction('fold');
    _playerActionHistory[playerIndex].add('FOLD');
    return true;
  }
  
  /// 레이즈 액션 수행
  bool _performRaiseAction(Player player, int playerIndex, Random random) {
    final potLimit = _bettingRound!.calculatePotLimit();
    final maxRaise = min(potLimit, player.chips);
    final minRaise = _bettingRound!.getMinimumRaise();
    
    if (maxRaise < minRaise) {
      debugPrint('Action: ALL-IN (부족한 칩) | Player: ${player.name}');
      _bettingRound!.performAction('allIn');
      _playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
      return true;
    }
    
    final step = _getAmountStep();
    final numSteps = ((maxRaise - minRaise) ~/ step) + 1;
    final raiseAmount = minRaise + (numSteps > 1 ? random.nextInt(numSteps) * step : 0);
    
    final formattedAmount = formatAmount(raiseAmount);
    final displayRaiseAmount = int.parse(formattedAmount.replaceAll(',', ''));
    
    if (displayRaiseAmount > player.chips) {
      debugPrint('Action: ALL-IN (부족한 칩) | Player: ${player.name}');
      _bettingRound!.performAction('allIn');
      _playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
      return true;
    }
    
    debugPrint('Action: RAISE | Player: ${player.name} | raiseAmount: \$${displayRaiseAmount}');
    _bettingRound!.performAction('raise', displayRaiseAmount);
    _playerActionHistory[playerIndex].add('RAISE: $formattedAmount');
    _raiseCount++;
    return true;
  }
  
  /// 콜 액션 수행
  bool _performCallAction(Player player, int playerIndex) {
    final maxBet = _players.fold(0, (max, p) => p.bet > max ? p.bet : max);
    final callAmount = maxBet;
    final playerCallDifference = max(0, maxBet - player.bet);
    
    if (playerCallDifference > player.chips) {
      debugPrint('Action: ALL-IN (콜 금액 부족) | Player: ${player.name}');
      _bettingRound!.performAction('allIn');
      _playerActionHistory[playerIndex].add('ALL-IN: ${formatAmount(player.bet)}');
    } else {
      debugPrint('Action: CALL | Player: ${player.name}');
      _bettingRound!.performAction('call');
      
      if (player.position == Position.bigBlind || player.position == Position.smallBlind) {
        _playerActionHistory[playerIndex].clear();
        _playerActionHistory[playerIndex].add('CALL: ${formatAmount(player.bet)}');
      } else {
        _playerActionHistory[playerIndex].add('CALL: ${formatAmount(callAmount)}');
      }
    }
    return true;
  }
  
  /// POT 액션 수행 (최적화: 계산 로직 분리)
  bool _performPotAction(Player player, int playerIndex) {
    if (player.chips < 0) player.chips = 0;
    
    final calculationResult = _calculatePotAction(player);
    final potBet = calculationResult['potBet'] as int;
    
    // POT 액션 정보 저장
    _potCorrectAnswer = potBet;
    _potLastCurrentPot = calculationResult['currentPot'] as int;
    _potLastCallAmount = calculationResult['callAmount'] as int;
    _potLastLimit = calculationResult['potLimit'] as int;
    
    debugPrint('Action: POT! | Player: ${player.name} | potBet: \$${potBet}');
    
    final totalPlayerChips = player.chips + player.bet;
    if (totalPlayerChips <= _potLastLimit!) {
      _bettingRound!.performAction('allIn');
    } else {
      _bettingRound!.performAction('raise', potBet);
    }
    
    _playerActionHistory[playerIndex].add('POT!');
    _playSound('pot');
    _startPotAnimation(playerIndex);
    _raiseCount++;
    
    return true;
  }

  /// POT 액션 계산 (별도 메서드로 분리)
  Map<String, int> _calculatePotAction(Player player) {
    final maxBet = _players.fold(0, (max, p) => p.bet > max ? p.bet : max);
    final callAmount = maxBet;
    
    int currentPot = 0;
    for (Player p in _players) {
      if (p != player) currentPot += p.bet;
    }
    
    final formattedCallAmount = int.tryParse(formatAmount(callAmount)) ?? callAmount;
    final formattedCurrentPot = int.tryParse(formatAmount(currentPot)) ?? currentPot;
    final formattedPotLimit = formattedCurrentPot + (formattedCallAmount * 2);
    
    final totalPlayerChips = player.chips + player.bet;
    final potBet = totalPlayerChips <= formattedPotLimit ? totalPlayerChips : formattedPotLimit;
    
    return {
      'potBet': potBet,
      'currentPot': formattedCurrentPot,
      'callAmount': formattedCallAmount,
      'potLimit': formattedPotLimit,
    };
  }

  /// POT 애니메이션 시작
  void _startPotAnimation(int playerIndex) {
    _isAnimating = true;
    _showPotAnimation = true;
    _potAnimationPlayerId = playerIndex;
    
    Timer(_animationDuration, () {
      if (_isGameStarted) {
        _showPotAnimation = false;
        _isPotGuessing = true;
        _isAnimating = false;
        notifyListeners();
      }
    });
    
    _isPotGuessing = false;
    _resultMessage = '';
  }

  /// 금액 단계 계산
  int _getAmountStep() {
    if (_smallBlind >= 1500 && _smallBlind < 4000) {
      return 500;
    } else if (_smallBlind >= 4000) {
      return 1000;
    } else {
      return 100;
    }
  }
    
  // === POT 추측 관련 ===

  /// POT 금액 추측 확인 (최적화: 조기 반환)
  void checkPotGuess() {
    if (_showNextGameButton) return;
    
    FocusManager.instance.primaryFocus?.unfocus();
    
    final userGuess = _parseUserGuess();
    if (userGuess == null) return;
    
    final correctPot = _potCorrectAnswer ?? 0;
    final isCorrect = _isGuessCorrect(userGuess, correctPot);
    
    if (isCorrect) {
      _currentScore++;
      _resultMessage = '${AppLanguage.getText('correctAnswer')}$_currentScore';
      _playSound('correct');
    } else {
      _resultMessage = '${AppLanguage.getText('wrongAnswer')}${AppLanguage.getText('correctAnswerIs')} ${formatAmount(correctPot)}';
      _playSound('wrong');
    }
    
    _showNextGameButton = true;
    _clearPlayerBets();
    _cancelGameTimer();
    
    notifyListeners();
  }

  /// 사용자 입력 파싱
  int? _parseUserGuess() {
    try {
      final userGuess = int.parse(_potGuessController.text.trim());
      if (userGuess < 0) throw const FormatException('음수는 허용되지 않습니다.');
      return userGuess;
    } catch (e) {
      _resultMessage = AppLanguage.getText('invalidNumberError');
      notifyListeners();
      return null;
    }
  }

  /// 추측이 정확한지 확인 (95% 허용 오차)
  bool _isGuessCorrect(int userGuess, int correctPot) {
    return userGuess == correctPot || 
           (correctPot > 0 && userGuess >= correctPot * 0.95 && userGuess <= correctPot * 1.05);
  }

  /// 플레이어 베팅 초기화
  void _clearPlayerBets() {
    for (var p in _players) {
      p.bet = 0;
    }
  }

  // === 팟 계산 상세 정보 ===
  
  /// 현재 팟 계산식 정보 반환 (최적화: 캐시된 값 우선 사용)
  Map<String, dynamic> getPotCalculationDetails() {
    if (_bettingRound == null) {
      return {
        'potLimit': 0,
        'currentPot': 0,
        'callAmount': 0,
        'explanation': AppLanguage.getText("gameNotStarted")
      };
    }
    
    final currentPot = _potLastCurrentPot ?? _calculateCurrentPot();
    final callAmount = _potLastCallAmount ?? _calculateCallAmount();
    final potLimit = _potLastLimit ?? (currentPot + callAmount * 2);
    
    return {
      'potLimit': potLimit,
      'currentPot': currentPot,
      'callAmount': callAmount,
      'correctAnswer': _potCorrectAnswer,
      'explanation': _buildExplanation(currentPot, callAmount, potLimit)
    };
  }

  /// 현재 팟 계산
  int _calculateCurrentPot() {
    final currentPlayerIndex = _bettingRound!.currentPlayerIndex; 
    final currentPlayer = _players[currentPlayerIndex];
    final rawCurrentPot = _players.where((p) => p != currentPlayer).fold(0, (sum, p) => sum + p.bet);
    return int.tryParse(formatAmount(rawCurrentPot)) ?? rawCurrentPot;
  }

  /// 콜 금액 계산
  int _calculateCallAmount() {
    final maxBet = _players.fold(0, (max, p) => p.bet > max ? p.bet : max);
    return int.tryParse(formatAmount(maxBet)) ?? maxBet;
  }

  /// 설명 텍스트 생성
  String _buildExplanation(int currentPot, int callAmount, int potLimit) {
    final currentPlayerIndex = _bettingRound!.currentPlayerIndex;
    final currentPlayer = _players[currentPlayerIndex];
    
    final bettingPlayersExceptCurrent = _players
        .where((p) => p.bet > 0 && p != currentPlayer)
        .toList();
    
    final potDetailsStr = _buildPotDetailsString(bettingPlayersExceptCurrent, currentPot);
    final correctAnswerText = _buildCorrectAnswerText();
    
    return '''
${AppLanguage.getText('currentPot')}:
$potDetailsStr

${AppLanguage.getText('callAmount')}:
$callAmount

${AppLanguage.getText('calculation')}:
$currentPot + ($callAmount × 2) = ${currentPot + callAmount * 2}

${AppLanguage.getText('potBetting')}:
$potLimit

${AppLanguage.getText('answer')}:
$correctAnswerText
''';
  }

  /// 팟 상세 문자열 생성
  String _buildPotDetailsString(List<Player> bettingPlayers, int currentPot) {
    if (bettingPlayers.isEmpty) return '$currentPot';
    
    final potDetailsStr = bettingPlayers.map((p) {
      final posName = _getPositionName(p.position);
      final betStr = formatAmount(p.bet);
      return '$betStr$posName';
    }).join(' + ');
    
    return bettingPlayers.length > 1 ? '$potDetailsStr = $currentPot' : potDetailsStr;
  }

  /// 포지션 이름 반환
  String _getPositionName(Position position) {
    switch (position) {
      case Position.smallBlind: return '(SB)';
      case Position.bigBlind: return '(BB)';
      case Position.underTheGun: return '(UTG)';
      case Position.hijack: return '(HJ)';
      case Position.cutoff: return '(CO)';
      case Position.dealer: return '(DEALER)';
      default: return '';
    }
  }

  /// 정답 텍스트 생성
  String _buildCorrectAnswerText() {
    final correctAnswerValue = _potCorrectAnswer;
    if (correctAnswerValue == null) return '';
    
    final calculatedPotLimit = (_potLastCurrentPot ?? 0) + ((_potLastCallAmount ?? 0) * 2);
    final isAllIn = calculatedPotLimit > correctAnswerValue;
    
    return isAllIn 
        ? '$correctAnswerValue (${AppLanguage.getText('allIn')})'
        : '$correctAnswerValue';
    }
    
  // === 리소스 정리 ===
  
  @override
  void dispose() {
    _cancelGameTimer();
    _potGuessController.dispose();
    super.dispose();
  }
} 