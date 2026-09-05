import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

/// Premium animated loading indicator with branded Bidly tag pulse and dual-ring spinner
class BidlyLoadingIndicator extends StatefulWidget {
  final double size;
  final String? message;
  final Color? color;
  final bool showLogo;

  const BidlyLoadingIndicator({
    super.key,
    this.size = 56,
    this.message,
    this.color,
    this.showLogo = true,
  });

  @override
  State<BidlyLoadingIndicator> createState() => _BidlyLoadingIndicatorState();
}

class _BidlyLoadingIndicatorState extends State<BidlyLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? const Color(0xFF004E54);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer glowing ring
            RotationTransition(
              turns: _rotationAnimation,
              child: Container(
                width: widget.size + 24,
                height: widget.size + 24,
                padding: const EdgeInsets.all(3),
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    primaryColor.withValues(alpha: 0.85),
                  ),
                  backgroundColor: const Color(0xFF99F6E4).withValues(alpha: 0.35),
                ),
              ),
            ),

            // Inner pulsing branded badge
            if (widget.showLogo)
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: const Color(0xFF004E54),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF004E54).withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.local_offer_rounded,
                      size: widget.size * 0.48,
                      color: const Color(0xFFE2A875),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            widget.message!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please wait a moment...',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }
}

/// Full-screen modern loading screen replacing stark blank white screens
class BidlyLoadingScreen extends StatelessWidget {
  final String? message;
  final String? appBarTitle;
  final bool showBackButton;

  const BidlyLoadingScreen({
    super.key,
    this.message,
    this.appBarTitle,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: (appBarTitle != null || showBackButton)
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      onPressed: () => Navigator.maybePop(context),
                    )
                  : null,
              title: appBarTitle != null
                  ? Text(
                      appBarTitle!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    )
                  : null,
            )
          : null,
      body: Center(
        child: BidlyLoadingIndicator(
          message: message ?? 'Loading Bidly...',
        ),
      ),
    );
  }
}

/// Loading overlay that mounts over forms/screens during async requests (like Login, OTP, etc.)
class BidlyLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Widget child;

  const BidlyLoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: BidlyLoadingIndicator(
                      size: 48,
                      message: message ?? 'Processing...',
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
