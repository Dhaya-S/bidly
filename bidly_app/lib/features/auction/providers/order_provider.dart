import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/auction_model.dart';

class OrderState {
  final bool isLoading;
  final String? errorMessage;
  final OrderModel? order;
  final bool isSubmittingReview;
  final bool isReviewSuccess;

  const OrderState({
    this.isLoading = false,
    this.errorMessage,
    this.order,
    this.isSubmittingReview = false,
    this.isReviewSuccess = false,
  });

  OrderState copyWith({
    bool? isLoading,
    String? errorMessage,
    OrderModel? order,
    bool? isSubmittingReview,
    bool? isReviewSuccess,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      order: order ?? this.order,
      isSubmittingReview: isSubmittingReview ?? this.isSubmittingReview,
      isReviewSuccess: isReviewSuccess ?? this.isReviewSuccess,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final ApiClient _apiClient;

  OrderNotifier(this._apiClient) : super(const OrderState());

  Future<void> fetchOrder(String orderId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiClient.get('/orders/$orderId');
      if (res.data != null && res.data['success'] == true) {
        final order = OrderModel.fromJson(res.data['data']);
        state = state.copyWith(isLoading: false, order: order);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load order');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error loading order: $e');
    }
  }

  Future<void> fetchOrderByListing(String listingId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiClient.get('/orders/listing/$listingId');
      if (res.data != null && res.data['success'] == true) {
        final order = OrderModel.fromJson(res.data['data']);
        state = state.copyWith(isLoading: false, order: order);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'No active order found');
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Order not found');
    }
  }

  Future<bool> confirmDelivery(String orderId) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _apiClient.post('/orders/$orderId/confirm-delivery');
      if (res.data != null && res.data['success'] == true) {
        final updatedOrder = OrderModel.fromJson(res.data['data']);
        state = state.copyWith(isLoading: false, order: updatedOrder);
        return true;
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
    return false;
  }

  Future<bool> updateDeliveryAddress(String orderId, {String? addressId, String? fullName, String? phone, String? addressLine, String? city, String? pincode}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiClient.put('/orders/$orderId/delivery-address', data: {
        'addressId': addressId,
        'fullName': fullName,
        'phone': phone,
        'addressLine': addressLine,
        'city': city,
        'pincode': pincode,
      });
      if (res.data != null && res.data['success'] == true) {
        final updatedOrder = OrderModel.fromJson(res.data['data']);
        state = state.copyWith(isLoading: false, order: updatedOrder);
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: res.data?['message']?.toString() ?? 'Failed to update address');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Network error updating address');
      return false;
    }
  }

  Future<bool> confirmMeetup(String orderId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiClient.post('/orders/$orderId/confirm-meetup');
      if (res.data != null && res.data['success'] == true) {
        final updatedOrder = OrderModel.fromJson(res.data['data']);
        state = state.copyWith(isLoading: false, order: updatedOrder);
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: res.data?['message']?.toString() ?? 'Failed to confirm meetup');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Network error confirming meetup: $e');
      return false;
    }
  }

  Future<bool> verifyMeetupOtp(String orderId, String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiClient.post('/orders/$orderId/verify-otp', data: {'otp': otp});
      if (res.data != null && res.data['success'] == true) {
        final updatedOrder = OrderModel.fromJson(res.data['data']);
        state = state.copyWith(isLoading: false, order: updatedOrder);
        return true;
      } else {
        final msg = res.data?['message']?.toString() ?? 'Invalid OTP code';
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Invalid OTP code. Please try again.');
      return false;
    }
  }

  Future<bool> createCourierShipment(
    String orderId, {
    required String trackingNumber,
    required String courierPartner,
    required DateTime estimatedDeliveryDate,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _apiClient.post('/orders/$orderId/courier-shipment', data: {
        'trackingNumber': trackingNumber,
        'courierPartner': courierPartner,
        'estimatedDeliveryDate': estimatedDeliveryDate.toUtc().toIso8601String(),
      });
      if (res.data != null && res.data['success'] == true && res.data['data'] != null) {
        final updatedOrder = OrderModel.fromJson(res.data['data']);
        state = state.copyWith(isLoading: false, order: updatedOrder);
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: res.data?['message'] ?? 'Failed to dispatch shipment');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error creating shipment: $e');
      return false;
    }
  }

  Future<bool> submitReview({
    required String orderId,
    required int rating,
    required String comment,
    List<String> photoUrls = const [],
  }) async {
    state = state.copyWith(isSubmittingReview: true);
    try {
      final res = await _apiClient.post('/reviews', data: {
        'orderId': orderId,
        'rating': rating,
        'comment': comment,
        'photoUrls': photoUrls,
      });
      if (res.data != null && res.data['success'] == true) {
        state = state.copyWith(isSubmittingReview: false, isReviewSuccess: true);
        return true;
      }
    } catch (_) {
      state = state.copyWith(isSubmittingReview: false);
    }
    return false;
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderNotifier(apiClient);
});
