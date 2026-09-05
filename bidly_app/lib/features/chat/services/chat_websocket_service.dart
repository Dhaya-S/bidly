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
  StompUnsubscribe? _userNotifSubscription;

  final void Function(ChatEventModel event)? onEvent;
  final void Function(Map<String, dynamic> notificationJson)? onNotification;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final VoidCallback? onResyncRequired;

  ChatWebSocketService({
    this.onEvent,
    this.onNotification,
    this.onConnected,
    this.onDisconnected,
    this.onResyncRequired,
  });

  bool get isConnected => _isConnected;
  String? get currentRoomId => _currentRoomId;

  /// Connects to STOMP WebSocket broker and subscribes to /topic/users/{userId}/chat and optionally /topic/chats/{roomId}
  void connect({
    required String wsUrl,
    String? roomId,
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

    if (_currentRoomId != null && _currentRoomId!.isNotEmpty) {
      _subscribeToRoom(_currentRoomId!);
    }

    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      _subscribeToUserNotifications(_currentUserId!);
    }

    // Trigger authoritative REST synchronization on reconnect
    onResyncRequired?.call();
  }

  /// Subscribe to a room dynamically without reconnecting the entire socket
  void subscribeToRoom(String roomId) {
    _currentRoomId = roomId;
    if (_isConnected) {
      _subscribeToRoom(roomId);
    }
  }

  /// Unsubscribe from the current room while keeping user notification subscription active
  void unsubscribeFromRoom() {
    _roomSubscription?.call();
    _roomSubscription = null;
    _currentRoomId = null;
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
    final chatDestination = '/topic/users/$userId/chat';
    debugPrint('[CHAT_WS] SUBSCRIBE destination=$chatDestination');

    _userSubscription = _stompClient?.subscribe(
      destination: chatDestination,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            if (json['notification'] != null && json['notification'] is Map) {
              onNotification?.call(Map<String, dynamic>.from(json['notification'] as Map));
            }
            final event = ChatEventModel.fromJson(json, currentUserId: _currentUserId);
            debugPrint('[CHAT_WS] USER_NOTIFICATION (chat) type=${event.eventType}');
            onEvent?.call(event);
          } catch (e) {
            debugPrint('[CHAT_WS] Failed to parse chat notification: $e');
          }
        }
      },
    );

    _userNotifSubscription?.call();
    final notifDestination = '/topic/users/$userId/notifications';
    debugPrint('[CHAT_WS] SUBSCRIBE destination=$notifDestination');

    _userNotifSubscription = _stompClient?.subscribe(
      destination: notifDestination,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            if (json['notification'] != null && json['notification'] is Map) {
              onNotification?.call(Map<String, dynamic>.from(json['notification'] as Map));
            }
            final event = ChatEventModel.fromJson(json, currentUserId: _currentUserId);
            debugPrint('[CHAT_WS] USER_NOTIFICATION (notifications) type=${event.eventType}');
            onEvent?.call(event);
          } catch (e) {
            debugPrint('[CHAT_WS] Failed to parse primary notification: $e');
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
    _userNotifSubscription?.call();
    _userNotifSubscription = null;
    if (_stompClient != null) {
      debugPrint('[CHAT_WS] DISCONNECTING client');
      _stompClient?.deactivate();
      _stompClient = null;
    }
    _isConnected = false;
    _currentRoomId = null;
  }
}
