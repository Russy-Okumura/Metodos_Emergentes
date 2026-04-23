import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_dashboard_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al iniciar sesión")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🔐 RECUPERAR CONTRASEÑA
  Future<void> _recoverPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa tu correo primero")),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correo de recuperación enviado")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al enviar recuperación")),
      );
    }
  }

  /// 🔹 INPUT PERSONALIZADO
  Widget _buildInput(
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// IMAGEN DE FONDO
          SizedBox.expand(
            child: Image.asset("images/fondo.jpg", fit: BoxFit.cover),
          ),

          /// CAPA OSCURA
          Container(color: Colors.black.withOpacity(0.6)),

          /// FORMULARIO
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 80),
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_person,
                        size: 70,
                        color: Color(0xFF1A73E8),
                      ),

                      const SizedBox(height: 20),

                      /// EMAIL
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Usuario"),
                      ),
                      const SizedBox(height: 5),
                      _buildInput(_emailController, Icons.person),

                      const SizedBox(height: 20),

                      /// PASSWORD
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Contraseña"),
                      ),
                      const SizedBox(height: 5),
                      _buildInput(
                        _passwordController,
                        Icons.lock,
                        isPassword: true,
                      ),

                      const SizedBox(height: 20),

                      /// BOTÓN
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black,
                                )
                              : const Text(
                                  "ACCEDER",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// RECUPERAR CONTRASEÑA
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _recoverPassword,
                          child: const Text(
                            "¿Olvidaste tu contraseña?",
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
