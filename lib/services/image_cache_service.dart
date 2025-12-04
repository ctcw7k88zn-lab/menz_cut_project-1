import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ImageCacheService {
  static const Duration cacheDuration = Duration(days: 7);
  
  static Widget cachedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    // Validate image URL
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: errorWidget ?? _defaultErrorWidget(),
      );
    }
    
    // Use CachedNetworkImage with proper error suppression
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
        errorWidget: (context, url, error) {
          // Suppress error - log in debug but never show text to user
          if (kDebugMode) {
            print('Image load error (suppressed): $url');
          }
          // Return error widget with proper sizing - no text ever
          return Container(
            width: width ?? double.infinity,
            height: height ?? double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: borderRadius ?? BorderRadius.zero,
            ),
            child: errorWidget ?? _defaultErrorWidget(),
          );
        },
        memCacheWidth: width != null && width.isFinite ? width.toInt() : null,
        memCacheHeight: height != null && height.isFinite ? height.toInt() : null,
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 800,
        httpHeaders: const {
          'Accept': 'image/*',
        },
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        useOldImageOnUrlChange: true,
      ),
    );
  }

  static Widget _defaultPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  static Widget _defaultErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  static Widget profileImage({
    required String imageUrl,
    double size = 50,
    BorderRadius? borderRadius,
  }) {
    return cachedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: borderRadius ?? BorderRadius.circular(size / 2),
      placeholder: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: const Icon(
          Icons.person,
          color: Colors.grey,
          size: 24,
        ),
      ),
      errorWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: const Icon(
          Icons.person,
          color: Colors.grey,
          size: 24,
        ),
      ),
    );
  }

  static Widget salonImage({
    required String imageUrl,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    // Handle empty or invalid URLs
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.store,
            color: Colors.grey,
            size: 32,
          ),
        ),
      );
    }
    
    return cachedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      placeholder: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.store,
            color: Colors.grey,
            size: 32,
          ),
        ),
      ),
      errorWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(
            Icons.store,
            color: Colors.grey,
            size: 32,
          ),
        ),
      ),
    );
  }

  static void clearCache() {
    CachedNetworkImage.evictFromCache('');
  }

  static Future<void> preloadImage(String imageUrl) async {
    await precacheImage(
      CachedNetworkImageProvider(imageUrl),
      NavigationService.navigatorKey.currentContext!,
    );
  }
}

// Navigation service for context access
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
