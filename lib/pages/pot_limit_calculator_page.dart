import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_language.dart';
import '../services/pot_limit_calculation_service.dart';
import '../widgets/pot_limit_calculator/preflop_calculator_widget.dart';
import '../widgets/pot_limit_calculator/postflop_calculator_widget.dart';
import '../widgets/pot_limit_calculator/calculation_result_widget.dart';

/// 팟 리밋 계산기 페이지
///
/// 프리플랍과 포스트플랍 팟 리밋 계산을 제공하는 페이지입니다.
class PotLimitCalculatorPage extends StatefulWidget {
  const PotLimitCalculatorPage({Key? key}) : super(key: key);

  @override
  State<PotLimitCalculatorPage> createState() => _PotLimitCalculatorPageState();
}

class _PotLimitCalculatorPageState extends State<PotLimitCalculatorPage> 
    with SingleTickerProviderStateMixin {
  // 탭 컨트롤러
  late TabController _tabController;
  
  // 프리플랍 계산기 컨트롤러
  final TextEditingController _sbController = TextEditingController(text: '400');
  final TextEditingController _bbController = TextEditingController(text: '800');
  final TextEditingController _preflopBetController = TextEditingController();
  List<int> _preflopBets = [];
  
  // 포스트플랍 계산기 컨트롤러
  final TextEditingController _flopPotController = TextEditingController();
  final TextEditingController _flopBetController = TextEditingController();
  List<int> _postflopBets = [];
  
  // 계산 결과
  int calculatedPotLimit = 0;
  bool hasCalculated = false;
  String calculationExplanation = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // 탭 변경 시 계산 결과 초기화
      setState(() {
        hasCalculated = false;
      });
    });
  }

  @override
  void dispose() {
    _sbController.dispose();
    _bbController.dispose();
    _preflopBetController.dispose();
    _flopPotController.dispose();
    _flopBetController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 프리플랍 베팅을 추가합니다.
  void _addPreflopBet() {
    final input = PotLimitCalculationService.validateInput(_preflopBetController.text);
    
    if (input == null) {
      _showErrorMessage(AppLanguage.isKorean ? '베팅 금액을 입력하세요' : 'Enter bet amount');
      return;
    }
    
    if (input <= 0) {
      _showErrorMessage(AppLanguage.getText('invalidNumberError'));
      return;
    }
    
    setState(() {
      _preflopBets.add(input);
      _preflopBetController.clear();
    });
  }

  /// 프리플랍 베팅을 삭제합니다.
  void _removePreflopBet(int index) {
    setState(() {
      _preflopBets.removeAt(index);
    });
  }

  /// 포스트플랍 베팅을 추가합니다.
  void _addPostflopBet() {
    final input = PotLimitCalculationService.validateInput(_flopBetController.text);
    
    if (input == null) {
      _showErrorMessage(AppLanguage.isKorean ? '베팅 금액을 입력하세요' : 'Enter bet amount');
      return;
    }
    
    if (input <= 0) {
      _showErrorMessage(AppLanguage.getText('invalidNumberError'));
      return;
    }
    
    setState(() {
      _postflopBets.add(input);
      _flopBetController.clear();
    });
  }

  /// 포스트플랍 베팅을 삭제합니다.
  void _removePostflopBet(int index) {
    setState(() {
      _postflopBets.removeAt(index);
    });
  }

  /// 프리플랍 팟 리밋을 계산합니다.
  void _calculatePreflopPotLimit() {
    // 입력값 유효성 검사
    final sb = PotLimitCalculationService.validateInput(_sbController.text);
    final bb = PotLimitCalculationService.validateInput(_bbController.text);
    
    if (sb == null || bb == null) {
      _showErrorMessage(AppLanguage.getText('invalidNumberError'));
      return;
    }
    
    final additionalBet = PotLimitCalculationService.validateInput(_preflopBetController.text) ?? 0;
    
    // 계산 실행
    final result = PotLimitCalculationService.calculatePreflopPotLimit(
      sb, bb, _preflopBets, additionalBet
    );
    
    setState(() {
      calculatedPotLimit = result.potLimit;
      calculationExplanation = result.explanation;
      hasCalculated = true;
    });
  }

  /// 포스트플랍 팟 리밋을 계산합니다.
  void _calculatePostflopPotLimit() {
    // 입력값 유효성 검사
    final currentPot = PotLimitCalculationService.validateInput(_flopPotController.text);
    
    if (currentPot == null) {
      _showErrorMessage(AppLanguage.getText('invalidNumberError'));
      return;
    }
    
    final additionalBet = PotLimitCalculationService.validateInput(_flopBetController.text) ?? 0;
    
    // 계산 실행
    final result = PotLimitCalculationService.calculatePostflopPotLimit(
      currentPot, _postflopBets, additionalBet
    );
    
    setState(() {
      calculatedPotLimit = result.potLimit;
      calculationExplanation = result.explanation;
      hasCalculated = true;
    });
  }

  /// 에러 메시지를 표시합니다.
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLanguage.getText('potLimitCalculator'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withAlpha((0.7 * 255).round()),
          indicatorColor: Colors.amber,
          tabs: [
            Tab(text: AppLanguage.isKorean ? '프리플랍' : 'Preflop'),
            Tab(text: AppLanguage.isKorean ? '포스트플랍' : 'Postflop'),
          ],
        ),
      ),
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
        child: TabBarView(
          controller: _tabController,
          children: [
            // 프리플랍 계산기 탭
            _buildPreflopTab(),
            // 포스트플랍 계산기 탭
            _buildPostflopTab(),
          ],
        ),
      ),
    );
  }

  /// 프리플랍 탭을 빌드합니다.
  Widget _buildPreflopTab() {
    return Column(
      children: [
        Expanded(
          child: PreflopCalculatorWidget(
            sbController: _sbController,
            bbController: _bbController,
            preflopBetController: _preflopBetController,
            preflopBets: _preflopBets,
            onAddBet: _addPreflopBet,
            onRemoveBet: _removePreflopBet,
            onCalculate: _calculatePreflopPotLimit,
          ),
        ),
        if (hasCalculated && _tabController.index == 0)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CalculationResultWidget(
              calculationExplanation: calculationExplanation,
              calculatedPotLimit: calculatedPotLimit,
            ),
          ),
      ],
    );
  }

  /// 포스트플랍 탭을 빌드합니다.
  Widget _buildPostflopTab() {
    return Column(
      children: [
        Expanded(
          child: PostflopCalculatorWidget(
            flopPotController: _flopPotController,
            flopBetController: _flopBetController,
            postflopBets: _postflopBets,
            onAddBet: _addPostflopBet,
            onRemoveBet: _removePostflopBet,
            onCalculate: _calculatePostflopPotLimit,
          ),
        ),
        if (hasCalculated && _tabController.index == 1)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CalculationResultWidget(
              calculationExplanation: calculationExplanation,
              calculatedPotLimit: calculatedPotLimit,
            ),
          ),
      ],
    );
  }
} 