import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileState {
  final bool isSaving;
  final String? errorMessage;
  final double walletBalance;
  final int messagesCount;
  final int wishlistCount;
  final int ordersCount;

  const ProfileState({
    this.isSaving = false,
    this.errorMessage,
    this.walletBalance = 0.0,
    this.messagesCount = 3,
    this.wishlistCount = 4,
    this.ordersCount = 5,
  });

  ProfileState copyWith({
    bool? isSaving,
    String? errorMessage,
    double? walletBalance,
    int? messagesCount,
    int? wishlistCount,
    int? ordersCount,
  }) {
    return ProfileState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      walletBalance: walletBalance ?? this.walletBalance,
      messagesCount: messagesCount ?? this.messagesCount,
      wishlistCount: wishlistCount ?? this.wishlistCount,
      ordersCount: ordersCount ?? this.ordersCount,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiClient _apiClient;
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  ProfileNotifier(this._apiClient, this._ref) : super(const ProfileState());

  Future<String?> pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      return image?.path;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? email,
    required String phone,
    required String sellerType,
    required String address,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final normalizedPhone = cleanPhone.length > 10
        ? cleanPhone.substring(cleanPhone.length - 10)
        : cleanPhone;

    final payload = {
      'name': name.trim(),
      'email': email?.trim(),
      'phone': normalizedPhone,
      'sellerType': sellerType,
      'address': address.trim(),
      'avatarUrl': avatarUrl,
    };

    try {
      final response = await _apiClient.dio.put('/user/profile', data: payload);

      if (response.data != null && response.data['success'] == true) {
        final userData = response.data['data'] as Map<String, dynamic>;
        await _apiClient.saveUserData(jsonEncode(userData));

        // Update auth state so app-wide UI reflects name, email, phone, etc.
        _ref.read(authProvider.notifier).checkAuthStatus();

        state = state.copyWith(isSaving: false);
        return true;
      } else {
        final msg = response.data?['message']?.toString() ?? 'Failed to update profile';
        state = state.copyWith(isSaving: false, errorMessage: msg);
        return false;
      }
    } catch (e) {
      // Optimistic local update if offline
      final currentUser = _ref.read(authProvider).user;
      if (currentUser != null) {
        final localUpdated = currentUser.copyWith(
          name: name.trim(),
          email: email?.trim(),
          phone: normalizedPhone,
          sellerType: sellerType,
          address: address.trim(),
          avatarUrl: avatarUrl,
        );
        await _apiClient.saveUserData(jsonEncode(localUpdated.toJson()));
      }
      state = state.copyWith(isSaving: false);
      return true;
    }
  }

  void addWalletBalance(double amount) {
    state = state.copyWith(walletBalance: state.walletBalance + amount);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileNotifier(apiClient, ref);
});
