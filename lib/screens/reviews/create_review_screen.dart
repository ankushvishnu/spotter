import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';
import '../../config/theme.dart';

class CreateReviewScreen extends StatefulWidget {
  final String bookingId;
  final String trainerId;
  final String trainerName;

  const CreateReviewScreen({
    super.key,
    required this.bookingId,
    required this.trainerId,
    required this.trainerName,
  });

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  final _reviewController = TextEditingController();

  int _overallRating = 0;
  int _professionalismRating = 0;
  int _punctualityRating = 0;
  int _knowledgeRating = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give an overall star rating')),
      );
      return;
    }

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      await _reviewService.submitReview(
        reviewerId: userId,
        trainerId: widget.trainerId,
        bookingId: widget.bookingId,
        rating: _overallRating,
        reviewText: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        professionalismRating:
            _professionalismRating > 0 ? _professionalismRating : null,
        punctualityRating:
            _punctualityRating > 0 ? _punctualityRating : null,
        knowledgeRating: _knowledgeRating > 0 ? _knowledgeRating : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted! 🎉'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate review was submitted
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate ${widget.trainerName}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [AppTheme.primaryGlow],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        widget.trainerName[0].toUpperCase(),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.backgroundColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMD),
                  Text(
                    'How was your session?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.backgroundColor,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'with ${widget.trainerName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.backgroundColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppTheme.spacingXL),

            // Overall Rating
            Text(
              'Overall Rating *',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: AppTheme.spacingMD),
            _buildStarRating(
              _overallRating,
              large: true,
              onChanged: (r) => setState(() => _overallRating = r),
            ),

            SizedBox(height: AppTheme.spacingXL),

            // Review Text
            Text(
              'Write a Review (optional)',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: AppTheme.spacingMD),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Share your experience with this trainer...',
              ),
            ),

            SizedBox(height: AppTheme.spacingXL),

            // Sub-ratings
            Text(
              'Rate Specific Areas (optional)',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: AppTheme.spacingMD),

            _buildCategoryRatingRow(
              label: 'Professionalism',
              icon: Icons.workspace_premium_rounded,
              rating: _professionalismRating,
              onChanged: (r) => setState(() => _professionalismRating = r),
            ),
            SizedBox(height: AppTheme.spacingMD),
            _buildCategoryRatingRow(
              label: 'Punctuality',
              icon: Icons.schedule_rounded,
              rating: _punctualityRating,
              onChanged: (r) => setState(() => _punctualityRating = r),
            ),
            SizedBox(height: AppTheme.spacingMD),
            _buildCategoryRatingRow(
              label: 'Knowledge',
              icon: Icons.school_rounded,
              rating: _knowledgeRating,
              onChanged: (r) => setState(() => _knowledgeRating = r),
            ),

            SizedBox(height: AppTheme.spacingXXL),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Submit Review'),
                        ],
                      ),
              ),
            ),

            SizedBox(height: AppTheme.spacingLG),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(
    int rating, {
    required Function(int) onChanged,
    bool large = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onChanged(index + 1),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: large ? 6 : 2),
            child: Icon(
              index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppTheme.warningColor,
              size: large ? 48 : 28,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCategoryRatingRow({
    required String label,
    required IconData icon,
    required int rating,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          _buildStarRating(rating, onChanged: onChanged),
        ],
      ),
    );
  }
}
