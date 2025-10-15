import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  // Premium Glassmorphism Color Palette
  static const Color primaryMauve = Color(0xFF6B3FA0);
  static const Color primaryLavender = Color(0xFFB77BFF);
  static const Color accentGold = Color(0xFFE0B85B);
  static const Color backgroundWhite = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A); // Dark slate
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color surfaceLight = Color(0x1AFFFFFF); // 10% opacity
  static const Color surfaceMedium = Color(0x2DFFFFFF); // 18% opacity
  static const Color surfaceDark = Color(0x4DFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF); // 20% opacity
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF3B82F6);

  // Premium gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryMauve, primaryLavender],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGold, Color(0xFFFFD700)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [successColor, Color(0xFF10B981)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [errorColor, Color(0xFFDC2626)],
  );

  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [infoColor, Color(0xFF2563EB)],
  );

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Responsive Helpers
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < mobileBreakpoint;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= mobileBreakpoint && MediaQuery.of(context).size.width < tabletBreakpoint;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= tabletBreakpoint;

  // Responsive Spacing
  static double getResponsiveSpacing(BuildContext context, {double mobile = 16, double tablet = 20, double desktop = 24}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive Font Size
  static double getResponsiveFontSize(BuildContext context, {double mobile = 14, double tablet = 16, double desktop = 18}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Responsive Grid Columns
  static int getResponsiveColumns(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Additional Gradients

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF),
      Color(0x0DFFFFFF),
    ],
  );


  // Typography
  static const String fontFamily = 'Poppins';

  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: textLight,
    height: 1.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    height: 1.2,
  );

  // Spacing
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 350);

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryMauve,
        brightness: Brightness.light,
        primary: primaryMauve,
        secondary: accentGold,
        surface: backgroundWhite,
        background: backgroundWhite,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: headingMedium,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMauve,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryMauve,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing12,
          ),
          textStyle: bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: primaryMauve,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryMauve, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing16,
        ),
        hintStyle: bodyMedium.copyWith(color: textLight),
        labelStyle: bodyMedium.copyWith(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        margin: const EdgeInsets.all(spacing8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: primaryMauve,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Custom Page Transitions
  static PageRouteBuilder<T> fadeSlideRoute<T extends Object?>(
    Widget page, {
    Duration duration = animationMedium,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.1);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeAnimation),
            child: child,
          ),
        );
      },
    );
  }

  // Premium Glassmorphism Helpers
  static Widget glassCard({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 20.0,
    double blur = 20.0,
    Color? backgroundColor,
    List<BoxShadow>? shadows,
    VoidCallback? onTap,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: backgroundColor ?? surfaceMedium,
              border: Border.all(
                color: glassBorder,
                width: 1.0,
              ),
              boxShadow: shadows ?? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget glassButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isOutlined = false,
    IconData? icon,
    double borderRadius = 16.0,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: isOutlined ? null : primaryGradient,
        border: isOutlined ? Border.all(color: glassBorder, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: primaryMauve.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: textColor ?? Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: buttonText.copyWith(
                      color: textColor ?? Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget elevatedGlass({
    required Widget child,
    double elevation = 8.0,
    double borderRadius = 20.0,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: glassCard(
        borderRadius: borderRadius,
        padding: padding,
        child: child,
      ),
    );
  }
}
