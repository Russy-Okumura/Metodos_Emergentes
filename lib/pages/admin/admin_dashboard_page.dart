// lib/pages/admin/admin_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registro_web.dart';
import 'tabs/records_tab.dart'; // <--- NUEVA PESTAÑA 1
import 'tabs/students_tab.dart'; // <--- NUEVA PESTAÑA 2

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final supabase = Supabase.instance.client;

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Gestión de Acceso ITC',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            // El botón de registro de alumnos se mueve al Dashboard
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegistroWebPage(),
                ),
              ),
              icon: const Icon(Icons.person_add, color: Colors.white),
              tooltip: 'Nuevo Registro de Alumno',
            ),
            IconButton(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Cerrar Sesión',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.history_toggle_off),
                text: "Registros de Acceso",
              ),
              Tab(icon: Icon(Icons.group), text: "Alumnos y Vehículos"),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Color(0xFFD4AF37),
          ),
        ),
        body: const TabBarView(
          children: [
            // Pestaña 1: Muestra TODOS los registros (Entrada/Salida)
            RecordsTab(),
            // Pestaña 2: Muestra la lista de Alumnos y Vehículos para CRUD
            StudentsTab(),
          ],
        ),
      ),
    );
  }
}
