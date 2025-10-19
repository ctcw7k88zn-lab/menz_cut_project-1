import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../models/review_model.dart';
import '../providers/reviews_provider.dart';
import '../providers/auth_provider.dart';
import '../services/app_api.dart';
import '../services/image_cache_service.dart';
import 'review_input_widget.dart';

class ReviewDisplayWidget extends ConsumerWidget {
  final String salonId;
  final VoidCallback? onReviewSubmitted;

  const ReviewDisplayWidget({
    super.key,
    required this.salonId,
    this.onReviewSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsState = ref.watch(reviewsProvider);
    final authState = ref.watch(authProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reviews Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.primaryMauve,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (authState.user != null)
              FutureBuilder<bool>(
                future: AppApi.canCustomerReviewSalon(authState.user!.id, salonId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return TextButton.icon(
                      onPressed: () => _showReviewDialog(context, ref),
                      icon: const Icon(Icons.edit, size: 16.0),
                      label: const Text('Write Review'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryMauve,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Reviews Content
        reviewsState.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return _buildEmptyReviews();
            }
            return Column(
              children: [
                // Review Stats
                _buildReviewStats(reviews),
                const SizedBox(height: 16.0),
                
                // Reviews List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12.0),
                  itemBuilder: (context, index) {
                    return _buildReviewCard(reviews[index]);
                  },
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[400],
                  size: 48.0,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Failed to load reviews',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: () {
                    ref.read(reviewsProvider.notifier).loadReviewsForSalon(salonId);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyReviews() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.reviews_outlined,
            size: 48.0,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12.0),
          Text(
            'No reviews yet',
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Be the first to share your experience!',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStats(List<ReviewModel> reviews) {
    final averageRating = reviews.isEmpty 
        ? 0.0 
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    
    final ratingDistribution = <int, int>{};
    for (final review in reviews) {
      ratingDistribution[review.rating] = (ratingDistribution[review.rating] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryMauve.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          // Average Rating
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: AppTheme.headingLarge.copyWith(
                  color: AppTheme.primaryMauve,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < averageRating ? Icons.star : Icons.star_border,
                    color: AppTheme.accentGold,
                    size: 16.0,
                  );
                }),
              ),
              Text(
                '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 24.0),
          
          // Rating Distribution
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final rating = 5 - index;
                final count = ratingDistribution[rating] ?? 0;
                final percentage = reviews.isEmpty ? 0.0 : (count / reviews.length) * 100;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      Text(
                        '$rating',
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        '$count',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review Header
          Row(
            children: [
              // Customer Avatar
              CircleAvatar(
                radius: 20.0,
                backgroundImage: review.customerAvatar != null
                    ? NetworkImage(review.customerAvatar!)
                    : null,
                child: review.customerAvatar == null
                    ? Text(
                        (review.customerName ?? 'U')[0].toUpperCase(),
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12.0),
              
              // Customer Info and Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName ?? 'Anonymous',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating ? Icons.star : Icons.star_border,
                            color: AppTheme.accentGold,
                            size: 14.0,
                          );
                        }),
                        const SizedBox(width: 8.0),
                        Text(
                          _formatDate(review.createdAt),
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          
          // Review Comment
          Text(
            review.comment,
            style: AppTheme.bodyMedium,
          ),
          
          // Review Images (if any)
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            SizedBox(
              height: 80.0,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        review.images[index],
                        width: 80.0,
                        height: 80.0,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80.0,
                            height: 80.0,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Write a Review'),
        content: SizedBox(
          width: double.maxFinite,
          child: ReviewInputWidget(
            salonId: salonId,
            onReviewSubmitted: () {
              Navigator.of(context).pop();
              ref.read(reviewsProvider.notifier).loadReviewsForSalon(salonId);
              onReviewSubmitted?.call();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
