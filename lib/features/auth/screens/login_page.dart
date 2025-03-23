// lib/features/auth/screens/login_page.dart

import 'package:Psiconnect/core/exceptions/exception_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '/core/exceptions/app_exception.dart';
import '/navigation/router.dart';
import '/features/auth/providers/session_provider.dart';
import '/core/widgets/responsive_widget.dart';
import '/core/constants/app_constants.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Track form state
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useState(GlobalKey<FormState>());
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final hidePassword = useState(true);
    
    // Access theme
    final theme = Theme.of(context);
    
    // Form submission logic
    Future<void> handleLogin() async {
      if (!formKey.value.currentState!.validate()) return;
      
      try {
        isLoading.value = true;
        errorMessage.value = null;
        
        // Log in using session provider
        await ref.read(sessionProvider.notifier).logIn(
          emailController.text.trim(),
          passwordController.text,
        );
        
        // After successful login, check the user's role and navigate accordingly
        if (context.mounted) {
          final userRole = ref.read(userRoleProvider);
          
          // Use context extension for cleaner navigation based on user role
          switch (userRole) {
            case 'admin':
              context.goAdmin();
              break;
            case 'professional':
              context.goProfessionalHome();
              break;
            case 'patient':
              context.goPatientHome();
              break;
            default:
              context.goHome();
          }
        }
      } catch (e) {
        // Handle login errors
        if (e is AppException) {
          errorMessage.value = e.message;
        } else {
          errorMessage.value = e.toString();
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage.value ?? 'Error al iniciar sesión'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }
    
    // Google sign-in logic
    Future<void> handleGoogleSignIn() async {
      errorMessage.value = null;
      
      try {
        isLoading.value = true;
        
        // Log in with Google using session provider
        await ref.read(sessionProvider.notifier).logInWithGoogle();
        
        // After successful Google login, navigate based on user role
        if (context.mounted) {
          final userRole = ref.read(userRoleProvider);
          
          // Use context extension methods for cleaner navigation
          switch (userRole) {
            case 'admin':
              context.goAdmin();
              break;
            case 'professional':
              context.goProfessionalHome();
              break;
            case 'patient':
              context.goPatientHome();
              break;
            default:
              context.goHome();
          }
        }
      } catch (e) {
        // Handle Google sign-in errors
        if (e is AuthException) {
          errorMessage.value = e.message;
        } else if (e is AppException) {
          errorMessage.value = e.message;
        } else if (e is FirebaseAuthException) {
          errorMessage.value = e.message ?? 'Error de autenticación con Google';
        } else {
          errorMessage.value = 'Error al iniciar sesión con Google: ${e.toString()}';
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage.value ?? 'Error al iniciar sesión con Google'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }
    
    // Show forgot password dialog
    void showForgotPasswordDialog() {
      final emailController = TextEditingController();
      final formKey = GlobalKey<FormState>();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.primaryColor,
          title: const Text('Recuperar contraseña', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    labelStyle: TextStyle(color: AppColors.primaryLight),
                    hintText: 'ejemplo@correo.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: AppColors.primaryLight),
                    ),
                  ),
                  style: TextStyle(color: AppColors.primaryLight),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa tu correo electrónico';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Por favor, ingresa un correo electrónico válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // TODO: Implement password reset
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Se ha enviado un correo para restablecer tu contraseña'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryColor,
              ),
              child: const Text('Enviar'),
            ),
          ],
        ),
      );
    }
    
    // Main UI with styling consistent with registration page
    return Scaffold(
      backgroundColor: Color.fromRGBO(2, 60, 67, 1), // Same as register page
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(2, 60, 67, 1),
        title: const Text('Iniciar Sesión', 
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
                width: 350,
                child: Card(
                  color: Color.fromRGBO(1, 40, 45, 1), // Same dark background as register
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
                              Image.asset(
                                'assets/images/logo.png',
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
                          
                          // Email field
                          Container(
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
                            child: TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                                hintText: 'Ingresa tu email',
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
                                  Icons.email_rounded,
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
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !isLoading.value,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Password field
                          Container(
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
                            child: TextField(
                              controller: passwordController,
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
                                    hidePassword.value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                    color: AppColors.primaryLight,
                                    size: 22,
                                  ),
                                  onPressed: () => hidePassword.value = !hidePassword.value,
                                  splashRadius: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              ),
                              obscureText: hidePassword.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              cursorColor: AppColors.primaryLight,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => handleLogin(),
                              enabled: !isLoading.value,
                            ),
                          ),
                          
                          // Forgot password link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading.value ? null : showForgotPasswordDialog,
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Login button - similar to register button
                          ElevatedButton(
                            onPressed: isLoading.value ? null : handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color.fromRGBO(154, 141, 140, 1),
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              elevation: 10,
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
                                    'Iniciar Sesión',
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
                          
                          // Google sign-in button - matching register style
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  spreadRadius: 4,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: OutlinedButton.icon(
                              onPressed: isLoading.value ? null : handleGoogleSignIn,
                              icon: SizedBox(
                                height: 20,
                                width: 20,
                                child: Image.asset(
                                  'assets/images/google_logo.png',
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
                                'Continuar con Google',
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
                          
                          // Register link
                          TextButton(
                            onPressed: isLoading.value 
                                ? null 
                                : () => GoRouter.of(context).go(RoutePaths.register),
                            child: Text(
                              '¿No tienes una cuenta? Regístrate aquí',
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
}