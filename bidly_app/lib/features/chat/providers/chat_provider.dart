import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/chat_event_model.dart';
import '../models/chat_message_model.dart';
import '../models/chat_room_model.dart';
import '../services/chat_websocket_service.dart';

class ChatRoomState {
  final ChatRoomModel? room;
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final bool isLoadingOlder;
  final bool hasMoreOlderMessages;
  final String? error;
  final double offerAmount;
  final bool isWebSocketConnected;
  final String? typingUser;

  const ChatRoomState({
    this.room,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.isLoadingOlder = false,
    this.hasMoreOlderMessages = true,
    this.error,
    this.offerAmount = 0.0,
    this.isWebSocketConnected = false,
    this.typingUser,
  });

  ChatRoomState copyWith({
    ChatRoomModel? room,
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    bool? isLoadingOlder,
    bool? hasMoreOlderMessages,
    String? error,
    double? offerAmount,
    bool? isWebSocketConnected,
    String? typingUser,
    bool clearTyping = false,
  }) {
    return ChatRoomState(
      room: room ?? this.room,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasMoreOlderMessages: hasMoreOlderMessages ?? this.hasMoreOlderMessages,
      error: error,
      offerAmount: offerAmount ?? this.offerAmount,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
      typingUser: clearTyping ? null : (typingUser ?? this.typingUser),
    );
  }
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final ApiClient _apiClient;
  final Ref _ref;
  late final ChatWebSocketService _webSocketService;
  Timer? _typingTimer;
  Timer? _typingTimeoutTimer;
  String? _currentRoomId;
  String? _currentListingId;
  bool _isTypingSent = false;

  ChatRoomNotifier(this._apiClient, this._ref) : super(const ChatRoomState()) {
    _webSocketService = ChatWebSocketService(
      onEvent: _handleWebSocketEvent,
      onConnected: () {
        state = state.copyWith(isWebSocketConnected: true);
      },
      onDisconnected: () {
        state = state.copyWith(isWebSocketConnected: false);
      },
      onResyncRequired: () {
        if (_currentRoomId != null) {
          loadMessages(_currentRoomId!, isSilent: true);
        }
      },
    );
  }

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
        await _connectWebSocket(room.id);
        markAsRead(room.id);
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

  /// Initialize chat by Room ID directly
  Future<void> initRoomById(String roomId) async {
    _currentRoomId = roomId;
    state = state.copyWith(isLoading: state.messages.isEmpty, error: null);
    await loadMessages(roomId);
    await _connectWebSocket(roomId);
    markAsRead(roomId);
  }

  Future<void> _connectWebSocket(String roomId) async {
    final token = await _apiClient.getToken();
    final userId = _ref.read(authProvider).user?.id;
    _webSocketService.connect(
      wsUrl: _apiClient.wsUrl,
      roomId: roomId,
      userId: userId,
      token: token,
    );
  }

  /// Load initial messages for a room
  Future<void> loadMessages(String roomId, {bool isSilent = false}) async {
    if (!isSilent && state.messages.isEmpty) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final currentUserId = _ref.read(authProvider).user?.id;
      final res = await _apiClient.get('/chat/rooms/$roomId/messages?limit=50');
      if (res.data != null && res.data['success'] == true) {
        final list = (res.data['data'] as List)
            .map((m) => ChatMessageModel.fromJson(m, currentUserId: currentUserId))
            .toList();
        state = state.copyWith(
          messages: list,
          isLoading: false,
          hasMoreOlderMessages: list.length >= 50,
        );
      } else {
        if (!isSilent) state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      if (!isSilent) state = state.copyWith(isLoading: false);
    }
  }

