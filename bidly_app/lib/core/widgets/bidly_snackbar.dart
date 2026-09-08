import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BidlySnackBar {
  static Timer? _autoDismissTimer;

  /// Shows a clean, white-themed floating snackbar with an 'Undo' action and close button.
  /// Automatically and reliably dismisses after [duration] to prevent getting stuck on screen.
  static void showUndo({
    required BuildContext context,
    required String message,
    required VoidCallback onUndo,
    IconData? icon = Icons.info_outline_rounded,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    _autoDismissTimer?.cancel();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        elevation: 6,
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        duration: duration,
        content: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF004E54), size: 18),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                _autoDismissTimer?.cancel();
                HapticFeedback.lightImpact();
                messenger.hideCurrentSnackBar();
                onUndo();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Undo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF004E54),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                _autoDismissTimer?.cancel();
                messenger.hideCurrentSnackBar();
              },
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );

    // Guaranteed fallback timer ensuring the snackbar dismisses even if
    // the platform accessibility layer attempts to keep it indefinitely.
    _autoDismissTimer = Timer(duration, () {
      try {
        messenger.hideCurrentSnackBar();
      } catch (_) {}
    });
  }

  /// Shows a clean, white-themed info or status message with guaranteed auto-dismiss.
  static void show({
    required BuildContext context,
    required String message,
    IconData? icon,
    Duration duration = const Duration(milliseconds: 2800),
  }) {
    _autoDismissTimer?.cancel();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        elevation: 6,
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        duration: duration,
        content: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF004E54), size: 18),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () {
                _autoDismissTimer?.cancel();
                messenger.hideCurrentSnackBar();
              },
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );

    _autoDismissTimer = Timer(duration, () {
      try {
        messenger.hideCurrentSnackBar();
      } catch (_) {}
    });
  }
}
