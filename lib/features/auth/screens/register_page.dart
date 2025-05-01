// lib/features/auth/screens/register_page.dart

import 'package:Psiconnect/core/widgets/storage_image.dart';
import 'package:Psiconnect/features/auth/widgets/role_selection_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '/core/exceptions/app_exception.dart';
import '/navigation/router.dart';
import '/features/auth/providers/session_provider.dart';
import '/core/constants/app_constants.dart';
import '/core/utils/validation_helper.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends HookConsumerWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Form controllers
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final nameController = useTextEditingController();
    final lastNameController = useTextEditingController();
    final dniController = useTextEditingController();
    final phoneController = useTextEditingController();
    final licenseController = useTextEditingController(text: 'MN-');
    
    // Form state
    final formKey = useState(GlobalKey<FormState>());
    final isProfessional = useState(false);
    final obscurePassword = useState(true);
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final selectedDocumentType = useState<String>('DNI');

    // Handle register submission
    Future<void> handleSubmit() async {
      if (!formKey.value.currentState!.validate()) return;

      try {
        isLoading.value = true;
        errorMessage.value = null;
        
        String role = isProfessional.value ? 'professional' : 'patient';
        final dni = dniController.text.trim();
        
        // Check if DNI already exists for the selected user type
        final isDniExisting = await ref.read(sessionProvider.notifier).checkDniExists(
          dni: dni,
          role: role,
        );
        
        if (isDniExisting) {
          errorMessage.value = isProfessional.value 
              ? 'Ya existe un profesional registrado con este DNI.' 
              : 'Ya existe un paciente registrado con este DNI.';
          isLoading.value = false;
          return;
        }
        
        // Datos comunes para ambos tipos de usuario
        await ref.read(sessionProvider.notifier).register(
          email: emailController.text.trim(),
          password: passwordController.text,
          role: role,
          firstName: nameController.text.trim(),
          lastName: lastNameController.text.trim(),
          dni: dni,
          phoneN: phoneController.text.trim(),
          
          // Si es profesional, agregar campos específicos
          license: isProfessional.value ? licenseController.text.trim() : null,
        );
        
        // Example for standard registration
        Map<String, dynamic> userData = {
          'firstName': nameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'uid': FirebaseAuth.instance.currentUser!.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'registerMethod': 'email',
          'profileCompleted': false,  // Explicitly set to false for new users
        };
        
        // Navegación basada en el rol
        // The router will automatically redirect to the appropriate home page
        // based on the user's role through the GoRouter redirect logic
        if (context.mounted) {
          // Use the route paths directly from RoutePaths class for consistency
          if (isProfessional.value) {
            GoRouterHelper(context).go(RoutePaths.professionalHome);
          } else {
            GoRouterHelper(context).go(RoutePaths.patientHome);
          }
        }
      } catch (e) {
        if (e is AuthException) {
          errorMessage.value = e.message;
        } else {
          errorMessage.value = e.toString();
        }
      } finally {
        isLoading.value = false;
      }
    }
    

    
    // Google sign-in function
    Future<void> handleGoogleSignIn() async {
      try {
        isLoading.value = true;
        errorMessage.value = null;

        // Cambia la forma de inicializar GoogleSignIn
        final googleSignIn = GoogleSignIn(
          clientId: kIsWeb ? '953533544770-j5flo9m30pi1lnri9csb9pannkkhapj4.apps.googleusercontent.com' : null,
          signInOption: SignInOption.standard,
          scopes: ['email', 'profile'],
        );
        // Para depurar - imprime la URL base actual
        print('URL base actual: ${Uri.base.toString()}');

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          print('Google Sign-In cancelado por el usuario.');
          isLoading.value = false;
          return;
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Autenticamos con Firebase usando las credenciales de Google
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = userCredential.user;
        if (user == null) {
          print('Error: No se obtuvo el usuario tras el sign-in.');
          isLoading.value = false;
          return;
        }

        // Mostramos el diálogo de selección de rol
        final selectedRole = await showDialog<UserRole>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return RoleSelectionDialog(
              onRoleSelected: (UserRole role) {
                Navigator.of(dialogContext).pop(role);
              },
            );
          },
        );

        if (selectedRole == null) {
          print('El usuario canceló la selección de rol. Se cerrará sesión.');
          // Cerramos sesión ya que no sabemos qué rol quiere el usuario
          await FirebaseAuth.instance.signOut();
          isLoading.value = false;
          return;
        }

        // Convertimos la selección al string correspondiente
        final roleString = selectedRole == UserRole.professional ? 'professional' : 'patient';

        // Registramos al usuario en la colección correspondiente (doctors o patients)
        await ref.read(sessionProvider.notifier).registerWithGoogle(roleString);

        // Navegamos a la pantalla de inicio según el rol seleccionado
        // Usando pushReplacement para reemplazar la página actual en la pila
        if (context.mounted) {
          if (roleString == 'professional') {
            GoRouter.of(context).pushReplacement(RoutePaths.professionalHome);
          } else {
            GoRouter.of(context).pushReplacement(RoutePaths.patientHome);
          }
        }
      } catch (e) {
        print('Error durante el registro con Google: $e');
        errorMessage.value = 'Error al registrarse con Google: $e';
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Color.fromRGBO(2, 60, 67, 1),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(2, 60, 67, 1),
        title: const Text('Registro', 
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          )
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go(RoutePaths.home),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 380,
                child: Card(
                  color: Color.fromRGBO(1, 40, 45, 1),
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: formKey.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo and title
                          Column(
                            children: [
                              StorageImage(
                                imagePath:'images/logo.png',
                                height: 100,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Bienvenido a Psiconnect',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Error message if present
                          if (errorMessage.value != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade700),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade300, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage.value!,
                                      style: TextStyle(color: Colors.red.shade300, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          // User type switch
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Paciente', 
                                  style: TextStyle(
                                    color: !isProfessional.value ? Colors.white : Colors.white70,
                                    fontWeight: !isProfessional.value ? FontWeight.bold : FontWeight.normal,
                                  )
                                ),
                                Switch(
                                  value: isProfessional.value,
                                  onChanged: (value) {
                                    isProfessional.value = value;
                                  },
                                  activeColor: AppColors.primaryLight,
                                  inactiveTrackColor: Colors.white30,
                                ),
                                Text('Profesional', 
                                  style: TextStyle(
                                    color: isProfessional.value ? Colors.white : Colors.white70,
                                    fontWeight: isProfessional.value ? FontWeight.bold : FontWeight.normal,
                                  )
                                ),
                              ],
                            ),
                          ),
                          
                          // Name field
                          _buildInputField(
                            controller: nameController,
                            labelText: 'Nombre',
                            hintText: 'Ingresa tu nombre',
                            icon: Icons.person_rounded,
                            validator: (value) => ValidationHelper.validateNotEmpty(value, 'nombre'),
                            isLoading: isLoading.value,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          
                          // Lastname field
                          _buildInputField(
                            controller: lastNameController,
                            labelText: 'Apellido',
                            hintText: 'Ingresa tu apellido',
                            icon: Icons.person_rounded,
                            validator: (value) => ValidationHelper.validateNotEmpty(value, 'apellido'),
                            isLoading: isLoading.value,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 16),
                          
                          // DNI field
                          _buildInputField(
                            controller: dniController,
                            labelText: 'DNI',
                            hintText: 'Ingresa tu DNI',
                            icon: Icons.badge_rounded,
                            validator: (value) => ValidationHelper.validateDocumentNumber(value),
                            isLoading: isLoading.value,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          
                          // Email field
                          _buildInputField(
                            controller: emailController,
                            labelText: 'Email',
                            hintText: 'Ingresa tu email',
                            icon: Icons.email_rounded,
                            validator: (value) => ValidationHelper.validateEmail(value),
                            isLoading: isLoading.value,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          
                          // Phone number field
                          _buildInputField(
                            controller: phoneController,
                            labelText: 'Teléfono',
                            hintText: 'Ingresa tu teléfono',
                            icon: Icons.phone_rounded,
                            validator: (value) => ValidationHelper.validatephoneN(value),
                            isLoading: isLoading.value,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          
                          // Password field
                          _buildPasswordField(
                            controller: passwordController,
                            obscurePassword: obscurePassword,
                            isLoading: isLoading.value,
                          ),
                          const SizedBox(height: 16),
                          
                          if (isProfessional.value) ...[
                            _buildLicenseField(
                              controller: licenseController,
                              labelText: 'Matrícula Nacional',
                              hintText: 'Ingresa solo los números',
                              icon: Icons.card_membership_rounded,
                              validator: (value) {
                                if (value == null || value.isEmpty || value == 'MN-') {
                                  return 'Por favor, ingresa tu matrícula nacional';
                                }
                                // Verificar que el formato sea correcto después del prefijo MN-
                                final numberPart = value.replaceFirst('MN-', '');
                                if (numberPart.isEmpty) {
                                  return 'Ingresa los números de la matrícula';
                                }
                                if (!RegExp(r'^\d+$').hasMatch(numberPart)) {
                                  return 'Solo se permiten números';
                                }
                                return null;
                              },
                              isLoading: isLoading.value,
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Submit button - Register
                          ElevatedButton(
                            onPressed: isLoading.value ? null : handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color.fromRGBO(1, 40, 45, 1),
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              elevation: 5,
                            ),
                            child: isLoading.value
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                                    ),
                                  )
                                : Text(
                                    'Registrarse',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white30)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'O CONTINUAR CON',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white30)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Google sign-in button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: OutlinedButton.icon(
                              onPressed: isLoading.value ? null : handleGoogleSignIn,
                              icon: SizedBox(
                                height: 20,
                                width: 20,
                                child: StorageImage(
                                  imagePath:'images/google_logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.g_mobiledata,
                                      size: 20,
                                      color: Colors.red,
                                    );
                                  },
                                ),
                              ),
                              label: Text(
                                'Registrarse con Google',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: AppColors.primaryLight),
                                backgroundColor: AppColors.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Login link
                          TextButton(
                            onPressed: isLoading.value 
                                ? null 
                                : () => GoRouter.of(context).go(RoutePaths.login),
                            child: Text(
                              '¿Ya tienes una cuenta? Inicia sesión aquí',
                              style: TextStyle(color: AppColors.primaryLight),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isLoading.value)
            Container(
              color: Colors.black45,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Helper method to build a consistent password field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required ValueNotifier<bool> obscurePassword,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Contraseña',
          labelStyle: TextStyle(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.w500,
          ),
          hintText: '••••••••',
          hintStyle: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
          filled: true,
          fillColor: AppColors.primaryColor.withOpacity(0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: AppColors.primaryLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: AppColors.primaryLight.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          prefixIcon: Icon(
            Icons.lock_rounded,
            color: AppColors.primaryLight,
            size: 22,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword.value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: AppColors.primaryLight,
              size: 22,
            ),
            onPressed: () => obscurePassword.value = !obscurePassword.value,
            splashRadius: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        obscureText: obscurePassword.value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        cursorColor: AppColors.primaryLight,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, ingresa tu contraseña';
          }
          if (value.length < ValidationConstants.minPasswordLength) {
            return 'La contraseña debe tener al menos ${ValidationConstants.minPasswordLength} caracteres';
          }
          return null;
        },
        enabled: !isLoading,
      ),
    );
  }
  
  // Helper method to build a consistent input field
  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required FormFieldValidator<String> validator,
    required bool isLoading,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.w500,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
          filled: true,
          fillColor: AppColors.primaryColor.withOpacity(0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: AppColors.primaryLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: AppColors.primaryLight.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primaryLight,
            size: 22,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        cursorColor: AppColors.primaryLight,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        validator: validator,
        enabled: !isLoading,
        textCapitalization: textCapitalization,
      ),
    );
  }

  // Helper method to build the license field with MN- prefix
  Widget _buildLicenseField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    required FormFieldValidator<String> validator,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.w500,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
          filled: true,
          fillColor: AppColors.primaryColor.withOpacity(0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: AppColors.primaryLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: AppColors.primaryLight.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primaryLight,
            size: 22,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        cursorColor: AppColors.primaryLight,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        validator: validator,
        enabled: !isLoading,
        inputFormatters: [
          // Mantener el prefijo MN- y permitir solo dígitos después
          TextInputFormatter.withFunction((oldValue, newValue) {
            // Asegurarse de que siempre tenga el prefijo MN-
            if (!newValue.text.startsWith('MN-')) {
              return TextEditingValue(
                text: 'MN-${newValue.text.replaceAll('MN-', '')}',
                selection: TextSelection.collapsed(offset: newValue.text.length + 3 - (newValue.text.startsWith('M') ? 1 : 0) - (newValue.text.startsWith('MN') ? 2 : 0))
              );
            }
            
            // Si se intenta borrar el prefijo, mantenerlo
            if (newValue.text == 'MN' || newValue.text == 'M') {
              return const TextEditingValue(
                text: 'MN-',
                selection: TextSelection.collapsed(offset: 3)
              );
            }
            
            // Validar que solo haya dígitos después del prefijo
            final parts = newValue.text.split('MN-');
            if (parts.length > 1) {
              final numberPart = parts[1];
              if (numberPart.isNotEmpty && !RegExp(r'^\d+$').hasMatch(numberPart)) {
                // Si hay caracteres no numéricos, rechazarlos
                return oldValue;
              }
            }
            
            return newValue;
          }),
        ],
        onChanged: (value) {
          // Asegurarse de que el cursor quede después del prefijo
          if (value.length <= 3) {
            controller.text = 'MN-';
            controller.selection = const TextSelection.collapsed(offset: 3);
          }
        },
      ),
    );
  }
}