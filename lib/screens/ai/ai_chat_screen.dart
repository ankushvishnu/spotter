import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../services/cerebras_service.dart';
import '../../services/chat_storage_service.dart';

class AIChatScreen extends StatefulWidget {
  final String? conversationId;

  const AIChatScreen({super.key, this.conversationId});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final CerebrasService _cerebrasService = CerebrasService();
  final ChatStorageService _storage = ChatStorageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<_ChatMessage> _messages = [];
  bool _isStreaming = false;
  bool _rateLimited = false;
  bool _isLoadingHistory = false;
  String? _conversationId;
  String? _conversationTitle;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    if (_conversationId != null) {
      _loadConversation();
    } else {
      _messages.add(_ChatMessage(
        role: 'assistant',
        content:
            'Hey! 👋 I\'m your AI fitness coach. Ask me anything about workouts, nutrition, training plans, or staying consistent. What\'s on your mind?',
      ));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    setState(() => _isLoadingHistory = true);
    final conv = await _storage.loadConversation(_conversationId!);
    if (conv != null && mounted) {
      setState(() {
        _conversationTitle = conv.title;
        _messages.clear();
        for (final m in conv.messages) {
          _messages.add(_ChatMessage(role: m.role, content: m.content));
        }
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _autoSave() async {
    // Don't save if only the welcome message exists, or if there are errors
    final saveable = _messages
        .where((m) =>
            m.content.isNotEmpty &&
            !m.content.startsWith('Chat cleared') &&
            !m.content.contains('daily limit') &&
            !m.content.contains('[ERROR]'))
        .toList();

    if (saveable.length < 2) return; // Need at least 1 user + 1 assistant

    // Generate title from first user message
    final firstUserMsg =
        saveable.firstWhere((m) => m.role == 'user', orElse: () => saveable.first);
    final title = _conversationTitle ??
        (firstUserMsg.content.length > 50
            ? '${firstUserMsg.content.substring(0, 50)}...'
            : firstUserMsg.content);

    // Preview = last assistant message
    final lastAssistant = saveable.lastWhere(
      (m) => m.role == 'assistant',
      orElse: () => saveable.last,
    );
    final preview = lastAssistant.content.length > 80
        ? '${lastAssistant.content.substring(0, 80)}...'
        : lastAssistant.content;

    try {
      final msgData = saveable
          .map((m) => ChatMessageData(
                role: m.role,
                content: m.content,
                createdAt: DateTime.now(),
              ))
          .toList();

      final savedId = await _storage.saveConversation(
        conversationId: _conversationId,
        title: title,
        feature: 'coach_chat',
        preview: preview,
        messages: msgData,
      );

      _conversationId = savedId;
      _conversationTitle = title;
    } catch (e) {
      debugPrint('AIChatScreen: Auto-save error: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isStreaming) return;

    _messageController.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _messages.add(_ChatMessage(role: 'assistant', content: ''));
      _isStreaming = true;
    });
    _scrollToBottom();

    // Build message history (last 10 messages for context)
    final history = _messages
        .where((m) => m.content.isNotEmpty)
        .skip(_messages.length > 12 ? _messages.length - 12 : 0)
        .take(10)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    if (history.isNotEmpty && history.last['content']!.isEmpty) {
      history.removeLast();
    }

    final buffer = StringBuffer();
    bool hasError = false;

    await for (final chunk in _cerebrasService.streamChat(history)) {
      if (!mounted) return;

      if (chunk == '[RATE_LIMITED]') {
        setState(() {
          _messages.last.content =
              'You\'ve reached the daily limit for guest users. Sign up for unlimited AI access! 🚀';
          _isStreaming = false;
          _rateLimited = true;
        });
        _scrollToBottom();
        hasError = true;
        break;
      }

      if (chunk.startsWith('[ERROR]')) {
        setState(() {
          _messages.last.content = chunk.substring(7);
          _isStreaming = false;
        });
        _scrollToBottom();
        hasError = true;
        break;
      }

      buffer.write(chunk);
      setState(() {
        _messages.last.content = buffer.toString();
      });
      _scrollToBottom();
    }

    setState(() => _isStreaming = false);
    _scrollToBottom();

    // Auto-save after successful response
    if (!hasError) {
      _autoSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppTheme.backgroundColor),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _conversationTitle ?? 'AI Coach',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_messages.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: _clearChat,
              tooltip: 'Clear chat',
            ),
        ],
      ),
      body: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildMessageList()),
                if (_rateLimited)
                  _buildRateLimitBanner()
                else
                  _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message, index);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, int index) {
    final isUser = message.role == 'user';
    final isLastAssistant =
        !isUser && index == _messages.length - 1 && _isStreaming;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppTheme.backgroundColor),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser ? AppTheme.primaryGradient : null,
                color: isUser ? null : AppTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content.isEmpty && isLastAssistant
                        ? '...'
                        : message.content,
                    style: TextStyle(
                      color: isUser
                          ? AppTheme.backgroundColor
                          : AppTheme.textPrimary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  if (isLastAssistant && message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  if (!isUser &&
                      message.content.isNotEmpty &&
                      !isLastAssistant) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: message.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Copied to clipboard'),
                            backgroundColor: AppTheme.surfaceColor,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 14,
                              color:
                                  AppTheme.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  AppTheme.textSecondary.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          top: BorderSide(
              color: AppTheme.textSecondary.withValues(alpha: 0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask your AI coach...',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isStreaming ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _isStreaming ? null : AppTheme.primaryGradient,
                color: _isStreaming ? AppTheme.surfaceColor : null,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isStreaming
                    ? Icons.hourglass_top_rounded
                    : Icons.send_rounded,
                color: _isStreaming
                    ? AppTheme.textSecondary
                    : AppTheme.backgroundColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateLimitBanner() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded,
              color: AppTheme.backgroundColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Daily limit reached. Sign up for unlimited AI access!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.backgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(_ChatMessage(
        role: 'assistant',
        content: 'Chat cleared! 🧹 What would you like to talk about?',
      ));
      _rateLimited = false;
      // Start a new conversation (don't reuse old ID)
      _conversationId = null;
      _conversationTitle = null;
    });
  }
}

class _ChatMessage {
  final String role;
  String content;

  _ChatMessage({required this.role, required this.content});
}

