import 'package:flutter/material.dart';

/// 게임 공통 배경 위젯
///
/// 모든 게임 페이지에서 사용되는 일관된 그라데이션 배경을 제공합니다.
class GameBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? customColors;
  final Alignment beginAlignment;
  final Alignment endAlignment;

  const GameBackground({
    Key? key,
    required this.child,
    this.customColors,
    this.beginAlignment = Alignment.topLeft,
    this.endAlignment = Alignment.bottomRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = customColors ?? _getDefaultColors();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: beginAlignment,
          end: endAlignment,
          colors: colors,
        ),
      ),
      child: child,
    );
  }

  List<Color> _getDefaultColors() {
    return const [
      Color(0xFF388E3C),
      Color(0xFF1B5E20),
      Color(0xFF43A047),
    ];
  }
}

/// 플레이어 카드 컨테이너 위젯
///
/// 플레이어 정보를 표시하는 일관된 스타일의 컨테이너를 제공합니다.
class PlayerCardContainer extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  const PlayerCardContainer({
    Key? key,
    required this.child,
    this.isSelected = false,
    this.isCorrect = false,
    this.isWrong = false,
    this.onTap,
    this.width,
    this.height,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.transparent;
    Color backgroundColor = Colors.white.withAlpha((0.13 * 255).round());
    double borderWidth = 1.2;

    if (isSelected) {
      borderColor = Colors.deepPurpleAccent.withAlpha((0.8 * 255).round());
      backgroundColor = Colors.deepPurpleAccent.withAlpha((0.18 * 255).round());
      borderWidth = 2.5;
    } else if (isCorrect) {
      borderColor = Colors.green.withAlpha((0.8 * 255).round());
      backgroundColor = Colors.green.withAlpha((0.18 * 255).round());
      borderWidth = 2.0;
    } else if (isWrong) {
      borderColor = Colors.red.withAlpha((0.8 * 255).round());
      backgroundColor = Colors.red.withAlpha((0.18 * 255).round());
      borderWidth = 2.0;
    }

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.18 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      padding: padding ?? const EdgeInsets.all(8),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}

/// 중앙 정렬된 콘텐츠 컨테이너
///
/// 게임 페이지의 주요 콘텐츠를 중앙에 정렬하여 표시합니다.
class CenteredGameContent extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool scrollable;
  final CrossAxisAlignment crossAxisAlignment;

  const CenteredGameContent({
    Key? key,
    required this.child,
    this.padding,
    this.scrollable = false,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: crossAxisAlignment,
      children: [child],
    );

    final paddedContent = Padding(
      padding: padding ?? const EdgeInsets.all(16.0),
      child: content,
    );

    if (scrollable) {
      return SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: paddedContent,
        ),
      );
    }

    return paddedContent;
  }
}

/// 반응형 그리드 레이아웃
///
/// 화면 크기에 따라 자동으로 조정되는 그리드 레이아웃을 제공합니다.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int maxColumns;
  final double spacing;
  final double runSpacing;
  final double? childAspectRatio;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.maxColumns = 2,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.childAspectRatio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    int crossAxisCount = maxColumns;
    double aspectRatio = childAspectRatio ?? (isSmallScreen ? 1.35 : 1.9);
    
    if (children.length <= 4) {
      crossAxisCount = 2; // 2x2
      aspectRatio = isSmallScreen ? 1.35 : 1.9;
    } else {
      crossAxisCount = maxColumns; // 최대 컬럼 수 사용
      aspectRatio = isSmallScreen ? 1.35 : 1.75;
    }

    return GridView.builder(
      padding: EdgeInsets.all(spacing),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// 게임 헤더 위젯
///
/// 게임 제목과 기본 정보를 표시하는 헤더 컴포넌트입니다.
class GameHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool isSmallScreen;

  const GameHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.actions,
    this.isSmallScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ],
      ),
    );
  }
}

/// 게임 하단 정보 표시 위젯
///
/// "made by SNO" 등의 하단 정보를 일관되게 표시합니다.
class GameFooter extends StatelessWidget {
  final String text;
  final bool isSmallScreen;
  final double? bottom;
  final double? right;

  const GameFooter({
    Key? key,
    this.text = 'made by SNO',
    this.isSmallScreen = false,
    this.bottom = 12,
    this.right = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: right,
      bottom: bottom,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withAlpha((0.7 * 255).round()),
          fontSize: isSmallScreen ? 15 : 17,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
} 