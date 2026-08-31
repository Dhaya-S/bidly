import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../../core/api/api_client.dart';

/// Possible lifecycle states of a VideoPlayerController in Reels
enum ControllerState {
  absent,
  initializing,
  ready,
  playing,
  paused,
  disposed,
}

/// Performance timing tracker for detailed Reel startup metrics
class ReelTimingTracker {
  final String listingId;
  final int itemIndex;
  final Stopwatch _stopwatch = Stopwatch()..start();
  int? controllerCreateMs;
  int? initStartMs;
  int? initCompleteMs;
  int? playerReadyMs;
  int? firstFrameMs;
  int? playStartMs;
  bool controllerReused = false;
  bool preloaded = false;
  bool _logged = false;

  ReelTimingTracker({required this.listingId, required this.itemIndex});

  void markControllerCreated() => controllerCreateMs = _stopwatch.elapsedMilliseconds;
  void markInitStart() => initStartMs = _stopwatch.elapsedMilliseconds;
  void markInitComplete() => initCompleteMs = _stopwatch.elapsedMilliseconds;
  void markPlayerReady() => playerReadyMs = _stopwatch.elapsedMilliseconds;
  void markFirstFrame() => firstFrameMs = _stopwatch.elapsedMilliseconds;
  void markPlayStart() => playStartMs = _stopwatch.elapsedMilliseconds;

  void printSummary() {
    if (_logged) return;
    _logged = true;
    final totalStartupMs = firstFrameMs ?? playerReadyMs ?? _stopwatch.elapsedMilliseconds;
    debugPrint(
      '[REEL_TIMING] listing=$listingId index=$itemIndex '
      'controller_create_ms=${controllerCreateMs ?? 0} '
      'initialize_start_ms=${initStartMs ?? 0} '
      'initialize_complete_ms=${initCompleteMs ?? 0} '
      'player_ready_ms=${playerReadyMs ?? 0} '
      'first_frame_ms=${firstFrameMs ?? 0} '
      'play_start_ms=${playStartMs ?? 0} '
      'total_startup_ms=$totalStartupMs '
      'controller_reused=$controllerReused '
      'preloaded=$preloaded',
    );
  }
}

/// Unified, stable entry representing a single Reel's video controller and lifecycle
class ControllerEntry {
  final String listingId;
  int itemIndex;
  VideoPlayerController? controller;
  ControllerState state;
  Future<VideoPlayerController?>? initFuture;
  int generationToken;
  bool isStale;
  bool firstFrameReady;
  DateTime lastUsed;
  final ReelTimingTracker timing;

  ControllerEntry({
    required this.listingId,
    required this.itemIndex,
    required this.generationToken,
    required this.timing,
    this.controller,
    this.state = ControllerState.absent,
    this.initFuture,
    this.isStale = false,
    this.firstFrameReady = false,
  }) : lastUsed = DateTime.now();

  bool get isInitialized =>
      controller != null &&
      !isStale &&
      state != ControllerState.disposed &&
      state != ControllerState.absent &&
      controller!.value.isInitialized;
}

/// Global Single-Owner Manager for Reel VideoPlayerControllers
/// Enforces:
/// 1. Maximum 3 active VideoPlayerControllers at any time ([activeIndex - 1, activeIndex, activeIndex + 1])
/// 2. Stable ControllerEntry reuse (no duplicate initializations or recreate churn)
/// 3. CURRENT-first priority (NEXT preloads only after CURRENT is ready)
/// 4. Decoupled widget lifecycle (widgets display controllers; manager owns lifetime)
class ReelsControllerManager {
  static final ReelsControllerManager _instance = ReelsControllerManager._internal();
  factory ReelsControllerManager() => _instance;
  ReelsControllerManager._internal();

  static const int maxActiveControllers = 3;

  final Map<String, ControllerEntry> _entries = {};
  final Map<int, VoidCallback> _deferredPreloads = {};

  int _globalTokenCounter = 0;
  int _currentActiveIndex = 0;

  int get activeCount => _entries.values.where((e) => e.controller != null && !e.isStale).length;
  int get currentActiveIndex => _currentActiveIndex;

