import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/app_exception.dart';

class MessagingService {
  final _supabase = SupabaseConfig.client;

  // Get or create conversation between two users
  Future<String> getOrCreateConversation({
    required String userId1,
    required String userId2,
  }) async {
    try {
      final conversationId = await _supabase.rpc(
        'get_or_create_conversation',
        params: {
          'p1_id': userId1,
          'p2_id': userId2,
        },
      );
      return conversationId as String;
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to open conversation.');
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'message_type': messageType,
        'is_read': false,
      });
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to send message.');
    }
  }

  // Get messages for a conversation (paginated)
  Future<List<Map<String, dynamic>>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
            *,
            sender:users!messages_sender_id_fkey(id, full_name, avatar_url),
            receiver:users!messages_receiver_id_fkey(id, full_name, avatar_url)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load messages.');
    }
  }

  // Subscribe to new messages in a conversation (real-time)
  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required String currentUserId,
    required Function(Map<String, dynamic>) onNewMessage,
    Function(List<String>)? onPresenceChange,
  }) {
    debugPrint('🔌 [Chat] Subscribing to conversation: $conversationId');

    final channel = _supabase.channel('messages:$conversationId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (payload) {
        debugPrint('✅ [Chat] New message received: ${payload.newRecord}');
        onNewMessage(payload.newRecord);
      },
    );

    if (onPresenceChange != null) {
      channel.onPresenceSync((payload) {
        final state = channel.presenceState();
        final onlineUserIds = <String>[];
        for (final presence in state) {
          final payload = presence.payload;
          if (payload != null && payload['user_id'] != null) {
            onlineUserIds.add(payload['user_id'] as String);
          }
        }
        onPresenceChange(onlineUserIds);
      });
    }

    channel.subscribe((status, error) async {
      if (error != null) {
        debugPrint('❌ [Chat] Realtime subscription error: $error');
      } else {
        debugPrint('✅ [Chat] Realtime subscription status: $status');
        if (status == RealtimeSubscribeStatus.subscribed) {
          try {
            await channel.track({'user_id': currentUserId});
          } catch (e) {
            debugPrint('❌ [Chat] Failed to track presence: $e');
          }
        }
      }
    });

    return channel;
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _supabase.from('messages').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      debugPrint('Failed to mark message as read: $e');
    }
  }

  // Mark all messages in conversation as read
  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Failed to mark conversation as read: $e');
    }
  }

  // Get all conversations for a user
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select('''
            *,
            participant_1:users!conversations_participant_1_id_fkey(id, full_name, avatar_url),
            participant_2:users!conversations_participant_2_id_fkey(id, full_name, avatar_url)
          ''')
          .or('participant_1_id.eq.$userId,participant_2_id.eq.$userId')
          .order('last_message_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to load conversations.');
    }
  }

  // Get unread message count for a conversation
  Future<int> getUnreadCount({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('receiver_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      debugPrint('Failed to get unread count: $e');
      return 0;
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('messages').update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      throw AppException.fromError(e, fallbackMessage: 'Failed to delete message.');
    }
  }

  // Unsubscribe from real-time updates
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}