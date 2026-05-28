// lib/pages/admin/tabs/students_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/registro_dashboard.dart';
import '../edit_data_dialog.dart';

class StudentVehicleData {
  final String alumnoId;
  final String vehiculoId;
  final String matricula;
  final String nombre;
  final String placas;
  final String marca;
  final String modelo;
  final String color;
  final String estado;

  StudentVehicleData({
    required this.alumnoId,
    required this.vehiculoId,
    required this.matricula,
    required this.nombre,
    required this.placas,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.estado,
  });

  String get vehiculo => '$marca $modelo'.trim();

  factory StudentVehicleData.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return StudentVehicleData(
      alumnoId: (data['alumnoUid'] ?? '').toString(),
      vehiculoId: doc.id,
      matricula: (data['matriculaAlumno'] ?? '').toString(),
      nombre: (data['nombreAlumno'] ?? '').toString(),
      placas: (data['placas'] ?? '').toString(),
      marca: (data['marca'] ?? '').toString(),
      modelo: (data['modelo'] ?? '').toString(),
      color: (data['color'] ?? 'No especificado').toString(),
      estado: (data['estado'] ?? 'pendiente').toString(),
    );
  }
}

class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<StudentVehicleData> _allStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _db
          .collection('vehiculos')
          .orderBy('placas')
          .get();

      _allStudents = snapshot.docs.map((doc) {
        return StudentVehicleData.fromFirestore(doc);
      }).toList();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar alumnos y vehículos: $e'),
          backgroundColor: Colors.red,
        ),
      );

      _allStudents = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditDialog(StudentVehicleData studentData) {
    final fakeRecord = RegistroDashboard(
      registroId: '',
      vehiculoId: studentData.vehiculoId,
      alumnoId: studentData.alumnoId,
      tipoMovimiento: '',
      createdAt: DateTime.now(),
      matriculaAlumno: studentData.matricula,
      nombreAlumno: studentData.nombre,
      marcaVehiculo: studentData.marca,
      modeloVehiculo: studentData.modelo,
      placasVehiculo: studentData.placas,
    );

    showDialog(
      context: context,
      builder: (context) {
        return EditDataDialog(
          record: fakeRecord,
          onDataUpdated: _fetchStudents,
        );
      },
    );
  }

  Future<void> _deleteStudent(String alumnoId, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar alumno'),
        content: Text(
          '¿Está seguro de que desea eliminar a $nombre?\n\n'
          'Se eliminarán sus datos de Firestore, su perfil, vehículos, QR y registros de acceso relacionados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final batch = _db.batch();

      final vehiculosSnap = await _db
          .collection('vehiculos')
          .where('alumnoUid', isEqualTo: alumnoId)
          .get();

      for (final doc in vehiculosSnap.docs) {
        batch.delete(doc.reference);
      }

      final pasesSnap = await _db
          .collection('pases_qr')
          .where('alumnoUid', isEqualTo: alumnoId)
          .get();

      for (final doc in pasesSnap.docs) {
        batch.delete(doc.reference);
      }

      final accesosSnap = await _db
          .collection('accesos')
          .where('alumnoUid', isEqualTo: alumnoId)
          .get();

      for (final doc in accesosSnap.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_db.collection('perfiles_alumnos').doc(alumnoId));
      batch.delete(_db.collection('usuarios').doc(alumnoId));

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alumno $nombre eliminado de Firestore.'),
          backgroundColor: Colors.blue,
        ),
      );

      _fetchStudents();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar alumno: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobado':
        return Colors.green.shade700;
      case 'pendiente':
        return Colors.orange.shade800;
      case 'rechazado':
      case 'bloqueado':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchStudents,
        child: const Icon(Icons.refresh),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allStudents.isEmpty
          ? const Center(
              child: Text('No hay alumnos ni vehículos registrados.'),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 25,
                  columns: const [
                    DataColumn(label: Text('Matrícula')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Placas')),
                    DataColumn(label: Text('Vehículo')),
                    DataColumn(label: Text('Color')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: _allStudents.map((student) {
                    return DataRow(
                      cells: [
                        DataCell(Text(student.matricula)),
                        DataCell(Text(student.nombre)),
                        DataCell(Text(student.placas)),
                        DataCell(Text(student.vehiculo)),
                        DataCell(Text(student.color)),
                        DataCell(
                          Text(
                            student.estado.toUpperCase(),
                            style: TextStyle(
                              color: _estadoColor(student.estado),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showEditDialog(student),
                                tooltip: 'Editar alumno/vehículo',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_forever,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteStudent(
                                  student.alumnoId,
                                  student.nombre,
                                ),
                                tooltip: 'Eliminar alumno',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }
}
