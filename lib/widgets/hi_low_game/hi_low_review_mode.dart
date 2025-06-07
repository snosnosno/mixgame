import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';
import '../../models/replay_round.dart';
import '../common/poker_card.dart';

/// Hi/Low 게임의 리뷰 모드 위젯
class HiLowReviewMode extends StatelessWidget {
  final ReplayRound? replayingRound;
  final int currentReviewIndex;
  final int totalRounds;
  final VoidCallback? onPreviousRound;
  final VoidCallback? onNextRound;
  final VoidCallback onEndReview;

  const HiLowReviewMode({
    Key? key,
    this.replayingRound,
    required this.currentReviewIndex,
    required this.totalRounds,
    this.onPreviousRound,
    this.onNextRound,
    required this.onEndReview,
  }) : super(key: key);

  String getText(String key) => AppLanguage.getText(key);

  @override
  Widget build(BuildContext context) {
    if (replayingRound == null) return Container();
    
    return Column(
      children: [
        // 리뷰 정보와 라운드 탐색 버튼을 하나의 행으로 통합
        _buildReviewHeader(),
        
        // 커뮤니티 카드 영역
        _buildCommunityCards(),
        
        // 결과 메시지 영역
        _buildResultMessage(),
        
        // 플레이어 카드 영역
        _buildPlayerGrid(),
        
        // 리뷰 종료 버튼
        _buildEndReviewButton(),
      ],
    );
  }

  Widget _buildReviewHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 리뷰 정보
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.15 * 255).round()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${getText("review")}: ${currentReviewIndex + 1}/$totalRounds',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SizedBox(width: 12),
          
          // 라운드 탐색 컨트롤
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.15 * 255).round()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: currentReviewIndex > 0 ? onPreviousRound : null,
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                Text(
                  '${getText("round")} ${currentReviewIndex + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed: currentReviewIndex < totalRounds - 1 ? onNextRound : null,
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCards() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              getText('communityCards'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: replayingRound!.communityCards
                .map((card) => PokerCard(
                      card: card,
                      size: 50,
                      margin: 2,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultMessage() {
    if (replayingRound!.winnerText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha((0.3 * 255).round()), width: 1),
      ),
      child: Text(
        replayingRound!.winnerText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPlayerGrid() {
    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: replayingRound!.numberOfPlayers,
        itemBuilder: (context, index) {
          return _buildPlayerCard(index);
        },
      ),
    );
  }

  Widget _buildPlayerCard(int index) {
    bool isHighSelected = replayingRound!.selectedHighWinnerIndex == index;
    bool isLowSelected = replayingRound!.selectedLowWinnerIndices.contains(index);
    bool isHighCorrect = replayingRound!.actualHighWinnerIndex == index;
    bool isLowCorrect = replayingRound!.actualLowWinnerIndices.contains(index);
    
    // High 핸드 선택 상태
    String highStatus = '';
    Color highStatusColor = Colors.transparent;
    IconData? highIcon;
    
    if (isHighSelected) {
      if (isHighCorrect) {
        highStatus = 'High: 정답';
        highStatusColor = Colors.green.shade300;
        highIcon = Icons.check_circle;
      } else {
        highStatus = 'High: 오답';
        highStatusColor = Colors.red.shade300;
        highIcon = Icons.cancel;
      }
    } else if (isHighCorrect) {
      highStatus = 'High: 정답';
      highStatusColor = Colors.blue.shade300;
      highIcon = Icons.check_circle_outline;
    }
    
    // Low 핸드 선택 상태
    String lowStatus = '';
    Color lowStatusColor = Colors.transparent;
    IconData? lowIcon;
    
    if (isLowSelected) {
      if (isLowCorrect) {
        lowStatus = 'Low: 정답';
        lowStatusColor = Colors.green.shade300;
        lowIcon = Icons.check_circle;
      } else {
        lowStatus = 'Low: 오답';
        lowStatusColor = Colors.red.shade300;
        lowIcon = Icons.cancel;
      }
    } else if (isLowCorrect) {
      // 선택하지 않은 정답 플레이어 (다른 정답 플레이어를 선택한 경우)
      if (replayingRound!.selectedLowWinnerIndices.isNotEmpty && 
          replayingRound!.actualLowWinnerIndices.any((i) => 
              replayingRound!.selectedLowWinnerIndices.contains(i))) {
        lowStatus = 'Low: 미선택 정답';
        lowStatusColor = Colors.blue.shade300;
        lowIcon = Icons.check_circle_outline;
      } else {
        lowStatus = 'Low: 정답';
        lowStatusColor = Colors.teal.shade300;
        lowIcon = Icons.check_circle_outline;
      }
    }
    
    // 플레이어 카드 컨테이너 색상 결정
    Color containerColor = Colors.white.withAlpha((0.15 * 255).round());
    if (isHighCorrect || isLowCorrect) {
      containerColor = Colors.white.withAlpha((0.25 * 255).round());
    }
    
    // 여러 Low 핸드 승자가 있는 경우 표시
    String multiWinnerLabel = '';
    if (isLowCorrect && replayingRound!.actualLowWinnerIndices.length > 1) {
      multiWinnerLabel = 'Low 스플릿';
    }
    
    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: (isHighCorrect || isLowCorrect) ? 
                 Colors.amber.withAlpha((0.5 * 255).round()) : 
                 Colors.transparent,
          width: 2,
        ),
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Text(
            'Player ${index + 1}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: replayingRound!.playerHands[index]
                .map((card) => PokerCard(
                      card: card,
                      size: 36,
                      margin: 0,
                    ))
                .toList(),
          ),
          Spacer(),
          
          // 여러 로우 핸드 승자 표시
          if (multiWinnerLabel.isNotEmpty)
            Container(
              margin: EdgeInsets.only(bottom: 4),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                multiWinnerLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          
          // High 및 Low 상태 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // High 핸드 정답/오답 표시
              if (highStatus.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: highStatusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (highIcon != null)
                        Icon(highIcon, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        highStatus,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Low 핸드 정답/오답 표시
              if (lowStatus.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(left: highStatus.isNotEmpty ? 4 : 0),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: lowStatusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lowIcon != null)
                        Icon(lowIcon, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        lowStatus,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEndReviewButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton.icon(
        onPressed: onEndReview,
        icon: Icon(Icons.arrow_back, size: 16),
        label: Text(getText('endReplay')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1B5E20),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          minimumSize: Size(120, 36),
          elevation: 2,
        ),
      ),
    );
  }
} 