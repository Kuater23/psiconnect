import 'package:Psiconnect/src/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  final String googlePlayURL =
      'https://play.google.com/store/apps/details?id=com.example.app';
  final String appStoreURL =
      'https://apps.apple.com/us/app/example-app/id123456789';

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Container(
      width: width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/screenshots/fondo.png',
              fit: BoxFit.cover,
            ),
          ),
          // Contenido centrado
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                          200, 202, 235, 248), // Fondo semi-transparente
                      borderRadius:
                          BorderRadius.circular(16), // Bordes redondeados
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20), // Espaciado interno ajustado
                    child: Text(
                      "Organizá tu Agenda desde tablets o smartphones",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 48, // Tamaño más grande para el título
                        color: Color.fromRGBO(
                            47, 67, 88, 1.0), // Color especificado
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                          200, 202, 235, 248), // Fondo semi-transparente
                      borderRadius:
                          BorderRadius.circular(16), // Bordes redondeados
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20), // Espaciado interno ajustado
                    child: Text(
                      "Vas de poder administrar todo desde cualquier dispositivo. ¡Lo que más comodo te resulte en el momento!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32, // Tamaño más grande para el subtítulo
                        color: Color.fromRGBO(
                            47, 67, 88, 1.0), // Color especificado
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _launchURL(googlePlayURL),
                        child: Image.asset(
                          'assets/images/google_play_badge.png',
                          height: 60,
                          width: 200,
                        ),
                      ),
                      SizedBox(width: 24),
                      GestureDetector(
                        onTap: () => _launchURL(appStoreURL),
                        child: Image.asset(
                          'assets/images/app_store_badge.png',
                          height: 60,
                          width: 200,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