  VideoPlayerController? getController(String listingId) => _entries[listingId]?.controller;
  ControllerEntry? getEntry(String listingId) => _entries[listingId];
  ReelTimingTracker? getTiming(String listingId) => _entries[listingId]?.timing;

  bool isControllerReady(String listingId) {
    final entry = _entries[listingId];
    return entry != null && entry.isInitialized;
  }

  bool isCurrentReady() {
    for (final entry in _entries.values) {
      if (entry.itemIndex == _currentActiveIndex && entry.isInitialized) {
        return true;
      }
    }
    return false;
  }

  /// Notified when CURRENT Reel renders its first frame or finishes initialization.
  /// Safely unlocks background preloading of NEXT Reel.
  void notifyCurrentReady(int activeIndex) {
    if (activeIndex != _currentActiveIndex) return;

    for (final entry in _entries.values) {
      if (entry.itemIndex == activeIndex && !entry.firstFrameReady) {
        entry.firstFrameReady = true;
        entry.state = ControllerState.playing;
      }
    }

    final nextIndex = activeIndex + 1;
    final preloadCallback = _deferredPreloads.remove(nextIndex);
    if (preloadCallback != null) {
      debugPrint('[REEL_CONTROLLER] PRELOAD_NEXT index=$nextIndex (unlocked by current)');
      preloadCallback();
    }
  }

  /// Updates current active page index, prunes distant controllers, and sets playback states.
  void setActiveIndex(int activeIndex, List<String> listingIds) {
    final prevActive = _currentActiveIndex;
    _currentActiveIndex = activeIndex;

    final direction = activeIndex >= prevActive ? 'FORWARD' : 'BACKWARD';
    debugPrint('[REEL_SCROLL] from=$prevActive to=$activeIndex direction=$direction active_controller_count=$activeCount');

    final allowedIndices = {activeIndex - 1, activeIndex, activeIndex + 1};

    // 1. Mark distant entries as stale and dispose them
    final toPrune = <String>[];
    _entries.forEach((listingId, entry) {
      if (!allowedIndices.contains(entry.itemIndex)) {
        toPrune.add(listingId);
      }
    });

    for (final listingId in toPrune) {
      _disposeEntry(listingId, reason: 'outside window [${activeIndex - 1}..${activeIndex + 1}]');
    }

    // 2. Adjust playback states for allowed entries
    _entries.forEach((listingId, entry) {
      final controller = entry.controller;
      if (controller != null && entry.isInitialized) {
        if (entry.itemIndex == activeIndex) {
          entry.state = ControllerState.playing;
          entry.lastUsed = DateTime.now();
          controller.setLooping(true);
          controller.play();
          debugPrint('[REEL_CONTROLLER] PLAY index=${entry.itemIndex} listing=$listingId');
        } else {
          entry.state = ControllerState.paused;
          if (controller.value.isPlaying) {
            controller.pause();
            debugPrint('[REEL_CONTROLLER] PAUSE index=${entry.itemIndex} listing=$listingId');
          }
        }
      }
    });

    _logActiveCount();
  }

  /// Acquires or initializes a controller with strict reuse, generation safety, and staged preloading.
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

    // 0. Distant rejection: never initialize controllers beyond window [activeIndex-1 .. activeIndex+1]
    final isAllowed = (itemIndex >= activeIndex - 1) && (itemIndex <= activeIndex + 1);
    if (!isAllowed) {
      debugPrint('[REEL_CONTROLLER] REJECT DISTANT index=$itemIndex listing=$listingId active=$activeIndex');
      return null;
    }

