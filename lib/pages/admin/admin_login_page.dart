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

  String _perfil = "Alumno";
  bool _isLoading = false;

  Future<void> _signIn() async {

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al iniciar sesión"))
      );
    }

    setState(() => _isLoading = false);
  }

  /// 🔐 RECUPERAR CONTRASEÑA
  Future<void> _recoverPassword() async {

    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa tu correo primero"))
      );
      return;
    }

    try {

      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correo de recuperación enviado"))
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al enviar recuperación"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [

          /// 🌄 FONDO
          SizedBox.expand(
            child: Image.asset(
              "images/fondo.jpg",
              fit: BoxFit.cover,
            ),
          ),

          /// 🌑 OVERLAY OSCURO
          Container(
            color: const Color(0xFF0D1B2A).withOpacity(0.7),
          ),

          /// 👉 FORMULARIO A LA DERECHA
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 80),

              child: SingleChildScrollView(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),

                  /// ✨ EFECTO VIDRIO (BLUR)
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

                          /// IDIOMA
                          const Text("Idioma", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0),fontWeight: FontWeight.w600,)),
                          const SizedBox(height: 5),
                          _buildDropdown(["Español", "Inglés"], "Español"),

                          const SizedBox(height: 20),

                          /// USUARIO
                          const Text("Usuario", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0),fontWeight: FontWeight.w600,)),
                          const SizedBox(height: 5),
                          _buildInput(_emailController, Icons.person),

                          const SizedBox(height: 20),

                          /// CONTRASEÑA
                          const Text("Contraseña", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0),fontWeight: FontWeight.w600,)),
                          const SizedBox(height: 5),
                          _buildInput(_passwordController, Icons.lock, isPassword: true),

                          const SizedBox(height: 20),

                          /// PERFIL
                          const Text("Perfil", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0),fontWeight: FontWeight.w600,)),
                          const SizedBox(height: 5),
                          _buildDropdown(["Alumno", "Seguridad", "Administrador"], _perfil),

                          const SizedBox(height: 20),

                          /// RECUPERAR
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _recoverPassword,
                              child: const Text(
                                "¿Olvidaste tu contraseña?",
                                style: TextStyle(
                                  color: Colors.white70,
                                  decoration: TextDecoration.underline,fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          /// BOTÓN
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 93, 180, 235),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : const Text(
                                      "Ingresar",
                                      style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600,),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// 🔹 INPUT
  Widget _buildInput(TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),fontWeight: FontWeight.w600,),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 0, 0, 0)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// 🔹 DROPDOWN
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
        underline: const SizedBox(),
        dropdownColor: const Color.fromARGB(255, 187, 193, 201),
        style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0),fontWeight: FontWeight.w600,),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (val) {
          setState(() => _perfil = val!);
        },
      ),
    );
  }
}