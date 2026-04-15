import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';

/// A conversation with its messages.
class ChatConversation {
  final String id;
  final String title;
  final String feature;
  final String? preview;
  final DateTime createdAt;
  final DateTime updatedAt;
  List<ChatMessageData> messages;

  ChatConversation({
    required this.id,
    required this.title,
    required this.feature,
    this.preview,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'feature': feature,
        'preview': preview,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      feature: json['feature'] as String? ?? 'coach_chat',
      preview: json['preview'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) =>
                  ChatMessageData.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ChatMessageData {
  final String role;
  final String content;
  final DateTime createdAt;

  ChatMessageData({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  factory ChatMessageData.fromJson(Map<String, dynamic> json) {
    return ChatMessageData(
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Dual-storage service: SharedPreferences for guests, Supabase for auth users.
class ChatStorageService {
  static final ChatStorageService _instance = ChatStorageService._internal();
  factory ChatStorageService() => _instance;
  ChatStorageService._internal();

  static const String _localKey = 'ai_chat_history';
  static const int _guestMaxConversations = 10;

  bool get _isAuthenticated =>
      SupabaseConfig.client.auth.currentSession != null;

  String? get _userId =>
      SupabaseConfig.client.auth.currentUser?.id;

  // ─── Public API ──────────────────────────────────────────────────────

  /// Load all conversations (most recent first).
  Future<List<ChatConversation>> loadConversations() async {
    if (_isAuthenticated) {
      return _loadFromSupabase();
    } else {
      return _loadFromLocal();
    }
  }

  /// Load a single conversation with all its messages.
  Future<ChatConversation?> loadConversation(String conversationId) async {
    if (_isAuthenticated) {
      return _loadConversationFromSupabase(conversationId);
    } else {
      return _loadConversationFromLocal(conversationId);
    }
  }

  /// Save or update a conversation with its messages.
  /// Returns the conversation ID (useful for new conversations).
  Future<String> saveConversation({
    String? conversationId,
    required String title,
    required String feature,
    required String? preview,
    required List<ChatMessageData> messages,
  }) async {
    if (_isAuthenticated) {
      return _saveToSupabase(
        conversationId: conversationId,
        title: title,
        feature: feature,
        preview: preview,
        messages: messages,
      );
    } else {
      return _saveToLocal(
        conversationId: conversationId,
        title: title,
        feature: feature,
        preview: preview,
        messages: messages,
      );
    }
  }

  /// Delete a conversation.
  Future<void> deleteConversation(String conversationId) async {
    if (_isAuthenticated) {
      await _deleteFromSupabase(conversationId);
    } else {
      await _deleteFromLocal(conversationId);
    }
  }

  /// Migrate local conversations to Supabase after login/signup.
  /// Returns the number of conversations migrated.
  Future<int> migrateLocalToSupabase() async {
    if (!_isAuthenticated) return 0;

    final localConversations = await _loadFromLocal();
    if (localConversations.isEmpty) return 0;

    int migrated = 0;
    for (final conv in localConversations) {
      try {
        await _saveToSupabase(
          title: conv.title,
          feature: conv.feature,
          preview: conv.preview,
          messages: conv.messages,
        );
        migrated++;
      } catch (e) {
        debugPrint('ChatStorageService: Migration failed for ${conv.id}: $e');
      }
    }

    // Clear local storage after successful migration
    if (migrated > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localKey);
    }

    return migrated;
  }

  /// Check if there are local conversations to migrate.
  Future<bool> hasLocalConversations() async {
    final convs = await _loadFromLocal();
    return convs.isNotEmpty;
  }

  // ─── Supabase Storage ────────────────────────────────────────────────

  Future<List<ChatConversation>> _loadFromSupabase() async {
    try {
      final data = await SupabaseConfig.client
          .from('ai_conversations')
          .select('id, title, feature, preview, created_at, updated_at')
          .eq('user_id', _userId!)
          .order('updated_at', ascending: false)
          .limit(50);

      return (data as List)
          .map((row) => ChatConversation(
                id: row['id'],
                title: row['title'],
                feature: row['feature'],
                preview: row['preview'],
                createdAt: DateTime.parse(row['created_at']),
                updatedAt: DateTime.parse(row['updated_at']),
              ))
          .toList();
    } catch (e) {
      debugPrint('ChatStorageService: Supabase load error: $e');
      return [];
    }
  }

  Future<ChatConversation?> _loadConversationFromSupabase(String id) async {
    try {
      final convData = await SupabaseConfig.client
          .from('ai_conversations')
          .select()
          .eq('id', id)
          .eq('user_id', _userId!)
          .single();

      final msgData = await SupabaseConfig.client
          .from('ai_messages')
          .select()
          .eq('conversation_id', id)
          .order('created_at', ascending: true);

      final messages = (msgData as List)
          .map((m) => ChatMessageData(
                role: m['role'],
                content: m['content'],
                createdAt: DateTime.parse(m['created_at']),
              ))
          .toList();

      return ChatConversation(
        id: convData['id'],
        title: convData['title'],
        feature: convData['feature'],
        preview: convData['preview'],
        createdAt: DateTime.parse(convData['created_at']),
        updatedAt: DateTime.parse(convData['updated_at']),
        messages: messages,
      );
    } catch (e) {
      debugPrint('ChatStorageService: Supabase load conversation error: $e');
      return null;
    }
  }

  Future<String> _saveToSupabase({
    String? conversationId,
    required String title,
    required String feature,
    required String? preview,
    required List<ChatMessageData> messages,
  }) async {
    try {
      String convId;

      if (conversationId != null) {
        // Update existing
        convId = conversationId;
        await SupabaseConfig.client.from('ai_conversations').update({
          'title': title,
          'preview': preview,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', convId);

        // Delete old messages and re-insert all (simpler than diffing)
        await SupabaseConfig.client
            .from('ai_messages')
            .delete()
            .eq('conversation_id', convId);
      } else {
        // Create new
        final result =
            await SupabaseConfig.client.from('ai_conversations').insert({
          'user_id': _userId,
          'title': title,
          'feature': feature,
          'preview': preview,
        }).select('id').single();

        convId = result['id'];
      }

      // Insert all messages
      if (messages.isNotEmpty) {
        final msgRows = messages
            .map((m) => {
                  'conversation_id': convId,
                  'role': m.role,
                  'content': m.content,
                })
            .toList();

        await SupabaseConfig.client.from('ai_messages').insert(msgRows);
      }

      return convId;
    } catch (e) {
      debugPrint('ChatStorageService: Supabase save error: $e');
      rethrow;
    }
  }

  Future<void> _deleteFromSupabase(String conversationId) async {
    await SupabaseConfig.client
        .from('ai_conversations')
        .delete()
        .eq('id', conversationId);
  }

  // ─── Local Storage ───────────────────────────────────────────────────

  Future<List<ChatConversation>> _loadFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_localKey);
      if (jsonStr == null) return [];

      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((j) =>
              ChatConversation.fromJson(j as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      debugPrint('ChatStorageService: Local load error: $e');
      return [];
    }
  }

  Future<ChatConversation?> _loadConversationFromLocal(String id) async {
    final all = await _loadFromLocal();
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<String> _saveToLocal({
    String? conversationId,
    required String title,
    required String feature,
    required String? preview,
    required List<ChatMessageData> messages,
  }) async {
    final all = await _loadFromLocal();
    final now = DateTime.now();
    String convId;

    if (conversationId != null) {
      // Update existing
      convId = conversationId;
      final idx = all.indexWhere((c) => c.id == convId);
      if (idx >= 0) {
        all[idx] = ChatConversation(
          id: convId,
          title: title,
          feature: feature,
          preview: preview,
          createdAt: all[idx].createdAt,
          updatedAt: now,
          messages: messages,
        );
      }
    } else {
      // Create new with a local UUID-like ID
      convId = 'local_${now.millisecondsSinceEpoch}';
      all.insert(
        0,
        ChatConversation(
          id: convId,
          title: title,
          feature: feature,
          preview: preview,
          createdAt: now,
          updatedAt: now,
          messages: messages,
        ),
      );
    }

    // Enforce guest limit
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final trimmed =
        all.length > _guestMaxConversations
            ? all.sublist(0, _guestMaxConversations)
            : all;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _localKey, jsonEncode(trimmed.map((c) => c.toJson()).toList()));

    return convId;
  }

  Future<void> _deleteFromLocal(String conversationId) async {
    final all = await _loadFromLocal();
    all.removeWhere((c) => c.id == conversationId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _localKey, jsonEncode(all.map((c) => c.toJson()).toList()));
  }
}
