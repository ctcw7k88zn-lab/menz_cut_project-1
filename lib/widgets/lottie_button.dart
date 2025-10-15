import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/app_theme.dart';

class LottieButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;
  final bool isOutlined;
  final String? lottieAsset;
  final String? lottieUrl;

  const LottieButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
    this.isOutlined = false,
    this.lottieAsset,
    this.lottieUrl,
  });

  @override
  State<LottieButton> createState() => _LottieButtonState();
}

class _LottieButtonState extends State<LottieButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showLottie = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onPressed() {
    if (widget.onPressed != null) {
      setState(() {
        _showLottie = true;
      });
      
      widget.onPressed!();
      
      // Hide lottie after animation
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showLottie = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height ?? 56,
              decoration: BoxDecoration(
                gradient: widget.isOutlined ? null : AppTheme.primaryGradient,
                color: widget.isOutlined ? Colors.transparent : null,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: widget.isOutlined 
                    ? Border.all(color: AppTheme.glassBorder, width: 1.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryMauve.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _onPressed,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Center(
                    child: _showLottie && (widget.lottieAsset != null || widget.lottieUrl != null)
                        ? SizedBox(
                            width: 40,
                            height: 40,
                            child: widget.lottieAsset != null
                                ? Lottie.asset(
                                    widget.lottieAsset!,
                                    fit: BoxFit.contain,
                                  )
                                : Lottie.network(
                                    widget.lottieUrl!,
                                    fit: BoxFit.contain,
                                  ),
                          )
                        : widget.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.icon != null) ...[
                                    Icon(
                                      widget.icon,
                                      color: widget.isOutlined 
                                          ? AppTheme.primaryMauve 
                                          : Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    widget.text,
                                    style: AppTheme.buttonText.copyWith(
                                      color: widget.isOutlined 
                                          ? AppTheme.primaryMauve 
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SuccessLottieButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const SuccessLottieButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return LottieButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      width: width,
      lottieUrl: 'https://assets5.lottiefiles.com/packages/lf20_jcikwtux.json', // Success animation
    );
  }
}

class LoadingLottieButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const LoadingLottieButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return LottieButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      width: width,
      lottieUrl: 'https://assets5.lottiefiles.com/packages/lf20_s2lryxtd.json', // Loading animation
    );
  }
}
