import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../admin/admin_login_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _selectedIndex = 0;

  String? _qrTexto;
  String? _qrVehiculo;
  String? _qrPlacas;

  static const Color azulTec = Color(0xFF1B396A);
  static const Color azulOscuro = Color(0xFF10284A);
  static const Color doradoTec = Color(0xFFD4AF37);
  static const Color fondo = Color(0xFFF5F7FA);

  String get _uid => _auth.currentUser?.uid ?? '';

  Future<void> _signOut() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      (route) => false,
    );
  }

  String _generarCodigoSeguro({int length = 18}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();

    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> _abrirRegistroVehiculo() async {
    final perfilDoc = await _db.collection('perfiles_alumnos').doc(_uid).get();

    if (!perfilDoc.exists) {
      _mostrarMensaje('No existe el perfil del alumno.', Colors.red);
      return;
    }

    final perfil = perfilDoc.data()!;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _RegistrarVehiculoDialog(
        db: _db,
        alumnoUid: _uid,
        matricula: (perfil['matricula'] ?? '').toString(),
        nombreAlumno: (perfil['nombreCompleto'] ?? '').toString(),
      ),
    );

    if (result == true) {
      _mostrarMensaje('Vehículo registrado correctamente.', Colors.green);
    }
  }

  Future<void> _crearOAbrirPase(_VehicleData vehiculo) async {
    if (vehiculo.estado.toLowerCase() != 'aprobado') {
      _mostrarMensaje(
        'Solo puedes generar pase con vehículos aprobados.',
        Colors.orange,
      );
      return;
    }

    try {
      final pasesSnap = await _db
          .collection('pases_qr')
          .where('alumnoUid', isEqualTo: _uid)
          .get();

      QueryDocumentSnapshot<Map<String, dynamic>>? paseExistente;

      for (final doc in pasesSnap.docs) {
        final data = doc.data();

        if (data['vehiculoId'] == vehiculo.id && data['estado'] == 'activo') {
          paseExistente = doc;
          break;
        }
      }

      if (paseExistente != null) {
        final data = paseExistente.data();

        setState(() {
          _qrTexto = (data['qrTexto'] ?? '').toString();
          _qrVehiculo = '${vehiculo.marca} ${vehiculo.modelo}';
          _qrPlacas = vehiculo.placas;
          _selectedIndex = 2;
        });

        return;
      }

      final paseRef = _db.collection('pases_qr').doc();
      final codigoSeguro = _generarCodigoSeguro();
      final qrTexto = 'PASE:${paseRef.id}:$codigoSeguro';

      await paseRef.set({
        'alumnoUid': _uid,
        'vehiculoId': vehiculo.id,
        'matriculaAlumno': vehiculo.matriculaAlumno,
        'nombreAlumno': vehiculo.nombreAlumno,
        'placas': vehiculo.placas,
        'codigoSeguro': codigoSeguro,
        'qrTexto': qrTexto,
        'estado': 'activo',
        'fechaCreacion': FieldValue.serverTimestamp(),
        'fechaExpiracion': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 180)),
        ),
        'creadoPor': _uid,
        'ultimoUso': null,
      });

      setState(() {
        _qrTexto = qrTexto;
        _qrVehiculo = '${vehiculo.marca} ${vehiculo.modelo}';
        _qrPlacas = vehiculo.placas;
        _selectedIndex = 2;
      });

      _mostrarMensaje('Pase QR generado correctamente.', Colors.green);
    } catch (e) {
      _mostrarMensaje('Error al generar pase: $e', Colors.red);
    }
  }

  void _mostrarMensaje(String mensaje, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildInicio();
      case 1:
        return _buildMisVehiculos();
      case 2:
        return _buildMiPase();
      case 3:
        return _buildHistorial();
      default:
        return _buildInicio();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(body: Center(child: Text('No hay sesión activa.')));
    }

    return Scaffold(
      backgroundColor: fondo,
      body: Row(
        children: [
          _StudentSidebar(
            selectedIndex: _selectedIndex,
            onSelected: (index) {
              if (index == 4) {
                _signOut();
                return;
              }

              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                _StudentHeader(
                  selectedIndex: _selectedIndex,
                  onSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Container(color: Colors.white, child: _getBody()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInicio() {
    return FutureBuilder<_HomeData>(
      future: _loadHomeData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data;

        if (data == null) {
          return const Center(
            child: Text('No se pudo cargar la información del alumno.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, ${data.nombre}',
                style: const TextStyle(
                  color: azulTec,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Matrícula: ${data.matricula} · ${data.carrera}',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  _InfoCard(
                    title: 'Vehículos',
                    value: data.vehiculos.toString(),
                    icon: Icons.directions_car,
                    color: azulTec,
                  ),
                  _InfoCard(
                    title: 'Pases activos',
                    value: data.pasesActivos.toString(),
                    icon: Icons.qr_code_2,
                    color: doradoTec,
                  ),
                  _InfoCard(
                    title: 'Accesos',
                    value: data.accesos.toString(),
                    icon: Icons.login,
                    color: Colors.green.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 34),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado del alumno',
                      style: TextStyle(
                        color: azulTec,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Nombre', value: data.nombre),
                    _InfoRow(label: 'Matrícula', value: data.matricula),
                    _InfoRow(label: 'Carrera', value: data.carrera),
                    _InfoRow(label: 'Último acceso', value: data.ultimoAcceso),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_HomeData> _loadHomeData() async {
    final perfilDoc = await _db.collection('perfiles_alumnos').doc(_uid).get();
    final perfil = perfilDoc.data() ?? {};

    final vehiculosSnap = await _db
        .collection('vehiculos')
        .where('alumnoUid', isEqualTo: _uid)
        .get();

    final pasesSnap = await _db
        .collection('pases_qr')
        .where('alumnoUid', isEqualTo: _uid)
        .get();

    final accesosSnap = await _db
        .collection('accesos')
        .where('alumnoUid', isEqualTo: _uid)
        .get();

    final pasesActivos = pasesSnap.docs.where((doc) {
      return (doc.data()['estado'] ?? '').toString() == 'activo';
    }).length;

    final accesos = [...accesosSnap.docs];

    accesos.sort((a, b) {
      final fa = a.data()['fechaHora'];
      final fb = b.data()['fechaHora'];

      if (fa is! Timestamp && fb is! Timestamp) return 0;
      if (fa is! Timestamp) return 1;
      if (fb is! Timestamp) return -1;

      return fb.toDate().compareTo(fa.toDate());
    });

    String ultimoAcceso = 'Sin registros';

    if (accesos.isNotEmpty) {
      final data = accesos.first.data();
      ultimoAcceso =
          '${(data['tipoMovimiento'] ?? '').toString().toUpperCase()} - ${_formatDate(data['fechaHora'])}';
    }

    return _HomeData(
      nombre: (perfil['nombreCompleto'] ?? 'Alumno').toString(),
      matricula: (perfil['matricula'] ?? '').toString(),
      carrera: (perfil['carrera'] ?? '').toString(),
      vehiculos: vehiculosSnap.docs.length,
      pasesActivos: pasesActivos,
      accesos: accesosSnap.docs.length,
      ultimoAcceso: ultimoAcceso,
    );
  }

  Widget _buildMisVehiculos() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Mis vehículos',
                  style: TextStyle(
                    color: azulTec,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _abrirRegistroVehiculo,
                icon: const Icon(Icons.add),
                label: const Text('Registrar vehículo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulTec,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db
                .collection('vehiculos')
                .where('alumnoUid', isEqualTo: _uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(
                  child: Text('Aún no tienes vehículos registrados.'),
                );
              }

              final vehiculos = docs.map(_VehicleData.fromDoc).toList();

              vehiculos.sort((a, b) => a.placas.compareTo(b.placas));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: vehiculos.map((vehiculo) {
                    return _VehicleCard(
                      vehiculo: vehiculo,
                      onGenerate: () => _crearOAbrirPase(vehiculo),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiPase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _qrTexto == null
              ? Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 90, color: azulTec),
                    const SizedBox(height: 18),
                    const Text(
                      'No hay pase seleccionado',
                      style: TextStyle(
                        color: azulTec,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ve a “Mis vehículos” y selecciona el vehículo con el que deseas generar tu pase QR.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _selectedIndex = 1);
                      },
                      icon: const Icon(Icons.directions_car),
                      label: const Text('Seleccionar vehículo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulTec,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    const Text(
                      'Pase vehicular',
                      style: TextStyle(
                        color: azulTec,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: _qrTexto!,
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    _InfoRow(label: 'Vehículo', value: _qrVehiculo ?? ''),
                    _InfoRow(label: 'Placas', value: _qrPlacas ?? ''),
                    _InfoRow(label: 'Estado', value: 'Activo'),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _selectedIndex = 1);
                      },
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Cambiar vehículo'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHistorial() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('accesos')
          .where('alumnoUid', isEqualTo: _uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = [...(snapshot.data?.docs ?? [])];

        docs.sort((a, b) {
          final fa = a.data()['fechaHora'];
          final fb = b.data()['fechaHora'];

          if (fa is! Timestamp && fb is! Timestamp) return 0;
          if (fa is! Timestamp) return 1;
          if (fb is! Timestamp) return -1;

          return fb.toDate().compareTo(fa.toDate());
        });

        if (docs.isEmpty) {
          return const Center(
            child: Text('Aún no tienes historial de accesos.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Movimiento')),
              DataColumn(label: Text('Placas')),
              DataColumn(label: Text('Caseta')),
              DataColumn(label: Text('Fecha y hora')),
            ],
            rows: docs.map((doc) {
              final data = doc.data();
              final movimiento = (data['tipoMovimiento'] ?? '')
                  .toString()
                  .toUpperCase();

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      movimiento,
                      style: TextStyle(
                        color: movimiento == 'ENTRADA'
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(Text((data['placas'] ?? '').toString())),
                  DataCell(Text((data['caseta'] ?? '').toString())),
                  DataCell(Text(_formatDate(data['fechaHora']))),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatDate(dynamic raw) {
    if (raw is! Timestamp) {
      return 'Sin fecha';
    }

    final d = raw.toDate();

    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final anio = d.year.toString();
    final hora = d.hour.toString().padLeft(2, '0');
    final minuto = d.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }
}

class _RegistrarVehiculoDialog extends StatefulWidget {
  final FirebaseFirestore db;
  final String alumnoUid;
  final String matricula;
  final String nombreAlumno;

  const _RegistrarVehiculoDialog({
    required this.db,
    required this.alumnoUid,
    required this.matricula,
    required this.nombreAlumno,
  });

  @override
  State<_RegistrarVehiculoDialog> createState() =>
      _RegistrarVehiculoDialogState();
}

class _RegistrarVehiculoDialogState extends State<_RegistrarVehiculoDialog> {
  final _formKey = GlobalKey<FormState>();

  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _placasCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _tipoCtrl = TextEditingController(text: 'Automóvil');

  bool _saving = false;

  @override
  void dispose() {
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _placasCtrl.dispose();
    _colorCtrl.dispose();
    _tipoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.db.collection('vehiculos').add({
        'alumnoUid': widget.alumnoUid,
        'matriculaAlumno': widget.matricula,
        'nombreAlumno': widget.nombreAlumno,
        'placas': _placasCtrl.text.trim().toUpperCase(),
        'marca': _marcaCtrl.text.trim(),
        'modelo': _modeloCtrl.text.trim(),
        'color': _colorCtrl.text.trim().isEmpty
            ? 'No especificado'
            : _colorCtrl.text.trim(),
        'tipo': _tipoCtrl.text.trim().isEmpty
            ? 'Automóvil'
            : _tipoCtrl.text.trim(),
        'estado': 'aprobado',
        'activo': true,
        'creadoPor': widget.alumnoUid,
        'creadoEn': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar vehículo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const azulTec = Color(0xFF1B396A);

    return AlertDialog(
      title: const Text('Registrar vehículo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _marcaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa la marca';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modeloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el modelo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _placasCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Placas',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pin),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa las placas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _colorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.color_lens),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tipoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.commute),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: azulTec,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : const Text('GUARDAR'),
        ),
      ],
    );
  }
}

class _StudentSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _StudentSidebar({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B396A), Color(0xFF10284A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 110,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.school, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Panel\nAlumno',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _StudentMenuItem(
                  icon: Icons.dashboard_outlined,
                  text: 'INICIO',
                  selected: selectedIndex == 0,
                  onTap: () => onSelected(0),
                ),
                _StudentMenuItem(
                  icon: Icons.directions_car,
                  text: 'MIS VEHÍCULOS',
                  selected: selectedIndex == 1,
                  onTap: () => onSelected(1),
                ),
                _StudentMenuItem(
                  icon: Icons.qr_code_2,
                  text: 'MI PASE QR',
                  selected: selectedIndex == 2,
                  onTap: () => onSelected(2),
                ),
                _StudentMenuItem(
                  icon: Icons.history,
                  text: 'HISTORIAL',
                  selected: selectedIndex == 3,
                  onTap: () => onSelected(3),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          _StudentMenuItem(
            icon: Icons.logout,
            text: 'SALIR',
            selected: false,
            onTap: () => onSelected(4),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _StudentMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _StudentMenuItem({
    required this.icon,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const azulTec = Color(0xFF1B396A);

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? azulTec : Colors.white.withOpacity(0.88),
                  size: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: selected
                          ? azulTec
                          : Colors.white.withOpacity(0.88),
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentHeader extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _StudentHeader({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final titles = ['INICIO', 'MIS VEHÍCULOS', 'MI PASE QR', 'HISTORIAL'];

    return Container(
      height: 86,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10284A), Color(0xFF1B396A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 28,
            bottom: 16,
            child: Row(
              children: List.generate(titles.length, (index) {
                final selected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => onSelected(index),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.14),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: selected
                                ? const Color(0xFFD4AF37)
                                : Colors.white24,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        titles[index],
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF1B396A)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Positioned(
            right: 28,
            top: 28,
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Alumno',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleData {
  final String id;
  final String alumnoUid;
  final String matriculaAlumno;
  final String nombreAlumno;
  final String placas;
  final String marca;
  final String modelo;
  final String color;
  final String tipo;
  final String estado;
  final bool activo;

  _VehicleData({
    required this.id,
    required this.alumnoUid,
    required this.matriculaAlumno,
    required this.nombreAlumno,
    required this.placas,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.tipo,
    required this.estado,
    required this.activo,
  });

  factory _VehicleData.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return _VehicleData(
      id: doc.id,
      alumnoUid: (data['alumnoUid'] ?? '').toString(),
      matriculaAlumno: (data['matriculaAlumno'] ?? '').toString(),
      nombreAlumno: (data['nombreAlumno'] ?? '').toString(),
      placas: (data['placas'] ?? '').toString(),
      marca: (data['marca'] ?? '').toString(),
      modelo: (data['modelo'] ?? '').toString(),
      color: (data['color'] ?? 'No especificado').toString(),
      tipo: (data['tipo'] ?? 'Automóvil').toString(),
      estado: (data['estado'] ?? 'pendiente').toString(),
      activo: data['activo'] == true,
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final _VehicleData vehiculo;
  final VoidCallback onGenerate;

  const _VehicleCard({required this.vehiculo, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    final estado = vehiculo.estado.toLowerCase();

    Color estadoColor;

    if (estado == 'aprobado') {
      estadoColor = Colors.green.shade700;
    } else if (estado == 'pendiente') {
      estadoColor = Colors.orange.shade800;
    } else {
      estadoColor = Colors.red.shade700;
    }

    return Container(
      width: 300,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_car, color: Color(0xFF1B396A), size: 38),
          const SizedBox(height: 12),
          Text(
            '${vehiculo.marca} ${vehiculo.modelo}',
            style: const TextStyle(
              color: Color(0xFF1B396A),
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Placas: ${vehiculo.placas}'),
          Text('Color: ${vehiculo.color}'),
          Text('Tipo: ${vehiculo.tipo}'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              vehiculo.estado.toUpperCase(),
              style: TextStyle(
                color: estadoColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: estado == 'aprobado' ? onGenerate : null,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Generar pase QR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B396A),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeData {
  final String nombre;
  final String matricula;
  final String carrera;
  final int vehiculos;
  final int pasesActivos;
  final int accesos;
  final String ultimoAcceso;

  _HomeData({
    required this.nombre,
    required this.matricula,
    required this.carrera,
    required this.vehiculos,
    required this.pasesActivos,
    required this.accesos,
    required this.ultimoAcceso,
  });
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      height: 120,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 38),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ),
    );
  }
}
