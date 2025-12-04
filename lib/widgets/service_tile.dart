import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/service_model.dart';
import '../services/image_cache_service.dart';
import 'glass_card.dart';

class ServiceTile extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;
  final VoidCallback? onBook;
  final bool showBookButton;
  final bool isCompact;

  const ServiceTile({
    super.key,
    required this.service,
    this.onTap,
    this.onBook,
    this.showBookButton = true,
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
      child: isCompact ? _buildCompactTile() : _buildFullTile(),
    );
  }

  Widget _buildFullTile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        if (service.imageUrl != null && service.imageUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: ImageCacheService.cachedImage(
              imageUrl: service.imageUrl!,
              height: 120,
              width: double.infinity,
            ),
          ),
        const SizedBox(height: AppTheme.spacing12),
        
        // Content
        _buildContent(),
      ],
    );
  }

  Widget _buildCompactTile() {
    return Row(
      children: [
        // Image
        if (service.imageUrl != null && service.imageUrl!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: ImageCacheService.cachedImage(
              imageUrl: service.imageUrl!,
              width: 60,
              height: 60,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
        ],
        
        // Content
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name and Price
        Row(
          children: [
            Expanded(
              child: Text(
                service.name,
                style: AppTheme.headingSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              AppTheme.formatCurrencyCompact(service.price),
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.primaryMauve,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        
        // Description
        Text(
          service.description,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppTheme.spacing12),
        
        // Duration and Category
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing8,
                vertical: AppTheme.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryMauve.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppTheme.primaryMauve,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${service.durationMinutes} min',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.primaryMauve,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacing8),
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
                service.category,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        // Tags
        if (service.category.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing8),
          Wrap(
            spacing: AppTheme.spacing4,
            runSpacing: AppTheme.spacing4,
            children: [service.category].map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing6,
                  vertical: AppTheme.spacing2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  tag,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        
        // Book Button
        if (showBookButton) ...[
          const SizedBox(height: AppTheme.spacing16),
          GlassButton(
            onPressed: onBook,
            backgroundColor: AppTheme.primaryMauve.withOpacity(0.1),
            foregroundColor: AppTheme.primaryMauve,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.primaryMauve,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Text('Book Now'),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class ServiceListTile extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;
  final VoidCallback? onBook;
  final Widget? trailing;

  const ServiceListTile({
    super.key,
    required this.service,
    this.onTap,
    this.onBook,
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
          if (service.imageUrl != null && service.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: ImageCacheService.cachedImage(
                imageUrl: service.imageUrl!,
                width: 60,
                height: 60,
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
          ],
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: AppTheme.headingSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing4),
                
                Text(
                  service.description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing8),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8,
                        vertical: AppTheme.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMauve.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppTheme.primaryMauve,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${service.durationMinutes} min',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.primaryMauve,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      AppTheme.formatCurrencyCompact(service.price),
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryMauve,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
}
