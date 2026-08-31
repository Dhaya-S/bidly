import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/auction_model.dart';

/// Real-time STOMP WebSocket Service for live auction bidding and instant event distribution
class AuctionWebSocketService {
  StompClient? _stompClient;
  String? _currentListingId;
  bool _isConnected = false;
  StompUnsubscribe? _currentSubscription;

  final void Function(AuctionEventModel event)? onEvent;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final VoidCallback? onResyncRequired;

  AuctionWebSocketService({
    this.onEvent,
    this.onConnected,
    this.onDisconnected,
    this.onResyncRequired,
  });

  bool get isConnected => _isConnected;
  String? get currentListingId => _currentListingId;

  /// Connects to STOMP WebSocket broker and subscribes to /topic/auctions/{listingId}
  void connect({
    required String wsUrl,
    required String listingId,
    String? token,
  }) {
    if (_stompClient != null && _currentListingId == listingId && _isConnected) {
      debugPrint('[AUCTION_WS] Already connected to listing: $listingId');
      return;
    }

    disconnect();

    _currentListingId = listingId;

    final connectHeaders = <String, String>{};
    if (token != null && token.isNotEmpty) {
      connectHeaders['Authorization'] = 'Bearer $token';
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        onConnect: _onConnectCallback,
        beforeConnect: () async {
          debugPrint('[AUCTION_WS] CONNECT url=$wsUrl listing=$listingId');
        },
        onWebSocketError: (dynamic error) {
          debugPrint('[AUCTION_WS] WEBSOCKET ERROR: $error');
          _isConnected = false;
          onDisconnected?.call();
        },
        onStompError: (StompFrame frame) {
          debugPrint('[AUCTION_WS] STOMP ERROR: ${frame.body}');
        },
        onDisconnect: (StompFrame frame) {
          debugPrint('[AUCTION_WS] DISCONNECT');
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
    debugPrint('[AUCTION_WS] CONNECTED session=${frame.headers['session']}');
    _isConnected = true;
    onConnected?.call();

    if (_currentListingId != null) {
      _subscribeToAuction(_currentListingId!);
    }

    // Trigger authoritative REST sync on reconnect
    onResyncRequired?.call();
  }

  void _subscribeToAuction(String listingId) {
    _currentSubscription?.call();
    final destination = '/topic/auctions/$listingId';
    debugPrint('[AUCTION_WS] SUBSCRIBE destination=$destination');

    _currentSubscription = _stompClient?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body != null) {
          try {
            final json = jsonDecode(frame.body!) as Map<String, dynamic>;
            final event = AuctionEventModel.fromJson(json);
            debugPrint('[AUCTION_WS] EVENT_RECEIVED type=${event.eventType} listing=$listingId bid=${event.highestBid}');
            onEvent?.call(event);
          } catch (e) {
            debugPrint('[AUCTION_WS] Failed to parse event JSON: $e');
          }
        }
      },
    );
  }

  void disconnect() {
    _currentSubscription?.call();
    _currentSubscription = null;
    if (_stompClient != null) {
      debugPrint('[AUCTION_WS] DISCONNECTING client');
      _stompClient?.deactivate();
      _stompClient = null;
    }
    _isConnected = false;
    _currentListingId = null;
  }
}
