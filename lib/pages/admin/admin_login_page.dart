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

  String _perfil = "Administrador";
  bool _isLoading = false;

  // 🔐 LOGIN
  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          );
        }
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al conectar con Supabase")),
      );
    }

    setState(() => _isLoading = false);
  }

  // 🆕 REGISTRAR NUEVO USUARIO
  Future<void> _registerUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'perfil': _perfil},
      );

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario creado correctamente")),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al registrar usuario")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌄 FONDO
          SizedBox.expand(
            child: Image.asset("images/fondo.jpg", fit: BoxFit.cover),
          ),

          // 🌑 OSCURECER FONDO
          Container(color: const Color(0xFF0D1B2A).withOpacity(0.7)),

          // 📦 LOGIN BOX
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 80),

              child: SingleChildScrollView(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),

                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),

                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),

                      padding: const EdgeInsets.all(25),

                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),

                        borderRadius: BorderRadius.circular(16),

                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Icon(
                            Icons.lock_person,
                            size: 70,
                            color: Color(0xFF1A73E8),
                          ),

                          const SizedBox(height: 20),

                          // 📧 EMAIL
                          const Text(
                            "Correo Electrónico",
                            style: TextStyle(color: Colors.white),
                          ),

                          const SizedBox(height: 5),

                          _buildInput(_emailController, Icons.email),

                          const SizedBox(height: 20),

                          // 🔑 PASSWORD
                          const Text(
                            "Contraseña",
                            style: TextStyle(color: Colors.white),
                          ),

                          const SizedBox(height: 5),

                          _buildInput(
                            _passwordController,
                            Icons.lock,
                            isPassword: true,
                          ),

                          const SizedBox(height: 20),

                          // 👤 PERFIL
                          const Text(
                            "Perfil",
                            style: TextStyle(color: Colors.white),
                          ),

                          const SizedBox(height: 5),

                          _buildDropdown([
                            "Administrador",
                            "Alumno",
                            "Seguridad",
                          ], _perfil),

                          const SizedBox(height: 30),

                          // 🔐 LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 50,

                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1A3C88),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),

                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text(
                                      "Ingresar",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          /*// 🆕 NUEVO USUARIO
                          SizedBox(
                            width: double.infinity,
                            height: 50,

                            child: ElevatedButton(
                              onPressed: _registerUser,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),

                              child: const Text(
                                "Nuevo Usuario",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),*/
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔤 INPUTS
  Widget _buildInput(
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,

      style: const TextStyle(color: Colors.white),

      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),

        filled: true,
        fillColor: Colors.white.withOpacity(0.2),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // 🔽 DROPDOWN
  Widget _buildDropdown(List<String> items, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),

      child: DropdownButton<String>(
        value: value,
        isExpanded: true,

        dropdownColor: const Color(0xFF1B263B),

        style: const TextStyle(color: Colors.white),

        underline: const SizedBox(),

        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),

        onChanged: (val) {
          setState(() => _perfil = val!);
        },
      ),
    );
  }
}
