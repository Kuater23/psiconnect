// lib/navigation/nav_bar_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// A styled button component for navigation elements
class NavBarButton extends HookConsumerWidget {
  final VoidCallback onTap;
  final String text;
  final Color? hoverColor;
  final Color? defaultColor;
  final bool isActive;
  final IconData? icon;
  final bool useUnderline;
  final EdgeInsets padding;

  const NavBarButton({
    Key? key,
    required this.onTap,
    required this.text,
    this.hoverColor,
    this.defaultColor,
    this.isActive = false,
    this.icon,
    this.useUnderline = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get colors from theme if not provided
    final theme = Theme.of(context);
    final actualDefaultColor = defaultColor ?? theme.colorScheme.onPrimary;
    final actualHoverColor = hoverColor ?? theme.colorScheme.secondary;
    
    // Track hover state with hooks
    final isHovered = useState<bool>(false);
    final isFocused = useState<bool>(false);
    
    // Determine current text color based on state
    Color textColor = actualDefaultColor;
    if (isActive) {
      textColor = theme.colorScheme.secondary;
    } else if (isHovered.value || isFocused.value) {
      textColor = actualHoverColor;
    }

    return Semantics(
      label: text,
      button: true,
      enabled: true,
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => isHovered.value = true,
        onExit: (_) => isHovered.value = false,
        child: Focus(
          onFocusChange: (hasFocus) => isFocused.value = hasFocus,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                border: useUnderline 
                  ? Border(
                      bottom: BorderSide(
                        color: isActive || isHovered.value || isFocused.value
                          ? actualHoverColor 
                          : Colors.transparent,
                        width: 2.0,
                      ),
                    )
                  : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: textColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive || isHovered.value
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A button specifically for mobile navigation
class MobileNavButton extends HookConsumerWidget {
  final VoidCallback onTap;
  final String text;
  final IconData? icon;
  final bool isActive;
  
  const MobileNavButton({
    Key? key,
    required this.onTap,
    required this.text,
    this.icon,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: icon != null 
          ? Icon(
              icon, 
              color: isActive 
                  ? theme.colorScheme.secondary 
                  : theme.colorScheme.onSurface,
            ) 
          : null,
      title: Text(
        text,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive 
              ? theme.colorScheme.secondary 
              : theme.colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
      tileColor: isActive ? theme.colorScheme.secondary.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}