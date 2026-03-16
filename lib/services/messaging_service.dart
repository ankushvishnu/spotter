import 'package:supabase_flutter/supabase_flutter.dart';

class MessagingService {
  final _supabase = Supabase.instance.client;

  // Get or create conversation between two users
  Future<String> getOrCreateConversation({
    required String userId1,
    required String userId2,
  }) async {
    final conversationId = await _supabase.rpc(
      'get_or_create_conversation',
      params: {
        'p1_id': userId1,
        'p2_id': userId2,
      },
    );
    return conversationId as String;
  }

  // Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
  }) async {
    await _supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'message_type': messageType,
      'is_read': false,
    });
  }

  // Get messages for a conversation (paginated)
  Future<List<Map<String, dynamic>>> getMessages({
    required String conversationId,
    int limit = 50,
    int offset = 0,
  }) async {
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
  }

  // Subscribe to new messages in a conversation (real-time)
  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required Function(Map<String, dynamic>) onNewMessage,
  }) {
    final channel = _supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onNewMessage(payload.newRecord);
          },
        )
        .subscribe();

    return channel;
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    await _supabase.from('messages').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  // Mark all messages in conversation as read
  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    await _supabase
        .from('messages')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('conversation_id', conversationId)
        .eq('receiver_id', userId)
        .eq('is_read', false);
  }

  // Get all conversations for a user
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
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
  }

  // Get unread message count for a conversation
  Future<int> getUnreadCount({
    required String conversationId,
    required String userId,
  }) async {
    final response = await _supabase
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .eq('receiver_id', userId)
        .eq('is_read', false);

    return response.length;
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _supabase.from('messages').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  // Unsubscribe from real-time updates
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}