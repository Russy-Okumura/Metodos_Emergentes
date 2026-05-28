// lib/pages/admin/tabs/records_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RecordsTab extends StatefulWidget {
  const RecordsTab({super.key});

  @override
  State<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<_AccessRecord> _allRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllRecords();
  }

  Future<void> _fetchAllRecords() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _db
          .collection('accesos')
          .orderBy('fechaHora', descending: true)
          .get();

      _allRecords = snapshot.docs.map((doc) {
        return _AccessRecord.fromFirestore(doc);
      }).toList();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar registros: $e'),
          backgroundColor: Colors.red,
        ),
      );

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
    final movimientoActual = currentMovement.toLowerCase();
    final nuevoMovimiento = movimientoActual == 'entrada'
        ? 'salida'
        : 'entrada';

    try {
      await _db.collection('accesos').doc(registroId).update({
        'tipoMovimiento': nuevoMovimiento,
        'fechaHora': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Movimiento actualizado a ${nuevoMovimiento.toUpperCase()}.',
          ),
          backgroundColor: Colors.blue,
        ),
      );

      _fetchAllRecords();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el movimiento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditMovementDialog(_AccessRecord record) {
    final currentMovement = record.tipoMovimiento.toUpperCase();
    final newMovement = record.tipoMovimiento.toLowerCase() == 'entrada'
        ? 'SALIDA'
        : 'ENTRADA';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Corregir Movimiento'),
          content: Text(
            '¿Cambiar el registro de $currentMovement a $newMovement para ${record.nombreAlumno}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateMovement(record.registroId, record.tipoMovimiento);
              },
              child: Text('CAMBIAR A $newMovement'),
            ),
          ],
        );
      },
    );
  }

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

    if (confirm != true) return;

    try {
      await _db.collection('accesos').doc(registroId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro eliminado.'),
          backgroundColor: Colors.blue,
        ),
      );

      _fetchAllRecords();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar registro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getMovementColor(String movimiento) {
    final mov = movimiento.toLowerCase();

    if (mov == 'entrada') {
      return Colors.green.shade700;
    }

    if (mov == 'salida') {
      return Colors.orange.shade800;
    }

    return Colors.grey.shade700;
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
              child: Text('No hay registros de acceso para mostrar.'),
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
                    DataColumn(label: Text('Resultado')),
                    DataColumn(label: Text('Fecha y Hora')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: _allRecords.map((record) {
                    final tipoMovimiento = record.tipoMovimiento.toUpperCase();

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            tipoMovimiento,
                            style: TextStyle(
                              color: _getMovementColor(record.tipoMovimiento),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataCell(Text(record.matriculaAlumno)),
                        DataCell(Text(record.nombreAlumno)),
                        DataCell(Text(record.placasVehiculo)),
                        DataCell(Text(record.resultado.toUpperCase())),
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

class _AccessRecord {
  final String registroId;
  final String tipoMovimiento;
  final String matriculaAlumno;
  final String nombreAlumno;
  final String placasVehiculo;
  final String resultado;
  final DateTime? fechaHora;

  _AccessRecord({
    required this.registroId,
    required this.tipoMovimiento,
    required this.matriculaAlumno,
    required this.nombreAlumno,
    required this.placasVehiculo,
    required this.resultado,
    required this.fechaHora,
  });

  factory _AccessRecord.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    DateTime? fecha;

    final fechaRaw = data['fechaHora'];

    if (fechaRaw is Timestamp) {
      fecha = fechaRaw.toDate();
    }

    return _AccessRecord(
      registroId: doc.id,
      tipoMovimiento: (data['tipoMovimiento'] ?? 'entrada').toString(),
      matriculaAlumno: (data['matriculaAlumno'] ?? '').toString(),
      nombreAlumno: (data['nombreAlumno'] ?? '').toString(),
      placasVehiculo: (data['placas'] ?? '').toString(),
      resultado: (data['resultado'] ?? 'permitido').toString(),
      fechaHora: fecha,
    );
  }

  String get formattedDate {
    if (fechaHora == null) {
      return 'Sin fecha';
    }

    final dia = fechaHora!.day.toString().padLeft(2, '0');
    final mes = fechaHora!.month.toString().padLeft(2, '0');
    final anio = fechaHora!.year.toString();

    final hora = fechaHora!.hour.toString().padLeft(2, '0');
    final minuto = fechaHora!.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }
}
