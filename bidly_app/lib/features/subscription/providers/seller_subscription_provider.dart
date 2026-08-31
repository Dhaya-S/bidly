import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubscriptionPlan {
  final String id;
  final String name; // Basic, Pro, Elite
  final String duration; // 30 Days, 90 Days, 365 Days
  final double price; // 299, 799, 1999
  final String? badge; // Most Popular, Elite
  final List<String> features;
  final int extraBenefitsCount;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.duration,
    required this.price,
    this.badge,
    required this.features,
    this.extraBenefitsCount = 0,
  });
}

class UserSubscriptionState {
  final bool hasActiveSubscription;
  final String planName; // Basic, Pro, Elite
  final String duration;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final List<SubscriptionPlan> availablePlans;
  final SubscriptionPlan selectedPlan;
  final String selectedPaymentMethod; // UPI, CARD, BANK

  const UserSubscriptionState({
    this.hasActiveSubscription = false,
    this.planName = 'Basic',
    this.duration = '30 Days',
    this.startDate,
    this.expiryDate,
    required this.availablePlans,
    required this.selectedPlan,
    this.selectedPaymentMethod = 'UPI',
  });

  UserSubscriptionState copyWith({
    bool? hasActiveSubscription,
    String? planName,
    String? duration,
    DateTime? startDate,
    DateTime? expiryDate,
    List<SubscriptionPlan>? availablePlans,
    SubscriptionPlan? selectedPlan,
    String? selectedPaymentMethod,
  }) {
    return UserSubscriptionState(
      hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
      planName: planName ?? this.planName,
      duration: duration ?? this.duration,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      availablePlans: availablePlans ?? this.availablePlans,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
    );
  }
}

class SellerSubscriptionNotifier extends StateNotifier<UserSubscriptionState> {
  static final List<SubscriptionPlan> _defaultPlans = [
    const SubscriptionPlan(
      id: 'plan_basic',
      name: 'Basic',
      duration: '30 Days',
      price: 299,
      features: [
        'Up to 10 Product Listings',
        'Join up to 5 Communities',
        'List in 5 Communities',
        '5 Bidding Events',
        'Standard Visibility',
        'Basic Seller Support',
      ],
    ),
    const SubscriptionPlan(
      id: 'plan_pro',
      name: 'Pro',
      duration: '90 Days',
      price: 799,
      badge: 'Most Popular',
      features: [
        'Up to 25 Product Listings',
        'Join up to 15 Communities',
        'All joined Communities',
        '20 Bidding Events',
        'Priority in Reels',
        'Priority Featured Posts',
      ],
      extraBenefitsCount: 4,
    ),
    const SubscriptionPlan(
      id: 'plan_elite',
      name: 'Elite',
      duration: '365 Days',
      price: 1999,
      badge: 'Elite',
      features: [
        'Unlimited Listings',
        'Unlimited Communities',
        'All Communities',
        'Unlimited Bidding',
        'Top Priority Reels',
        'Top Featured Posts',
      ],
      extraBenefitsCount: 7,
    ),
  ];

  SellerSubscriptionNotifier()
      : super(
          UserSubscriptionState(
            availablePlans: _defaultPlans,
            selectedPlan: _defaultPlans[0],
          ),
        );

  void selectPlan(SubscriptionPlan plan) {
    state = state.copyWith(selectedPlan: plan);
  }

  void selectPaymentMethod(String method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  void activateSubscription(SubscriptionPlan plan) {
    final now = DateTime.now();
    int days = 30;
    if (plan.duration.contains('90')) days = 90;
    if (plan.duration.contains('365')) days = 365;

    state = state.copyWith(
      hasActiveSubscription: true,
      planName: plan.name,
      duration: plan.duration,
      startDate: now,
      expiryDate: now.add(Duration(days: days)),
      selectedPlan: plan,
    );
  }
}

final sellerSubscriptionProvider =
    StateNotifierProvider<SellerSubscriptionNotifier, UserSubscriptionState>((ref) {
  return SellerSubscriptionNotifier();
});
