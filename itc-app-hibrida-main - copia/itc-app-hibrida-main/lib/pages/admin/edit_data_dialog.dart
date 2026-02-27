// lib/pages/admin/edit_data_dialog.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controladores para los datos del Alumno
  late TextEditingController _matriculaController;
  late TextEditingController _nombreController;

  // Controladores para los datos del Vehículo
  late TextEditingController _placasController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con los datos actuales del registro
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

  // Función principal para actualizar ambos registros: Alumno y Vehículo
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 1. Actualizar datos del ALUMNO
      await _supabase
          .from('alumnos')
          .update({
            'matricula': _matriculaController.text.trim(),
            'nombre_completo': _nombreController.text.trim(),
          })
          .eq('id', widget.record.alumnoId);

      // 2. Actualizar datos del VEHÍCULO
      await _supabase
          .from('vehiculos')
          .update({
            'placas': _placasController.text.trim(),
            'marca': _marcaController.text.trim(),
            'modelo': _modeloController.text.trim(),
          })
          .eq('id', widget.record.vehiculoId);

      if (mounted) {
        widget.onDataUpdated(); // Recarga el dashboard
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos de Alumno y Vehículo actualizados con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
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
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('GUARDAR CAMBIOS'),
        ),
      ],
    );
  }
}
