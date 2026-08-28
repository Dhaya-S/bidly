import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';

class ChatRoomState {
  final ChatRoomModel? room;
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final double offerAmount;

  const ChatRoomState({
    this.room,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.offerAmount = 0.0,
  });

  ChatRoomState copyWith({
    ChatRoomModel? room,
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    double? offerAmount,
  }) {
    return ChatRoomState(
      room: room ?? this.room,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
      offerAmount: offerAmount ?? this.offerAmount,
    );
  }
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final ApiClient _apiClient;
  final Ref _ref;
  Timer? _pollingTimer;
  String? _currentRoomId;
  String? _currentListingId;

  ChatRoomNotifier(this._apiClient, this._ref) : super(const ChatRoomState());

  /// Initialize chat for a given listing (creates or joins room)
  Future<ChatRoomModel?> initRoomForListing(String listingId, double initialPrice) async {
    _currentListingId = listingId;
    state = state.copyWith(isLoading: state.messages.isEmpty, error: null, offerAmount: initialPrice);
    try {
      final res = await _apiClient.post('/chat/rooms', data: {'listingId': listingId});
      if (res.data != null && res.data['success'] == true) {
        final room = ChatRoomModel.fromJson(res.data['data']);
        _currentRoomId = room.id;
        state = state.copyWith(room: room, isLoading: false);
        await loadMessages(room.id);
        startPolling(room.id);
        return room;
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Connecting to chat...';
      state = state.copyWith(isLoading: false, error: msg.toString());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
    return null;
  }

  /// Load all messages for a room
  Future<void> loadMessages(String roomId) async {
    try {
      final res = await _apiClient.get('/chat/rooms/$roomId/messages');
      if (res.data != null && res.data['success'] == true) {
        final list = (res.data['data'] as List)
            .map((m) => ChatMessageModel.fromJson(m))
            .toList();
        state = state.copyWith(messages: list);
      }
    } catch (_) {}
  }

  /// Poll for new messages every 3 seconds
  void startPolling(String roomId) {
    _pollingTimer?.cancel();
    _currentRoomId = roomId;
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_currentRoomId == null) return;
      try {
        final res = await _apiClient.get('/chat/rooms/$_currentRoomId/messages');
        if (res.data != null && res.data['success'] == true) {
          final list = (res.data['data'] as List)
              .map((m) => ChatMessageModel.fromJson(m))
              .toList();
          if (list.length != state.messages.length ||
              (list.isNotEmpty && state.messages.isNotEmpty && list.last.id != state.messages.last.id)) {
            state = state.copyWith(messages: list);
          }
        }
      } catch (_) {}
    });
  }

  /// Send a text message
  Future<bool> sendTextMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final currentUserId = _ref.read(authProvider).user?.id ?? 'me';

    // Optimistic local message
    final optimisticMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: _currentRoomId ?? '',
      senderId: currentUserId,
      content: trimmed,
      type: 'TEXT',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, optimisticMsg],
      isSending: true,
    );

    if (_currentRoomId == null && _currentListingId != null) {
      await initRoomForListing(_currentListingId!, state.offerAmount);
    }

    if (_currentRoomId != null) {
      try {
        final res = await _apiClient.post(
          '/chat/rooms/$_currentRoomId/messages',
          data: {
            'content': trimmed,
            'type': 'TEXT',
          },
        );
        if (res.data != null && res.data['success'] == true) {
          final newMsg = ChatMessageModel.fromJson(res.data['data']);
          final updated = state.messages.map((m) => m.id == optimisticMsg.id ? newMsg : m).toList();
          state = state.copyWith(messages: updated, isSending: false);
          return true;
        }
      } catch (e) {
        state = state.copyWith(isSending: false);
      }
    }
    state = state.copyWith(isSending: false);
    return true;
  }

  /// Send an offer amount
  Future<bool> sendOffer(double amount) async {
    if (amount <= 0) return false;
    final currentUserId = _ref.read(authProvider).user?.id ?? 'me';

    // Optimistic offer message
    final optimisticMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: _currentRoomId ?? '',
      senderId: currentUserId,
      offerAmount: amount,
      content: 'Offered Rs. ${amount.toInt()}',
      type: 'OFFER',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, optimisticMsg],
      isSending: true,
    );

    if (_currentRoomId == null && _currentListingId != null) {
      await initRoomForListing(_currentListingId!, amount);
    }

    if (_currentRoomId != null) {
      try {
        final res = await _apiClient.post(
          '/chat/rooms/$_currentRoomId/messages',
          data: {
            'offerAmount': amount,
            'content': 'Offered Rs. ${amount.toInt()}',
            'type': 'OFFER',
          },
        );
        if (res.data != null && res.data['success'] == true) {
          final newMsg = ChatMessageModel.fromJson(res.data['data']);
          final updated = state.messages.map((m) => m.id == optimisticMsg.id ? newMsg : m).toList();
          state = state.copyWith(messages: updated, isSending: false);
          return true;
        }
      } catch (e) {
        state = state.copyWith(isSending: false);
      }
    }
    state = state.copyWith(isSending: false);
    return true;
  }

  /// Send a quick reply message
  Future<bool> sendQuickReply(String replyText) async {
    final trimmed = replyText.trim();
    if (trimmed.isEmpty) return false;
    return sendTextMessage(trimmed);
  }

  void updateOfferAmount(double newAmount) {
    if (newAmount >= 0) {
      state = state.copyWith(offerAmount: newAmount);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final chatRoomNotifierProvider =
    StateNotifierProvider.autoDispose<ChatRoomNotifier, ChatRoomState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRoomNotifier(apiClient, ref);
});
