import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? height;
  final IconData? icon;
  final String? text;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height,
    this.icon,
    this.text,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: widget.width,
                height: widget.height,
                padding: widget.padding ?? const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing24,
                  vertical: AppTheme.spacing16,
                ),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? AppTheme.primaryMauve,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.backgroundColor ?? AppTheme.primaryMauve).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: widget.isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.foregroundColor ?? Colors.white,
                          ),
                        ),
                      )
                    : DefaultTextStyle(
                        style: AppTheme.bodyMedium.copyWith(
                          color: widget.foregroundColor ?? Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        child: widget.child,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      width: width,
      backgroundColor: AppTheme.primaryMauve,
      foregroundColor: Colors.white,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: AppTheme.spacing8),
          ],
          Text(text),
        ],
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      width: width,
      backgroundColor: Colors.transparent,
      foregroundColor: AppTheme.primaryMauve,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primaryMauve,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: AppTheme.spacing8),
            ],
            Text(text),
          ],
        ),
      ),
    );
  }
}

class IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;

  const IconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      width: size,
      height: size,
      backgroundColor: backgroundColor ?? AppTheme.primaryMauve,
      foregroundColor: foregroundColor ?? Colors.white,
      borderRadius: size / 2,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? Colors.white,
                ),
              ),
            )
          : Icon(icon, size: 24),
    );
  }
}

class FloatingActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const FloatingActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      width: 56,
      height: 56,
      backgroundColor: backgroundColor ?? AppTheme.primaryMauve,
      foregroundColor: foregroundColor ?? Colors.white,
      borderRadius: 28,
      child: isLoading
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? Colors.white,
                ),
              ),
            )
          : Icon(icon, size: 28),
    );
  }
}
