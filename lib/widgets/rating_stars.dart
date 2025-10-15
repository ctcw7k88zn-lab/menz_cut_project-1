import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'glass_card.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final bool showRating;
  final bool showReviewCount;
  final int? reviewCount;
  final Color? activeColor;
  final Color? inactiveColor;

  const RatingStars({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 16,
    this.showRating = false,
    this.showReviewCount = false,
    this.reviewCount,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxRating, (index) {
            final starRating = index + 1;
            if (starRating <= rating.floor()) {
              return Icon(
                Icons.star,
                size: size,
                color: activeColor ?? AppTheme.accentGold,
              );
            } else if (starRating - 0.5 <= rating) {
              return Icon(
                Icons.star_half,
                size: size,
                color: activeColor ?? AppTheme.accentGold,
              );
            } else {
              return Icon(
                Icons.star_border,
                size: size,
                color: inactiveColor ?? AppTheme.textLight,
              );
            }
          }),
        ),
        
        // Rating number
        if (showRating) ...[
          const SizedBox(width: AppTheme.spacing4),
          Text(
            rating.toStringAsFixed(1),
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
        
        // Review count
        if (showReviewCount && reviewCount != null) ...[
          const SizedBox(width: AppTheme.spacing4),
          Text(
            '($reviewCount)',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class RatingBar extends StatefulWidget {
  final double rating;
  final int maxRating;
  final double size;
  final bool allowRating;
  final ValueChanged<double>? onRatingChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const RatingBar({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 24,
    this.allowRating = false,
    this.onRatingChanged,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        final starRating = index + 1;
        final isActive = starRating <= _currentRating;
        
        return GestureDetector(
          onTap: widget.allowRating ? () {
            setState(() {
              _currentRating = starRating.toDouble();
            });
            widget.onRatingChanged?.call(_currentRating);
          } : null,
          child: Container(
            padding: const EdgeInsets.all(2),
            child: Icon(
              isActive ? Icons.star : Icons.star_border,
              size: widget.size,
              color: isActive 
                  ? (widget.activeColor ?? AppTheme.accentGold)
                  : (widget.inactiveColor ?? AppTheme.textLight),
            ),
          ),
        );
      }),
    );
  }
}

class RatingDistribution extends StatelessWidget {
  final Map<int, int> ratingCounts;
  final int totalReviews;
  final double averageRating;

  const RatingDistribution({
    super.key,
    required this.ratingCounts,
    required this.totalReviews,
    required this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average rating
        Row(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: AppTheme.headingLarge.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            RatingStars(
              rating: averageRating,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              '($totalReviews reviews)',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        
        // Rating breakdown
        ...List.generate(5, (index) {
          final rating = 5 - index;
          final count = ratingCounts[rating] ?? 0;
          final percentage = totalReviews > 0 ? count / totalReviews : 0.0;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
            child: Row(
              children: [
                Text(
                  '$rating',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Icon(
                  Icons.star,
                  size: 16,
                  color: AppTheme.accentGold,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppTheme.textLight.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text(
                  '$count',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class ReviewCard extends StatelessWidget {
  final String reviewerName;
  final double rating;
  final String reviewText;
  final DateTime reviewDate;
  final String? reviewerImageUrl;
  final List<String>? reviewImages;

  const ReviewCard({
    super.key,
    required this.reviewerName,
    required this.rating,
    required this.reviewText,
    required this.reviewDate,
    this.reviewerImageUrl,
    this.reviewImages,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryMauve.withOpacity(0.1),
                backgroundImage: reviewerImageUrl != null 
                    ? NetworkImage(reviewerImageUrl!)
                    : null,
                child: reviewerImageUrl == null
                    ? Text(
                        reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : '?',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryMauve,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RatingStars(
                      rating: rating,
                      size: 14,
                      showRating: true,
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(reviewDate),
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          
          // Review text
          Text(
            reviewText,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
          
          // Review images
          if (reviewImages != null && reviewImages!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: reviewImages!.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: AppTheme.spacing8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      child: Image.network(
                        reviewImages![index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: AppTheme.textLight.withOpacity(0.3),
                            child: Icon(
                              Icons.image,
                              color: AppTheme.textSecondary,
                            ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
