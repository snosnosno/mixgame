import 'package:flutter/material.dart';
import 'winner_game_page.dart';
import 'pot_limit_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1B5E20), // 진한 초록색
                  const Color(0xFF2E7D32), // 중간 초록색
                  const Color(0xFF4CAF50), // 밝은 초록색
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'PLO Practice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 28 : 36,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
      ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4 - (isMobile ? 28 : 36)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
                        _buildGameButton(
                          context,
                          'Winner Guessing Game',
                          const WinnerGamePage(),
                          isMobile,
                        ),
                        const SizedBox(height: 20),
                        _buildGameButton(
                  context,
                          'Pot Limit Calculator',
                          const PotLimitPage(),
                          isMobile,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: Text(
              'made by SNO',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
                );
  }

  Widget _buildGameButton(
    BuildContext context,
    String text,
    Widget page,
    bool isMobile,
  ) {
    return Container(
      width: isMobile ? double.infinity : 400,
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
          style: TextStyle(
            fontSize: isMobile ? 18 : 24,
            fontWeight: FontWeight.bold,
            ),
        ),
      ),
    );
  }
}
