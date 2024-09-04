import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blue,
          colorScheme: ColorScheme.dark().copyWith(
            secondary: Colors.blueAccent,
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
          ),
        ),
        home: ProfessionalPage(),
      ),
    );
  }
}

class ProfessionalPage extends ConsumerStatefulWidget {
  @override
  _ProfessionalPageState createState() => _ProfessionalPageState();
}

class _ProfessionalPageState extends ConsumerState<ProfessionalPage> {
  final PageController _pageController = PageController();
  String _pageTitle = 'Professional Page'; // Título de la página

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onMenuItemSelected(int pageIndex, String title) {
    setState(() {
      _pageTitle = title;
    });
    _pageController.jumpToPage(pageIndex);
    Navigator.pop(context); // Cerrar el drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
      ),
      drawer: _buildDrawer(context),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(), // Deshabilita el swipe
        children: [
          _buildSection('Professional Home', Colors.black),
          _buildSection('Información Profesional', Colors.blueGrey),
          _buildSection('Horarios de Atención', Colors.green),
          _buildSection('Lista de Pacientes', Colors.orange),
          _buildSection('Calendario', Colors.purple),
        ],
      ),
    );
  }

  // Drawer (Menú lateral) para la ProfessionalPage
  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Profesional',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: Text('Professional Home'),
            onTap: () => _onMenuItemSelected(0, 'Professional Page'),
          ),
          ListTile(
            title: Text('Información Profesional'),
            onTap: () => _onMenuItemSelected(1, 'Información Profesional'),
          ),
          ListTile(
            title: Text('Horarios de Atención'),
            onTap: () => _onMenuItemSelected(2, 'Horarios de Atención'),
          ),
          ListTile(
            title: Text('Lista de Pacientes'),
            onTap: () => _onMenuItemSelected(3, 'Lista de Pacientes'),
          ),
          ListTile(
            title: Text('Calendario'),
            onTap: () => _onMenuItemSelected(4, 'Calendario'),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: EdgeInsets.symmetric(vertical: 15.0),
              ),
              child: Text(
                'SALIR',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sección para cada opción del menú con diferentes colores de fondo
  Widget _buildSection(String title, Color color) {
    return Container(
      color: color,
      child: Center(
        child: Text(
          title,
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
