import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';
import '../../features/auth/providers/auth_provider.dart';

class LiveLocationState {
  final bool isLoading;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? locality;
  final String? formattedAddress;
  final String? errorMessage;

  const LiveLocationState({
    this.isLoading = false,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.locality,
    this.formattedAddress,
    this.errorMessage,
  });

  String get displayText {
    if (isLoading && city == null) return 'Detecting location...';
    if (city != null && city!.isNotEmpty) {
      if (locality != null && locality!.isNotEmpty && locality != city) {
        return '$locality, $city';
      }
      if (state != null && state!.isNotEmpty) {
        return '$city, $state';
      }
      return city!;
    }
    if (formattedAddress != null && formattedAddress!.isNotEmpty) {
      final parts = formattedAddress!.split(',');
      if (parts.length >= 2) {
        return '${parts[0].trim()}, ${parts[1].trim()}';
      }
      return formattedAddress!;
    }
    return 'Location detected';
  }

  LiveLocationState copyWith({
    bool? isLoading,
    double? latitude,
    double? longitude,
    String? city,
    String? state,
    String? locality,
    String? formattedAddress,
    String? errorMessage,
  }) {
    return LiveLocationState(
      isLoading: isLoading ?? this.isLoading,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      state: state ?? this.state,
      locality: locality ?? this.locality,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      errorMessage: errorMessage,
    );
  }
}

class LiveLocationNotifier extends StateNotifier<LiveLocationState> {
  final Ref _ref;

  LiveLocationNotifier(this._ref) : super(const LiveLocationState()) {
    // Check authenticated user profile cache first, then fetch live GPS immediately
    final user = _ref.read(authProvider).user;
    if (user != null && user.city != null && user.city!.isNotEmpty) {
      state = state.copyWith(
        latitude: user.latitude,
        longitude: user.longitude,
        city: user.city,
        state: user.state,
        formattedAddress: user.address,
      );
    }
    fetchLiveLocation();
  }

  Future<void> fetchLiveLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        final details = await LocationService.getDetailsFromCoordinates(pos.latitude, pos.longitude);
        if (details != null && (details.city.isNotEmpty || details.formattedAddress.isNotEmpty)) {
          state = state.copyWith(
            isLoading: false,
            latitude: pos.latitude,
            longitude: pos.longitude,
            city: details.city.isNotEmpty ? details.city : null,
            state: details.state.isNotEmpty ? details.state : null,
            formattedAddress: details.formattedAddress,
          );
          return;
        } else {
          state = state.copyWith(
            isLoading: false,
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
          return;
        }
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error detecting live location: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void updateLocationManually({
    required double latitude,
    required double longitude,
    required String city,
    String? state,
    String? formattedAddress,
  }) {
    this.state = this.state.copyWith(
      latitude: latitude,
      longitude: longitude,
      city: city,
      state: state,
      formattedAddress: formattedAddress,
      isLoading: false,
    );
  }
}

final liveLocationProvider = StateNotifierProvider<LiveLocationNotifier, LiveLocationState>((ref) {
  return LiveLocationNotifier(ref);
});
