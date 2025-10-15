import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/app_theme.dart';

class LottieLoader extends StatelessWidget {
  final String? assetPath;
  final String? networkUrl;
  final double? width;
  final double? height;
  final String? message;
  final bool repeat;
  final bool reverse;

  const LottieLoader({
    super.key,
    this.assetPath,
    this.networkUrl,
    this.width,
    this.height,
    this.message,
    this.repeat = true,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (assetPath != null || networkUrl != null)
            Lottie.asset(
              assetPath ?? '',
              width: width ?? 200,
              height: height ?? 200,
              repeat: repeat,
              reverse: reverse,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackLoader();
              },
            )
          else if (networkUrl != null)
            Lottie.network(
              networkUrl!,
              width: width ?? 200,
              height: height ?? 200,
              repeat: repeat,
              reverse: reverse,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackLoader();
              },
            )
          else
            _buildFallbackLoader(),
          
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacing16),
            Text(
              message!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackLoader() {
    return SizedBox(
      width: width ?? 200,
      height: height ?? 200,
      child: const CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMauve),
      ),
    );
  }
}

class SuccessAnimation extends StatelessWidget {
  final String? message;
  final VoidCallback? onAnimationComplete;

  const SuccessAnimation({
    super.key,
    this.message,
    this.onAnimationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return LottieLoader(
      assetPath: 'assets/lottie/success.json',
      width: 150,
      height: 150,
      message: message ?? 'Success!',
      repeat: false,
      // TODO: Add onAnimationComplete callback when Lottie supports it
    );
  }
}

class ErrorAnimation extends StatelessWidget {
  final String? message;

  const ErrorAnimation({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return LottieLoader(
      assetPath: 'assets/lottie/error.json',
      width: 150,
      height: 150,
      message: message ?? 'Something went wrong',
      repeat: false,
    );
  }
}

class LoadingAnimation extends StatelessWidget {
  final String? message;

  const LoadingAnimation({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return LottieLoader(
      assetPath: 'assets/lottie/loading.json',
      width: 100,
      height: 100,
      message: message ?? 'Loading...',
      repeat: true,
    );
  }
}

class EmptyStateAnimation extends StatelessWidget {
  final String? message;
  final String? subtitle;
  final Widget? action;

  const EmptyStateAnimation({
    super.key,
    this.message,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LottieLoader(
            assetPath: 'assets/lottie/empty.json',
            width: 200,
            height: 200,
            repeat: true,
          ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacing16),
            Text(
              message!,
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacing8),
            Text(
              subtitle!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppTheme.spacing24),
            action!,
          ],
        ],
      ),
    );
  }
}

class ShimmerLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoader({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isLoading) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _animationController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor ?? AppTheme.textLight.withOpacity(0.3),
                widget.highlightColor ?? AppTheme.textLight.withOpacity(0.6),
                widget.baseColor ?? AppTheme.textLight.withOpacity(0.3),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

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
        color: AppTheme.textLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
