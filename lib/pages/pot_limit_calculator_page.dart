import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../home_page.dart';

class PotLimitCalculatorPage extends StatefulWidget {
  const PotLimitCalculatorPage({Key? key}) : super(key: key);

  @override
  State<PotLimitCalculatorPage> createState() => _PotLimitCalculatorPageState();
}

class _PotLimitCalculatorPageState extends State<PotLimitCalculatorPage> with SingleTickerProviderStateMixin {
  // 탭 컨트롤러
  late TabController _tabController;
  
  // 일반 계산기 컨트롤러
  final TextEditingController _potController = TextEditingController();
  final TextEditingController _callController = TextEditingController();
  
  // 프리플랍 계산기 컨트롤러
  final TextEditingController _sbController = TextEditingController();
  final TextEditingController _bbController = TextEditingController();
  final TextEditingController _preflopBetController = TextEditingController();
  List<int> _preflopBets = []; // 프리플랍 베팅 리스트
  
  // 포스트플랍 계산기 컨트롤러
  final TextEditingController _flopPotController = TextEditingController();
  final TextEditingController _flopBetController = TextEditingController();
  List<int> _postflopBets = []; // 포스트플랍 베팅 리스트
  
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
    
    // 기본값 설정
    _sbController.text = '400';
    _bbController.text = '800';
  }

  @override
  void dispose() {
    _potController.dispose();
    _callController.dispose();
    _sbController.dispose();
    _bbController.dispose();
    _preflopBetController.dispose();
    _flopPotController.dispose();
    _flopBetController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // 프리플랍 베팅 추가
  void _addPreflopBet() {
    if (_preflopBetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLanguage.isKorean ? '베팅 금액을 입력하세요' : 'Enter bet amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      int bet = int.parse(_preflopBetController.text.trim());
      if (bet <= 0) throw FormatException('양수만 입력 가능합니다');
      
      setState(() {
        _preflopBets.add(bet);
        _preflopBetController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLanguage.getText('invalidNumberError')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // 프리플랍 베팅 삭제
  void _removePreflopBet(int index) {
    setState(() {
      _preflopBets.removeAt(index);
    });
  }
  
  // 포스트플랍 베팅 추가
  void _addPostflopBet() {
    if (_flopBetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLanguage.isKorean ? '베팅 금액을 입력하세요' : 'Enter bet amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      int bet = int.parse(_flopBetController.text.trim());
      if (bet <= 0) throw FormatException('양수만 입력 가능합니다');
      
      setState(() {
        _postflopBets.add(bet);
        _flopBetController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLanguage.getText('invalidNumberError')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // 포스트플랍 베팅 삭제
  void _removePostflopBet(int index) {
    setState(() {
      _postflopBets.removeAt(index);
    });
  }

  // 일반 계산 함수
  void _calculatePotLimit() {
    // 입력값 유효성 검사
    int currentPot = 0;
    int callAmount = 0;
    try {
      currentPot = int.parse(_potController.text.trim());
      callAmount = int.parse(_callController.text.trim());
      
      if (currentPot < 0 || callAmount < 0) {
        throw FormatException('음수는 허용되지 않습니다.');
      }
    } catch (e) {
      // 숫자가 아니거나 음수인 경우 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLanguage.getText('invalidNumberError')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // POT! 리밋 계산: 현재 팟 + (콜 금액 x 2)
    setState(() {
      calculatedPotLimit = currentPot + (callAmount * 2);
      calculationExplanation = '${_potController.text} + (${_callController.text} × 2) = $calculatedPotLimit';
      hasCalculated = true;
    });
  }
  
  // 프리플랍 계산 함수
  void _calculatePreflopPotLimit() {
    // 입력값 유효성 검사
    int sb = 0;
    int bb = 0;
    try {
      sb = int.parse(_sbController.text.trim());
      bb = int.parse(_bbController.text.trim());
      
      if (sb < 0 || bb < 0) {
        throw FormatException('음수는 허용되지 않습니다.');
      }
    } catch (e) {
      // 숫자가 아니거나 음수인 경우 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLanguage.getText('invalidNumberError')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 현재 팟 계산: SB + BB + 추가된 모든 베팅
    int currentPot = sb + bb + _preflopBets.fold(0, (sum, bet) => sum + bet);
    
    // 콜 금액 = BB (프리플랍에서는 일반적으로 BB가 콜 금액)
    int callAmount = bb;
    
    // 추가 베팅이 있으면 마지막 베팅이 콜 금액
    if (_preflopBets.isNotEmpty) {
      callAmount = _preflopBets.last;
    }
    
    // 현재 입력된 베팅도 있으면 처리
    int additionalBet = 0;
    if (_preflopBetController.text.isNotEmpty) {
      try {
        additionalBet = int.parse(_preflopBetController.text.trim());
        if (additionalBet > 0) {
          callAmount = additionalBet;
          currentPot += additionalBet;
        }
      } catch (e) {
        // 숫자가 아닌 경우 무시
      }
    }
    
    // POT! 리밋 계산: 현재 팟 + (콜 금액 x 2)
    setState(() {
      calculatedPotLimit = currentPot + (callAmount * 2);
      
      // 계산 과정 설명
      String potExplanation = '$sb(SB) + $bb(BB)';
      
      // 추가 베팅이 있으면 표시
      if (_preflopBets.isNotEmpty) {
        for (int bet in _preflopBets) {
          potExplanation += ' + $bet(베팅)';
        }
      }
      
      // 현재 입력 중인 베팅도 있으면 표시
      if (additionalBet > 0) {
        potExplanation += ' + $additionalBet(베팅)';
      }
      
      potExplanation += ' = $currentPot';
      
      calculationExplanation = '$potExplanation + ($callAmount × 2) = $calculatedPotLimit';
      hasCalculated = true;
    });
  }
  
  // 포스트플랍 계산 함수
  void _calculatePostflopPotLimit() {
    // 입력값 유효성 검사
    int currentPot = 0;
    try {
      currentPot = int.parse(_flopPotController.text.trim());
      
      if (currentPot < 0) {
        throw FormatException('음수는 허용되지 않습니다.');
      }
    } catch (e) {
      // 숫자가 아니거나 음수인 경우 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLanguage.getText('invalidNumberError')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 기본 팟에 추가된 모든 베팅을 더함
    int totalPot = currentPot + _postflopBets.fold(0, (sum, bet) => sum + bet);
    
    // 콜 금액 (마지막 베팅 또는 현재 입력 중인 베팅)
    int callAmount = 0;
    
    // 추가 베팅이 있으면 마지막 베팅이 콜 금액
    if (_postflopBets.isNotEmpty) {
      callAmount = _postflopBets.last;
    }
    
    // 현재 입력된 베팅도 있으면 처리
    int additionalBet = 0;
    if (_flopBetController.text.isNotEmpty) {
      try {
        additionalBet = int.parse(_flopBetController.text.trim());
        if (additionalBet > 0) {
          callAmount = additionalBet;
          totalPot += additionalBet;
        }
      } catch (e) {
        // 숫자가 아닌 경우 무시
      }
    }
    
    // POT! 리밋 계산: 현재 팟 + (콜 금액 x 2)
    setState(() {
      calculatedPotLimit = totalPot + (callAmount * 2);
      
      // 계산 과정 설명
      String potExplanation = '$currentPot(기본 팟)';
      
      // 추가 베팅이 있으면 표시
      if (_postflopBets.isNotEmpty) {
        for (int bet in _postflopBets) {
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
      
      calculationExplanation = '$potExplanation + ($callAmount × 2) = $calculatedPotLimit';
      hasCalculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLanguage.getText('potLimitCalculator'),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
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
            _buildPreflopCalculator(),
            // 포스트플랍 계산기 탭
            _buildPostflopCalculator(),
          ],
        ),
      ),
    );
  }
  
  // 프리플랍 계산기 위젯
  Widget _buildPreflopCalculator() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCalculatorCard(
              title: AppLanguage.isKorean ? '프리플랍 계산기' : 'Preflop Calculator',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SB:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          TextField(
                            controller: _sbController,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BB:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          TextField(
                            controller: _bbController,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  AppLanguage.isKorean ? '콜/레이즈 금액:' : 'Call/Raise Amount:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _preflopBetController,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: AppLanguage.isKorean ? '예: 1600 (콜)' : 'Ex: 1600 (call)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addPreflopBet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 4),
                          Text(
                            AppLanguage.isKorean ? '추가' : 'Add',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // 추가된 베팅 목록
                if (_preflopBets.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    AppLanguage.isKorean ? '추가된 베팅:' : 'Added Bets:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.all(8),
                      itemCount: _preflopBets.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          title: Text(
                            '${index + 1}. ${_preflopBets[index]}',
                            style: TextStyle(fontSize: 16),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: Colors.red, size: 20),
                            onPressed: () => _removePreflopBet(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                
                SizedBox(height: 20),
                _buildCalculateButton(_calculatePreflopPotLimit),
              ],
            ),
            SizedBox(height: 24),
            if (hasCalculated && _tabController.index == 0)
              _buildResultCard(calculationExplanation),
          ],
        ),
      ),
    );
  }
  
  // 포스트플랍 계산기 위젯
  Widget _buildPostflopCalculator() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCalculatorCard(
              title: AppLanguage.isKorean ? '포스트플랍 계산기' : 'Postflop Calculator',
              children: [
                Text(
                  AppLanguage.isKorean ? '현재 팟 금액:' : 'Current Pot:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                TextField(
                  controller: _flopPotController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: AppLanguage.isKorean ? '예: 5000' : 'Ex: 5000',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  AppLanguage.isKorean ? '베팅/레이즈 금액:' : 'Bet/Raise Amount:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _flopBetController,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: AppLanguage.isKorean ? '예: 2500 (베팅)' : 'Ex: 2500 (bet)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addPostflopBet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 4),
                          Text(
                            AppLanguage.isKorean ? '추가' : 'Add',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // 추가된 베팅 목록
                if (_postflopBets.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    AppLanguage.isKorean ? '추가된 베팅:' : 'Added Bets:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.all(8),
                      itemCount: _postflopBets.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          title: Text(
                            '${index + 1}. ${_postflopBets[index]}',
                            style: TextStyle(fontSize: 16),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: Colors.red, size: 20),
                            onPressed: () => _removePostflopBet(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                
                SizedBox(height: 20),
                _buildCalculateButton(_calculatePostflopPotLimit),
              ],
            ),
            SizedBox(height: 24),
            if (hasCalculated && _tabController.index == 1)
              _buildResultCard(calculationExplanation),
          ],
        ),
      ),
    );
  }
  
  // 계산기 카드 위젯
  Widget _buildCalculatorCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  // 계산 버튼 위젯
  Widget _buildCalculateButton(VoidCallback onPressed) {
    return Center(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          AppLanguage.getText('submit'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  // 결과 카드 위젯
  Widget _buildResultCard(String calculation) {
    return Card(
      elevation: 8,
      color: Colors.amber.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              AppLanguage.getText('potCalculation'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              AppLanguage.getText('calculation') + ':\n' + calculation,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLanguage.getText('potBetting') + ': $calculatedPotLimit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 