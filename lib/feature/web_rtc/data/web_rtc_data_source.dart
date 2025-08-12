import 'package:guitara_task/core/http/api_consumer.dart';
import 'package:guitara_task/core/http/failure.dart';
import 'package:guitara_task/core/http/either.dart';

class WebRtcDataSource {
  final ApiConsumer _apiConsumer;

  WebRtcDataSource(this._apiConsumer);

  /// Send signaling message via GetStream Chat API
  Future<Either<Failure, Map<String, dynamic>>> sendSignal({
    required String channelId,
    required Map<String, dynamic> data,
    required String streamApiKey,
  }) async {
    final url = 'https://chat.stream-io-api.com/channels/messaging/$channelId/message';
    
    final response = await _apiConsumer.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $streamApiKey',
        'Stream-Auth-Type': 'jwt',
        'X-Stream-Client': 'stream-chat-flutter-client',
      },
      data: data,
    );

    return response;
  }

  /// Get channel messages for signaling
  Future<Either<Failure, List<Map<String, dynamic>>>> getChannelMessages({
    required String channelId,
    required String streamApiKey,
  }) async {
    final url = 'https://chat.stream-io-api.com/channels/messaging/$channelId/messages';
    
    final response = await _apiConsumer.get(
      url,
      headers: {
        'Authorization': 'Bearer $streamApiKey',
        'Stream-Auth-Type': 'jwt',
        'X-Stream-Client': 'stream-chat-flutter-client',
      },
    );

    return response.fold(
      (failure) => Left(failure),
      (data) {
        if (data.containsKey('messages')) {
          final messages = List<Map<String, dynamic>>.from(data['messages']);
          return Right(messages);
        }
        return const Right([]);
      },
    );
  }

  /// Create or join a channel
  Future<Either<Failure, Map<String, dynamic>>> createOrJoinChannel({
    required String channelId,
    required String streamApiKey,
    required String userName,
  }) async {
    final url = 'https://chat.stream-io-api.com/channels/messaging/$channelId';
    
    final response = await _apiConsumer.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $streamApiKey',
        'Stream-Auth-Type': 'jwt',
        'X-Stream-Client': 'stream-chat-flutter-client',
      },
      data: {
        'members': [userName],
        'created_by_id': userName,
      },
    );

    return response;
  }

  /// Validate API key
  Future<Either<Failure, bool>> validateApiKey(String streamApiKey) async {
    final url = 'https://chat.stream-io-api.com/channels/messaging/test-channel';
    
    final response = await _apiConsumer.get(
      url,
      headers: {
        'Authorization': 'Bearer $streamApiKey',
        'Stream-Auth-Type': 'jwt',
        'X-Stream-Client': 'stream-chat-flutter-client',
      },
    );

    return response.fold(
      (failure) {
        if (failure is UnauthorizedFailure) {
          return Left(UnauthorizedFailure(message: 'Invalid API key. Please check your Stream API key.'));
        }
        // If we get a different error, the API key might be valid but the channel doesn't exist
        // which is expected for a test channel
        return const Right(true);
      },
      (data) => const Right(true),
    );
  }
} 