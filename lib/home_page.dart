import 'package:flutter/material.dart';
import 'winner_game_page.dart';
import 'pot_limit_page.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            Positioned(
              left: 16,
              top: 48,
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
                  '후원하기',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: isMobile ? 14 : 16,
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
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PLO 연습',
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
                        '보드 리딩',
                        const WinnerGamePage(),
                        isMobile,
                        isTablet,
                        isDesktop,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _buildGameButton(
                        context,
                        '팟 리밋 계산',
                        const PotLimitPage(),
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
          'made by SNO',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
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
    String text,
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

    return Container(
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
            horizontal: isMobile ? 24 : 32,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: const Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
