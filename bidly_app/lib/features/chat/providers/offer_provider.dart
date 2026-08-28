import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/offer_model.dart';

class OfferState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final OfferModel? activeOffer;

  const OfferState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.activeOffer,
  });

  OfferState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    OfferModel? activeOffer,
    bool clearActiveOffer = false,
  }) {
    return OfferState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      activeOffer: clearActiveOffer ? null : (activeOffer ?? this.activeOffer),
    );
  }
}

class OfferNotifier extends StateNotifier<OfferState> {
  final ApiClient _apiClient;

  OfferNotifier(this._apiClient) : super(const OfferState());

  Future<void> fetchLatestOffer(String listingId, {String? buyerId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final query = buyerId != null ? '?buyerId=$buyerId' : '';
      final response = await _apiClient.dio.get('/listings/$listingId/offers/latest$query');
      if (response.data != null && response.data['success'] == true && response.data['data'] != null) {
        final offer = OfferModel.fromJson(response.data['data']);
        state = state.copyWith(isLoading: false, activeOffer: offer);
      } else {
        state = state.copyWith(isLoading: false, clearActiveOffer: true);
      }
    } catch (e) {
      debugPrint('Error fetching latest offer: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> submitOffer({
    required String listingId,
    required double amount,
    String? message,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post(
        '/listings/$listingId/offers',
        data: {
          'amount': amount,
          'message': message,
        },
      );

      if (response.data != null && response.data['success'] == true && response.data['data'] != null) {
        final created = OfferModel.fromJson(response.data['data']);
        state = state.copyWith(isSubmitting: false, activeOffer: created);
        return true;
      } else {
        final msg = response.data?['message']?.toString() ?? 'Failed to submit offer';
        state = state.copyWith(isSubmitting: false, errorMessage: msg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'Unable to submit offer');
      return false;
    }
  }

  Future<bool> counterOffer({
    required String offerId,
    required double counterAmount,
    String? message,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post(
        '/offers/$offerId/counter',
        data: {
          'counterAmount': counterAmount,
          'message': message,
        },
      );

      if (response.data != null && response.data['success'] == true && response.data['data'] != null) {
        final updated = OfferModel.fromJson(response.data['data']);
        state = state.copyWith(isSubmitting: false, activeOffer: updated);
        return true;
      } else {
        final msg = response.data?['message']?.toString() ?? 'Failed to counter offer';
        state = state.copyWith(isSubmitting: false, errorMessage: msg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'Unable to counter offer');
      return false;
    }
  }

  Future<bool> rejectOffer(String offerId) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post('/offers/$offerId/reject');
      if (response.data != null && response.data['success'] == true && response.data['data'] != null) {
        final updated = OfferModel.fromJson(response.data['data']);
        state = state.copyWith(isSubmitting: false, activeOffer: updated);
        return true;
      } else {
        state = state.copyWith(isSubmitting: false, errorMessage: 'Failed to reject offer');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'Unable to reject offer');
      return false;
    }
  }

  Future<String?> acceptOffer({
    required String offerId,
    required String deliveryType, // COURIER, IN_PERSON_MEETUP
    String? addressId,
    String? meetupLocation,
    DateTime? meetupTime,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final response = await _apiClient.dio.post(
        '/offers/$offerId/accept',
        data: {
          'deliveryType': deliveryType,
          'addressId': addressId,
          'meetupLocation': meetupLocation,
          'meetupTime': meetupTime?.toUtc().toIso8601String(),
        },
      );

      if (response.data != null && response.data['success'] == true && response.data['data'] != null) {
        final accepted = OfferModel.fromJson(response.data['data']);
        state = state.copyWith(isSubmitting: false, activeOffer: accepted);
        return accepted.orderId;
      } else {
        final msg = response.data?['message']?.toString() ?? 'Failed to accept offer';
        state = state.copyWith(isSubmitting: false, errorMessage: msg);
        return null;
      }
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'Unable to accept offer');
      return null;
    }
  }
}

final offerProvider = StateNotifierProvider<OfferNotifier, OfferState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OfferNotifier(apiClient);
});
