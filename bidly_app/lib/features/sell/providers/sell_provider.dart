import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../explore/models/listing_model.dart';
import '../../explore/providers/explore_provider.dart';
import '../../home/providers/reels_provider.dart';

class SellState {
  final bool isLoading;
  final String? errorMessage;
  final String category;
  final String subcategory;
  final List<String> photos;
  final String? reelPath;
  final String title;
  final String? purchaseDate;
  final String description;
  final double price;
  final String condition;
  final bool hasDamage;
  final String? damageDetails;
  final String sellingScope; // 'COMMUNITIES', 'GLOBAL', 'CUSTOM_RADIUS'
  final String? communityId;
  final String? communityName;
  final int targetRadiusKm;
  final String sellingMethod; // 'DIRECT_BUY', 'AUCTION'
  final double? minimumBid;
  final double? bidIncrement;
  final String? auctionEndDate;
  final String? auctionEndTime;
  final ListingModel? createdListing;

  const SellState({
    this.isLoading = false,
    this.errorMessage,
    this.category = 'Electronics',
    this.subcategory = 'Phones',
    this.photos = const [],
    this.reelPath,
    this.title = '',
    this.purchaseDate,
    this.description = '',
    this.price = 0.0,
    this.condition = 'Excellent',
    this.hasDamage = false,
    this.damageDetails,
    this.sellingScope = 'GLOBAL',
    this.communityId,
    this.communityName,
    this.targetRadiusKm = 10,
    this.sellingMethod = 'DIRECT_BUY',
    this.minimumBid,
    this.bidIncrement,
    this.auctionEndDate,
    this.auctionEndTime,
    this.createdListing,
  });

  SellState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? category,
    String? subcategory,
    List<String>? photos,
    String? reelPath,
    String? title,
    String? purchaseDate,
    String? description,
    double? price,
    String? condition,
    bool? hasDamage,
    String? damageDetails,
    String? sellingScope,
    String? communityId,
    String? communityName,
    int? targetRadiusKm,
    String? sellingMethod,
    double? minimumBid,
    double? bidIncrement,
    String? auctionEndDate,
    String? auctionEndTime,
    ListingModel? createdListing,
  }) {
    return SellState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      photos: photos ?? this.photos,
      reelPath: reelPath ?? this.reelPath,
      title: title ?? this.title,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      description: description ?? this.description,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      hasDamage: hasDamage ?? this.hasDamage,
      damageDetails: damageDetails ?? this.damageDetails,
      sellingScope: sellingScope ?? this.sellingScope,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      targetRadiusKm: targetRadiusKm ?? this.targetRadiusKm,
      sellingMethod: sellingMethod ?? this.sellingMethod,
      minimumBid: minimumBid ?? this.minimumBid,
      bidIncrement: bidIncrement ?? this.bidIncrement,
      auctionEndDate: auctionEndDate ?? this.auctionEndDate,
      auctionEndTime: auctionEndTime ?? this.auctionEndTime,
      createdListing: createdListing ?? this.createdListing,
    );
  }
}

class SellNotifier extends StateNotifier<SellState> {
  final ApiClient _apiClient;
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  SellNotifier(this._apiClient, this._ref) : super(const SellState());

  void initForCommunity({required String communityId, required String communityName}) {
    state = state.copyWith(
      sellingScope: 'COMMUNITIES',
      communityId: communityId,
      communityName: communityName,
    );
  }

  void setCommunity({String? communityId, String? communityName}) {
    state = state.copyWith(
      communityId: communityId,
      communityName: communityName,
    );
  }

  void setCategory(String category, {String? defaultSubcategory}) {
    state = state.copyWith(
      category: category,
      subcategory: defaultSubcategory ?? _getDefaultSubcategory(category),
    );
  }

  void setSubcategory(String subcategory) {
    state = state.copyWith(subcategory: subcategory);
  }

  void setCondition(String condition) {
    state = state.copyWith(condition: condition);
  }

  void setHasDamage(bool hasDamage) {
    state = state.copyWith(hasDamage: hasDamage);
  }

  void setDamageDetails(String details) {
    state = state.copyWith(damageDetails: details);
  }

  void setBasicDetails({
    required String title,
    required String description,
    required double price,
    String? purchaseDate,
  }) {
    state = state.copyWith(
      title: title,
      description: description,
      price: price,
      purchaseDate: purchaseDate,
    );
  }

  void setSellingScope(String scope, {int? radiusKm}) {
    state = state.copyWith(
      sellingScope: scope,
      targetRadiusKm: radiusKm ?? state.targetRadiusKm,
    );
  }

  void setSellingMethod(String method) {
    state = state.copyWith(sellingMethod: method);
  }

