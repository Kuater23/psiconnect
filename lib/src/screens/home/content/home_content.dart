import 'package:Psiconnect/src/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

const googlePlayURL =
    'https://play.google.com/store/apps/details?id=com.google.android.youtube';
const appStoreURL = 'https://apps.apple.com/tw/app/youtube/id544007664';

class HomeContent extends ResponsiveWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget buildDesktop(BuildContext context) => DesktopHomeContent();

  @override
  Widget buildMobile(BuildContext context) => MobileHomeContent();
}

class DesktopHomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Container(
      height: height * .65,
      width: width, // Ocupar todo el ancho disponible
      child: Row(
        children: [
          Expanded(
            flex: 1, // Proporciona espacio para la imagen
            child: Align(
              alignment: Alignment.bottomRight,
              child: Image.asset('assets/images/app_screen.png',
                  fit: BoxFit.contain),
            ),
          ),
          SizedBox(width: 24),
          Expanded(
            flex: 2, // Proporciona más espacio para el contenido de texto
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Software para psicólogos y consultorios",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      color: Color.fromRGBO(47, 67, 88, 1.0)),
                ),
                SizedBox(height: 24),
                Text(
                  'Administrá tus pacientes, historias clínicas, agenda, archivos, turnos, sesiones, videollamadas, pagos, notificaciones de WhatsApp y mucho más de una manera simple y eficaz.',
                  style: TextStyle(
                      fontSize: 20, color: Color.fromRGBO(47, 67, 88, 1.0)),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => launchUrlString(googlePlayURL),
                      child: Image.asset(
                        'assets/images/google_play_badge.png',
                        height: 60,
                        width: 200,
                      ),
                    ),
                    SizedBox(width: 24),
                    GestureDetector(
                      onTap: () => launchUrlString(appStoreURL),
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
          )
        ],
      ),
    );
  }
}

class MobileHomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Psiconnect",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 40,
                color: Color.fromRGBO(47, 67, 88, 1.0)),
          ),
          SizedBox(height: 24),
          Text(
            'Administrá tus pacientes, historias clínicas, agenda, archivos, turnos, sesiones, videollamadas, pagos, notificaciones de WhatsApp y mucho más de una manera simple y eficaz.',
            style:
                TextStyle(fontSize: 20, color: Color.fromRGBO(47, 67, 88, 1.0)),
          ),
          SizedBox(height: 24),
          GestureDetector(
            onTap: () => launchUrlString(googlePlayURL),
            child: Image.asset(
              'assets/images/google_play_badge.png',
              height: 60,
              width: 200,
            ),
          ),
          SizedBox(height: 24),
          GestureDetector(
            onTap: () => launchUrlString(appStoreURL),
            child: Image.asset(
              'assets/images/app_store_badge.png',
              height: 60,
              width: 200,
            ),
          ),
          SizedBox(height: 48),
          Image.asset(
            'assets/images/app_screen.png',
            height: 350,
          ),
        ],
      ),
    );
  }
}
