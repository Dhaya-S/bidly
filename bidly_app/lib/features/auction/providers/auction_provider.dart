import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/auction_model.dart';
import '../services/auction_websocket_service.dart';

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
  final bool isWebSocketConnected;
  final int secondsRemaining;
  final String timeLeftFormatted;

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
    this.isWebSocketConnected = false,
    this.secondsRemaining = 0,
    this.timeLeftFormatted = '--:--',
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
    bool? isWebSocketConnected,
    int? secondsRemaining,
    String? timeLeftFormatted,
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
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      timeLeftFormatted: timeLeftFormatted ?? this.timeLeftFormatted,
    );
  }
}

class AuctionNotifier extends StateNotifier<AuctionState> {
  final ApiClient _apiClient;
  final Ref _ref;
  late final AuctionWebSocketService _webSocketService;
  Timer? _countdownTimer;
  String? _activeListingId;

  AuctionNotifier(this._apiClient, this._ref) : super(const AuctionState()) {
    _webSocketService = AuctionWebSocketService(
      onEvent: _handleWebSocketEvent,
      onConnected: () {
        state = state.copyWith(isWebSocketConnected: true);
      },
      onDisconnected: () {
        state = state.copyWith(isWebSocketConnected: false);
      },
      onResyncRequired: () {
        if (_activeListingId != null) {
          fetchAuctionDetails(_activeListingId!, isSilent: true);
        }
      },
    );
  }

  /// Initial entry point when opening an auction screen
  Future<void> initAuction(String listingId) async {
    _activeListingId = listingId;
    await Future.wait([
      fetchAuctionDetails(listingId),
      fetchWallet(),
      fetchAddresses(),
    ]);

    // Connect to real-time STOMP topic
    await _connectWebSocket(listingId);
  }

  /// Silent init — used when auctionDetails is already loaded (e.g. navigated from PlaceBidScreen).
  /// Fetches in background without isLoading spinner and connects WebSocket.
  Future<void> initAuctionSilent(String listingId) async {
    _activeListingId = listingId;
    unawaited(fetchAuctionDetails(listingId, isSilent: true));
    unawaited(fetchWallet());
    await _connectWebSocket(listingId);
  }

  Future<void> _connectWebSocket(String listingId) async {
    final token = await _apiClient.getToken();
    _webSocketService.connect(
      wsUrl: _apiClient.wsUrl,
      listingId: listingId,
      token: token,
    );
  }

  Duration _serverClockOffset = Duration.zero;

  void _syncServerClock(String? serverTimestamp) {
    if (serverTimestamp != null && serverTimestamp.isNotEmpty) {
      try {
        final serverTime = DateTime.parse(serverTimestamp).toUtc();
        final deviceNow = DateTime.now().toUtc();
        _serverClockOffset = serverTime.difference(deviceNow);
        debugPrint('[AUCTION_TIME] Synchronized server time: offset=${_serverClockOffset.inMilliseconds}ms');
      } catch (e) {
        debugPrint('[AUCTION_TIME] Error parsing serverTimestamp: $e');
      }
    }
  }

  int _computeRemainingSeconds(String? endTimeStr, int fallbackSeconds) {
    if (endTimeStr != null && endTimeStr.isNotEmpty) {
      try {
        final end = DateTime.parse(endTimeStr).toUtc();
        final nowAdjusted = DateTime.now().toUtc().add(_serverClockOffset);
        final diff = end.difference(nowAdjusted).inSeconds;
        return diff > 0 ? diff : 0;
      } catch (e) {
        debugPrint('[AUCTION_TIME] Error computing remaining seconds: $e');
      }
    }
    return fallbackSeconds > 0 ? fallbackSeconds : 0;
  }

