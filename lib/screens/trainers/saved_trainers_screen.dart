import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/trainer_service.dart';
import '../../models/trainer_model.dart';
import 'trainer_detail_screen_modern.dart';

class SavedTrainersScreen extends StatefulWidget {
  const SavedTrainersScreen({super.key});

  @override
  State<SavedTrainersScreen> createState() => _SavedTrainersScreenState();
}

class _SavedTrainersScreenState extends State<SavedTrainersScreen> {
  late final TrainerService _trainerService;
  List<TrainerModel> _savedTrainers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _trainerService = context.read<TrainerService>();
    _loadSavedTrainers();
  }

  Future<void> _loadSavedTrainers() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final results = await _trainerService.getSavedTrainers(userId);
      final trainers = results.map((t) => TrainerModel.fromJson(t)).toList();
      
      setState(() {
        _savedTrainers = trainers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading saved trainers: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Trainers'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedTrainers.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(
            'No Saved Trainers',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            'Trainers you save will appear here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadSavedTrainers,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        itemCount: _savedTrainers.length,
        itemBuilder: (context, index) {
          final trainer = _savedTrainers[index];
          return _buildTrainerCard(trainer);
        },
      ),
    );
  }

  Widget _buildTrainerCard(TrainerModel trainer) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrainerDetailScreen(trainerId: trainer.id),
          ),
        ).then((_) => _loadSavedTrainers());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
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
                shape: BoxShape.circle,
                image: trainer.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(trainer.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: trainer.avatarUrl == null
                  ? Center(
                      child: Text(
                        trainer.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.backgroundColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppTheme.spacingMD),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trainer.fullName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (trainer.specialties.isNotEmpty)
                    Text(
                      trainer.specialties.join(', '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppTheme.warningColor),
                      const SizedBox(width: 4),
                      Text(
                        trainer.averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningColor,
                            ),
                      ),
                      Text(
                        ' (${trainer.totalReviews})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Icon
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
