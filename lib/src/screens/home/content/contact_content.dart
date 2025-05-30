import 'package:Psiconnect/src/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

const address =
    'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d101408.21722940235!2d-122.15130702796334!3d37.41331444145766!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x808fb7495bec0189%3A0x7c17d44a466baf9b!2sMountain%20View%2C%20CA%2C%20USA!5e0!3m2!1sen!2stw!4v1613513352653!5m2!1sen!2stw';

final _webController = WebViewController()..loadRequest(Uri.parse(address));

class ContactContent extends ResponsiveWidget {
  ContactContent({Key? key}) : super(key: key);

  @override
  Widget buildDesktop(BuildContext context) => DesktopContactContent();

  @override
  Widget buildMobile(BuildContext context) => MobileContactContent();
}

class DesktopContactContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      color: Colors.blue, // Fondo azul para distinguir la sección
      width: width, // Ocupar todo el ancho disponible
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: width * .4, // Ajustar el ancho para el contenido de texto
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Contact Information Section",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 25),
                  Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                    style: TextStyle(color: Colors.white), // Texto en blanco
                  ),
                ],
              ),
            ),
            SizedBox(width: 24),
            Container(
              height: 400,
              width: 400,
              child: WebViewWidget(
                controller: _webController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MobileContactContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Container(
      color: Colors.blue, // Fondo azul para móviles
      width: width, // Ocupar todo el ancho disponible en móviles
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Contact Information Section",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 40,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 25),
            Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
              style: TextStyle(color: Colors.white), // Texto en blanco
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Container(
              height: 400,
              width: width * 0.9, // Ajustar el tamaño para móviles
              child: WebViewWidget(
                controller: _webController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
