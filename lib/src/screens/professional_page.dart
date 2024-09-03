import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for locale initialization

void main() async {
  // Ensure that all binding is initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for the desired locale
  await initializeDateFormatting('es_ES', null);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark, // Use dark theme
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
        color: Colors.black, // Set the background color to black
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Text(
                  'Welcome to the Professional Page!',
                  style: TextStyle(fontSize: 24, color: Colors.white), // Set text color to white
                ),
                SizedBox(height: 20),
                Flexible(
                  child: ListView(
                    children: <Widget>[
                      ListTile(
                        leading: Icon(Icons.check, color: Colors.white), // Set icon color to white
                        title: Text('Skill 1', style: TextStyle(color: Colors.white)), // Set text color to white
                      ),
                      ListTile(
                        leading: Icon(Icons.check, color: Colors.white), // Set icon color to white
                        title: Text('Skill 2', style: TextStyle(color: Colors.white)), // Set text color to white
                      ),
                      ListTile(
                        leading: Icon(Icons.check, color: Colors.white), // Set icon color to white
                        title: Text('Skill 3', style: TextStyle(color: Colors.white)), // Set text color to white
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to another page
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
