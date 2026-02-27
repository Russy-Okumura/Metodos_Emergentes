// lib/pages/admin/tabs/students_tab.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/registro_dashboard.dart'; // Usamos el modelo para la estructura de datos
import '../edit_data_dialog.dart'; // Para la edición

// Definimos un modelo simplificado para la tabla de Alumnos/Vehículos
class StudentVehicleData {
  final String alumnoId;
  final String vehiculoId;
  final String matricula;
  final String nombre;
  final String placas;
  final String vehiculo;

  StudentVehicleData({
    required this.alumnoId,
    required this.vehiculoId,
    required this.matricula,
    required this.nombre,
    required this.placas,
    required this.vehiculo,
  });

  factory StudentVehicleData.fromJson(Map<String, dynamic> json) {
    // La consulta aquí será diferente, asumimos que estamos consultando vehiculos directamente
    final alumno = json['alumnos'] as Map<String, dynamic>;

    return StudentVehicleData(
      alumnoId: alumno['id']?.toString() ?? '',
      vehiculoId: json['id']?.toString() ?? '',
      matricula: alumno['matricula'] as String,
      nombre: alumno['nombre_completo'] as String,
      placas: json['placas'] as String,
      vehiculo: '${json['marca']} ${json['modelo']}',
    );
  }
}

class StudentsTab extends StatefulWidget {
  const StudentsTab({super.key});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  final supabase = Supabase.instance.client;
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
      // Consulta todos los vehículos y sus alumnos asociados
      final response = await supabase
          .from('vehiculos')
          .select('*, alumnos!inner(id, matricula, nombre_completo)')
          .order('placas', ascending: true);

      _allStudents = (response as List)
          .map(
            (json) => StudentVehicleData.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar alumnos: $e. Revise las políticas de RLS.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      _allStudents = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Muestra el diálogo de edición (reutilizando el widget EditDataDialog)
  void _showEditDialog(StudentVehicleData studentData) {
    // Convertimos StudentVehicleData a RegistroDashboard para reutilizar el diálogo de edición
    final fakeRecord = RegistroDashboard(
      registroId: '', // No importa
      vehiculoId: studentData.vehiculoId,
      alumnoId: studentData.alumnoId,
      tipoMovimiento: '',
      createdAt: DateTime.now(),
      matriculaAlumno: studentData.matricula,
      nombreAlumno: studentData.nombre,
      marcaVehiculo: studentData.vehiculo.split(' ').first, // Simple split
      modeloVehiculo: studentData.vehiculo.split(' ').last, // Simple split
      placasVehiculo: studentData.placas,
    );

    showDialog(
      context: context,
      builder: (context) {
        return EditDataDialog(
          record: fakeRecord,
          onDataUpdated: _fetchStudents, // Recargar la tabla de alumnos
        );
      },
    );
  }

  // Implementación de la función ELIMINAR ALUMNO (Elimina vehículo y alumno en cascada)
  Future<void> _deleteStudent(String alumnoId, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Alumno'),
        content: Text(
          '¿Está seguro de que desea eliminar a $nombre y todos sus vehículos y registros asociados de forma permanente?',
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
              'ELIMINAR PERMANENTEMENTE',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Gracias a la restricción FOREIGN KEY con ON DELETE CASCADE,
        // al eliminar el alumno, sus vehículos y registros_acceso se eliminan automáticamente.
        await supabase.from('alumnos').delete().eq('id', alumnoId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Alumno $nombre eliminado.'),
              backgroundColor: Colors.blue,
            ),
          );
          _fetchStudents();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error al eliminar el alumno. Asegúrese de que la política RLS de DELETE esté activa.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
              child: Text("No hay alumnos ni vehículos registrados."),
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
                    DataColumn(label: Text('Vehículo (Marca/Modelo)')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: _allStudents.map((student) {
                    return DataRow(
                      cells: [
                        DataCell(Text(student.matricula)),
                        DataCell(Text(student.nombre)),
                        DataCell(Text(student.placas)),
                        DataCell(Text(student.vehiculo)),
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
                                tooltip: 'Editar Alumno/Vehículo',
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
                                tooltip: 'Eliminar Alumno',
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
