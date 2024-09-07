import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NavBarButton extends HookConsumerWidget {
  final VoidCallback onTap;
  final String text;
  final Color hoverColor;
  final Color defaultColor;

  const NavBarButton({
    Key? key,
    required this.onTap,
    required this.text,
    this.hoverColor = Colors.blue,
    this.defaultColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = useState<Color>(defaultColor);

    return Semantics(
      label: text,
      button: true,
      child: MouseRegion(
        onEnter: (value) {
          textColor.value = hoverColor;
        },
        onExit: (value) {
          textColor.value = defaultColor;
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 30,
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
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
