import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../auction/providers/order_provider.dart';
import '../../auction/screens/review_rating_screen.dart';

class BuyerShowOtpModal extends ConsumerStatefulWidget {
  final String orderId;

  const BuyerShowOtpModal({
    super.key,
    required this.orderId,
  });

  static Future<void> show(BuildContext context, {required String orderId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BuyerShowOtpModal(orderId: orderId),
    );
  }

  @override
  ConsumerState<BuyerShowOtpModal> createState() => _BuyerShowOtpModalState();
}

class _BuyerShowOtpModalState extends ConsumerState<BuyerShowOtpModal> {
  bool _isLoading = true;
  bool _isConfirmingDelivery = false;
  String _otp = '------';
  String _buyerName = '';
  String _meetupDate = '';
  String _meetupTime = '';
  String _meetupLocation = '';
  DateTime? _expiresAt;
  Timer? _countdownTimer;
  String _timeRemaining = '05:00';

  @override
  void initState() {
    super.initState();
    _fetchOtpDetails();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOtpDetails() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/orders/${widget.orderId}/otp');
      if (res.data != null && res.data['success'] == true && res.data['data'] != null) {
        final data = res.data['data'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _otp = data['otp']?.toString() ?? '------';
            _buyerName = data['buyerName']?.toString() ?? '';
            _meetupDate = data['meetupDateFormatted']?.toString() ?? '';
            _meetupTime = data['meetupTimeFormatted']?.toString() ?? '';
            _meetupLocation = data['meetupLocation']?.toString() ?? '';
            if (data['otpExpiresAt'] != null) {
              _expiresAt = DateTime.tryParse(data['otpExpiresAt'].toString());
            } else {
              _expiresAt = DateTime.now().add(const Duration(minutes: 5));
            }
            _isLoading = false;
          });
          _startTimer();
          return;
        }
      }
    } catch (_) {
      // Read realtime active order details from provider
      final order = ref.read(orderProvider).order;
      if (mounted) {
        setState(() {
          if (order?.meetupOtp != null && order!.meetupOtp!.isNotEmpty) {
            _otp = order.meetupOtp!;
          }
          if (order?.buyerName != null) {
            _buyerName = order!.buyerName;
          }
          if (order?.meetupLocation != null) {
            _meetupLocation = order!.meetupLocation!;
          }
          if (order?.meetupTime != null) {
            _meetupTime = order!.meetupTime!;
          }
          _expiresAt = DateTime.now().add(const Duration(minutes: 5));
          _isLoading = false;
        });
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _updateTimer();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  void _updateTimer() {
    if (_expiresAt == null) {
      if (mounted) setState(() => _timeRemaining = 'Active');
      return;
    }
    final now = DateTime.now();
    final diff = _expiresAt!.difference(now);
    if (diff.isNegative) {
      if (mounted) {
        setState(() => _timeRemaining = 'Expired');
        _countdownTimer?.cancel();
      }
    } else {
      final minutes = diff.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
      if (mounted) {
        setState(() => _timeRemaining = '$minutes:$seconds');
      }
    }
  }

  Future<void> _handleItemReceived() async {
    setState(() => _isConfirmingDelivery = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/orders/${widget.orderId}/confirm-delivery');
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewRatingScreen(orderId: widget.orderId),
        ),
      );
    }
  }

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFF004E54),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buyerInitials = _buyerName.isNotEmpty
        ? _buyerName.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'AK';

    final digits = _otp.padRight(6, '-').split('').take(6).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top Dark Teal Header Card (Image 2) ────────────────
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF005459),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    // Center drag handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top Row: Avatar + "Generated for Buyer" + Secured Pill
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF003F43),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              buyerInitials,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Generated for',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11.5,
                                  color: Color(0xFF99F6E4),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                '$_buyerName • Buyer',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003F43),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.7),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                size: 13,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'BIDLY Secured',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // 6 Individual OTP Digit Cards (Image 2)
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: digits.map((digit) {
                              return Container(
                                width: 48,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF004448),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF00757D),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    digit,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 18),

                    // Bottom row of teal section: Countdown Timer & Copy Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 15,
                              color: Color(0xFF80CBC4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Expires in $_timeRemaining',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12.5,
                                color: Color(0xFF80CBC4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _otp));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('OTP copied to clipboard!'),
                                duration: Duration(seconds: 1),
                                backgroundColor: Color(0xFF004E54),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00757D),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'Copy',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Bottom White Section (Image 2) ─────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scheduled Meetup Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFCCFBF1),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: Color(0xFF004E54),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_meetupDate · $_meetupTime',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        _meetupLocation,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: Color(0xFF64748B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF99F6E4),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Confirmed',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF004E54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // AT THE MEETUP instructions
                    const Text(
                      'AT THE MEETUP',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStep('1', 'Open this screen when you meet the seller'),
                    _buildStep('2', 'Show your OTP — seller will read the digits'),
                    _buildStep('3', 'Once Verified, item is handed over to you'),
                    const SizedBox(height: 24),

                    // Big Action Button: [ Item Received • Rate Seller ]
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isConfirmingDelivery ? null : _handleItemReceived,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004E54),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isConfirmingDelivery
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.verified_outlined,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Item Received · Rate Seller',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dismiss Footer
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Close — I\'ll come back later',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
