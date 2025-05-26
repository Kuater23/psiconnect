// lib/core/services/web_image_optimizer.dart

import 'package:Psiconnect/core/widgets/storage_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/core/services/error_logger.dart';

/// Service for optimizing image loading in web environments
class WebImageOptimizer {
  /// Get optimized image URL based on web display context
  static String getOptimizedUrl(String originalUrl, {
    int? width,
    int? height,
    ImageQuality quality = ImageQuality.medium,
  }) {
    // If not on web, return original URL
    if (!kIsWeb) return originalUrl;

    // If it's a local asset, we can't optimize
    if (!originalUrl.startsWith('http')) return originalUrl;

    try {
      // For Firebase Storage images, we can use URL parameters
      if (originalUrl.contains('firebasestorage.googleapis.com')) {
        final Uri uri = Uri.parse(originalUrl);
        final queryParams = Map<String, String>.from(uri.queryParameters);
        
        // Add optimization parameters
        if (width != null) queryParams['width'] = width.toString();
        if (height != null) queryParams['height'] = height.toString();
        queryParams['quality'] = _getQualityValue(quality).toString();
        
        // Build optimized URL
        final optimizedUri = uri.replace(queryParameters: queryParams);
        return optimizedUri.toString();
      }
    } catch (e) {
      ErrorLogger.logEvent(
        'Image URL optimization failed',
        parameters: {'url': originalUrl, 'error': e.toString()},
        level: LogLevel.warning,
      );
    }
    
    // For other URLs, return original
    return originalUrl;
  }
  
  /// Convert quality enum to numeric value
  static int _getQualityValue(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.low:
        return 60; // Lower quality, smaller size
      case ImageQuality.medium:
        return 80; // Balanced quality
      case ImageQuality.high:
        return 95; // High quality, larger size
    }
  }
  
  /// Widget that optimizes image loading for web with lazy loading
  static Widget optimizedNetworkImage({
    required String url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    ImageQuality quality = ImageQuality.medium,
  }) {
    // Convert dimensions to integers for URL
    final int? intWidth = width?.toInt();
    final int? intHeight = height?.toInt();
    
    // Get optimized URL
    final optimizedUrl = getOptimizedUrl(
      url,
      width: intWidth,
      height: intHeight,
      quality: quality,
    );
    
    // In web, implement lazy loading
    if (kIsWeb) {
      return _WebLazyImage(
        url: optimizedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }
    
    // Fallback for non-web (should not happen in this web-only app)
    return Image.network(
      optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _defaultPlaceholder(width, height);
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _defaultErrorWidget(width, height);
      },
    );
  }
  
  /// Default placeholder
  static Widget _defaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
        ),
      ),
    );
  }
  
  /// Default error widget
  static Widget _defaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.red[300],
          size: 24,
        ),
      ),
    );
  }
}

/// Enum for image quality
enum ImageQuality {
  low,
  medium,
  high,
}

/// Internal widget for lazy loading images in web
class _WebLazyImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const _WebLazyImage({
    required this.url,
    this.width,
    this.height,
    required this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  _WebLazyImageState createState() => _WebLazyImageState();
}

class _WebLazyImageState extends State<_WebLazyImage> {
  bool _isInView = false;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Simulate lazy loading with a small delay
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isInView = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInView) {
      return widget.placeholder ?? 
             WebImageOptimizer._defaultPlaceholder(widget.width, widget.height);
    }

    if (_hasError) {
      return widget.errorWidget ?? 
             WebImageOptimizer._defaultErrorWidget(widget.width, widget.height);
    }

    return Stack(
      children: [
        // Placeholder while loading
        if (!_isLoaded)
          widget.placeholder ?? 
          WebImageOptimizer._defaultPlaceholder(widget.width, widget.height),
        
        // Actual image
        Opacity(
          opacity: _isLoaded ? 1.0 : 0.0,
          child: Image.network(
            widget.url,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                // Image fully loaded
                if (!_isLoaded && mounted) {
                  // Small delay for smooth animation
                  Future.delayed(Duration(milliseconds: 30), () {
                    if (mounted) {
                      setState(() {
                        _isLoaded = true;
                      });
                    }
                  });
                }
                return child;
              }
              return const SizedBox.shrink(); // Don't show anything while loading
            },
            errorBuilder: (context, error, stackTrace) {
              // Mark error and show error widget
              if (mounted) {
                setState(() {
                  _hasError = true;
                });
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}