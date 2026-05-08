import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';
import '../../config/theme.dart';
import '../../utils/app_exception.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    
    try {
      final reviews = await _reviewService.getUserReviews(userId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reviews: $e')),
        );
      }
    }
  }

  void _showEditReviewDialog(ReviewModel review) {
    final textController = TextEditingController(text: review.reviewText ?? '');
    int currentRating = review.rating;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBuilder) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              title: const Text('Edit Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < currentRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateBuilder(() {
                            currentRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateReview(review.id, currentRating, textController.text);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _updateReview(String reviewId, int rating, String text) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    try {
      await _reviewService.updateReview(
        reviewId: reviewId,
        reviewerId: userId,
        rating: rating,
        reviewText: text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review updated successfully'), backgroundColor: AppTheme.successColor),
        );
        _loadReviews();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppException.cleanMessage(e)), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Reviews'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? _buildEmptyState()
              : _buildReviewsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'No reviews yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reviews you leave for trainers will appear here.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Row(
                    children: [
                       CircleAvatar(
                         radius: 16,
                         backgroundImage: review.reviewerAvatar != null ? NetworkImage(review.reviewerAvatar!) : null,
                         child: review.reviewerAvatar == null ? Text(review.reviewerName[0]) : null,
                       ),
                       const SizedBox(width: 8),
                       Text(
                         review.reviewerName, // mapped from trainer
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                       ),
                    ],
                   ),
                   Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(review.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(review.reviewText!, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4)),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showEditReviewDialog(review),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit Review'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
