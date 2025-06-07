import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'pages/winner_game_page.dart';
import 'pages/pot_limit_page.dart';
import 'pages/pot_limit_calculator_page.dart';
import 'pages/hi_low_game_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'l10n/app_language.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _appVersion = '...'; // 초기값
  String _buildNumber = '...'; // 초기값

  // getText 함수를 AppLanguage에서 가져옵니다
  String getText(String key) => AppLanguage.getText(key);

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    });
  }

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
                color: Colors.amber.withAlpha((0.8 * 255).round()),
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
                              color: Colors.black.withAlpha((0.3 * 255).round()),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          getText('madeBy') + ' | Version $_appVersion+$_buildNumber',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.white.withAlpha((0.7 * 255).round()),
            fontSize: isMobile ? 14 : 17,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
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
                color: Colors.black.withAlpha((0.2 * 255).round()),
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
                color: Colors.amber.withAlpha((0.7 * 255).round()),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).round()),
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
