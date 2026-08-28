import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/auction_model.dart';

class AuctionState {
  final bool isLoading;
  final String? errorMessage;
  final AuctionDetailsModel? auctionDetails;
  final AuctionLiveStatusModel? liveStatus;
  final WalletModel? wallet;
  final List<DeliveryAddressModel> addresses;
  final DeliveryAddressModel? selectedAddress;
  final bool isPlacingBid;
  final bool isWalletValidating;
  final bool hasSufficientFunds;
  final String? bidSuccessMessage;

  const AuctionState({
    this.isLoading = false,
    this.errorMessage,
    this.auctionDetails,
    this.liveStatus,
    this.wallet,
    this.addresses = const [],
    this.selectedAddress,
    this.isPlacingBid = false,
    this.isWalletValidating = false,
    this.hasSufficientFunds = true,
    this.bidSuccessMessage,
  });

  AuctionState copyWith({
    bool? isLoading,
    String? errorMessage,
    AuctionDetailsModel? auctionDetails,
    AuctionLiveStatusModel? liveStatus,
    WalletModel? wallet,
    List<DeliveryAddressModel>? addresses,
    DeliveryAddressModel? selectedAddress,
    bool? isPlacingBid,
    bool? isWalletValidating,
    bool? hasSufficientFunds,
    String? bidSuccessMessage,
  }) {
    return AuctionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      auctionDetails: auctionDetails ?? this.auctionDetails,
      liveStatus: liveStatus ?? this.liveStatus,
      wallet: wallet ?? this.wallet,
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      isPlacingBid: isPlacingBid ?? this.isPlacingBid,
      isWalletValidating: isWalletValidating ?? this.isWalletValidating,
      hasSufficientFunds: hasSufficientFunds ?? this.hasSufficientFunds,
      bidSuccessMessage: bidSuccessMessage,
    );
  }
}

class AuctionNotifier extends StateNotifier<AuctionState> {
  final ApiClient _apiClient;
  Timer? _pollingTimer;

  AuctionNotifier(this._apiClient) : super(const AuctionState());

  Future<void> fetchAuctionDetails(String listingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiClient.get('/auctions/$listingId');
      if (res.data != null && res.data['success'] == true) {
        final details = AuctionDetailsModel.fromJson(res.data['data']);
        state = state.copyWith(
          isLoading: false,
          auctionDetails: details,
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load auction');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error loading auction: $e');
    }
  }

  Future<void> fetchWallet() async {
    try {
      final res = await _apiClient.get('/wallet');
      if (res.data != null && res.data['success'] == true) {
        final wallet = WalletModel.fromJson(res.data['data']);
        state = state.copyWith(wallet: wallet);
      }
    } catch (_) {}
  }

  Future<void> fetchAddresses() async {
    try {
      final res = await _apiClient.get('/addresses');
      if (res.data != null && res.data['success'] == true) {
        final list = (res.data['data'] as List)
            .map((e) => DeliveryAddressModel.fromJson(e as Map<String, dynamic>))
            .toList();
        DeliveryAddressModel? defaultAddr = list.isNotEmpty
            ? list.firstWhere((a) => a.isDefault, orElse: () => list.first)
            : null;
        state = state.copyWith(addresses: list, selectedAddress: defaultAddr);
      }
    } catch (_) {}
  }

  void selectAddress(DeliveryAddressModel address) {
    state = state.copyWith(selectedAddress: address);
  }

  Future<DeliveryAddressModel?> saveAddress({
    required String fullName,
    required String phone,
    required String addressLine,
    required String city,
    required String pincode,
  }) async {
    try {
      final res = await _apiClient.post('/addresses', data: {
        'fullName': fullName,
        'phone': phone,
        'addressLine': addressLine,
        'city': city,
        'pincode': pincode,
        'default': true,
      });
      if (res.data != null && res.data['success'] == true) {
        final newAddr = DeliveryAddressModel.fromJson(res.data['data']);
        final updatedList = [newAddr, ...state.addresses];
        state = state.copyWith(addresses: updatedList, selectedAddress: newAddr);
        return newAddr;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> validateWallet(String listingId, double bidAmount) async {
    state = state.copyWith(isWalletValidating: true);
    try {
      final res = await _apiClient.post('/auctions/$listingId/validate-wallet', data: {
        'amount': bidAmount,
      });
      if (res.data != null && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        final sufficient = data['sufficient'] == true;
        state = state.copyWith(
          isWalletValidating: false,
          hasSufficientFunds: sufficient,
        );
        return sufficient;
      }
    } catch (_) {
      state = state.copyWith(isWalletValidating: false, hasSufficientFunds: false);
    }
    return false;
  }

  Future<bool> placeBid(String listingId, double amount) async {
    state = state.copyWith(isPlacingBid: true, errorMessage: null);
    try {
      final res = await _apiClient.post('/auctions/$listingId/bid', data: {
        'amount': amount,
        'deliveryAddressId': state.selectedAddress?.id,
      });
      if (res.data != null && res.data['success'] == true) {
        final data = res.data['data'] as Map<String, dynamic>;
        if (data['auctionDetails'] != null) {
          final updatedDetails = AuctionDetailsModel.fromJson(data['auctionDetails']);
          state = state.copyWith(
            isPlacingBid: false,
            auctionDetails: updatedDetails,
            bidSuccessMessage: 'Bid placed successfully!',
          );
        } else {
          state = state.copyWith(isPlacingBid: false);
        }
        await fetchWallet();
        return true;
      } else {
        state = state.copyWith(
          isPlacingBid: false,
          errorMessage: res.data['message'] ?? 'Failed to place bid',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isPlacingBid: false,
        errorMessage: 'Network error placing bid. Please try again.',
      );
      return false;
    }
  }

  Future<void> withdrawBid(String listingId) async {
    try {
      await _apiClient.post('/auctions/$listingId/withdraw');
      await fetchAuctionDetails(listingId);
      await fetchWallet();
    } catch (_) {}
  }

  void startLivePolling(String listingId) {
    stopLivePolling();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) async {
      try {
        final res = await _apiClient.get('/auctions/$listingId/live-status');
        if (res.data != null && res.data['success'] == true) {
          final live = AuctionLiveStatusModel.fromJson(res.data['data']);
          state = state.copyWith(liveStatus: live);
        }
      } catch (_) {}
    });
  }

  void stopLivePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    stopLivePolling();
    super.dispose();
  }
}

final auctionProvider = StateNotifierProvider<AuctionNotifier, AuctionState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuctionNotifier(apiClient);
});
