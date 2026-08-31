import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../providers/seller_subscription_provider.dart';
import 'subscription_checkout_screen.dart';
import 'subscription_status_screen.dart';

class SellerSubscriptionScreen extends ConsumerWidget {
  const SellerSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(sellerSubscriptionProvider);

    if (subState.hasActiveSubscription) {
      return const SubscriptionStatusScreen();
    }

    final tags = ['Priority Reels', 'Home Feed', 'Seller Badge', 'More Buyers', 'Early Access'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Seller Subscription',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.border.withValues(alpha: 0.7),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ── Top Teal Banner ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF004E54),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seller Subscription',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Boost your listings and reach thousands of buyers with priority placement across Bidly.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Plan 1: Basic (₹299 / 30 Days) ────────────────────
            _buildPlanCard(
              context,
              ref,
              plan: subState.availablePlans[0],
              cardBgColor: Colors.white,
              borderColor: AppTheme.border,
              headerColor: AppTheme.textPrimary,
              priceColor: const Color(0xFF004E54),
              buttonColor: const Color(0xFF004E54),
              buttonTextColor: Colors.white,
              buttonText: 'Subscribe Now',
              isSelected: subState.selectedPlan.id == subState.availablePlans[0].id,
            ),
            const SizedBox(height: 16),

            // ── Plan 2: Pro (₹799 / 90 Days) ──────────────────────
            _buildPlanCard(
              context,
              ref,
              plan: subState.availablePlans[1],
              cardBgColor: const Color(0xFF004E54),
              borderColor: const Color(0xFF004E54),
              headerColor: Colors.white,
              priceColor: Colors.white,
              buttonColor: const Color(0xFF006970),
              buttonTextColor: Colors.white,
              buttonText: 'Upgrade to Pro',
              isSelected: subState.selectedPlan.id == subState.availablePlans[1].id,
              isDarkCard: true,
            ),
            const SizedBox(height: 16),

            // ── Plan 3: Elite (₹1,999 / 365 Days) ─────────────────
            _buildPlanCard(
              context,
              ref,
              plan: subState.availablePlans[2],
              cardBgColor: const Color(0xFF996B1E),
              borderColor: const Color(0xFF996B1E),
              headerColor: Colors.white,
              priceColor: Colors.white,
              buttonColor: const Color(0xFF7A5212),
              buttonTextColor: Colors.white,
              buttonText: 'Go Elite',
              isSelected: subState.selectedPlan.id == subState.availablePlans[2].id,
              isDarkCard: true,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    WidgetRef ref, {
    required SubscriptionPlan plan,
    required Color cardBgColor,
    required Color borderColor,
    required Color headerColor,
    required Color priceColor,
    required Color buttonColor,
    required Color buttonTextColor,
    required String buttonText,
    required bool isSelected,
    bool isDarkCard = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: headerColor,
                        ),
                      ),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: plan.badge == 'Most Popular'
                                ? const Color(0xFFFFC107)
                                : const Color(0xFFD4AF37),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plan.badge!,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF332600),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.duration,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: isDarkCard ? Colors.white.withValues(alpha: 0.7) : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '₹${plan.price.toInt()}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: priceColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkCard ? Colors.white : AppTheme.border,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDarkCard ? Colors.white.withValues(alpha: 0.15) : AppTheme.border,
          ),
          const SizedBox(height: 14),

          // Features
          ...plan.features.map((f) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: isDarkCard ? const Color(0xFF86EFAC) : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkCard ? Colors.white.withValues(alpha: 0.9) : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          if (plan.extraBenefitsCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              '+${plan.extraBenefitsCount} more benefits',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDarkCard ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF004E54),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                ref.read(sellerSubscriptionProvider.notifier).selectPlan(plan);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SubscriptionCheckoutScreen(plan: plan),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