  /// Keyset pagination to load older messages
  Future<void> loadOlderMessages() async {
    if (state.isLoadingOlder || !state.hasMoreOlderMessages || state.messages.isEmpty || _currentRoomId == null) {
      return;
    }
    state = state.copyWith(isLoadingOlder: true);
    try {
      final oldest = state.messages.first;
      final currentUserId = _ref.read(authProvider).user?.id;
      final uri = '/chat/rooms/$_currentRoomId/messages?beforeCreatedAt=${oldest.createdAt.toUtc().toIso8601String()}&beforeId=${oldest.id}&limit=30';
      final res = await _apiClient.get(uri);
      if (res.data != null && res.data['success'] == true) {
        final olderList = (res.data['data'] as List)
            .map((m) => ChatMessageModel.fromJson(m, currentUserId: currentUserId))
            .toList();

        if (olderList.isEmpty) {
          state = state.copyWith(isLoadingOlder: false, hasMoreOlderMessages: false);
        } else {
          // Merge deduplicating by ID
          final existingIds = state.messages.map((m) => m.id).toSet();
          final uniqueOlder = olderList.where((m) => !existingIds.contains(m.id)).toList();
          state = state.copyWith(
            messages: [...uniqueOlder, ...state.messages],
            isLoadingOlder: false,
            hasMoreOlderMessages: olderList.length >= 30,
          );
        }
      } else {
        state = state.copyWith(isLoadingOlder: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingOlder: false);
    }
  }

  void _handleWebSocketEvent(ChatEventModel event) {
    debugPrint('[CHAT_WS] Received event ${event.eventType} for room ${event.roomId}');

    final currentUserId = _ref.read(authProvider).user?.id;

    if (event.eventType == 'NEW_MESSAGE' && event.message != null) {
      final newMsg = event.message!;

      // Deduplicate with optimistic messages
      final existingIndex = state.messages.indexWhere((m) =>
          (m.clientMessageId != null && m.clientMessageId == newMsg.clientMessageId) ||
          m.id == newMsg.id);

      List<ChatMessageModel> updated;
      if (existingIndex != -1) {
        updated = List<ChatMessageModel>.from(state.messages);
        updated[existingIndex] = newMsg;
      } else {
        updated = [...state.messages, newMsg];
      }

      state = state.copyWith(messages: updated);

      // If incoming message is from the other user and active room, mark as read
      if (!newMsg.isMine && _currentRoomId != null) {
        markAsRead(_currentRoomId!);
      }
    } else if (event.eventType == 'MESSAGE_READ') {
      final readIds = event.readMessageIds.toSet();
      final updated = state.messages.map((m) {
        if (readIds.contains(m.id) || (m.isMine && !m.isRead)) {
          return m.copyWith(status: 'READ', readAt: event.readAt ?? DateTime.now());
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updated);
    } else if (event.eventType == 'TYPING_STARTED') {
      if (event.userId != currentUserId && event.userName != null) {
        state = state.copyWith(typingUser: event.userName);
        _typingTimeoutTimer?.cancel();
        _typingTimeoutTimer = Timer(const Duration(seconds: 3), () {
          state = state.copyWith(clearTyping: true);
        });
      }
    } else if (event.eventType == 'TYPING_STOPPED') {
      if (event.userId != currentUserId) {
        state = state.copyWith(clearTyping: true);
      }
    }
  }

  /// Optimistic send with clientMessageId idempotency and retry support
  Future<bool> sendTextMessage(String text, {String? retryClientMessageId}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final currentUserId = _ref.read(authProvider).user?.id ?? 'me';
    final clientMessageId = retryClientMessageId ??
        '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';

    // Optimistic local message with SENDING status
    final optimisticMsg = ChatMessageModel(
      id: clientMessageId,
      roomId: _currentRoomId ?? '',
      senderId: currentUserId,
      clientMessageId: clientMessageId,
      content: trimmed,
      type: 'TEXT',
      status: 'SENDING',
      isMine: true,
      createdAt: DateTime.now(),
    );

    // If retrying, replace old; otherwise append
    List<ChatMessageModel> msgs = List.from(state.messages);
    final retryIndex = msgs.indexWhere((m) => m.clientMessageId == clientMessageId);
    if (retryIndex != -1) {
      msgs[retryIndex] = optimisticMsg;
    } else {
      msgs.add(optimisticMsg);
    }

    state = state.copyWith(messages: msgs, isSending: true);

    if (_currentRoomId == null && _currentListingId != null) {
      await initRoomForListing(_currentListingId!, state.offerAmount);
    }

    if (_currentRoomId != null) {
      try {
        final res = await _apiClient.post(
          '/chat/rooms/$_currentRoomId/messages',
          data: {
            'clientMessageId': clientMessageId,
            'content': trimmed,
            'type': 'TEXT',
          },
        );
        if (res.data != null && res.data['success'] == true) {
          final serverMsg = ChatMessageModel.fromJson(res.data['data'], currentUserId: currentUserId);
          final updated = state.messages.map((m) =>
              (m.clientMessageId == clientMessageId || m.id == optimisticMsg.id) ? serverMsg : m).toList();
          state = state.copyWith(messages: updated, isSending: false);
          return true;
        } else {
          _markMessageFailed(clientMessageId);
          return false;
        }
      } catch (e) {
        _markMessageFailed(clientMessageId);
        return false;
      }
    }

    _markMessageFailed(clientMessageId);
    return false;
  }

  void _markMessageFailed(String clientMessageId) {
    final updated = state.messages.map((m) {
      if (m.clientMessageId == clientMessageId) {
        return m.copyWith(status: 'FAILED');
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated, isSending: false);
  }

  /// Send an offer amount
  Future<bool> sendOffer(double amount) async {
    if (amount <= 0) return false;
    final currentUserId = _ref.read(authProvider).user?.id ?? 'me';
    final clientMessageId = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';

    final optimisticMsg = ChatMessageModel(
      id: clientMessageId,
      roomId: _currentRoomId ?? '',
      senderId: currentUserId,
      clientMessageId: clientMessageId,
      offerAmount: amount,
      content: 'Submitted an offer of ₹${amount.toInt()}',
      type: 'OFFER',
      status: 'SENDING',
      isMine: true,
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
            'clientMessageId': clientMessageId,
            'offerAmount': amount,
            'content': 'Submitted an offer of ₹${amount.toInt()}',
            'type': 'OFFER',
          },
        );
        if (res.data != null && res.data['success'] == true) {
          final serverMsg = ChatMessageModel.fromJson(res.data['data'], currentUserId: currentUserId);
          final updated = state.messages.map((m) =>
              (m.clientMessageId == clientMessageId || m.id == optimisticMsg.id) ? serverMsg : m).toList();
          state = state.copyWith(messages: updated, isSending: false);
          return true;
        } else {
          _markMessageFailed(clientMessageId);
        }
      } catch (e) {
        _markMessageFailed(clientMessageId);
      }
    }
    return false;
  }

  /// Send quick reply
  Future<bool> sendQuickReply(String replyText) async {
    final trimmed = replyText.trim();
    if (trimmed.isEmpty) return false;
    return sendTextMessage(trimmed);
  }

  /// Send In-Person Meetup request
  Future<bool> sendMeetupRequest({
    required DateTime meetupTime,
    required String location,
  }) async {
    final currentUserId = _ref.read(authProvider).user?.id ?? 'me';
    final clientMessageId = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';
    final metadataStr = '{"location":"$location","time":"${meetupTime.toIso8601String()}"}';

    final optimisticMsg = ChatMessageModel(
      id: clientMessageId,
      roomId: _currentRoomId ?? '',
      senderId: currentUserId,
      clientMessageId: clientMessageId,
      content: '📅 In-Person Meetup Request\nLocation: $location\nTime: ${meetupTime.toLocal().toString().substring(0, 16)}',
      type: 'MEETUP_REQUEST',
      status: 'SENDING',
      metadata: metadataStr,
      isMine: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, optimisticMsg],
      isSending: true,
    );

    if (_currentRoomId != null) {
      try {
        final res = await _apiClient.post(
          '/chat/rooms/$_currentRoomId/messages',
          data: {
            'clientMessageId': clientMessageId,
            'content': optimisticMsg.content,
            'type': 'MEETUP_REQUEST',
            'metadata': metadataStr,
          },
        );
        if (res.data != null && res.data['success'] == true) {
          final serverMsg = ChatMessageModel.fromJson(res.data['data'], currentUserId: currentUserId);
          final updated = state.messages.map((m) =>
              (m.clientMessageId == clientMessageId || m.id == optimisticMsg.id) ? serverMsg : m).toList();
          state = state.copyWith(messages: updated, isSending: false);
          return true;
        } else {
          _markMessageFailed(clientMessageId);
        }
      } catch (e) {
        _markMessageFailed(clientMessageId);
      }
    }
    return false;
  }

  /// Throttled typing event handler
  void onTextChanged(String text) {
    if (_currentRoomId == null) return;

    if (text.isNotEmpty && !_isTypingSent) {
      _isTypingSent = true;
      _sendTypingStatus(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_isTypingSent) {
        _isTypingSent = false;
        _sendTypingStatus(false);
      }
    });
  }

