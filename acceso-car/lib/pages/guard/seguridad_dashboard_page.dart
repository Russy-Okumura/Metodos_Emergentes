import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/admin_login_page.dart';
import 'escaner.dart';

class SeguridadDashboardPage extends StatefulWidget {
  const SeguridadDashboardPage({super.key});

  @override
  State<SeguridadDashboardPage> createState() => _SeguridadDashboardPageState();
}

class _SeguridadDashboardPageState extends State<SeguridadDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _selectedIndex = 0;
  int _refreshCounter = 0;

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

  void _abrirEscaner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EscanerPage()),
    );
  }

  void _actualizarDashboard() {
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Información actualizada'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildInicio();
      case 1:
        return _buildEscanerPanel();
      case 2:
        return _buildHistorial();
      case 3:
        return _buildPerfil();
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
          _SecuritySidebar(
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
                _SecurityHeader(
                  selectedIndex: _selectedIndex,
                  onRefresh: _actualizarDashboard,
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
    return FutureBuilder<_SecurityHomeData>(
      future: _loadHomeData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data;

        if (data == null) {
          return const Center(
            child: Text('No se pudo cargar la información de seguridad.'),
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
                'Caseta asignada: ${data.caseta} · Turno: ${data.turno}',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 28),

              Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  _InfoCard(
                    title: 'Accesos registrados',
                    value: data.totalAccesos.toString(),
                    icon: Icons.fact_check_outlined,
                    color: azulTec,
                  ),
                  _InfoCard(
                    title: 'Accesos de hoy',
                    value: data.accesosHoy.toString(),
                    icon: Icons.today_outlined,
                    color: Colors.green.shade700,
                  ),
                  _InfoCard(
                    title: 'Caseta',
                    value: data.casetaCorta,
                    icon: Icons.sensor_door_outlined,
                    color: doradoTec,
                  ),
                ],
              ),

              const SizedBox(height: 34),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: azulTec.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        size: 42,
                        color: azulTec,
                      ),
                    ),
                    const SizedBox(width: 22),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Escaneo de acceso vehicular',
                            style: TextStyle(
                              color: azulTec,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Desde esta sección puedes abrir el escáner QR para validar pases, registrar entradas y salidas, y guardar el historial en Firebase.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    ElevatedButton.icon(
                      onPressed: _abrirEscaner,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Abrir escáner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulTec,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 34),

              const Text(
                'Últimos accesos registrados',
                style: TextStyle(
                  color: azulTec,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              _RecentAccessList(db: _db, seguridadUid: _uid),
            ],
          ),
        );
      },
    );
  }

  Future<_SecurityHomeData> _loadHomeData() async {
    String nombre = 'Seguridad';
    String turno = 'No especificado';
    String caseta = 'No especificada';

    final usuarioDoc = await _db.collection('usuarios').doc(_uid).get();

    if (usuarioDoc.exists) {
      final data = usuarioDoc.data()!;
      nombre = (data['nombre'] ?? nombre).toString();
    }

    final perfilDoc = await _db
        .collection('perfiles_seguridad')
        .doc(_uid)
        .get();

    if (perfilDoc.exists) {
      final data = perfilDoc.data()!;
      nombre = (data['nombreCompleto'] ?? nombre).toString();
      turno = (data['turno'] ?? turno).toString();
      caseta = (data['casetaAsignada'] ?? caseta).toString();
    }

    final accesosSnap = await _db
        .collection('accesos')
        .where('seguridadUid', isEqualTo: _uid)
        .get();

    final hoy = DateTime.now();

    final accesosHoy = accesosSnap.docs.where((doc) {
      final fechaRaw = doc.data()['fechaHora'];

      if (fechaRaw is! Timestamp) return false;

      final fecha = fechaRaw.toDate();

      return fecha.year == hoy.year &&
          fecha.month == hoy.month &&
          fecha.day == hoy.day;
    }).length;

    return _SecurityHomeData(
      nombre: nombre,
      turno: turno,
      caseta: caseta,
      totalAccesos: accesosSnap.docs.length,
      accesosHoy: accesosHoy,
    );
  }

  Widget _buildEscanerPanel() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 650),
        padding: const EdgeInsets.all(34),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: azulTec.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 62,
                color: azulTec,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Escáner de seguridad',
              style: TextStyle(
                color: azulTec,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Utiliza la cámara para leer el pase QR del alumno. El sistema validará el pase, el vehículo y registrará automáticamente la entrada o salida.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _abrirEscaner,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text(
                  'INICIAR ESCANEO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulTec,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Asegúrate de tener permisos de cámara habilitados.',
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorial() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('accesos')
          .where('seguridadUid', isEqualTo: _uid)
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
            child: Text('Aún no tienes registros de acceso.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Historial de accesos',
                style: TextStyle(
                  color: azulTec,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    azulTec.withOpacity(0.08),
                  ),
                  columnSpacing: 26,
                  columns: const [
                    DataColumn(label: Text('Movimiento')),
                    DataColumn(label: Text('Matrícula')),
                    DataColumn(label: Text('Alumno')),
                    DataColumn(label: Text('Placas')),
                    DataColumn(label: Text('Caseta')),
                    DataColumn(label: Text('Fecha y hora')),
                  ],
                  rows: docs.map((doc) {
                    final data = doc.data();

                    final movimiento = (data['tipoMovimiento'] ?? '')
                        .toString()
                        .toUpperCase();

                    final colorMovimiento = movimiento == 'ENTRADA'
                        ? Colors.green.shade700
                        : Colors.orange.shade800;

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            movimiento,
                            style: TextStyle(
                              color: colorMovimiento,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(
                          Text((data['matriculaAlumno'] ?? '').toString()),
                        ),
                        DataCell(Text((data['nombreAlumno'] ?? '').toString())),
                        DataCell(Text((data['placas'] ?? '').toString())),
                        DataCell(Text((data['caseta'] ?? '').toString())),
                        DataCell(Text(_formatDate(data['fechaHora']))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerfil() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadPerfil(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 650),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mi perfil de seguridad',
                  style: TextStyle(
                    color: azulTec,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 22),

                _InfoRow(
                  label: 'Nombre',
                  value: (data['nombreCompleto'] ?? data['nombre'] ?? '')
                      .toString(),
                ),
                _InfoRow(
                  label: 'Correo',
                  value: (data['correo'] ?? '').toString(),
                ),
                _InfoRow(
                  label: 'Teléfono',
                  value: (data['telefono'] ?? '').toString(),
                ),
                _InfoRow(
                  label: 'Turno',
                  value: (data['turno'] ?? '').toString(),
                ),
                _InfoRow(
                  label: 'Caseta',
                  value: (data['casetaAsignada'] ?? '').toString(),
                ),
                _InfoRow(
                  label: 'Estado',
                  value: (data['estado'] ?? 'activo').toString(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadPerfil() async {
    final result = <String, dynamic>{};

    final usuarioDoc = await _db.collection('usuarios').doc(_uid).get();

    if (usuarioDoc.exists) {
      result.addAll(usuarioDoc.data()!);
    }

    final perfilDoc = await _db
        .collection('perfiles_seguridad')
        .doc(_uid)
        .get();

    if (perfilDoc.exists) {
      result.addAll(perfilDoc.data()!);
    }

    return result;
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

class _SecuritySidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SecuritySidebar({
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
                    color: Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.security, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Panel\nSeguridad',
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
                _SecurityMenuItem(
                  icon: Icons.dashboard_outlined,
                  text: 'INICIO',
                  selected: selectedIndex == 0,
                  onTap: () => onSelected(0),
                ),
                _SecurityMenuItem(
                  icon: Icons.qr_code_scanner,
                  text: 'ESCANEAR QR',
                  selected: selectedIndex == 1,
                  onTap: () => onSelected(1),
                ),
                _SecurityMenuItem(
                  icon: Icons.history,
                  text: 'HISTORIAL',
                  selected: selectedIndex == 2,
                  onTap: () => onSelected(2),
                ),
                _SecurityMenuItem(
                  icon: Icons.person_outline,
                  text: 'MI PERFIL',
                  selected: selectedIndex == 3,
                  onTap: () => onSelected(3),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24),

          _SecurityMenuItem(
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

class _SecurityMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _SecurityMenuItem({
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

class _SecurityHeader extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onRefresh;

  const _SecurityHeader({
    required this.selectedIndex,
    required this.onSelected,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final titles = ['INICIO', 'ESCANEAR QR', 'HISTORIAL', 'MI PERFIL'];

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

          Positioned(
            right: 28,
            top: 22,
            child: Row(
              children: [
                IconButton(
                  onPressed: onRefresh,
                  tooltip: 'Actualizar',
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),

                const SizedBox(width: 8),

                const Icon(Icons.security, color: Colors.white),

                const SizedBox(width: 8),

                const Text(
                  'Seguridad',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 14),

                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 21,
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

class _RecentAccessList extends StatelessWidget {
  final FirebaseFirestore db;
  final String seguridadUid;

  const _RecentAccessList({required this.db, required this.seguridadUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('accesos')
          .where('seguridadUid', isEqualTo: seguridadUid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = [...(snapshot.data?.docs ?? [])];

        docs.sort((a, b) {
          final fa = a.data()['fechaHora'];
          final fb = b.data()['fechaHora'];

          if (fa is! Timestamp && fb is! Timestamp) return 0;
          if (fa is! Timestamp) return 1;
          if (fb is! Timestamp) return -1;

          return fb.toDate().compareTo(fa.toDate());
        });

        final recientes = docs.take(5).toList();

        if (recientes.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Aún no hay accesos registrados por este usuario.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return Column(
          children: recientes.map((doc) {
            final data = doc.data();

            final movimiento = (data['tipoMovimiento'] ?? '')
                .toString()
                .toUpperCase();

            final colorMovimiento = movimiento == 'ENTRADA'
                ? Colors.green.shade700
                : Colors.orange.shade800;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorMovimiento.withOpacity(0.12),
                    child: Icon(
                      movimiento == 'ENTRADA' ? Icons.login : Icons.logout,
                      color: colorMovimiento,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '${data['nombreAlumno'] ?? ''} · ${data['placas'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    movimiento,
                    style: TextStyle(
                      color: colorMovimiento,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SecurityHomeData {
  final String nombre;
  final String turno;
  final String caseta;
  final int totalAccesos;
  final int accesosHoy;

  _SecurityHomeData({
    required this.nombre,
    required this.turno,
    required this.caseta,
    required this.totalAccesos,
    required this.accesosHoy,
  });

  String get casetaCorta {
    if (caseta.length <= 8) return caseta;
    return caseta.substring(0, 8);
  }
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
      width: 225,
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    fontSize: 13,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
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
            child: Text(
              value.isEmpty ? 'No especificado' : value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
