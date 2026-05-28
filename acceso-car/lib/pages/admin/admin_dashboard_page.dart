// lib/pages/admin/admin_dashboard_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_login_page.dart';
import 'registro_web.dart';
import 'tabs/records_tab.dart';
import 'tabs/students_tab.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  static const Color azulTec = Color(0xFF1B396A);
  static const Color azulOscuro = Color(0xFF10284A);
  static const Color doradoTec = Color(0xFFD4AF37);
  static const Color fondo = Color(0xFFF5F7FA);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      (route) => false,
    );
  }

  void _openRegistroUsuario() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegistroWebPage()),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _EstadoSistema(db: _db, azulTec: azulTec, doradoTec: doradoTec);
      case 1:
        return const RecordsTab();
      case 2:
        return const StudentsTab();
      default:
        return _EstadoSistema(db: _db, azulTec: azulTec, doradoTec: doradoTec);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: _selectedIndex,
            azulTec: azulTec,
            azulOscuro: azulOscuro,
            doradoTec: doradoTec,
            onSelected: (index) {
              if (index == 3) {
                _openRegistroUsuario();
                return;
              }

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
                _TopHeader(
                  selectedIndex: _selectedIndex,
                  azulTec: azulTec,
                  azulOscuro: azulOscuro,
                  doradoTec: doradoTec,
                  onSelected: (index) {
                    if (index == 3) {
                      _openRegistroUsuario();
                      return;
                    }

                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(color: Colors.white, child: _getBody()),
                    ),
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

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Color azulTec;
  final Color azulOscuro;
  final Color doradoTec;
  final ValueChanged<int> onSelected;

  const _Sidebar({
    required this.selectedIndex,
    required this.azulTec,
    required this.azulOscuro,
    required this.doradoTec,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [azulTec, azulOscuro],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 110,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: doradoTec,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Control\nAcceso ITC',
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
                _MenuItem(
                  icon: Icons.dashboard_outlined,
                  text: 'ESTADO',
                  selected: selectedIndex == 0,
                  onTap: () => onSelected(0),
                ),
                _MenuItem(
                  icon: Icons.history_toggle_off,
                  text: 'REGISTROS',
                  selected: selectedIndex == 1,
                  onTap: () => onSelected(1),
                ),
                _MenuItem(
                  icon: Icons.directions_car_filled_outlined,
                  text: 'ALUMNOS Y VEHÍCULOS',
                  selected: selectedIndex == 2,
                  onTap: () => onSelected(2),
                ),
                _MenuItem(
                  icon: Icons.person_add_alt_1,
                  text: 'NUEVO USUARIO',
                  selected: false,
                  onTap: () => onSelected(3),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          _MenuItem(
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? const Color(0xFF1B396A)
                      : Colors.white.withOpacity(0.88),
                  size: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF1B396A)
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

class _TopHeader extends StatelessWidget {
  final int selectedIndex;
  final Color azulTec;
  final Color azulOscuro;
  final Color doradoTec;
  final ValueChanged<int> onSelected;

  const _TopHeader({
    required this.selectedIndex,
    required this.azulTec,
    required this.azulOscuro,
    required this.doradoTec,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final titles = ['ESTADO', 'REGISTROS', 'ALUMNOS', 'NUEVO USUARIO'];

    return Container(
      height: 86,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [azulOscuro, azulTec],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                            color: selected ? doradoTec : Colors.white24,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        titles[index],
                        style: TextStyle(
                          color: selected ? azulTec : Colors.white,
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
                const Icon(Icons.admin_panel_settings, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Administrador',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 18),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: doradoTec,
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

class _EstadoSistema extends StatelessWidget {
  final FirebaseFirestore db;
  final Color azulTec;
  final Color doradoTec;

  const _EstadoSistema({
    required this.db,
    required this.azulTec,
    required this.doradoTec,
  });

  Future<Map<String, int>> _getCounts() async {
    final usuarios = await db.collection('usuarios').get();
    final alumnos = await db
        .collection('usuarios')
        .where('rol', isEqualTo: 'alumno')
        .get();
    final seguridad = await db
        .collection('usuarios')
        .where('rol', isEqualTo: 'seguridad')
        .get();
    final vehiculos = await db.collection('vehiculos').get();
    final pases = await db.collection('pases_qr').get();
    final accesos = await db.collection('accesos').get();

    return {
      'usuarios': usuarios.docs.length,
      'alumnos': alumnos.docs.length,
      'seguridad': seguridad.docs.length,
      'vehiculos': vehiculos.docs.length,
      'pases': pases.docs.length,
      'accesos': accesos.docs.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _getCounts(),
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;

        final data =
            snapshot.data ??
            {
              'usuarios': 0,
              'alumnos': 0,
              'seguridad': 0,
              'vehiculos': 0,
              'pases': 0,
              'accesos': 0,
            };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estado general del sistema',
                style: TextStyle(
                  color: azulTec,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Resumen del control de acceso vehicular registrado en Firebase.',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),

              const SizedBox(height: 28),

              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    _InfoCard(
                      title: 'Usuarios',
                      value: data['usuarios'].toString(),
                      icon: Icons.people_alt_outlined,
                      color: azulTec,
                    ),
                    _InfoCard(
                      title: 'Alumnos',
                      value: data['alumnos'].toString(),
                      icon: Icons.school_outlined,
                      color: Colors.green.shade700,
                    ),
                    _InfoCard(
                      title: 'Seguridad',
                      value: data['seguridad'].toString(),
                      icon: Icons.security_outlined,
                      color: Colors.indigo.shade700,
                    ),
                    _InfoCard(
                      title: 'Vehículos',
                      value: data['vehiculos'].toString(),
                      icon: Icons.directions_car_filled_outlined,
                      color: Colors.orange.shade800,
                    ),
                    _InfoCard(
                      title: 'Pases QR',
                      value: data['pases'].toString(),
                      icon: Icons.qr_code_2,
                      color: doradoTec,
                    ),
                    _InfoCard(
                      title: 'Accesos',
                      value: data['accesos'].toString(),
                      icon: Icons.login_outlined,
                      color: Colors.blueGrey.shade700,
                    ),
                  ],
                ),

              const SizedBox(height: 35),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del sistema',
                      style: TextStyle(
                        color: azulTec,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Base de datos', value: 'Cloud Firestore'),
                    _InfoRow(
                      label: 'Autenticación',
                      value: 'Firebase Authentication',
                    ),
                    _InfoRow(
                      label: 'Roles disponibles',
                      value: 'Administrador, Seguridad y Alumno',
                    ),
                    _InfoRow(
                      label: 'Validación de acceso',
                      value: 'Código QR con pase seguro',
                    ),
                    _InfoRow(
                      label: 'Estado',
                      value: 'Sistema en configuración',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
      width: 210,
      height: 120,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
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
                    fontSize: 13,
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
            width: 190,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
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