    // 1. Check existing stable entry
    final existingEntry = _entries[listingId];
    if (existingEntry != null && !existingEntry.isStale) {
      existingEntry.itemIndex = itemIndex;
      existingEntry.lastUsed = DateTime.now();

      // If already initialized
      if (existingEntry.isInitialized) {
        existingEntry.timing.controllerReused = true;
        debugPrint('[REEL_CONTROLLER] REUSE index=$itemIndex listing=$listingId state=${existingEntry.state}');

        final controller = existingEntry.controller!;
        if (itemIndex == activeIndex || autoPlay) {
          existingEntry.state = ControllerState.playing;
          controller.setLooping(true);
          controller.play();
          debugPrint('[REEL_CONTROLLER] PLAY (reused) index=$itemIndex listing=$listingId');
          notifyCurrentReady(itemIndex);
        } else {
          existingEntry.state = ControllerState.paused;
          controller.pause();
          debugPrint('[REEL_CONTROLLER] PAUSE (reused) index=$itemIndex listing=$listingId');
        }

        onReady();
        return controller;
      }

      // If already initializing in-flight, reuse same Future
      if (existingEntry.initFuture != null) {
        debugPrint('[REEL_CONTROLLER] SKIP_DUPLICATE listing=$listingId in-flight');
        return await existingEntry.initFuture;
      }
    }

    // 2. Staged Preloading Guard:
    // If this is NEXT (itemIndex == activeIndex + 1) and CURRENT is not yet ready, defer preload until CURRENT is ready!
    if (itemIndex == activeIndex + 1 && !isCurrentReady()) {
      debugPrint('[REEL_CONTROLLER] DEFER PRELOAD index=$itemIndex listing=$listingId until current is ready');
      _deferredPreloads[itemIndex] = () {
        acquireController(
          listingId: listingId,
          rawReelUrl: rawReelUrl,
          itemIndex: itemIndex,
          activeIndex: _currentActiveIndex,
          autoPlay: false,
          onReady: onReady,
          onError: onError,
        );
      };
      return null;
    }

    // 3. Centralized capacity enforcement before creating a new controller
    _enforceCapacity(targetListingId: listingId, activeIndex: activeIndex);

    final timing = ReelTimingTracker(listingId: listingId, itemIndex: itemIndex);
    final currentToken = ++_globalTokenCounter;

    final newEntry = ControllerEntry(
      listingId: listingId,
      itemIndex: itemIndex,
      generationToken: currentToken,
      timing: timing,
      state: ControllerState.initializing,
    );
    _entries[listingId] = newEntry;

    final future = _initializeControllerInternal(
      entry: newEntry,
      rawReelUrl: rawReelUrl,
      itemIndex: itemIndex,
      activeIndex: activeIndex,
      autoPlay: autoPlay,
      onReady: onReady,
      onError: onError,
    );

