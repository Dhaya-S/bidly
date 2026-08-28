import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Reusable Bidly Brand Wordmark & Icon
class BidlyLogo extends StatelessWidget {
  final double fontSize;
  final bool isLight;

  const BidlyLogo({
    super.key,
    this.fontSize = 28,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        children: [
          TextSpan(
            text: 'BID',
            style: TextStyle(
              color: isLight ? Colors.white : AppTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: 'ly',
            style: TextStyle(
              color: isLight ? Colors.white.withValues(alpha: 0.9) : AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bidly Tag Icon Graphic as seen in Splash & Brand graphics
class BidlyTagIcon extends StatelessWidget {
  final double size;
  final Color? containerColor;
  final Color? iconColor;

  const BidlyTagIcon({
    super.key,
    this.size = 64,
    this.containerColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: containerColor ?? AppTheme.tagBg,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Icon(
          Icons.local_offer_rounded,
          size: size * 0.52,
          color: iconColor ?? AppTheme.accent,
        ),
      ),
    );
  }
}
