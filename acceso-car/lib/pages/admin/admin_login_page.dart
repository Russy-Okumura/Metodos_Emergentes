import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_dashboard_page.dart';
import '../guard/seguridad_dashboard_page.dart';
import '../student/student_auth_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _perfilSeleccionado = 'alumno';

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Ingresa usuario y contraseña');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        _showMessage('No se pudo obtener el usuario');
        return;
      }

      final usuarioDoc = await _db.collection('usuarios').doc(user.uid).get();

      if (!usuarioDoc.exists) {
        await _auth.signOut();
        _showMessage('El usuario no tiene perfil registrado en Firebase');
        return;
      }

      final usuarioData = usuarioDoc.data()!;

      final String rolFirebase = (usuarioData['rol'] ?? '')
          .toString()
          .toLowerCase();

      final bool activo = usuarioData['activo'] == true;

      if (!activo) {
        await _auth.signOut();
        _showMessage('Este usuario está desactivado');
        return;
      }

      if (rolFirebase != _perfilSeleccionado) {
        await _auth.signOut();
        _showMessage('El perfil seleccionado no corresponde con tu cuenta');
        return;
      }

      if (!mounted) return;

      if (rolFirebase == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      } else if (rolFirebase == 'seguridad') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SeguridadDashboardPage()),
        );
      } else if (rolFirebase == 'alumno') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboardPage()),
        );
      } else {
        await _auth.signOut();
        _showMessage('Rol no válido en la base de datos');
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al iniciar sesión';

      if (e.code == 'invalid-email') {
        mensaje = 'Correo electrónico no válido';
      } else if (e.code == 'user-not-found') {
        mensaje = 'No existe una cuenta con ese correo';
      } else if (e.code == 'wrong-password') {
        mensaje = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-credential') {
        mensaje = 'Correo o contraseña incorrectos';
      }

      _showMessage(mensaje);
    } catch (e) {
      _showMessage('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _recoverPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Ingresa tu correo primero');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);

      _showMessage('Correo de recuperación enviado', color: Colors.green);
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al enviar recuperación';

      if (e.code == 'invalid-email') {
        mensaje = 'Correo electrónico no válido';
      } else if (e.code == 'user-not-found') {
        mensaje = 'No existe una cuenta con ese correo';
      }

      _showMessage(mensaje);
    } catch (e) {
      _showMessage('Error al enviar recuperación');
    }
  }

  void _showMessage(String message, {Color color = Colors.red}) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  String _textoPerfil(String value) {
    switch (value) {
      case 'admin':
        return 'Administrador';
      case 'seguridad':
        return 'Seguridad';
      default:
        return 'Alumno';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final double formWidth = screenWidth < 900 ? 290 : 330;
    final double rightPadding = screenWidth < 900 ? 30 : 155;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset('images/fondo.jpg', fit: BoxFit.cover),
          ),

          Container(color: const Color(0xFF0D1B2A).withOpacity(0.58)),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: rightPadding),
              child: SingleChildScrollView(
                child: Transform.translate(
                  offset: const Offset(0, 18),
                  child: SizedBox(
                    width: formWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Usuario'),
                        const SizedBox(height: 5),
                        _buildTextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 13),

                        _label('Contraseña'),
                        const SizedBox(height: 5),
                        _buildPasswordField(),

                        const SizedBox(height: 13),

                        _label('Perfil'),
                        const SizedBox(height: 5),
                        _buildPerfilDropdown(),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _recoverPassword,
                            child: const Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 128,
                            height: 42,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00AEEF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.3,
                                      ),
                                    )
                                  : const Text(
                                      'Ingresar',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
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
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.88),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 9,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: SizedBox(
          height: 40,
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black54,
                  size: 18,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.88),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 9,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilDropdown() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(22),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _perfilSeleccionado,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                size: 25,
                color: Colors.black,
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              items: const [
                DropdownMenuItem(value: 'alumno', child: Text('Alumno')),
                DropdownMenuItem(value: 'seguridad', child: Text('Seguridad')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              ],
              selectedItemBuilder: (context) {
                return ['alumno', 'seguridad', 'admin'].map((value) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _textoPerfil(value),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList();
              },
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _perfilSeleccionado = value;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