  void setBidSettings({
    required double minimumBid,
    required double bidIncrement,
    required String endDate,
    required String endTime,
  }) {
    state = state.copyWith(
      minimumBid: minimumBid,
      bidIncrement: bidIncrement,
      auctionEndDate: endDate,
      auctionEndTime: endTime,
    );
  }

  Future<void> pickPhoto() async {
    if (state.photos.length >= 8) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        final docDir = await getApplicationDocumentsDirectory();
        final ext = image.path.split('.').last;
        final targetPath = '${docDir.path}/photo_${DateTime.now().millisecondsSinceEpoch}_${state.photos.length}.$ext';
        final savedFile = await File(image.path).copy(targetPath);
        final updated = List<String>.from(state.photos)..add(savedFile.path);
        state = state.copyWith(photos: updated);
      }
    } catch (_) {}
  }

  Future<void> pickMultiPhotos() async {
    if (state.photos.length >= 8) return;
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        final docDir = await getApplicationDocumentsDirectory();
        final updated = List<String>.from(state.photos);
        for (final img in images) {
          if (updated.length >= 8) break;
          final ext = img.path.split('.').last;
          final targetPath = '${docDir.path}/photo_${DateTime.now().millisecondsSinceEpoch}_${updated.length}.$ext';
          final savedFile = await File(img.path).copy(targetPath);
          updated.add(savedFile.path);
        }
        state = state.copyWith(photos: updated);
      }
    } catch (_) {}
  }

  void removePhoto(int index) {
    if (index >= 0 && index < state.photos.length) {
      final updated = List<String>.from(state.photos)..removeAt(index);
      state = state.copyWith(photos: updated);
    }
  }

  Future<void> pickReel() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (video != null) {
        final file = File(video.path);
        if (!file.existsSync()) {
          state = state.copyWith(errorMessage: 'Selected video file not found.');
          return;
        }

        // Validate max file size (100 MB limit)
        final sizeBytes = await file.length();
        if (sizeBytes > 104857600) {
          final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
          state = state.copyWith(errorMessage: 'Video file size (${sizeMb}MB) exceeds the 100MB limit.');
          return;
        }

        // Validate supported video extension
        final ext = video.path.split('.').last.toLowerCase();
        final supportedExts = {'mp4', 'mov', 'm4v', 'webm', '3gp', 'mkv', 'avi'};
        if (!supportedExts.contains(ext)) {
          state = state.copyWith(errorMessage: 'Unsupported video format ($ext). Please choose an MP4 or MOV video.');
          return;
        }

        final docDir = await getApplicationDocumentsDirectory();
        final targetPath = '${docDir.path}/reel_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final savedFile = await file.copy(targetPath);
        state = state.copyWith(reelPath: savedFile.path, errorMessage: null);
      }
    } catch (e) {
      debugPrint('Error picking reel: $e');
    }
  }

  void removeReel() {
    state = state.copyWith(reelPath: null);
  }

  /// Upload file to Cloudflare R2 bucket via Backend API (with retry)
  Future<String?> _uploadFileToR2(String filePath, {String folder = 'listings'}) async {
    final res = await _uploadMediaToR2(filePath, folder: folder);
    return res?['url'];
  }

  /// Detailed upload returning both primary media URL and companion thumbnail URL
  Future<Map<String, String?>?> _uploadMediaToR2(String filePath, {String folder = 'listings'}) async {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return {'url': filePath, 'thumbnailUrl': null}; // Already a remote CDN URL
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      debugPrint('Media file not found at path: $filePath');
      return null;
    }

    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final fileName = filePath.split(Platform.pathSeparator).last;
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath, filename: fileName),
          'folder': folder,
        });

        final response = await _apiClient.dio.post(
          '/media/upload',
          data: formData,
          options: Options(
            sendTimeout: const Duration(minutes: 5),
            receiveTimeout: const Duration(minutes: 5),
          ),
        );

        if (response.data != null && response.data['success'] == true) {
          final data = response.data['data'] as Map<String, dynamic>;
          return {
            'url': data['url'] as String?,
            'thumbnailUrl': data['thumbnailUrl'] as String?,
          };
        }
      } catch (e) {
        debugPrint('Media upload attempt $attempt/$maxRetries failed: $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt)); // Backoff
          continue;
        }
      }
    }
    return null;
  }

  /// Submit the completed listing to the backend API and store in database
  Future<bool> submitListing() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final user = _ref.read(authProvider).user;

    // 1. Upload photos to Cloudflare R2
    List<String> r2MediaUrls = [];
    for (final photoPath in state.photos) {
      final uploadedUrl = await _uploadFileToR2(photoPath, folder: 'listings/photos');
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        r2MediaUrls.add(uploadedUrl);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to upload photo. Please check your connection and try again.',
        );
        return false;
      }
    }

    // 2. Upload reel video to Cloudflare R2 if present (with companion thumbnail extraction)
    String? r2ReelUrl;
    if (state.reelPath != null && state.reelPath!.isNotEmpty) {
      final file = File(state.reelPath!);
      if (file.existsSync()) {
        final uploadResult = await _uploadMediaToR2(state.reelPath!, folder: 'listings/reels');
        if (uploadResult != null && uploadResult['url'] != null && uploadResult['url']!.isNotEmpty) {
          r2ReelUrl = uploadResult['url'];
          // If seller did not select photos, use the auto-generated thumbnail as the listing's primary image!
          final thumb = uploadResult['thumbnailUrl'];
          if (r2MediaUrls.isEmpty && thumb != null && thumb.isNotEmpty) {
            r2MediaUrls.add(thumb);
          }
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to upload reel video. Please try again.',
          );
          return false;
        }
      } else {
        debugPrint('Reel file at ${state.reelPath} not found on disk, skipping reel.');
      }
    }

    // Convert condition to enum format
    String conditionEnum = state.condition.toUpperCase().replaceAll(' ', '_');

    // Build auction end time if AUCTION
    String? auctionEndIso;
    if (state.sellingMethod == 'AUCTION' && state.auctionEndDate != null) {
      try {
        final dateParts = state.auctionEndDate!.split('-');
        if (dateParts.length == 3) {
          int year = int.parse(dateParts[0]);
          int month = int.parse(dateParts[1]);
          int day = int.parse(dateParts[2]);

          int hour = 18;
          int minute = 0;
          if (state.auctionEndTime != null && state.auctionEndTime!.isNotEmpty) {
            final cleanTime = state.auctionEndTime!.trim().toUpperCase();
            final isPm = cleanTime.contains('PM');
            final isAm = cleanTime.contains('AM');
            final rawDigits = cleanTime.replaceAll(RegExp(r'[^\d:]'), '').trim();
            final timeParts = rawDigits.split(':');
            if (timeParts.isNotEmpty) {
              hour = int.parse(timeParts[0]);
              if (timeParts.length > 1) {
                minute = int.parse(timeParts[1]);
              }
              if (isPm && hour < 12) hour += 12;
              if (isAm && hour == 12) hour = 0;
            }
          }
          final dt = DateTime(year, month, day, hour, minute);
          auctionEndIso = dt.toUtc().toIso8601String();
        }
      } catch (e) {
        debugPrint('Error parsing auction end time: $e');
      }
    }

    final payload = {
      'category': state.category,
      'subcategory': state.subcategory,
      'title': state.title,
      'description': state.description,
      'price': state.price,
      'condition': conditionEnum,
      'purchaseDate': state.purchaseDate,
      'hasDamage': state.hasDamage,
      'damageDetails': state.damageDetails,
      'sellingScope': state.sellingScope,
      'communityId': state.communityId,
      'communityName': state.communityName,
      'targetRadiusKm': state.targetRadiusKm,
      'sellingMethod': state.sellingMethod,
      'startingBid': state.minimumBid ?? state.price,
      'bidIncrement': state.bidIncrement ?? 100.0,
      'auctionEndTime': auctionEndIso,
      'mediaUrls': r2MediaUrls,
      'reelUrl': r2ReelUrl,
      'sellerId': user?.id,
      'sellerName': user?.name,
      'sellerPhone': user?.phone,
      'city': user?.city,
      'state': user?.state,
      'locality': user?.address,
      'latitude': user?.latitude,
      'longitude': user?.longitude,
    };

    try {
      final response = await _apiClient.dio.post('/listings', data: payload);

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final created = ListingModel.fromJson(data);

        state = state.copyWith(isLoading: false, createdListing: created);

        // Refresh explore feed and home reels feed so new item shows immediately
        _ref.read(exploreProvider.notifier).fetchExploreData(isRefresh: true);
        _ref.read(reelsProvider.notifier).fetchReels(isRefresh: true);
        return true;
      } else {
        final msg = response.data?['message']?.toString() ?? 'Failed to list product';
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to connect to server. Please try again.',
      );
      return false;
    }
  }

  void resetForm() {
    state = const SellState();
  }

  String _getDefaultSubcategory(String category) {
    switch (category) {
      case 'Electronics':
      case 'Electronic':
        return 'Phones';
      case 'Computers':
        return 'Laptops';
      case 'Fashion':
        return 'Men';
      case 'Vehicles':
        return 'Cars';
      case 'Sports':
        return 'Fitness';
      default:
        return 'General';
    }
  }
}

final sellProvider = StateNotifierProvider<SellNotifier, SellState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SellNotifier(apiClient, ref);
});
