import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationDetails {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String city;
  final String state;
  final String pincode;

  const LocationDetails({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.city,
    required this.state,
    required this.pincode,
  });
}

class LocationService {
  static const String _googleMapsApiKey = 'AIzaSyALDMYAfDXu-dDv5dXd6VuQCJCTsRPG4UY';
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Requests permission and fetches user's real GPS position from device
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location service is off on device
        return await Geolocator.getLastKnownPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await Geolocator.getLastKnownPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }

      // Try fetching current live GPS position
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        // Fallback to last known position if current position timed out
        return await Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocodes coordinates to human-readable address & city using Google Geocoding API + fallback
  static Future<LocationDetails?> getDetailsFromCoordinates(double lat, double lng) async {
    // 1. Try Google Maps Geocoding HTTP API (Primary & most reliable)
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_googleMapsApiKey';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final firstResult = data['results'][0];
          final formattedAddress = firstResult['formatted_address'] as String? ?? '';

          String city = '';
          String state = '';
          String pincode = '';
          String area = '';

          final addressComponents = firstResult['address_components'] as List? ?? [];
          for (var comp in addressComponents) {
            final types = comp['types'] as List? ?? [];
            if (types.contains('locality')) {
              city = comp['long_name'] as String? ?? '';
            } else if (city.isEmpty && types.contains('administrative_area_level_2')) {
              city = comp['long_name'] as String? ?? '';
            }
            if (types.contains('administrative_area_level_1')) {
              state = comp['long_name'] as String? ?? '';
            }
            if (types.contains('postal_code')) {
              pincode = comp['long_name'] as String? ?? '';
            }
            if (types.contains('sublocality') || types.contains('sublocality_level_1')) {
              area = comp['long_name'] as String? ?? '';
            }
          }

          String displayAddress = formattedAddress;
          if (displayAddress.isEmpty) {
            displayAddress = [area, city, state].where((s) => s.isNotEmpty).join(', ');
          }

          return LocationDetails(
            latitude: lat,
            longitude: lng,
            formattedAddress: displayAddress.isNotEmpty ? displayAddress : '$lat, $lng',
            city: city.isNotEmpty ? city : area,
            state: state,
            pincode: pincode,
          );
        }
      }
    } catch (_) {}

    // 2. Native Geocoding Fallback
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String city = place.locality ?? place.subAdministrativeArea ?? '';
        String state = place.administrativeArea ?? '';
        String pincode = place.postalCode ?? '';
        String area = place.subLocality ?? place.name ?? '';

        String formatted = [area, city, state]
            .where((s) => s.isNotEmpty)
            .join(', ');

        return LocationDetails(
          latitude: lat,
          longitude: lng,
          formattedAddress: formatted.isNotEmpty ? formatted : (city.isNotEmpty ? city : '$lat, $lng'),
          city: city,
          state: state,
          pincode: pincode,
        );
      }
    } catch (_) {}

    return LocationDetails(
      latitude: lat,
      longitude: lng,
      formattedAddress: '',
      city: '',
      state: '',
      pincode: '',
    );
  }

  /// Forward geocodes text query to real coordinates using Google Geocoding API + fallback
  static Future<LocationDetails?> getDetailsFromAddress(String query) async {
    if (query.trim().isEmpty) return null;

    // 1. Try Google Maps Geocoding API
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encoded&key=$_googleMapsApiKey';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final firstResult = data['results'][0];
          final location = firstResult['geometry']?['location'];
          if (location != null) {
            final lat = (location['lat'] as num).toDouble();
            final lng = (location['lng'] as num).toDouble();
            final formattedAddress = firstResult['formatted_address'] as String? ?? query;

            String city = '';
            String state = '';
            String pincode = '';

            final addressComponents = firstResult['address_components'] as List? ?? [];
            for (var comp in addressComponents) {
              final types = comp['types'] as List? ?? [];
              if (types.contains('locality')) {
                city = comp['long_name'] as String? ?? '';
              } else if (city.isEmpty && types.contains('administrative_area_level_2')) {
                city = comp['long_name'] as String? ?? '';
              }
              if (types.contains('administrative_area_level_1')) {
                state = comp['long_name'] as String? ?? '';
              }
              if (types.contains('postal_code')) {
                pincode = comp['long_name'] as String? ?? '';
              }
            }

            return LocationDetails(
              latitude: lat,
              longitude: lng,
              formattedAddress: formattedAddress,
              city: city,
              state: state,
              pincode: pincode,
            );
          }
        }
      }
    } catch (_) {}

    // 2. Native Forward Geocoding Fallback
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location loc = locations.first;
        return await getDetailsFromCoordinates(loc.latitude, loc.longitude);
      }
    } catch (_) {}

    return null;
  }
}