  void _startLocalCountdown(String? endTimeStr, int initialSeconds) {
    _countdownTimer?.cancel();
    int currentSecs = _computeRemainingSeconds(endTimeStr, initialSeconds);
    state = state.copyWith(
      secondsRemaining: currentSecs,
      timeLeftFormatted: _formatSeconds(currentSecs),
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = _computeRemainingSeconds(endTimeStr, 0);
      if (remaining > 0) {
        state = state.copyWith(
          secondsRemaining: remaining,
          timeLeftFormatted: _formatSeconds(remaining),
        );
      } else {
        timer.cancel();
        state = state.copyWith(
          secondsRemaining: 0,
          timeLeftFormatted: 'Ended',
        );
      }
    });
  }

  String _formatSeconds(int totalSecs) {
    if (totalSecs <= 0) return 'Ended';
    final hours = totalSecs ~/ 3600;
    final mins = (totalSecs % 3600) ~/ 60;
    final secs = totalSecs % 60;
    if (hours > 0) {
      return '${hours}h ${mins.toString().padLeft(2, '0')}m';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _handleWebSocketEvent(AuctionEventModel event) {
    debugPrint('[AUCTION_WS] Handling event: ${event.eventType} for listing ${event.listingId}');
    _syncServerClock(event.serverTimestamp);

    final currentUserId = _ref.read(authProvider).user?.id;
    final isWinning = currentUserId != null && event.highestBidderId == currentUserId;
    final existingUserBid = state.liveStatus?.currentUserBid ?? state.auctionDetails?.currentUserBid;
    final isOutbid = !isWinning && (existingUserBid != null) && (event.highestBid > existingUserBid);
    final behindBy = isOutbid ? (event.highestBid - existingUserBid) : null;

    final remainingSecs = _computeRemainingSeconds(event.auctionEndTime, event.secondsRemaining);

    final updatedLive = AuctionLiveStatusModel(
      listingId: event.listingId,
      currentHighestBid: event.highestBid,
      minNextBid: event.minimumNextBid,
      totalBids: event.totalBids,
      watchingCount: event.watchingCount ?? state.liveStatus?.watchingCount ?? 0,
      secondsRemaining: remainingSecs,
      timeLeftFormatted: _formatSeconds(remainingSecs),
      status: event.auctionStatus,
      isAuctionEnded: remainingSecs <= 0 || event.auctionStatus != 'ACTIVE',
      isCurrentUserWinning: isWinning,
      isCurrentUserOutbid: isOutbid,
      currentUserBid: isWinning ? event.highestBid : existingUserBid,
      currentUserRank: isWinning ? 1 : state.liveStatus?.currentUserRank,
      behindByAmount: behindBy,
      highestBidderId: event.highestBidderId,
      highestBidderName: event.highestBidderDisplayName,
      serverTimestamp: event.serverTimestamp,
      liveBidFeed: event.recentBids,
    );

    // Update countdown timer from synchronized server time
    _startLocalCountdown(event.auctionEndTime, remainingSecs);

    state = state.copyWith(
      liveStatus: updatedLive,
      secondsRemaining: remainingSecs,
      timeLeftFormatted: _formatSeconds(remainingSecs),
    );

    // Refresh wallet balance seamlessly
    fetchWallet();
  }

  Future<void> fetchAuctionDetails(String listingId, {bool isSilent = false}) async {
    if (!isSilent) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    try {
      final res = await _apiClient.get('/auctions/$listingId');
      if (res.data != null && res.data['success'] == true) {
        final details = AuctionDetailsModel.fromJson(res.data['data']);
        _syncServerClock(details.serverTimestamp);
        final remainingSecs = _computeRemainingSeconds(details.auctionEndTime, details.secondsRemaining);

        _startLocalCountdown(details.auctionEndTime, remainingSecs);
        state = state.copyWith(
          isLoading: false,
          auctionDetails: details,
          secondsRemaining: remainingSecs,
          timeLeftFormatted: _formatSeconds(remainingSecs),
        );
      } else {
        if (!isSilent) {
          state = state.copyWith(isLoading: false, errorMessage: 'Failed to load auction');
        }
      }
    } catch (e) {
      if (!isSilent) {
        state = state.copyWith(isLoading: false, errorMessage: 'Error loading auction: $e');
      }
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

  /// Atomic, Idempotent Bid Placement sending unique clientBidId
  Future<bool> placeBid(String listingId, double amount, {String? retryClientBidId}) async {
    if (state.isPlacingBid) return false;
    state = state.copyWith(isPlacingBid: true, errorMessage: null);

    final clientBidId = retryClientBidId ??
        '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';

    try {
      final res = await _apiClient.post('/auctions/$listingId/bid', data: {
        'amount': amount,
        'deliveryAddressId': state.selectedAddress?.id,
        'clientBidId': clientBidId,
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

  Future<bool> withdrawBid(String listingId) async {
    state = state.copyWith(errorMessage: null);
    try {
      final res = await _apiClient.post('/auctions/$listingId/withdraw');
      if (res.data != null && res.data['success'] == true) {
        await fetchAuctionDetails(listingId, isSilent: true);
        await fetchWallet();
        return true;
      } else {
        state = state.copyWith(errorMessage: res.data?['message'] ?? 'Failed to withdraw bid');
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Network error withdrawing bid. Please try again.');
      return false;
    }
  }

  Future<AuctionWinnerModel?> endAuction(String listingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiClient.post('/auctions/$listingId/end');
      state = state.copyWith(isLoading: false);
      if (res.data != null && res.data['success'] == true && res.data['data'] != null) {
        final winner = AuctionWinnerModel.fromJson(res.data['data'] as Map<String, dynamic>);
        return winner;
      } else {
        state = state.copyWith(errorMessage: res.data?['message'] ?? 'Failed to end auction');
        return null;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error ending auction: $e');
      return null;
    }
  }

  Future<AuctionWinnerModel?> fetchAuctionWinner(String listingId) async {
    try {
      final res = await _apiClient.get('/auctions/$listingId/winner');
      if (res.data != null && res.data['success'] == true && res.data['data'] != null) {
        return AuctionWinnerModel.fromJson(res.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  void disconnectWebSocket() {
    _webSocketService.disconnect();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }
}

final auctionProvider = StateNotifierProvider<AuctionNotifier, AuctionState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuctionNotifier(apiClient, ref);
});
