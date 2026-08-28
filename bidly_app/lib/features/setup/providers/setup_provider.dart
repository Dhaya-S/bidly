import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/location_service.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class SetupState {
  final bool isLoading;
  final bool isLocationLoading;
  final String? errorMessage;
  final int currentStep;
  final String? detectedLocation;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;
  final String? stateName;
  final String? pincode;
  final int selectedRadiusKm;
  final Set<String> selectedCategories;

  const SetupState({
    this.isLoading = false,
    this.isLocationLoading = false,
    this.errorMessage,
    this.currentStep = 1,
    this.detectedLocation,
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.stateName,
    this.pincode,
    this.selectedRadiusKm = 5,
    this.selectedCategories = const {},
  });

  SetupState copyWith({
    bool? isLoading,
    bool? isLocationLoading,
    String? errorMessage,
    int? currentStep,
    String? detectedLocation,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? stateName,
    String? pincode,
    int? selectedRadiusKm,
    Set<String>? selectedCategories,
  }) {
    return SetupState(
      isLoading: isLoading ?? this.isLoading,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
      errorMessage: errorMessage,
      currentStep: currentStep ?? this.currentStep,
      detectedLocation: detectedLocation ?? this.detectedLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      stateName: stateName ?? this.stateName,
      pincode: pincode ?? this.pincode,
      selectedRadiusKm: selectedRadiusKm ?? this.selectedRadiusKm,
      selectedCategories: selectedCategories ?? this.selectedCategories,
    );
  }
}

class SetupNotifier extends StateNotifier<SetupState> {
  final ApiClient _apiClient;
  final Ref _ref;

  SetupNotifier(this._apiClient, this._ref) : super(const SetupState());

  void setRadius(int radiusKm) {
    String? updatedBanner;
    if (state.city != null && state.city!.isNotEmpty) {
      final stateStr = state.stateName != null && state.stateName!.isNotEmpty ? ', ${state.stateName}' : '';
      updatedBanner = '${state.city}$stateStr — ${radiusKm}km radius detected';
    }
    state = state.copyWith(
      selectedRadiusKm: radiusKm,
      detectedLocation: updatedBanner ?? state.detectedLocation,
    );
  }

  /// Sets coordinates, reverse-geocodes to real address, and updates state
  Future<void> setCoordinates(double lat, double lng) async {
    state = state.copyWith(isLocationLoading: true, latitude: lat, longitude: lng);
    final details = await LocationService.getDetailsFromCoordinates(lat, lng);
    if (details != null && (details.city.isNotEmpty || details.formattedAddress.isNotEmpty)) {
      final stateStr = details.state.isNotEmpty ? ', ${details.state}' : '';
      final cityName = details.city.isNotEmpty ? details.city : (details.state.isNotEmpty ? details.state : '');
      state = state.copyWith(
        isLocationLoading: false,
        latitude: lat,
        longitude: lng,
        address: details.formattedAddress,
        city: details.city,
        stateName: details.state,
        pincode: details.pincode,
        detectedLocation: cityName.isNotEmpty ? '$cityName$stateStr — ${state.selectedRadiusKm}km radius detected' : 'GPS Location detected',
      );
    } else {
      state = state.copyWith(
        isLocationLoading: false,
        latitude: lat,
        longitude: lng,
        detectedLocation: 'GPS Location detected — ${state.selectedRadiusKm}km radius',
      );
    }
  }

  /// Fetches real GPS position from device
  Future<void> fetchCurrentGpsLocation() async {
    state = state.copyWith(isLocationLoading: true, errorMessage: null);
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        await setCoordinates(pos.latitude, pos.longitude);
      } else {
        state = state.copyWith(isLocationLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLocationLoading: false);
    }
  }

  /// Searches address in real time and forward-geocodes it
  Future<bool> searchAndSetAddress(String query) async {
    if (query.trim().isEmpty) return false;
    state = state.copyWith(isLocationLoading: true);
    try {
      final details = await LocationService.getDetailsFromAddress(query);
      if (details != null) {
        final stateStr = details.state.isNotEmpty ? ', ${details.state}' : '';
        final cityName = details.city.isNotEmpty ? details.city : query;
        state = state.copyWith(
          isLocationLoading: false,
          latitude: details.latitude,
          longitude: details.longitude,
          address: details.formattedAddress,
          city: details.city,
          stateName: details.state,
          pincode: details.pincode,
          detectedLocation: '$cityName$stateStr — ${state.selectedRadiusKm}km radius detected',
        );
        return true;
      }
      state = state.copyWith(isLocationLoading: false);
      return false;
    } catch (_) {
      state = state.copyWith(isLocationLoading: false);
      return false;
    }
  }

  void toggleCategory(String category) {
    final current = Set<String>.from(state.selectedCategories);
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    state = state.copyWith(selectedCategories: current);
  }

  /// Verify identity via DigiLocker
  Future<bool> verifyDigiLocker() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.dio.put(
        '/user/setup/identity',
        data: {'provider': 'DIGILOCKER'},
      );

      if (response.data != null && response.data['success'] == true) {
        final userData = response.data['data'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);
        _updateAuthUser(user);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        final msg = response.data?['message'] as String? ?? 'Verification failed';
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message']?.toString() ?? 'Failed to connect to DigiLocker',
      );
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Unexpected error occurred');
      return false;
    }
  }

  /// Save location preferences and persist coordinates in database
  Future<bool> saveLocation({
    String? manualAddress,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // If manual address is entered and no coordinates exist, try forward-geocoding first
    if ((state.latitude == null || state.longitude == null) && manualAddress != null && manualAddress.trim().isNotEmpty) {
      await searchAndSetAddress(manualAddress.trim());
    }

    final finalAddress = (manualAddress != null && manualAddress.trim().isNotEmpty)
        ? manualAddress.trim()
        : state.address;

    try {
      final response = await _apiClient.dio.put(
        '/user/setup/location',
        data: {
          'address': finalAddress,
          'city': state.city,
          'state': state.stateName,
          'pincode': state.pincode,
          'latitude': state.latitude,
          'longitude': state.longitude,
          'searchRadiusKm': state.selectedRadiusKm,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final userData = response.data['data'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);
        _updateAuthUser(user);
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to save location coordinates');
      return false;
    }
  }

  /// Save category preferences and finish setup
  Future<bool> finishSetup() async {
    if (state.selectedCategories.length < 3) {
      state = state.copyWith(errorMessage: 'Please select at least 3 categories');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.dio.put(
        '/user/setup/interests',
        data: {
          'interests': state.selectedCategories.toList(),
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final userData = response.data['data'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);
        _updateAuthUser(user);
        state = state.copyWith(isLoading: false);
        return true;
      }
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to complete setup');
      return false;
    }
  }

  void _updateAuthUser(UserModel user) {
    final currentAuthState = _ref.read(authProvider);
    _ref.read(authProvider.notifier).state = currentAuthState.copyWith(user: user);
  }
}

final setupProvider = StateNotifierProvider<SetupNotifier, SetupState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SetupNotifier(apiClient, ref);
});
