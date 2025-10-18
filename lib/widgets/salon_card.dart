import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/salon_model.dart';
import '../services/image_cache_service.dart';
import 'glass_card.dart';

class SalonCard extends StatelessWidget {
  final SalonModel salon;
  final VoidCallback? onTap;
  final bool showDistance;
  final double? distance;
  final bool isCompact;

  const SalonCard({
    super.key,
    required this.salon,
    this.onTap,
    this.showDistance = false,
    this.distance,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing4,
      ),
      child: isCompact ? _buildCompactCard() : _buildFullCard(),
    );
  }

  Widget _buildFullCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image with Hero animation
        Hero(
          tag: 'salon_image_${salon.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: ImageCacheService.salonImage(
              imageUrl: salon.primaryImageUrl,
              height: 140, // Reduced from 160
              width: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Content
        _buildContent(),
      ],
    );
  }

  Widget _buildCompactCard() {
    return Row(
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: ImageCacheService.salonImage(
            imageUrl: salon.primaryImageUrl,
            width: 80,
            height: 80,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        
        // Content
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Name and Rating
        Row(
          children: [
            Expanded(
              child: Text(
                salon.name,
                style: AppTheme.headingSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (salon.isVerified)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified,
                      size: 12,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Rating and Reviews
        Row(
          children: [
            _buildRatingStars(salon.rating),
            const SizedBox(width: 8),
            Text(
              salon.formattedRating,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${salon.reviewCount} reviews)',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Address
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                salon.address,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Categories and Status
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: salon.categories.take(2).map((category) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMauve.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      category,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primaryMauve,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (showDistance && distance != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  '${distance!.toStringAsFixed(1)} km',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        
        // Open/Closed Status
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: salon.isOpen ? AppTheme.successColor : AppTheme.errorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              salon.isOpen ? 'Open now' : 'Closed',
              style: AppTheme.bodySmall.copyWith(
                color: salon.isOpen ? AppTheme.successColor : AppTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (salon.averagePrice != null) ...[
              const Spacer(),
              Text(
                'From \$${salon.averagePrice!.toStringAsFixed(0)}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starRating = index + 1;
        if (starRating <= rating.floor()) {
          return Icon(
            Icons.star,
            size: 16,
            color: AppTheme.accentGold,
          );
        } else if (starRating - 0.5 <= rating) {
          return Icon(
            Icons.star_half,
            size: 16,
            color: AppTheme.accentGold,
          );
        } else {
          return Icon(
            Icons.star_border,
            size: 16,
            color: AppTheme.textLight,
          );
        }
      }),
    );
  }
}

class SalonListCard extends StatelessWidget {
  final SalonModel salon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SalonListCard({
    super.key,
    required this.salon,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: ImageCacheService.salonImage(
              imageUrl: salon.primaryImageUrl,
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salon.name,
                  style: AppTheme.headingSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    _buildRatingStars(salon.rating),
                    const SizedBox(width: 8),
                    Text(
                      salon.formattedRating,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${salon.reviewCount})',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Text(
                  salon.address,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: salon.isOpen ? AppTheme.successColor : AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      salon.isOpen ? 'Open' : 'Closed',
                      style: AppTheme.bodySmall.copyWith(
                        color: salon.isOpen ? AppTheme.successColor : AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (salon.averagePrice != null) ...[
                      const Spacer(),
                      Text(
                        'From \$${salon.averagePrice!.toStringAsFixed(0)}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Trailing widget
          if (trailing != null) ...[
            const SizedBox(width: AppTheme.spacing16),
            trailing!,
          ],
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starRating = index + 1;
        if (starRating <= rating.floor()) {
          return Icon(
            Icons.star,
            size: 14,
            color: AppTheme.accentGold,
          );
        } else if (starRating - 0.5 <= rating) {
          return Icon(
            Icons.star_half,
            size: 14,
            color: AppTheme.accentGold,
          );
        } else {
          return Icon(
            Icons.star_border,
            size: 14,
            color: AppTheme.textLight,
          );
        }
      }),
    );
  }
}
