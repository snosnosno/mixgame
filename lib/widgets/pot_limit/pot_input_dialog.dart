import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../home_page.dart';

/// POT 입력 대화상자 위젯
///
/// 사용자가 POT 금액을 입력할 수 있는 대화상자 위젯입니다.
class PotInputDialog extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final double screenWidth;
  final double screenHeight;
  final bool isSmallScreen;

  const PotInputDialog({
    Key? key,
    required this.controller,
    required this.onSubmit,
    required this.screenWidth,
    required this.screenHeight,
    required this.isSmallScreen,
  }) : super(key: key);

  @override
  State<PotInputDialog> createState() => _PotInputDialogState();
}

class _PotInputDialogState extends State<PotInputDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late FocusNode _focusNode;

  String getText(String key) => AppLanguage.getText(key);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // 애니메이션 시작
    _animationController.forward();
    
    // 100ms 후에 포커스 설정 (애니메이션 시작 후)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // 제출 처리 및 키보드 숨김
  void _handleSubmit() {
    // 키보드 숨기기
    _focusNode.unfocus();
    // 약간의 딜레이 후 제출 호출 (키보드가 사라지는 애니메이션과 충돌 방지)
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        widget.onSubmit();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          left: 0,
          right: 0,
          bottom: 20,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.black.withOpacity(0.7),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 타이틀
                      Text(
                        getText('enterPotAmount'),
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: widget.isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 입력 필드
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextField(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: false, 
                              signed: false
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoMono',
                            ),
                            decoration: const InputDecoration(
                              hintText: 'ex) 1600',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                              ),
                              border: InputBorder.none,
                            ),
                            textAlign: TextAlign.center,
                            autofocus: false,
                            onEditingComplete: _handleSubmit,
                            onSubmitted: (_) => _handleSubmit(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 제출 버튼
                      ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.isSmallScreen ? 20 : 30,
                            vertical: widget.isSmallScreen ? 10 : 15,
                          ),
                        ),
                        child: Text(
                          getText('submit'),
                          style: TextStyle(
                            fontSize: widget.isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 