  void _sendTypingStatus(bool isTyping) async {
    if (_currentRoomId == null) return;
    try {
      await _apiClient.post('/chat/rooms/$_currentRoomId/typing', data: {'isTyping': isTyping});
    } catch (_) {}
  }

  /// Mark visible room messages as read
  Future<void> markAsRead(String roomId) async {
    try {
      await _apiClient.post('/chat/rooms/$roomId/read');
    } catch (_) {}
  }

  void updateOfferAmount(double newAmount) {
    if (newAmount >= 0) {
      state = state.copyWith(offerAmount: newAmount);
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _typingTimeoutTimer?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }
}

final chatRoomNotifierProvider =
    StateNotifierProvider.autoDispose<ChatRoomNotifier, ChatRoomState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRoomNotifier(apiClient, ref);
});

class ChatRoomListState {
  final List<ChatRoomModel> rooms;
  final bool isLoading;
  final String? error;

  const ChatRoomListState({
    this.rooms = const [],
    this.isLoading = false,
    this.error,
  });

  ChatRoomListState copyWith({
    List<ChatRoomModel>? rooms,
    bool? isLoading,
    String? error,
  }) {
    return ChatRoomListState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatRoomListNotifier extends StateNotifier<ChatRoomListState> {
  final ApiClient _apiClient;

  ChatRoomListNotifier(this._apiClient) : super(const ChatRoomListState()) {
    fetchRooms();
  }

  Future<void> fetchRooms({bool isSilent = false}) async {
    if (!isSilent && state.rooms.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final res = await _apiClient.get('/chat/rooms');
      if (res.data != null && res.data['success'] == true) {
        final list = (res.data['data'] as List)
            .map((r) => ChatRoomModel.fromJson(r))
            .toList();
        state = state.copyWith(rooms: list, isLoading: false);
      } else {
        if (!isSilent) state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      if (!isSilent) state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void onNewMessageArrived(ChatEventModel event) {
    if (event.roomId == null) return;
    fetchRooms(isSilent: true);
  }
}

final chatRoomListProvider =
    StateNotifierProvider<ChatRoomListNotifier, ChatRoomListState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRoomListNotifier(apiClient);
});


