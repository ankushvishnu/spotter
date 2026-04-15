import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/chat_storage_service.dart';
import 'ai_chat_screen.dart';
import 'ai_generate_screen.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ChatStorageService _storage = ChatStorageService();
  List<ChatConversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final convs = await _storage.loadConversations();
    if (mounted) {
      setState(() {
        _conversations = convs;
        _isLoading = false;
      });
    }
  }

  Future<void> _delete(String id) async {
    await _storage.deleteConversation(id);
    _load();
  }

  void _openConversation(ChatConversation conv) {
    if (conv.feature == 'coach_chat') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AIChatScreen(conversationId: conv.id),
        ),
      ).then((_) => _load());
    } else {
      // For generation features, open as read-only with results
      final configs = {
        'write_bio': {
          'title': 'Write My Bio',
          'description': 'View your previously generated bio.',
          'placeholder': '',
          'icon': Icons.edit_note_rounded,
          'color': AppTheme.accentColor,
        },
        'write_description': {
          'title': 'Session Description',
          'description': 'View your previously generated description.',
          'placeholder': '',
          'icon': Icons.description_rounded,
          'color': AppTheme.warningColor,
        },
        'workout_plan': {
          'title': 'Workout Plan',
          'description': 'View your previously generated workout plan.',
          'placeholder': '',
          'icon': Icons.fitness_center_rounded,
          'color': AppTheme.secondaryColor,
        },
      };

      final config = configs[conv.feature];
      if (config != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AIGenerateScreen(
              feature: conv.feature,
              title: config['title'] as String,
              description: config['description'] as String,
              placeholder: config['placeholder'] as String,
              icon: config['icon'] as IconData,
              color: config['color'] as Color,
              conversationId: conv.id,
            ),
          ),
        ).then((_) => _load());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 48, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              'Start chatting with AI Coach or generate content — your history will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    // Group by date
    final grouped = <String, List<ChatConversation>>{};
    for (final conv in _conversations) {
      final label = _dateLabel(conv.updatedAt);
      grouped.putIfAbsent(label, () => []).add(conv);
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        itemCount: grouped.length,
        itemBuilder: (context, sectionIndex) {
          final sectionLabel = grouped.keys.elementAt(sectionIndex);
          final items = grouped[sectionLabel]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sectionIndex > 0) const SizedBox(height: AppTheme.spacingSM),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: AppTheme.spacingXS),
                child: Text(
                  sectionLabel.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              ...items.map((conv) => _buildConversationTile(conv)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conv) {
    final featureConfig = _featureConfig(conv.feature);
    final timeStr = DateFormat('h:mm a').format(conv.updatedAt.toLocal());

    return Dismissible(
      key: Key(conv.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded,
            color: AppTheme.errorColor, size: 24),
      ),
      confirmDismiss: (_) => _confirmDelete(conv.title),
      onDismissed: (_) => _delete(conv.id),
      child: GestureDetector(
        onTap: () => _openConversation(conv),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (featureConfig['color'] as Color).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      (featureConfig['color'] as Color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  featureConfig['icon'] as IconData,
                  color: featureConfig['color'] as Color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conv.title,
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (conv.preview != null &&
                        conv.preview!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        conv.preview!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Text(
                timeStr,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: AppTheme.textSecondary.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(String title) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete conversation?'),
        content: Text('Remove "$title"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (d.isAfter(today.subtract(const Duration(days: 7)))) return 'This Week';
    return DateFormat('MMM yyyy').format(date);
  }

  Map<String, dynamic> _featureConfig(String feature) {
    switch (feature) {
      case 'coach_chat':
        return {
          'icon': Icons.chat_bubble_rounded,
          'color': AppTheme.primaryColor
        };
      case 'write_bio':
        return {
          'icon': Icons.edit_note_rounded,
          'color': AppTheme.accentColor
        };
      case 'write_description':
        return {
          'icon': Icons.description_rounded,
          'color': AppTheme.warningColor
        };
      case 'workout_plan':
        return {
          'icon': Icons.fitness_center_rounded,
          'color': AppTheme.secondaryColor
        };
      default:
        return {
          'icon': Icons.auto_awesome_rounded,
          'color': AppTheme.primaryColor
        };
    }
  }
}

