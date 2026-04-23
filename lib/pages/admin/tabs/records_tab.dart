// lib/pages/admin/tabs/records_tab.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/registro_dashboard.dart';

class RecordsTab extends StatefulWidget {
  const RecordsTab({super.key});

  @override
  State<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  final supabase = Supabase.instance.client;
  List<RegistroDashboard> _allRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllRecords();
  }

  Future<void> _fetchAllRecords() async {
    setState(() => _isLoading = true);
    try {
      // Consulta para obtener todos los registros, uniendo la información
      final response = await supabase
          .from('registros_acceso')
          .select(
            '*, vehiculos!inner(id, marca, modelo, placas, alumnos!inner(id, matricula, nombre_completo))',
          )
          .order('created_at', ascending: false);

      _allRecords = (response as List)
          .map(
            (json) => RegistroDashboard.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar registros: $e. Revise las políticas de RLS.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      _allRecords = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateMovement(
    String registroId,
    String currentMovement,
  ) async {
    final newMovement = currentMovement == 'ENTRADA' ? 'SALIDA' : 'ENTRADA';
    try {
      await supabase
          .from('registros_acceso')
          .update({
            'tipo_movimiento': newMovement,
            'created_at': DateTime.now().toIso8601String(),
          })
          .eq('id', registroId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Movimiento actualizado a $newMovement.'),
            backgroundColor: Colors.blue,
          ),
        );
        _fetchAllRecords();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el movimiento.')),
        );
      }
    }
  }

  void _showEditMovementDialog(RegistroDashboard record) {
    final currentMovement = record.tipoMovimiento;
    final newMovement = currentMovement == 'ENTRADA' ? 'SALIDA' : 'ENTRADA';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Corregir Movimiento'),
          content: Text(
            'Cambiar el registro de $currentMovement a $newMovement para ${record.nombreAlumno}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateMovement(record.registroId, currentMovement);
              },
              child: Text('CAMBIAR A $newMovement'),
            ),
          ],
        );
      },
    );
  }

  // Implementación de la función ELIMINAR REGISTRO
  Future<void> _deleteRecord(String registroId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: const Text(
          '¿Está seguro de que desea eliminar este registro de acceso de forma permanente?',
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

    if (confirm == true) {
      try {
        await supabase.from('registros_acceso').delete().eq('id', registroId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro eliminado.'),
              backgroundColor: Colors.blue,
            ),
          );
          _fetchAllRecords();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar registro.'),
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
        onPressed: _fetchAllRecords,
        child: const Icon(Icons.refresh),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allRecords.isEmpty
          ? const Center(
              child: Text("No hay registros de acceso para mostrar."),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 25,
                  columns: const [
                    DataColumn(label: Text('Movimiento')),
                    DataColumn(label: Text('Matrícula')),
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Placas')),
                    DataColumn(label: Text('Fecha y Hora')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: _allRecords.map((record) {
                    final tipoMovimiento = record.tipoMovimiento;

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            tipoMovimiento,
                            style: TextStyle(
                              color: tipoMovimiento == 'ENTRADA'
                                  ? Colors.green.shade700
                                  : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(Text(record.matriculaAlumno)),
                        DataCell(Text(record.nombreAlumno)),
                        DataCell(Text(record.placasVehiculo)),
                        DataCell(Text(record.formattedDate)),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_note,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showEditMovementDialog(record),
                                tooltip: 'Corregir Entrada/Salida',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _deleteRecord(record.registroId),
                                tooltip: 'Eliminar Registro de Acceso',
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
