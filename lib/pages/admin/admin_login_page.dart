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

      final response = await supabase
          .from('users')
          .select()
          .eq('usuario', _emailController.text.trim())
          .eq('password', _passwordController.text.trim())
          .maybeSingle();

      if (response != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Usuario o contraseña incorrectos")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión con la base de datos")),
      );
    }

    setState(() => _isLoading = false);
  }

  // 🆕 REGISTRAR USUARIO
  Future<void> _registrarUsuario() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Completa los campos")));
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('users').insert({
        'usuario': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'perfil': _perfil,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario creado correctamente")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error al crear usuario")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset("images/fondo.jpg", fit: BoxFit.cover),
          ),

          Container(color: const Color(0xFF0D1B2A).withOpacity(0.7)),

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

                          const Text("Usuario"),
                          const SizedBox(height: 5),
                          _buildInput(_emailController, Icons.person),

                          const SizedBox(height: 20),

                          const Text("Contraseña"),
                          const SizedBox(height: 5),
                          _buildInput(
                            _passwordController,
                            Icons.lock,
                            isPassword: true,
                          ),

                          const SizedBox(height: 20),

                          const Text("Perfil"),
                          const SizedBox(height: 5),
                          _buildDropdown([
                            "Alumno",
                            "Seguridad",
                            "Administrador",
                          ], _perfil),

                          const SizedBox(height: 25),

                          /// 🔐 BOTÓN LOGIN
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text("Ingresar"),
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// 🆕 BOTÓN REGISTRO
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _registrarUsuario,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text("Nuevo Usuario"),
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
        ],
      ),
    );
  }

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
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

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
