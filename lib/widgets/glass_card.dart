import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final bool enableHover;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.blur = 10.0,
    this.color,
    this.shadows,
    this.onTap,
    this.enableHover = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = AppTheme.glassCard(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      blur: blur,
      backgroundColor: color,
      shadows: shadows,
      child: child,
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    if (enableHover) {
      card = MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: card,
      );
    }

    return card;
  }
}

class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final bool isEnabled;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GlassCard(
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing24,
                vertical: AppTheme.spacing16,
              ),
              borderRadius: widget.borderRadius,
              color: widget.backgroundColor,
              onTap: null, // Handled by GestureDetector
              child: widget.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.foregroundColor ?? AppTheme.textPrimary,
                        ),
                      ),
                    )
                  : DefaultTextStyle(
                      style: AppTheme.bodyMedium.copyWith(
                        color: widget.foregroundColor ?? AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      child: widget.child,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class GlassInputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const GlassInputField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
        ],
        GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: AppTheme.radiusMedium,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            readOnly: readOnly,
            maxLines: maxLines,
            maxLength: maxLength,
            validator: validator,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            onTap: onTap,
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textLight,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing16,
              ),
              counterText: '',
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppTheme.spacing4),
          Text(
            errorText!,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
        ],
      ],
    );
  }
}
