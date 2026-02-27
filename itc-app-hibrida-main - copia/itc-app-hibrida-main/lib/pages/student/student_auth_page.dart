// lib/pages/student/student_auth_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/registro_web.dart'; // Importamos la página de registro de vehículo/QR

class StudentAuthPage extends StatefulWidget {
  const StudentAuthPage({super.key});

  @override
  State<StudentAuthPage> createState() => _StudentAuthPageState();
}

class _StudentAuthPageState extends State<StudentAuthPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSigningUp = true; // Empieza en Registro (SignUp)
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.red}) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isSigningUp) {
        // --- PROCESO DE REGISTRO (SIGN UP) ---
        await supabase.auth.signUp(email: email, password: password);
        _showSnackBar(
          '¡Registro exitoso! Revisa tu email para confirmar.',
          color: Colors.green,
        );
        // Opcionalmente, puedes enviarlo directamente a la página de registro de vehículo:
        _navigateToVehicleRegistration();
      } else {
        // --- PROCESO DE INICIO DE SESIÓN (SIGN IN) ---
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        _showSnackBar('Inicio de sesión exitoso.', color: Colors.green);
        _navigateToVehicleRegistration();
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Error inesperado: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToVehicleRegistration() {
    // Si la autenticación es exitosa, navega a la página de registro del vehículo
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegistroWebPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSigningUp ? 'Registro de Alumno' : 'Inicio de Sesión'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isSigningUp ? 'Crea tu Cuenta' : 'Accede a tu Pase',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico (Matrícula)',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleAuth,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isSigningUp ? 'REGISTRARME' : 'INICIAR SESIÓN'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSigningUp = !_isSigningUp;
                  });
                },
                child: Text(
                  _isSigningUp
                      ? '¿Ya tienes cuenta? Inicia Sesión'
                      : '¿No tienes cuenta? Regístrate',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
