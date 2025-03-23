import 'package:Psiconnect/core/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
      color: Color.fromARGB(255, 202, 235,
          248), // Color de fondo para la sección de características
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Text(
              "Ventajas",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                  color: Color.fromRGBO(47, 67, 88, 1.0)),
            ),
            SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Text(
                'Un sistema simple, moderno, potente y seguro',
                style: TextStyle(
                    fontSize: 20, color: Color.fromRGBO(47, 67, 88, 1.0)),
              ),
            ),
            SizedBox(height: 24), // Espacio vertical de 24 píxeles
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Distribuye los contenedores con espacio entre ellos
              children: [
                Container(
                  width: (width - (horizontalPadding * 2) - 48) /
                      3, // Ajusta el ancho de cada contenedor
                  height: 200, // Altura de cada contenedor
                  decoration: BoxDecoration(
                    color: Colors.white, // Fondo blanco
                    borderRadius:
                        BorderRadius.circular(8), // Bordes redondeados
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/ventajas/rayo_ventajas.png',
                          height: 50, // Ajusta la altura de la imagen
                        ),
                        SizedBox(
                            height: 8), // Espacio entre la imagen y el título
                        Text(
                          'Intuitivo',
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.black), // Estilo del texto
                        ),
                        SizedBox(
                            height:
                                8), // Espacio entre el texto principal y el subtítulo
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0), // Añade padding horizontal
                          child: Text(
                            'Nos enfocamos en la experiencia de usuario de los profesionales de la salud',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey), // Estilo del subtítulo
                            textAlign: TextAlign.center, // Centra el texto
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: (width - (horizontalPadding * 2) - 48) /
                      3, // Ajusta el ancho de cada contenedor
                  height: 200, // Altura de cada contenedor
                  decoration: BoxDecoration(
                    color: Colors.white, // Fondo blanco
                    borderRadius:
                        BorderRadius.circular(8), // Bordes redondeados
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/ventajas/reloj_ventajas.png',
                          height: 50, // Ajusta la altura de la imagen
                        ),
                        SizedBox(
                            height: 8), // Espacio entre la imagen y el título
                        Text(
                          'Ahorro de tiempo',
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.black), // Estilo del texto
                        ),
                        SizedBox(
                            height:
                                8), // Espacio entre el texto principal y el subtítulo
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0), // Añade padding horizontal
                          child: Text(
                            'Desarrollamos las funcionalidades para optimizar el recurso más preciado de todas las personas: El tiempo',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey), // Estilo del subtítulo
                            textAlign: TextAlign.center, // Centra el texto
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: (width - (horizontalPadding * 2) - 48) /
                      3, // Ajusta el ancho de cada contenedor
                  height: 200, // Altura de cada contenedor
                  decoration: BoxDecoration(
                    color: Colors.white, // Fondo blanco
                    borderRadius:
                        BorderRadius.circular(8), // Bordes redondeados
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/ventajas/red_ventajas.png',
                          height: 50, // Ajusta la altura de la imagen
                        ),
                        SizedBox(
                            height: 8), // Espacio entre la imagen y el título
                        Text(
                          '100% en línea',
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.black), // Estilo del texto
                        ),
                        SizedBox(
                            height:
                                8), // Espacio entre el texto principal y el subtítulo
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0), // Añade padding horizontal
                          child: Text(
                            'Podés utilizarlo desde cualquier dispositivo, en cualquier momento y en cualquier lugar, sin la necesidad de realizar ninguna instalación',
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey), // Estilo del subtítulo
                            textAlign: TextAlign.center, // Centra el texto
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24), // Espacio vertical de 24 píxeles
            Container(
              width: double.infinity, // Ocupa todo el ancho disponible
              padding: EdgeInsets.all(
                  16.0), // Añade padding alrededor del contenedor
              decoration: BoxDecoration(
                color: Colors.white, // Fondo blanco
                borderRadius: BorderRadius.circular(8), // Bordes redondeados
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Espacio entre las dos columnas
                children: [
                  // Columna izquierda con el título y los 7 ítems
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Por qué PsiConnect?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 50,
                              color: Color.fromRGBO(
                                  47, 67, 88, 1.0)), // Estilo del título
                        ),
                        SizedBox(
                            height: 16), // Espacio entre el título y los ítems
                        Text(
                            'Gestioná los turnos fácilmente con nuestra Agenda, y programá los turnos recurrentes que se repiten semanalmente/mensualmente.',
                            style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8), // Espacio entre los ítems
                        Text(
                            'Envía notificaciones por WhatsApp de recordatorios de turnos, sesiones, pagos, entre otras.',
                            style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8),
                        Text(
                            'Determiná el estado de las sesiones rápidamente con los filtros.',
                            style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8),
                        Text(
                            'Descargá rápidamente las historias clínicas de los pacientes.',
                            style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8),
                        Text(
                            'Actualizá y accedé a los archivos de los pacientes rápidamente (imágenes, fotos, documentos PDF).',
                            style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8),
                        Text(
                            'Ofrecé sesiones virtuales desde el sistema mediante videollamadas.',
                            style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8),
                        Text(
                            'Utilizá la aplicación móvil cuando te sea conveniente.',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  // Columna derecha con la imagen
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: 200, // Ajusta el ancho de la imagen
                      height: 500, // Ajusta la altura de la imagen
                      child: Image.asset(
                        'assets/images/ventajas/pq_psiconnect_ventajas.png', // Ruta de la imagen
                        fit: BoxFit
                            .cover, // Ajusta la imagen para cubrir el espacio disponible
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
