import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class SignalingService {
  static final SignalingService _instance = SignalingService._internal();
  factory SignalingService() => _instance;
  SignalingService._internal();

  // Simple in-memory signaling (for demo purposes)
  // In a real app, you'd use WebSocket or a signaling server
  final Map<String, StreamController<Map<String, dynamic>>> _rooms = {};
  final Map<String, List<String>> _roomParticipants = {};

  /// Join a room and get a stream of signaling messages
  Stream<Map<String, dynamic>> joinRoom(String roomId, String participantId) {
    if (!_rooms.containsKey(roomId)) {
      _rooms[roomId] = StreamController<Map<String, dynamic>>.broadcast();
      _roomParticipants[roomId] = [];
    }

    if (!_roomParticipants[roomId]!.contains(participantId)) {
      _roomParticipants[roomId]!.add(participantId);
    }

    // Notify others that a new participant joined
    _sendToRoom(roomId, {
      'type': 'participant_joined',
      'participantId': participantId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    return _rooms[roomId]!.stream;
  }

  /// Send a message to all participants in a room
  void sendToRoom(String roomId, Map<String, dynamic> message) {
    _sendToRoom(roomId, message);
  }

  void _sendToRoom(String roomId, Map<String, dynamic> message) {
    if (_rooms.containsKey(roomId)) {
      _rooms[roomId]!.add(message);
      if (kDebugMode) {
        print('Signaling: ${json.encode(message)}');
      }
    }
  }

  /// Leave a room
  void leaveRoom(String roomId, String participantId) {
    if (_roomParticipants.containsKey(roomId)) {
      _roomParticipants[roomId]!.remove(participantId);
      
      // Notify others that participant left
      _sendToRoom(roomId, {
        'type': 'participant_left',
        'participantId': participantId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Clean up if room is empty
      if (_roomParticipants[roomId]!.isEmpty) {
        _rooms[roomId]?.close();
        _rooms.remove(roomId);
        _roomParticipants.remove(roomId);
      }
    }
  }

  /// Get participants in a room
  List<String> getRoomParticipants(String roomId) {
    return _roomParticipants[roomId] ?? [];
  }

  /// Dispose all resources
  void dispose() {
    for (final controller in _rooms.values) {
      controller.close();
    }
    _rooms.clear();
    _roomParticipants.clear();
  }
} 