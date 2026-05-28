// lib/pages/admin/edit_data_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/registro_dashboard.dart';

class EditDataDialog extends StatefulWidget {
  final RegistroDashboard record;
  final VoidCallback onDataUpdated;

  const EditDataDialog({
    super.key,
    required this.record,
    required this.onDataUpdated,
  });

  @override
  State<EditDataDialog> createState() => _EditDataDialogState();
}

class _EditDataDialogState extends State<EditDataDialog> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _matriculaController;
  late TextEditingController _nombreController;

  late TextEditingController _placasController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _matriculaController = TextEditingController(
      text: widget.record.matriculaAlumno,
    );

    _nombreController = TextEditingController(text: widget.record.nombreAlumno);

    _placasController = TextEditingController(
      text: widget.record.placasVehiculo,
    );

    _marcaController = TextEditingController(text: widget.record.marcaVehiculo);

    _modeloController = TextEditingController(
      text: widget.record.modeloVehiculo,
    );
  }

  @override
  void dispose() {
    _matriculaController.dispose();
    _nombreController.dispose();
    _placasController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final alumnoUid = widget.record.alumnoId.toString();
      final vehiculoId = widget.record.vehiculoId.toString();

      final matricula = _matriculaController.text.trim();
      final nombre = _nombreController.text.trim();
      final placas = _placasController.text.trim().toUpperCase();
      final marca = _marcaController.text.trim();
      final modelo = _modeloController.text.trim();

      final batch = _db.batch();

      final alumnoRef = _db.collection('perfiles_alumnos').doc(alumnoUid);
      final usuarioRef = _db.collection('usuarios').doc(alumnoUid);
      final vehiculoRef = _db.collection('vehiculos').doc(vehiculoId);

      batch.update(alumnoRef, {
        'matricula': matricula,
        'nombreCompleto': nombre,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      batch.update(usuarioRef, {
        'nombre': nombre,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      batch.update(vehiculoRef, {
        'matriculaAlumno': matricula,
        'nombreAlumno': nombre,
        'placas': placas,
        'marca': marca,
        'modelo': modelo,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (!mounted) return;

      widget.onDataUpdated();

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos actualizados correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Datos de Alumno y Vehículo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos del Alumno',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),

              TextFormField(
                controller: _matriculaController,
                decoration: const InputDecoration(labelText: 'Matrícula'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Datos del Vehículo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),

              TextFormField(
                controller: _placasController,
                decoration: const InputDecoration(labelText: 'Placas'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(labelText: 'Marca'),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(labelText: 'Modelo'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text('GUARDAR CAMBIOS'),
        ),
      ],
    );
  }
}
