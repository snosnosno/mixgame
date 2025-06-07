import 'package:flutter/material.dart';

/// 게임에서 사용되는 공통 버튼 위젯
///
/// 다양한 스타일과 크기 옵션을 제공하여 재사용성을 높입니다.
class GameButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final GameButtonStyle style;
  final GameButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final double? width;

  const GameButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.style = GameButtonStyle.primary,
    this.size = GameButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final textStyle = _getTextStyle();
    final padding = _getPadding();

    Widget buttonChild = _buildButtonContent(textStyle);

    if (icon != null) {
      return SizedBox(
        width: width,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: buttonStyle,
          icon: isLoading 
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      style == GameButtonStyle.primary ? Colors.white : const Color(0xFF1B5E20),
                    ),
                  ),
                )
              : icon!,
          label: Text(text, style: textStyle),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: buttonChild,
      ),
    );
  }

  Widget _buildButtonContent(TextStyle textStyle) {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                style == GameButtonStyle.primary ? Colors.white : const Color(0xFF1B5E20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: textStyle),
        ],
      );
    }
    return Text(text, style: textStyle);
  }

  ButtonStyle _getButtonStyle() {
    Color backgroundColor;
    Color foregroundColor;
    
    switch (style) {
      case GameButtonStyle.primary:
        backgroundColor = Colors.deepPurpleAccent;
        foregroundColor = Colors.white;
        break;
      case GameButtonStyle.secondary:
        backgroundColor = Colors.amber;
        foregroundColor = Colors.white;
        break;
      case GameButtonStyle.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = Colors.white;
        break;
      case GameButtonStyle.danger:
        backgroundColor = Colors.red;
        foregroundColor = Colors.white;
        break;
      case GameButtonStyle.success:
        backgroundColor = Colors.green;
        foregroundColor = Colors.white;
        break;
    }

    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: style == GameButtonStyle.outline 
            ? const BorderSide(color: Colors.white, width: 2)
            : BorderSide.none,
      ),
      elevation: style == GameButtonStyle.outline ? 0 : 8,
      padding: _getPadding(),
    );
  }

  TextStyle _getTextStyle() {
    double fontSize;
    
    switch (size) {
      case GameButtonSize.small:
        fontSize = 14;
        break;
      case GameButtonSize.medium:
        fontSize = 16;
        break;
      case GameButtonSize.large:
        fontSize = 18;
        break;
    }

    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case GameButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case GameButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case GameButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 18);
    }
  }
}

/// 버튼 스타일 열거형
enum GameButtonStyle {
  primary,
  secondary,
  outline,
  danger,
  success,
}

/// 버튼 크기 열거형
enum GameButtonSize {
  small,
  medium,
  large,
} 