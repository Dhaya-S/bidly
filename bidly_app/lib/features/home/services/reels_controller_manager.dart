import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../../core/api/api_client.dart';

/// Global Manager for Reel VideoPlayerControllers enforcing a STRICT HARD LIMIT of max 3 active controllers.
class ReelsControllerManager {
  static final ReelsControllerManager _instance = ReelsControllerManager._internal();
  factory ReelsControllerManager() => _instance;
  ReelsControllerManager._internal();

  static const int maxActiveControllers = 3;

  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, int> _itemIndices = {};
  final Map<String, int> _generationTokens = {};
  int _globalTokenCounter = 0;
  int _currentActiveIndex = 0;

  int get activeCount => _controllers.length;

  int get currentActiveIndex => _currentActiveIndex;

  VideoPlayerController? getController(String listingId) => _controllers[listingId];

  bool isControllerReady(String listingId) {
    final c = _controllers[listingId];
    return c != null && c.value.isInitialized;
  }

  /// Updates current active page index and prunes distant controllers.
  void setActiveIndex(int activeIndex, List<String> listingIds) {
    _currentActiveIndex = activeIndex;
    final allowedIndices = {activeIndex - 1, activeIndex, activeIndex + 1};

    final toRemove = <String>[];
    _itemIndices.forEach((listingId, idx) {
      if (!allowedIndices.contains(idx)) {
        toRemove.add(listingId);
      }
    });

    for (final listingId in toRemove) {
      _disposeEntry(listingId, reason: 'outside window [${activeIndex - 1}..${activeIndex + 1}]');
    }

    // Play current active, pause others
    _controllers.forEach((listingId, controller) {
      final idx = _itemIndices[listingId];
      if (idx == activeIndex) {
        if (controller.value.isInitialized) {
          controller.setLooping(true);
          controller.play();
          debugPrint('[REEL_CONTROLLER] PLAY index=$idx listing=$listingId');
        }
      } else {
        if (controller.value.isInitialized && controller.value.isPlaying) {
          controller.pause();
          debugPrint('[REEL_CONTROLLER] PAUSE index=$idx listing=$listingId');
        }
      }
    });
  }

  /// Acquires or initializes a controller with strict budget checking.
  Future<VideoPlayerController?> acquireController({
    required String listingId,
    required String rawReelUrl,
    required int itemIndex,
    required int activeIndex,
    required bool autoPlay,
    required VoidCallback onReady,
    required VoidCallback onError,
  }) async {
    _currentActiveIndex = activeIndex;
    _itemIndices[listingId] = itemIndex;

    // 1. If already exists and initialized
    final existing = _controllers[listingId];
    if (existing != null) {
      if (existing.value.isInitialized) {
        if (itemIndex == activeIndex || autoPlay) {
          existing.setLooping(true);
          existing.play();
          debugPrint('[REEL_CONTROLLER] PLAY (existing) index=$itemIndex listing=$listingId');
        } else {
          existing.pause();
        }
        onReady();
        return existing;
      }
    }

    // 2. Enforce hard budget: prune controllers outside allowed window
    final allowedIndices = {activeIndex - 1, activeIndex, activeIndex + 1};
    final toPrune = <String>[];
    _itemIndices.forEach((id, idx) {
      if (id != listingId && !allowedIndices.contains(idx)) {
        toPrune.add(id);
      }
    });

    for (final pruneId in toPrune) {
      _disposeEntry(pruneId, reason: 'budget enforcement');
    }

    // If still at or above capacity (e.g. 3 controllers already in window), prune furthest
    if (_controllers.length >= maxActiveControllers) {
      String? furthestId;
      int maxDist = -1;
      _itemIndices.forEach((id, idx) {
        if (id != listingId) {
          final dist = (idx - activeIndex).abs();
          if (dist > maxDist) {
            maxDist = dist;
            furthestId = id;
          }
        }
      });
      if (furthestId != null) {
        _disposeEntry(furthestId!, reason: 'capacity limit $maxActiveControllers');
      }
    }

    // 3. Increment token for generation safety
    final currentToken = ++_globalTokenCounter;
    _generationTokens[listingId] = currentToken;

    // 4. Resolve URL and instantiate controller
    final reelUrl = ApiClient.resolveMediaUrl(rawReelUrl.trim());
    VideoPlayerController controller;
    if (reelUrl.startsWith('http://') || reelUrl.startsWith('https://')) {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(reelUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    } else if (reelUrl.startsWith('/') || reelUrl.contains(r'\')) {
      controller = VideoPlayerController.file(File(reelUrl));
    } else {
      controller = VideoPlayerController.asset(reelUrl);
    }

    // Dispose old reference for this listingId if any
    if (_controllers.containsKey(listingId)) {
      _disposeEntry(listingId, reason: 'recreating');
    }

    _controllers[listingId] = controller;
    _itemIndices[listingId] = itemIndex;
    debugPrint('[REEL_CONTROLLER] CREATE index=$itemIndex listing=$listingId');
    debugPrint('[REEL_CONTROLLER_COUNT] active=${_controllers.length}');

    try {
      await controller.initialize().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Reel video initialization timed out after 8s');
        },
      );

      // Generation & window safety check after async initialization
      if (_generationTokens[listingId] != currentToken ||
          _controllers[listingId] != controller ||
          !allowedIndices.contains(_itemIndices[listingId])) {
        debugPrint('[REEL_CONTROLLER] STALE DISPOSE index=$itemIndex listing=$listingId (token=$currentToken vs ${_generationTokens[listingId]})');
        _disposeEntry(listingId, reason: 'stale async result');
        return null;
      }

      controller.setLooping(true);
      if (itemIndex == _currentActiveIndex || autoPlay) {
        controller.play();
        debugPrint('[REEL_CONTROLLER] READY & PLAY index=$itemIndex listing=$listingId');
      } else {
        controller.pause();
        debugPrint('[REEL_CONTROLLER] READY & PAUSE (preload) index=$itemIndex listing=$listingId');
      }

      onReady();
      return controller;
    } catch (e) {
      debugPrint('[REEL_CONTROLLER] INIT ERROR index=$itemIndex listing=$listingId error=$e');
      if (_controllers[listingId] == controller) {
        _disposeEntry(listingId, reason: 'init failed');
      }
      onError();
      return null;
    }
  }

  /// Disposes controller for a single listing.
  void releaseController(String listingId) {
    _disposeEntry(listingId, reason: 'explicit release');
  }

  void _disposeEntry(String listingId, {required String reason}) {
    final controller = _controllers.remove(listingId);
    _itemIndices.remove(listingId);
    _generationTokens.remove(listingId);

    if (controller != null) {
      debugPrint('[REEL_CONTROLLER] DISPOSE listing=$listingId reason=$reason');
      try {
        controller.pause();
        controller.dispose();
      } catch (e) {
        debugPrint('[REEL_CONTROLLER] DISPOSE error: $e');
      }
      debugPrint('[REEL_CONTROLLER_COUNT] active=${_controllers.length}');
    }
  }

  /// Disposes all video controllers (called when navigating away from Reels).
  void disposeAll() {
    final keys = List<String>.from(_controllers.keys);
    for (final k in keys) {
      _disposeEntry(k, reason: 'disposeAll');
    }
    _controllers.clear();
    _itemIndices.clear();
    _generationTokens.clear();
    debugPrint('[REEL_CONTROLLER_COUNT] active=0 (all disposed)');
  }
}
