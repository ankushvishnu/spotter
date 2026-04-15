import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../services/cerebras_service.dart';
import '../../services/chat_storage_service.dart';

/// Screen for one-shot AI generation: bio, description, workout plan.
class AIGenerateScreen extends StatefulWidget {
  final String feature;
  final String title;
  final String description;
  final String placeholder;
  final IconData icon;
  final Color color;
  final String? conversationId;

  const AIGenerateScreen({
    super.key,
    required this.feature,
    required this.title,
    required this.description,
    required this.placeholder,
    required this.icon,
    required this.color,
    this.conversationId,
  });

  @override
  State<AIGenerateScreen> createState() => _AIGenerateScreenState();
}

class _AIGenerateScreenState extends State<AIGenerateScreen>
    with SingleTickerProviderStateMixin {
  final CerebrasService _cerebrasService = CerebrasService();
  final ChatStorageService _storage = ChatStorageService();
  final TextEditingController _inputController = TextEditingController();
  String? _generatedContent;
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _conversationId;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (_conversationId != null) {
      _loadPastGeneration();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPastGeneration() async {
    setState(() => _isLoadingHistory = true);
    final conv = await _storage.loadConversation(_conversationId!);
    if (conv != null && mounted) {
      // Find user input and assistant output from messages
      for (final m in conv.messages) {
        if (m.role == 'user') {
          _inputController.text = m.content;
        } else if (m.role == 'assistant') {
          _generatedContent = m.content;
        }
      }
    }
    if (mounted) setState(() => _isLoadingHistory = false);
  }

  Future<void> _generate() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide some details first'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedContent = null;
    });

    final result = await _cerebrasService.generate(
      feature: widget.feature,
      userMessage: input,
    );

    if (mounted) {
      setState(() {
        _generatedContent = result;
        _isLoading = false;
      });

      // Auto-save the generation
      _autoSave(input, result);
    }
  }

  Future<void> _autoSave(String userInput, String output) async {
    // Don't save error responses
    if (output.contains('temporarily unavailable') ||
        output.contains('Something went wrong') ||
        output.contains('Daily limit reached')) {
      return;
    }

    final title = userInput.length > 50
        ? '${userInput.substring(0, 50)}...'
        : userInput;

    final preview = output.length > 80
        ? '${output.substring(0, 80)}...'
        : output;

    try {
      final savedId = await _storage.saveConversation(
        conversationId: _conversationId,
        title: title,
        feature: widget.feature,
        preview: preview,
        messages: [
          ChatMessageData(
            role: 'user',
            content: userInput,
            createdAt: DateTime.now(),
          ),
          ChatMessageData(
            role: 'assistant',
            content: output,
            createdAt: DateTime.now(),
          ),
        ],
      );
      _conversationId = savedId;
    } catch (e) {
      debugPrint('AIGenerateScreen: Auto-save error: $e');
    }
  }

  void _copyToClipboard() {
    if (_generatedContent == null) return;
    Clipboard.setData(ClipboardData(text: _generatedContent!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard! 📋'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _regenerate() {
    _generate();
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
                color: widget.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, size: 16, color: widget.color),
            ),
            const SizedBox(width: 10),
            Text(widget.title),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingLG),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.color.withValues(alpha: 0.2),
                          widget.color.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(widget.icon, color: widget.color, size: 32),
                        const SizedBox(height: AppTheme.spacingMD),
                        Text(
                          widget.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXL),

                  // Input
                  Text(
                    'Your Details',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  TextField(
                    controller: _inputController,
                    maxLines: 5,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingLG),

                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generate,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                          _isLoading ? 'Generating...' : 'Generate with AI'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingMD),
                      ),
                    ),
                  ),

                  // Loading animation
                  if (_isLoading) ...[
                    const SizedBox(height: AppTheme.spacingXL),
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Opacity(
                            opacity:
                                0.3 + (_pulseController.value * 0.7),
                            child: Column(
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    size: 48, color: widget.color),
                                const SizedBox(height: AppTheme.spacingMD),
                                Text(
                                  'AI is crafting your content...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: widget.color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Result
                  if (_generatedContent != null) ...[
                    const SizedBox(height: AppTheme.spacingXL),
                    Row(
                      children: [
                        Text(
                          'Generated Content',
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _copyToClipboard,
                          icon:
                              const Icon(Icons.copy_rounded, size: 20),
                          tooltip: 'Copy',
                          color: AppTheme.primaryColor,
                        ),
                        IconButton(
                          onPressed: _regenerate,
                          icon:
                              const Icon(Icons.refresh_rounded, size: 20),
                          tooltip: 'Regenerate',
                          color: AppTheme.accentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTheme.spacingLG),
                      decoration: BoxDecoration(
                        gradient: AppTheme.cardGradient,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: SelectableText(
                        _generatedContent!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              height: 1.7,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingLG),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy_rounded,
                                size: 16),
                            label: const Text('Copy'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacingSM),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMD),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _regenerate,
                            icon: const Icon(Icons.refresh_rounded,
                                size: 16),
                            label: const Text('Regenerate'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacingSM),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppTheme.spacingXXL),
                ],
              ),
            ),
    );
  }
}

