import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/messaging_service.dart';
import '../../models/conversation_model.dart';
import '../../config/theme.dart';
import '../../utils/image_utils.dart';
import 'chat_screen.dart';


class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final MessagingService _messagingService = MessagingService();
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    if (currentUserId != null && currentUserId != _lastUserId) {
      _lastUserId = currentUserId;
      _loadConversations();
    }
  }

  Future<void> _loadConversations() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final conversations = await _messagingService.getConversations(userId);
      setState(() {
        _conversations = conversations
            .map((c) => ConversationModel.fromJson(c))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _conversations.isEmpty
                      ? _buildEmptyState()
                      : _buildConversationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      child: Row(
        children: [
          Text(
            'Messages',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            'No Conversations Yet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            'Start chatting with trainers',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (currentUserId == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final otherUser = conversation.getOtherParticipant(currentUserId);

          return _buildConversationCard(
            conversation: conversation,
            otherUserName: otherUser['name'] ?? 'Unknown',
            otherUserAvatar: otherUser['avatar'],
            otherUserId: otherUser['id'] ?? '',
          );
        },
      ),
    );
  }

  Widget _buildConversationCard({
    required ConversationModel conversation,
    required String otherUserName,
    String? otherUserAvatar,
    required String otherUserId,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
              otherUserAvatar: otherUserAvatar,
            ),
          ),
        ).then((_) => _loadConversations()); // Refresh on return
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [AppTheme.primaryGlow],
              ),
              padding: const EdgeInsets.all(2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: otherUserAvatar != null && otherUserAvatar.isNotEmpty
                    ? Image.network(
                        corsProxyUrl(otherUserAvatar),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildInitial(otherUserName),
                      )
                    : _buildInitial(otherUserName),
              ),
            ),

            const SizedBox(width: AppTheme.spacingMD),

            // Message Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        conversation.timeAgo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    conversation.lastMessagePreview ?? 'No messages yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppTheme.spacingMD),

          ],
        ),
      ),
    );
  }

  Widget _buildInitial(String name) {
    return Container(
      color: AppTheme.surfaceColor,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
