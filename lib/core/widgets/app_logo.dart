import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_gears.png',
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to settings icon if image not found
            return Icon(Icons.settings, size: size, color: Colors.black);
          },
        ),
        SizedBox(width: size * 0.2),
        Text(
          'FixIT',
          style: TextStyle(
            fontSize: size * 0.8,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}