    newEntry.initFuture = future;
    try {
      final result = await future;
      return result;
    } finally {
      if (identical(newEntry.initFuture, future)) {
        newEntry.initFuture = null;
      }
    }
  }

  Future<VideoPlayerController?> _initializeControllerInternal({
    required ControllerEntry entry,
    required String rawReelUrl,
    required int itemIndex,
    required int activeIndex,
    required bool autoPlay,
    required VoidCallback onReady,
    required VoidCallback onError,
  }) async {
    final listingId = entry.listingId;
    final timing = entry.timing;
    final currentToken = entry.generationToken;

    timing.markControllerCreated();
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

    entry.controller = controller;
    debugPrint('[REEL_CONTROLLER] CREATE index=$itemIndex listing=$listingId (token=$currentToken)');
    _logActiveCount();

    timing.markInitStart();
    try {
      final timeoutDuration = itemIndex == _currentActiveIndex
          ? const Duration(seconds: 10)
          : const Duration(seconds: 8);

      await controller.initialize().timeout(
        timeoutDuration,
        onTimeout: () {
          throw TimeoutException('Reel video initialization timed out after ${timeoutDuration.inSeconds}s');
        },
      );

      timing.markInitComplete();

      // Check if entry became stale during async initialization (e.g. rapid swipe)
      final allowedIndices = {_currentActiveIndex - 1, _currentActiveIndex, _currentActiveIndex + 1};
      if (entry.isStale ||
          entry.generationToken != currentToken ||
          !allowedIndices.contains(entry.itemIndex) ||
          _entries[listingId] != entry) {
        debugPrint('[REEL_CONTROLLER] STALE_CANCELLED index=$itemIndex listing=$listingId (token=$currentToken vs ${entry.generationToken})');
        try {
          controller.dispose();
        } catch (_) {}
        entry.state = ControllerState.disposed;
        return null;
      }

      controller.setLooping(true);
      timing.markPlayerReady();
      entry.state = ControllerState.ready;

      if (entry.itemIndex == _currentActiveIndex || autoPlay) {
        entry.state = ControllerState.playing;
        controller.play();
        timing.markPlayStart();
        debugPrint('[REEL_CONTROLLER] READY & PLAY index=$itemIndex listing=$listingId');
        notifyCurrentReady(itemIndex);
      } else {
        entry.state = ControllerState.paused;
        controller.pause();
        debugPrint('[REEL_CONTROLLER] READY_PRELOAD index=$itemIndex listing=$listingId');
      }

      onReady();
      return controller;
    } catch (e) {
      if (entry.isStale || entry.generationToken != currentToken || _entries[listingId] != entry) {
        debugPrint('[REEL_CONTROLLER] STALE_CANCELLED (on error) index=$itemIndex listing=$listingId');
        try {
          controller.dispose();
        } catch (_) {}
        entry.state = ControllerState.disposed;
        return null;
      }

      debugPrint('[REEL_CONTROLLER] INIT ERROR index=$itemIndex listing=$listingId error=$e');
      _disposeEntry(listingId, reason: 'init failed');
      onError();
      return null;
    }
  }

  void _enforceCapacity({required String targetListingId, required int activeIndex}) {
    while (_entries.length >= maxActiveControllers) {
      String? furthestId;
      int maxDist = -1;

      _entries.forEach((id, entry) {
        if (id != targetListingId) {
          final dist = (entry.itemIndex - activeIndex).abs();
          if (dist > maxDist) {
            maxDist = dist;
            furthestId = id;
          }
        }
      });

      if (furthestId != null) {
        _disposeEntry(furthestId!, reason: 'capacity limit $maxActiveControllers');
      } else {
        break;
      }
    }
  }

  void _disposeEntry(String listingId, {required String reason}) {
    final entry = _entries.remove(listingId);
    if (entry != null) {
      entry.isStale = true;
      entry.state = ControllerState.disposed;
      _deferredPreloads.remove(entry.itemIndex);

      final controller = entry.controller;
      if (controller != null) {
        debugPrint('[REEL_CONTROLLER] DISPOSE listing=$listingId reason=$reason');
        try {
          controller.pause();
          controller.dispose();
        } catch (e) {
          debugPrint('[REEL_CONTROLLER] DISPOSE error: $e');
        }
      }
    }
  }

  void _logActiveCount() {
    final count = activeCount;
    if (count > maxActiveControllers) {
      debugPrint('[REEL_CONTROLLER_COUNT] VIOLATION active=$count (max=$maxActiveControllers)');
    } else {
      debugPrint('[REEL_CONTROLLER_COUNT] active=$count');
    }
  }

  /// Pauses all active video controllers immediately (when leaving Feed tab, switching subtabs, or backgrounding app).
  void pauseAll() {
    debugPrint('[REEL_CONTROLLER] pauseAll() called');
    for (final entry in _entries.values) {
      final controller = entry.controller;
      if (controller != null && controller.value.isInitialized) {
        try {
          controller.pause();
          entry.state = ControllerState.paused;
        } catch (e) {
          debugPrint('[REEL_CONTROLLER] Error pausing controller: $e');
        }
      }
    }
  }

  /// Resumes playback of the current active Reel if on the Feed tab and initialized.
  void resumeCurrent() {
    debugPrint('[REEL_CONTROLLER] resumeCurrent() for active index $_currentActiveIndex');
    for (final entry in _entries.values) {
      if (entry.itemIndex == _currentActiveIndex) {
        final controller = entry.controller;
        if (controller != null && controller.value.isInitialized) {
          try {
            controller.play();
            entry.state = ControllerState.playing;
          } catch (e) {
            debugPrint('[REEL_CONTROLLER] Error resuming current controller: $e');
          }
        }
      }
    }
  }

  /// Disposes all video controllers (called when navigating away from Reels tab or app shutdown).
  void disposeAll() {
    final keys = List<String>.from(_entries.keys);
    for (final k in keys) {
      _disposeEntry(k, reason: 'disposeAll');
    }
    _entries.clear();
    _deferredPreloads.clear();
    debugPrint('[REEL_CONTROLLER_COUNT] active=0 (all disposed)');
  }
}
