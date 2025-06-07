import 'package:flutter/material.dart';

/// 저작권 텍스트 위젯
class PotLimitCopyright extends StatelessWidget {
  const PotLimitCopyright({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 12,
      child: Text(
        'made by SNO',
        style: TextStyle(
          color: Colors.white.withAlpha((0.7 * 255).round()),
          fontSize: 17,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
} 