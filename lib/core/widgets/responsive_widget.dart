// lib/core/widgets/responsive_widget.dart

import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 960;
  static const double desktop = 1280;
  static const double largeDesktop = 1440;
}

/// Enum representing different layout sizes
enum LayoutSize {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Base class for responsive widgets in the application
abstract class ResponsiveWidget extends StatelessWidget {
  const ResponsiveWidget({Key? key}) : super(key: key);

  /// Build method for mobile layouts
  Widget buildMobile(BuildContext context);

  /// Build method for tablet layouts
  Widget buildTablet(BuildContext context) => buildMobile(context);

  /// Build method for desktop layouts
  Widget buildDesktop(BuildContext context);

  /// Build method for large desktop layouts
  Widget buildLargeDesktop(BuildContext context) => buildDesktop(context);

  /// Determine current layout size based on width
  static LayoutSize getLayoutSize(double width) {
    if (width < ResponsiveBreakpoints.mobile) {
      return LayoutSize.mobile;
    } else if (width < ResponsiveBreakpoints.tablet) {
      return LayoutSize.tablet;
    } else if (width < ResponsiveBreakpoints.desktop) {
      return LayoutSize.desktop;
    } else {
      return LayoutSize.largeDesktop;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layoutSize = getLayoutSize(width);

        switch (layoutSize) {
          case LayoutSize.mobile:
            return buildMobile(context);
          case LayoutSize.tablet:
            return buildTablet(context);
          case LayoutSize.desktop:
            return buildDesktop(context);
          case LayoutSize.largeDesktop:
            return buildLargeDesktop(context);
        }
      },
    );
  }
}

/// A responsive container that changes its padding and width based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final EdgeInsetsGeometry? desktopPadding;
  final double? mobileMaxWidth;
  final double? tabletMaxWidth;
  final double? desktopMaxWidth;
  final Color? backgroundColor;
  final Alignment alignment;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.mobilePadding = const EdgeInsets.all(16),
    this.tabletPadding = const EdgeInsets.all(24),
    this.desktopPadding = const EdgeInsets.all(32),
    this.mobileMaxWidth,
    this.tabletMaxWidth = 768,
    this.desktopMaxWidth = 1200,
    this.backgroundColor,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final layoutSize = ResponsiveWidget.getLayoutSize(width);

        EdgeInsetsGeometry padding;
        double? maxWidth;

        switch (layoutSize) {
          case LayoutSize.mobile:
            padding = mobilePadding ?? EdgeInsets.all(16);
            maxWidth = mobileMaxWidth;
            break;
          case LayoutSize.tablet:
            padding = tabletPadding ?? EdgeInsets.all(24);
            maxWidth = tabletMaxWidth;
            break;
          case LayoutSize.desktop:
          case LayoutSize.largeDesktop:
            padding = desktopPadding ?? EdgeInsets.all(32);
            maxWidth = desktopMaxWidth;
            break;
        }

        return Container(
          width: double.infinity,
          color: backgroundColor,
          alignment: alignment,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? double.infinity,
            ),
            padding: padding,
            child: child,
          ),
        );
      },
    );
  }
}

/// A widget that shows different content based on the screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, LayoutSize) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutSize = ResponsiveWidget.getLayoutSize(constraints.maxWidth);
        return builder(context, layoutSize);
      },
    );
  }
}

/// Extensions to check current layout size
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveWidget.getLayoutSize(MediaQuery.of(this).size.width) == LayoutSize.mobile;
  bool get isTablet => ResponsiveWidget.getLayoutSize(MediaQuery.of(this).size.width) == LayoutSize.tablet;
  bool get isDesktop => ResponsiveWidget.getLayoutSize(MediaQuery.of(this).size.width) == LayoutSize.desktop;
  bool get isLargeDesktop => ResponsiveWidget.getLayoutSize(MediaQuery.of(this).size.width) == LayoutSize.largeDesktop;
  
  bool get isMobileOrTablet => isMobile || isTablet;
  bool get isDesktopOrLarger => isDesktop || isLargeDesktop;
}