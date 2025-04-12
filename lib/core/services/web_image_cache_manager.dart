// lib/core/services/web_image_cache_manager.dart

import 'package:Psiconnect/core/widgets/storage_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/core/services/error_logger.dart';

/// Manager for web-optimized image caching
class WebImageCacheManager {
  // Singleton pattern
  static final WebImageCacheManager _instance = WebImageCacheManager._internal();
  factory WebImageCacheManager() => _instance;
  WebImageCacheManager._internal();
  
  // In-memory cache for images
  final Map<String, Image> _memoryCache = {};
  
  /// Get image from cache or network with optimized loading
  Widget getOptimizedImage({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Duration cacheDuration = const Duration(days: 7),
    bool useMemoryCache = true,
  }) {
    if (!kIsWeb) {
      // For non-web platforms, use CachedNetworkImage
      return CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => 
            placeholder ?? _defaultPlaceholder(width, height),
        errorWidget: (context, url, error) => 
            errorWidget ?? _defaultErrorWidget(width, height),
      );
    }
    
    // For web, optimize further
    if (useMemoryCache && _memoryCache.containsKey(url)) {
      return SizedBox(
        width: width,
        height: height,
        child: _memoryCache[url]!,
      );
    }
    
    // Optimize URL for Firebase Storage images
    String optimizedUrl = _getOptimizedUrl(url, width: width?.toInt(), height: height?.toInt());
    
    return Image.network(
      optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Cache image in memory on successful load
          if (useMemoryCache && !_memoryCache.containsKey(url)) {
            _memoryCache[url] = Image.network(
              optimizedUrl,
              fit: fit,
              width: width,
              height: height,
            );
          }
          return child;
        }
        return placeholder ?? _defaultPlaceholder(width, height);
      },
      errorBuilder: (context, error, stackTrace) {
        ErrorLogger.logError(
          'Error loading image', 
          error, 
          stackTrace!,
          additionalData: {'url': url}
        );
        return errorWidget ?? _defaultErrorWidget(width, height);
      },
    );
  }
  
  /// Default placeholder widget
  Widget _defaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }
  
  /// Default error widget
  Widget _defaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 24,
        ),
      ),
    );
  }
  
  /// Optimize image URL for Firebase Storage
  String _getOptimizedUrl(String url, {int? width, int? height}) {
    if (!url.startsWith('http')) return url;
    
    try {
      if (url.contains('firebasestorage.googleapis.com')) {
        final Uri uri = Uri.parse(url);
        final params = Map<String, String>.from(uri.queryParameters);
        
        if (width != null) params['width'] = width.toString();
        if (height != null) params['height'] = height.toString();
        
        return uri.replace(queryParameters: params).toString();
      }
    } catch (e) {
      ErrorLogger.logEvent(
        'Failed to optimize image URL',
        parameters: {'url': url, 'error': e.toString()},
        level: LogLevel.warning,
      );
    }
    
    return url;
  }
  
  /// Clear memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
  }
  
  /// Remove specific image from cache
  void removeFromCache(String url) {
    _memoryCache.remove(url);
  }
}

/// Widget for optimized image loading
class OptimizedNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useMemoryCache;
  
  const OptimizedNetworkImage({
    Key? key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.useMemoryCache = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return WebImageCacheManager().getOptimizedImage(
      url: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      useMemoryCache: useMemoryCache,
    );
  }
}