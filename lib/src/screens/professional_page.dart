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
          brightness: Brightness.dark, // Tema oscuro
          primaryColor: Colors.blue,
          colorScheme: ColorScheme.dark().copyWith(
            secondary: Colors.blueAccent, // Reemplazo de accentColor
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.white), // Reemplazo de bodyText1
            bodyMedium: TextStyle(color: Colors.white), // Reemplazo de bodyText2
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
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Controladores para los campos de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _chronicDiseasesController = TextEditingController();
  final TextEditingController _currentMedicationsController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    _chronicDiseasesController.dispose();
    _currentMedicationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Professional Page'),
      ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Text(
                  'Welcome to the Professional Page!',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                SizedBox(height: 20),
                Flexible(
                  child: ListView(
                    children: <Widget>[
                      ListTile(
                        leading: Icon(Icons.check, color: Colors.white),
                        title: Text('Skill 1', style: TextStyle(color: Colors.white)),
                      ),
                      ListTile(
                        leading: Icon(Icons.check, color: Colors.white),
                        title: Text('Skill 2', style: TextStyle(color: Colors.white)),
                      ),
                      ListTile(
                        leading: Icon(Icons.check, color: Colors.white),
                        title: Text('Skill 3', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Implementar lógica de navegación
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AnotherPage()),
                    );
                  },
                  child: Text('Go to Next Page'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Página de ejemplo para navegación
class AnotherPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Another Page'),
      ),
      body: Center(
        child: Text('This is the next page'),
      ),
    );
  }
}
