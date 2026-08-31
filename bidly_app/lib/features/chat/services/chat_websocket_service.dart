import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/chat_event_model.dart';

/// Real-time STOMP WebSocket Service for Buyer <-> Seller Chat and Live Events
class ChatWebSocketService {
  StompClient? _stompClient;
  String? _currentRoomId;
  String? _currentUserId;
  bool _isConnected = false;
  StompUnsubscribe? _roomSubscription;
  StompUnsubscribe? _userSubscription;

  final void Function(ChatEventModel event)? onEvent;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final VoidCallback? onResyncRequired;

  ChatWebSocketService({
    this.onEvent,
    this.onConnected,
    this.onDisconnected,
    this.onResyncRequired,
  });

  bool get isConnected => _isConnected;
  String? get currentRoomId => _currentRoomId;

  /// Connects to STOMP WebSocket broker and subscribes to /topic/chats/{roomId}
  void connect({
    required String wsUrl,
    required String roomId,
    String? userId,
    String? token,
  }) {
    if (_stompClient != null && _currentRoomId == roomId && _isConnected) {
      debugPrint('[CHAT_WS] Already connected to room: $roomId');
      return;
    }

    disconnect();

    _currentRoomId = roomId;
    _currentUserId = userId;

    final connectHeaders = <String, String>{};
    if (token != null && token.isNotEmpty) {
      connectHeaders['Authorization'] = 'Bearer $token';
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnectCallback,
        beforeConnect: () async {
          debugPrint('[CHAT_WS] CONNECT url=$wsUrl roomId=$roomId');
        },
        onWebSocketError: (dynamic error) {
          debugPrint('[CHAT_WS] WEBSOCKET ERROR: $error');
          _isConnected = false;
          onDisconnected?.call();
        },
        onStompError: (StompFrame frame) {
          debugPrint('[CHAT_WS] STOMP ERROR: ${frame.body}');
        },
        onDisconnect: (StompFrame frame) {
          debugPrint('[CHAT_WS] DISCONNECT');
          _isConnected = false;
          onDisconnected?.call();
        },
        stompConnectHeaders: connectHeaders,
        webSocketConnectHeaders: connectHeaders,
        reconnectDelay: const Duration(seconds: 3),
      ),
    );

    _stompClient?.activate();
  }

  void _onConnectCallback(StompFrame frame) {
    debugPrint('[CHAT_WS] CONNECTED session=${frame.headers['session']}');
    _isConnected = true;
    onConnected?.call();

    if (_currentRoomId != null) {
      _subscribeToRoom(_currentRoomId!);
    }

    if (_currentUserId != null) {
      _subscribeToUserNotifications(_currentUserId!);
    }

    // Trigger authoritative REST synchronization on reconnect
    onResyncRequired?.call();
  }

  void _subscribeToRoom(String roomId) {
    _roomSubscription?.call();
    final destination = '/topic/chats/$roomId';
    debugPrint('[CHAT_WS] SUBSCRIBE destination=$destination');

    _roomSubscription = _stompClient?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            final event = ChatEventModel.fromJson(json, currentUserId: _currentUserId);
            debugPrint('[CHAT_WS] EVENT_RECEIVED type=${event.eventType} room=$roomId');
            onEvent?.call(event);
          } catch (e) {
            debugPrint('[CHAT_WS] Failed to parse chat event: $e');
          }
        }
      },
    );
  }

  void _subscribeToUserNotifications(String userId) {
    _userSubscription?.call();
    final destination = '/topic/users/$userId/chat';
    debugPrint('[CHAT_WS] SUBSCRIBE destination=$destination');

    _userSubscription = _stompClient?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            final event = ChatEventModel.fromJson(json, currentUserId: _currentUserId);
            debugPrint('[CHAT_WS] USER_NOTIFICATION type=${event.eventType}');
            onEvent?.call(event);
          } catch (e) {
            debugPrint('[CHAT_WS] Failed to parse notification: $e');
          }
        }
      },
    );
  }

  void disconnect() {
    _roomSubscription?.call();
    _roomSubscription = null;
    _userSubscription?.call();
    _userSubscription = null;
    if (_stompClient != null) {
      debugPrint('[CHAT_WS] DISCONNECTING client');
      _stompClient?.deactivate();
      _stompClient = null;
    }
    _isConnected = false;
    _currentRoomId = null;
  }
}
