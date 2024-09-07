import 'package:Psiconnect/src/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';

class ScreenshotsContent extends ResponsiveWidget {
  const ScreenshotsContent({Key? key}) : super(key: key);

  @override
  Widget buildDesktop(BuildContext context) =>
      ScreenshotsContentResponsive(200);

  @override
  Widget buildMobile(BuildContext context) => ScreenshotsContentResponsive(24);
}

class ScreenshotsContentResponsive extends StatelessWidget {
  final double horizontalPadding;

  const ScreenshotsContentResponsive(this.horizontalPadding);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Container(
      width: width, // Ocupar todo el ancho disponible
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Text(
              "Screenshots Section",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
            ),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              ),
            ),
            SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Image(image: "assets/images/screenshots/screen1.png"),
                  _Image(image: "assets/images/screenshots/screen2.png"),
                  _Image(image: "assets/images/screenshots/screen3.png"),
                  _Image(image: "assets/images/screenshots/screen4.png"),
                  _Image(image: "assets/images/screenshots/screen5.png"),
                  _Image(image: "assets/images/screenshots/screen6.png"),
                  _Image(image: "assets/images/screenshots/screen7.png"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Image extends StatelessWidget {
  final String image;

  const _Image({Key? key, required this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 16),
        Image.asset(image),
        SizedBox(width: 16),
      ],
    );
  }
}
