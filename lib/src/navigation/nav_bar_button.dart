import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NavBarButton extends HookConsumerWidget {
  final VoidCallback onTap;
  final String text;
  final Color hoverColor;
  final Color defaultColor;
  final double fontSize;

  const NavBarButton({
    Key? key,
    required this.onTap,
    required this.text,
    this.hoverColor = Colors.blue,
    this.defaultColor = Colors.black,
    this.fontSize = 15.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = useState<Color>(defaultColor);

    return Semantics(
      label: text,
      button: true,
      child: MouseRegion(
        onEnter: (_) => textColor.value = hoverColor,
        onExit: (_) => textColor.value = defaultColor,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(5),
            child: Container(
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: textColor.value, width: 1.2),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: textColor.value,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
