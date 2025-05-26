import 'package:flutter/material.dart';
import 'package:Psiconnect/src/services/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:Psiconnect/src/providers/session_provider.dart';
import 'package:Psiconnect/src/screens/home/content/home_page.dart';
import 'package:Psiconnect/src/navigation/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider para manejar el estado del rol del usuario.
final userRoleStateProvider =
    StateNotifierProvider<UserRoleNotifier, String?>((ref) {
  return UserRoleNotifier();
});

class UserRoleNotifier extends StateNotifier<String?> {
  UserRoleNotifier() : super(null) {
    _initializeRole();
  }

  Future<void> _initializeRole() async {
    print('[UserRoleNotifier] Inicializando rol del usuario...');
    final role = await getCurrentRole();
    print('[UserRoleNotifier] Rol inicial obtenido: $role');
    state = role;
  }

  Future<String?> getCurrentRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('[UserRoleNotifier] No hay usuario autenticado.');
        return null;
      }
      print('[UserRoleNotifier] Usuario autenticado: ${user.uid}');

      // Consultar la colección de doctors.
      print('[UserRoleNotifier] Consultando colección "doctors" para el UID: ${user.uid}');
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();
      print('[UserRoleNotifier] doctorDoc.exists: ${doctorDoc.exists}');
      if (doctorDoc.exists) {
        print('[UserRoleNotifier] Rol determinado: professional');
        return 'professional';
      }

      // Consultar la colección de patients.
      print('[UserRoleNotifier] Consultando colección "patients" para el UID: ${user.uid}');
      final patientDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .get();
      print('[UserRoleNotifier] patientDoc.exists: ${patientDoc.exists}');
      if (patientDoc.exists) {
        print('[UserRoleNotifier] Rol determinado: patient');
        return 'patient';
      }

      print('[UserRoleNotifier] No se encontró documento en ninguna colección para el UID: ${user.uid}');
      return null;
    } catch (e) {
      print('[UserRoleNotifier] Error al obtener el rol del usuario: $e');
      return null;
    }
  }

  void clearRole() {
    print('[UserRoleNotifier] Limpiando rol del usuario.');
    state = null;
  }

  Future<void> refreshRole() async {
    print('[UserRoleNotifier] Actualizando rol del usuario...');
    final newRole = await getCurrentRole();
    print('[UserRoleNotifier] Rol actualizado: $newRole');
    state = newRole;
  }
}

class SharedDrawer extends ConsumerStatefulWidget {
  final VoidCallback toggleTheme;

  const SharedDrawer({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _SharedDrawerState createState() => _SharedDrawerState();
}

class _SharedDrawerState extends ConsumerState<SharedDrawer> {
  @override
  void initState() {
    super.initState();
    print('[SharedDrawer] initState: Se va a refrescar el rol del usuario.');
    // Refrescar el rol cuando se crea el Drawer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[SharedDrawer] PostFrameCallback: Refrescando rol del usuario...');
      ref.read(userRoleStateProvider.notifier).refreshRole();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userRoleStateProvider);
    print('[SharedDrawer] build: Rol actual del usuario: $userRole');

    if (userRole == null) {
      print('[SharedDrawer] build: Rol nulo, mostrando CircularProgressIndicator.');
      return const Drawer(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),
          _buildNavigationItems(context, userRole),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      height: 90,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(1, 40, 45, 1),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(
              'assets/images/logoCompleto_psiconnect.png',
              width: MediaQuery.of(context).size.width * 0.4,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems(BuildContext context, String userRole) {
    final isProfessional = userRole == 'professional';
    final isPatient = userRole == 'patient';

    print('[SharedDrawer] _buildNavigationItems: isProfessional: $isProfessional, isPatient: $isPatient');

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Inicio'),
          onTap: () => _navigateTo(context, AppRoutes.home),
        ),
        if (isProfessional) ...[
          _buildListTile(context, Icons.person, 'Perfil', AppRoutes.professionalHome),
          _buildListTile(context, Icons.folder, 'Archivos por Paciente', AppRoutes.professionalFiles),
          _buildListTile(context, Icons.event, 'Mis Sesiones', AppRoutes.mySessionsProfessional),
        ],
        if (isPatient) ...[
          _buildListTile(context, Icons.person, 'Perfil del Paciente', AppRoutes.patientHome),
          _buildListTile(context, Icons.calendar_today, 'Agenda Digital', AppRoutes.patientAppointments),
          _buildListTile(context, Icons.folder, 'Archivos', AppRoutes.patientFiles),
          _buildListTile(context, Icons.event, 'Mis Sesiones', AppRoutes.mySessionsPatient),
        ],
      ],
    );
  }

  ListTile _buildListTile(BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => _navigateTo(context, route),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    print('[SharedDrawer] Navegando a: $route');
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      print('[SharedDrawer] Cerrando sesión...');
      await AuthService().signOut();
      ref.read(sessionProvider.notifier).logOut();
      ref.read(userRoleStateProvider.notifier).clearRole();
      print('[SharedDrawer] Sesión cerrada, redireccionando a HomePage...');
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            onReload: () {},
            toggleTheme: widget.toggleTheme,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      print('[SharedDrawer] Error al cerrar sesión: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cerrar sesión')),
      );
    }
  }
}
