import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/salon_model.dart';

class MapMarkerCard extends StatelessWidget {
  final SalonModel salon;
  final VoidCallback? onTap;
  final VoidCallback? onBookNow;

  const MapMarkerCard({
    super.key,
    required this.salon,
    this.onTap,
    this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppTheme.glassCard(
        width: 280,
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image and basic info
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Image.network(
                  salon.primaryImageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: AppTheme.textLight,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salon.name,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: AppTheme.accentGold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          salon.rating.toStringAsFixed(1),
                          style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${salon.reviewCount})',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            salon.address,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacing12),
          
          // Categories preview
          if (salon.categories.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: salon.categories.take(3).map((category) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMauve.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryMauve,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacing12),
          ],
          
          // Price range and book button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From \$${salon.averagePrice?.toStringAsFixed(0) ?? '0'}',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryMauve,
                      ),
                    ),
                    Text(
                      'per service',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              AppTheme.glassButton(
                text: 'Book Now',
                onPressed: onBookNow ?? () {},
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class MapMarker extends StatelessWidget {
  final SalonModel salon;
  final bool isSelected;
  final VoidCallback? onTap;

  const MapMarker({
    super.key,
    required this.salon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 50 : 40,
        height: isSelected ? 50 : 40,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryMauve : AppTheme.accentGold,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? AppTheme.primaryMauve : AppTheme.accentGold)
                  .withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.business,
          color: Colors.white,
          size: isSelected ? 24 : 20,
        ),
      ),
    );
  }
}
