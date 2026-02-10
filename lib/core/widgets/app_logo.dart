import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color textColor;
  final String text;
  final String assetPath;

  const AppLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.textColor = Colors.black,
    this.text = 'FixIT',
    this.assetPath = 'assets/images/logo_gears.png',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          assetPath,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to settings icon if image not found
            return Icon(Icons.settings, size: size, color: textColor);
          },
        ),
        if (showText) SizedBox(width: size * 0.2),
        if (showText) ...[
          Text(
            text,
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -1,
            ),
          ),
        ],
      ],
    );
  }
}
