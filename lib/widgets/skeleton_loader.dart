import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/app_theme.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: AppTheme.surfaceLight,
      ),
      child: Shimmer.fromColors(
        baseColor: AppTheme.surfaceLight,
        highlightColor: AppTheme.surfaceMedium,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final bool isCompact;

  const SkeletonCard({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return AppTheme.glassCard(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Row(
          children: [
            const SkeletonLoader(
              width: 80,
              height: 80,
              borderRadius: AppTheme.radiusSmall,
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  const SkeletonLoader(
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  const SkeletonLoader(
                    height: 12,
                    width: 100,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppTheme.glassCard(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(
            height: 160,
            borderRadius: AppTheme.radiusMedium,
          ),
          const SizedBox(height: AppTheme.spacing12),
          const SkeletonLoader(
            height: 20,
            borderRadius: 4,
          ),
          const SizedBox(height: AppTheme.spacing8),
          const SkeletonLoader(
            height: 14,
            borderRadius: 4,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            children: [
              const SkeletonLoader(
                height: 12,
                width: 60,
                borderRadius: 4,
              ),
              const Spacer(),
              const SkeletonLoader(
                height: 12,
                width: 40,
                borderRadius: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final bool isCompact;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacing16),
      itemBuilder: (context, index) => SkeletonCard(isCompact: isCompact),
    );
  }
}
