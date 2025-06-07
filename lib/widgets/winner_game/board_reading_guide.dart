import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';

/// 보드 리딩 가이드 다이얼로그
class BoardReadingGuide {
  /// 보드 리딩 가이드 다이얼로그를 표시하는 함수
  static void showBoardReadingGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            AppLanguage.getText('boardReadingGuide'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGuideSection(
                  AppLanguage.isKorean ? '딜러를 위한 PLO 핵심 규칙' : 'Key Rules for PLO Dealers',
                  AppLanguage.isKorean ? [
                    '• 각 플레이어는 반드시 4장의 홀 카드를 받습니다(홀덤의 2장과 다름).',
                    '• 커뮤니티 카드는 5장이며 모든 플레이어가 공유합니다.',
                    '• "정확히" 2장의 홀 카드와 "정확히" 3장의 커뮤니티 카드를 사용해야 합니다.',
                    '• 1장 또는 3장의 홀 카드 사용은 불가능합니다. 반드시 2장만 사용해야 합니다.',
                    '• 카드 평가 시 모든 가능한 조합을 확인하여 최고의 핸드를 찾아야 합니다.',
                  ] : [
                    '• Each player must receive exactly 4 hole cards (different from Hold\'em\'s 2 cards).',
                    '• There are 5 community cards shared by all players.',
                    '• Players MUST use EXACTLY 2 hole cards and EXACTLY 3 community cards.',
                    '• Using 1 or 3 hole cards is not allowed. Players must use exactly 2 hole cards.',
                    '• When evaluating hands, check all possible combinations to find the best hand.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildGuideSection(
                  AppLanguage.isKorean ? '핸드 판정 시 주의사항' : 'Important Notes for Hand Judging',
                  AppLanguage.isKorean ? [
                    '• 가능한 조합은 총 60가지입니다: 홀카드 2장 선택(6가지) × 커뮤니티카드 3장 선택(10가지)',
                    '• 플레이어가 "나는 이 2장만 쓸래요"라고 선언해도, 규칙상 최고의 핸드를 사용해야 합니다.',
                    '• 플레이어의 최적 핸드를 딜러가 찾아주어야 합니다(플레이어가 실수할 수 있음).',
                    '• 홀덤과 달리 플러시는 반드시 홀 카드 중 2장이 같은 무늬여야 가능합니다.',
                    '• 스트레이트도 홀 카드 중 2장이 반드시 사용되어야 합니다.',
                  ] : [
                    '• There are 60 possible combinations: choosing 2 from hole cards (6 ways) × choosing 3 from community cards (10 ways)',
                    '• Even if a player declares "I want to use just these 2 cards," the rules require using their best possible hand.',
                    '• Dealers must find the player\'s optimal hand (players may make mistakes).',
                    '• Unlike Hold\'em, a flush requires that 2 of the hole cards be of the same suit.',
                    '• Straights also require that 2 of the hole cards be used.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildGuideSection(
                  AppLanguage.isKorean ? '자주 헷갈리는 상황' : 'Common Confusing Situations',
                  AppLanguage.isKorean ? [
                    '• "플러시 보드": 커뮤니티에 같은 무늬 4장이 있어도, 홀 카드에 같은 무늬가 없다면 플러시 불가능',
                    '• "원페어 보드": 모든 플레이어가 해당 페어를 사용 가능하므로, 나머지 3장으로 승부 결정',
                    '• "쿼드 보드": 커뮤니티에 4장이 같은 숫자일 때, 모든 플레이어가 쿼드를 사용할 수 있음',
                    '• "로우 핸드": PLO Hi/Lo에서는 A-2-3-4-5가 최상의 로우 핸드입니다(PLO 하이에서는 무시)',
                    '• "이중 페어": 커뮤니티에 2쌍의 페어가 있을 때, 홀 카드의 더 높은 카드가 키커가 됨',
                  ] : [
                    '• "Flush board": Even with 4 cards of the same suit on the board, a flush is impossible without 2 matching suit cards in hand.',
                    '• "One pair board": Since all players can use this pair, the remaining 3 cards determine the winner.',
                    '• "Quads board": When 4 cards of the same rank are on the board, all players can use the quads.',
                    '• "Low hand": In PLO Hi/Lo, A-2-3-4-5 is the best low hand (ignored in PLO High).',
                    '• "Double paired board": When there are 2 pairs on the board, the higher card from hole cards becomes the kicker.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildGuideSection(
                  AppLanguage.isKorean ? '핸드 리딩 기술' : 'Hand Reading Skills',
                  AppLanguage.isKorean ? [
                    '• 보드의 텍스처(무늬 분포, 연결성, 페어 등)를 먼저 확인하세요.',
                    '• 가능한 너트(최강) 핸드가 무엇인지 항상 파악하세요.',
                    '• 각 플레이어의 베팅 패턴을 통해 핸드 범위를 좁혀나가세요.',
                    '• AAxx 형태의 포켓 에이스 페어는 홀덤보다 약하다는 점을 기억하세요.',
                    '• 더블 페어드 보드에서는 투 페어가 약하므로 풀하우스 가능성을 항상 체크하세요.',
                  ] : [
                    '• First check the board texture (suit distribution, connectivity, pairs, etc.).',
                    '• Always identify what the nuts (best possible hand) could be.',
                    '• Narrow down hand ranges through players\' betting patterns.',
                    '• Remember that AAxx pocket aces are weaker in Omaha than in Hold\'em.',
                    '• On double-paired boards, two pair is weak, so always check for full house possibilities.',
                  ],
                ),
                const SizedBox(height: 16),
                _buildGuideSection(
                  AppLanguage.isKorean ? '이 앱의 게임 진행 방법' : 'How to Play This App',
                  AppLanguage.isKorean ? [
                    '• 보드 리딩 게임: 커뮤니티 카드와 각 플레이어의 홀 카드가 주어지면 승자를 맞추는 훈련',
                    '• 정답 선택: 가장 강한 핸드를 가진 플레이어를 선택하세요',
                    '• 60초 제한: 빠른 판단력을 기르기 위해 시간 제한이 있습니다',
                    '• 점수 획득: 정확한 판단 시 1점 획득, 최고 점수 기록 확인 가능',
                    '• 리뷰 기능: 잘못된 판단에 대해 정답과 함께 리뷰 가능',
                    '• 팟 리밋 게임: 팟 리밋 오마하에서의 베팅 계산을 연습하는 모드도 있습니다',
                  ] : [
                    '• Board Reading Game: Practice identifying winners given community cards and each player\'s hole cards.',
                    '• Selecting Answers: Choose the player with the strongest hand.',
                    '• 60-Second Limit: There\'s a time limit to develop quick decision-making skills.',
                    '• Scoring: Earn 1 point for each correct judgment, track your high score.',
                    '• Review Feature: Review incorrect judgments with the correct answer.',
                    '• Pot Limit Game: There\'s also a mode to practice betting calculations in Pot Limit Omaha.',
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Text(
                    AppLanguage.isKorean
                        ? '이 앱은 실제 오마하 포커 딜러와 플레이어를 위한 훈련 도구입니다. 빠른 핸드 판정과 정확한 팟 계산 능력을 향상시켜 실전에서의 딜링 스킬을 높이는 데 도움이 됩니다.'
                        : 'This app is a training tool for real Omaha poker dealers and players. It helps improve quick hand evaluation and accurate pot calculation skills to enhance your dealing abilities in real games.',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLanguage.getText('confirm'),
                style: const TextStyle(
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  /// 가이드 섹션 위젯 빌더
  static Widget _buildGuideSection(String title, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withAlpha((0.5 * 255).round())),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: points.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(point),
            )).toList(),
          ),
        ),
      ],
    );
  }
} 