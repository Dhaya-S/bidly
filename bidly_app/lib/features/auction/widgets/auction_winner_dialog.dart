import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/auction_model.dart';
import 'choose_delivery_method_bottom_sheet.dart';

class AuctionWinnerDialog extends ConsumerWidget {
  final AuctionWinnerModel winner;
  final String listingId;

  const AuctionWinnerDialog({
    super.key,
    required this.winner,
    required this.listingId,
  });

  static Future<void> show(BuildContext context, {required AuctionWinnerModel winner, required String listingId}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AuctionWinnerDialog(winner: winner, listingId: listingId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final currentUserId = ref.watch(authProvider).user?.id;
    final isWinner = (winner.winnerId != null && winner.winnerId == currentUserId) ||
        winner.winnerName.toLowerCase() == 'you';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF004E54),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Trophy Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF14B8A6), width: 1.5),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFF5EEAD4),
                size: 30,
              ),
            ),
            const SizedBox(height: 14),

            // Badge & Headline
            const Text(
              'AUCTION ENDED',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF5EEAD4),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isWinner ? 'Congratulations!\nYou Won the Auction' : '${winner.winnerName}\nWon the Auction',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 18),

            // Inner Card for Amount & Details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Winning Bid Amount',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(winner.winningAmount),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF004E54),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Escrow Protection Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Secured in Escrow',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Funds held safely · Released to seller after delivery',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Button: [ Continue to Order Status ] for Buyer, [ Ship package ] for Seller
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss Winner Dialog
                  if (isWinner) {
                    context.push('/auction/$listingId/won');
                  } else {
                    ChooseDeliveryMethodBottomSheet.show(
                      context,
                      winner: winner,
                      listingId: listingId,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004E54),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isWinner) ...[
                      const Icon(Icons.local_shipping_outlined, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isWinner ? 'Continue to Order Status' : 'Ship package',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
