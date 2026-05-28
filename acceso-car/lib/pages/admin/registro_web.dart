import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../firebase_options.dart';

class RegistroWebPage extends StatefulWidget {
  const RegistroWebPage({super.key});

  @override
  State<RegistroWebPage> createState() => _RegistroWebPageState();
}

class _RegistroWebPageState extends State<RegistroWebPage> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  final _matriculaCtrl = TextEditingController();
  final _carreraCtrl = TextEditingController(
    text: 'Ingeniería en Sistemas Computacionales',
  );
  final _semestreCtrl = TextEditingController();
  final _grupoCtrl = TextEditingController();

  final _turnoCtrl = TextEditingController();
  final _casetaCtrl = TextEditingController();

  String _rolSeleccionado = 'alumno';
  bool _cargando = false;
  bool _obscurePassword = true;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool get _esAlumno => _rolSeleccionado == 'alumno';
  bool get _esSeguridad => _rolSeleccionado == 'seguridad';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();

    _matriculaCtrl.dispose();
    _carreraCtrl.dispose();
    _semestreCtrl.dispose();
    _grupoCtrl.dispose();

    _turnoCtrl.dispose();
    _casetaCtrl.dispose();

    super.dispose();
  }

  Future<FirebaseAuth> _getSecondaryAuth() async {
    FirebaseApp secondaryApp;

    try {
      secondaryApp = Firebase.app('SecondaryApp');
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    return FirebaseAuth.instanceFor(app: secondaryApp);
  }

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    final adminUid = FirebaseAuth.instance.currentUser?.uid;

    if (adminUid == null) {
      _mostrarMensaje('No hay administrador autenticado.', Colors.red);
      setState(() => _cargando = false);
      return;
    }

    final nombre = _nombreCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();

    try {
      final secondaryAuth = await _getSecondaryAuth();

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: correo,
        password: password,
      );

      final nuevoUsuario = credential.user;

      if (nuevoUsuario == null) {
        throw Exception('No se pudo crear el usuario.');
      }

      final uidNuevoUsuario = nuevoUsuario.uid;

      await secondaryAuth.signOut();

      final batch = _db.batch();

      final usuarioRef = _db.collection('usuarios').doc(uidNuevoUsuario);

      batch.set(usuarioRef, {
        'uid': uidNuevoUsuario,
        'nombre': nombre,
        'correo': correo,
        'rol': _rolSeleccionado,
        'activo': true,
        'telefono': telefono,
        'creadoPor': adminUid,
        'creadoEn': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      if (_rolSeleccionado == 'alumno') {
        final alumnoRef = _db
            .collection('perfiles_alumnos')
            .doc(uidNuevoUsuario);

        batch.set(alumnoRef, {
          'uid': uidNuevoUsuario,
          'matricula': _matriculaCtrl.text.trim().toUpperCase(),
          'nombreCompleto': nombre,
          'carrera': _carreraCtrl.text.trim(),
          'semestre': _semestreCtrl.text.trim(),
          'grupo': _grupoCtrl.text.trim().toUpperCase(),
          'telefono': telefono,
          'estado': 'activo',
          'creadoEn': FieldValue.serverTimestamp(),
          'actualizadoEn': FieldValue.serverTimestamp(),
        });
      }

      if (_rolSeleccionado == 'seguridad') {
        final seguridadRef = _db
            .collection('perfiles_seguridad')
            .doc(uidNuevoUsuario);

        batch.set(seguridadRef, {
          'uid': uidNuevoUsuario,
          'nombreCompleto': nombre,
          'turno': _turnoCtrl.text.trim(),
          'casetaAsignada': _casetaCtrl.text.trim(),
          'telefono': telefono,
          'estado': 'activo',
          'creadoEn': FieldValue.serverTimestamp(),
          'actualizadoEn': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      _mostrarMensaje('Usuario creado correctamente.', Colors.green);
      _limpiar();
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al crear usuario.';

      if (e.code == 'email-already-in-use') {
        mensaje = 'Ese correo ya está registrado.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'Correo no válido.';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es muy débil. Usa mínimo 6 caracteres.';
      }

      _mostrarMensaje(mensaje, Colors.red);
    } catch (e) {
      _mostrarMensaje('Error: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _limpiar() {
    _nombreCtrl.clear();
    _correoCtrl.clear();
    _passwordCtrl.clear();
    _telefonoCtrl.clear();

    _matriculaCtrl.clear();
    _carreraCtrl.text = 'Ingeniería en Sistemas Computacionales';
    _semestreCtrl.clear();
    _grupoCtrl.clear();

    _turnoCtrl.clear();
    _casetaCtrl.clear();

    setState(() {
      _rolSeleccionado = 'alumno';
      _obscurePassword = true;
    });
  }

  void _mostrarMensaje(String mensaje, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    const azulTec = Color(0xFF1B396A);
    const doradoTec = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Crear usuario'),
        backgroundColor: azulTec,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(34),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.manage_accounts, size: 34, color: azulTec),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Nuevo usuario del sistema',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: azulTec,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'El administrador crea la cuenta y asigna el rol. El alumno dará de alta su vehículo desde su panel.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),

                      const Divider(height: 34),

                      DropdownButtonFormField<String>(
                        value: _rolSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Rol del usuario',
                          prefixIcon: Icon(Icons.verified_user_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'alumno',
                            child: Text('Alumno'),
                          ),
                          DropdownMenuItem(
                            value: 'seguridad',
                            child: Text('Seguridad'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Administrador'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _rolSeleccionado = value);
                        },
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el nombre completo';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _correoCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa el correo';
                                }
                                if (!value.contains('@')) {
                                  return 'Ingresa un correo válido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _telefonoCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                prefixIcon: Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña temporal',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa una contraseña';
                          }
                          if (value.trim().length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),

                      if (_esAlumno) ...[
                        const SizedBox(height: 28),
                        _sectionTitle('Datos académicos del alumno', doradoTec),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _matriculaCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Matrícula',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (_esAlumno &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Ingresa la matrícula';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _semestreCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Semestre',
                                  prefixIcon: Icon(Icons.school_outlined),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _carreraCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Carrera',
                                  prefixIcon: Icon(Icons.menu_book_outlined),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _grupoCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Grupo',
                                  prefixIcon: Icon(Icons.groups_outlined),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_esSeguridad) ...[
                        const SizedBox(height: 28),
                        _sectionTitle(
                          'Datos del personal de seguridad',
                          doradoTec,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _turnoCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Turno',
                                  prefixIcon: Icon(Icons.schedule_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (_esSeguridad &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Ingresa el turno';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _casetaCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Caseta asignada',
                                  prefixIcon: Icon(Icons.sensor_door_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (_esSeguridad &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Ingresa la caseta';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 34),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _cargando ? null : _registrarUsuario,
                          icon: const Icon(Icons.save_outlined),
                          label: _cargando
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('CREAR USUARIO'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azulTec,
                            foregroundColor: Colors.white,
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
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
