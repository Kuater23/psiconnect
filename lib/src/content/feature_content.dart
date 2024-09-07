import 'package:Psiconnect/src/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const youtubeVideo = 'https://www.youtube.com/embed/k32xyP3KuWE';

final _webController = WebViewController()
  ..loadRequest(Uri.parse(youtubeVideo));

class FeaturesContent extends ResponsiveWidget {
  FeaturesContent({Key? key}) : super(key: key);

  @override
  Widget buildDesktop(BuildContext context) => FeaturesContentResponsive(200);

  @override
  Widget buildMobile(BuildContext context) => FeaturesContentResponsive(24);
}

class FeaturesContentResponsive extends StatelessWidget {
  final double horizontalPadding;

  const FeaturesContentResponsive(this.horizontalPadding);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Container(
      width: width, // Ocupar todo el ancho disponible
      color: Colors.blue, // Color de fondo para la sección de características
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Text(
              "Features Section",
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
            Container(
              width: 800,
              height: 450,
              child: WebViewWidget(
                controller: _webController,
              ),
            )
          ],
        ),
      ),
    );
  }
}
