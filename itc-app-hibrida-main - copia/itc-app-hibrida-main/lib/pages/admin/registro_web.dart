import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ticket_page.dart';

class RegistroWebPage extends StatefulWidget {
  const RegistroWebPage({super.key});
  @override
  State<RegistroWebPage> createState() => _RegistroWebPageState();
}

class _RegistroWebPageState extends State<RegistroWebPage> {
  final _matriculaCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _placasCtrl = TextEditingController();
  bool _cargando = false;

  Future<void> _registrarAlumno() async {
    if (_matriculaCtrl.text.isEmpty || _nombreCtrl.text.isEmpty) return;
    setState(() => _cargando = true);
    try {
      final supabase = Supabase.instance.client;
      final alumnoResponse = await supabase.from('alumnos').insert({
        'matricula': _matriculaCtrl.text.toUpperCase(),
        'nombre_completo': _nombreCtrl.text,
        'carrera': 'ISC', 
      }).select().single();
      await supabase.from('vehiculos').insert({
        'alumno_id': alumnoResponse['id'],
        'marca': _marcaCtrl.text,
        'modelo': _modeloCtrl.text,
        'placas': _placasCtrl.text.toUpperCase(),
        'color': 'Generico',
      });
      if (!mounted) return;
      setState(() => _cargando = false);
      Navigator.push(context, MaterialPageRoute(builder: (context) => TicketPage(
            matricula: _matriculaCtrl.text.toUpperCase(),
            nombre: _nombreCtrl.text,
            autoDesc: "${_marcaCtrl.text} ${_modeloCtrl.text}",
      ))).then((_) => _limpiar());
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _limpiar() {
    _matriculaCtrl.clear(); _nombreCtrl.clear(); _marcaCtrl.clear(); _modeloCtrl.clear(); _placasCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Administrativo'), backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [Icon(Icons.app_registration, size: 30, color: Theme.of(context).primaryColor), const SizedBox(width: 15), const Text("Nuevo Ingreso", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 10), const Text("Complete el formulario para generar el pase.", style: TextStyle(color: Colors.grey)), const Divider(height: 40),
                    TextField(controller: _matriculaCtrl, decoration: const InputDecoration(labelText: 'Matrícula', prefixIcon: Icon(Icons.badge_outlined))), const SizedBox(height: 20),
                    TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 20),
                    Row(children: [Expanded(child: TextField(controller: _marcaCtrl, decoration: const InputDecoration(labelText: 'Marca', prefixIcon: Icon(Icons.directions_car_outlined)))), const SizedBox(width: 15), Expanded(child: TextField(controller: _modeloCtrl, decoration: const InputDecoration(labelText: 'Modelo', prefixIcon: Icon(Icons.numbers))))]), const SizedBox(height: 20),
                    TextField(controller: _placasCtrl, decoration: const InputDecoration(labelText: 'Placas', prefixIcon: Icon(Icons.featured_play_list_outlined))), const SizedBox(height: 40),
                    SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(onPressed: _cargando ? null : _registrarAlumno, icon: const Icon(Icons.arrow_forward), label: _cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('REGISTRAR Y VER TICKET'), style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white)))
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}