import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/vehiculo.dart';

class EscanerPage extends StatefulWidget {
  const EscanerPage({super.key});
  @override
  State<EscanerPage> createState() => _EscanerPageState();
}

class _EscanerPageState extends State<EscanerPage> {
  final MobileScannerController _cameraController = MobileScannerController();

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (capture.barcodes.isEmpty) return;
    final codigo = capture.barcodes.first.rawValue;
    if (codigo != null) {
      _cameraController.stop();
      await _procesarCodigo(codigo);
      _cameraController.start();
    }
  }

  // NUEVO MÉTODO: Muestra un selector si hay múltiples vehículos.
  Future<Vehiculo?> _mostrarSelectorVehiculos(List<Vehiculo> vehiculos) async {
    return await showModalBottomSheet<Vehiculo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Múltiples Vehículos Encontrados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Seleccione el vehículo que está ingresando/saliendo.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Divider(height: 30),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: vehiculos
                        .map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              tileColor: Colors.grey[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              leading: Icon(
                                Icons.directions_car_filled,
                                color: primaryColor,
                              ),
                              title: Text(
                                '${v.marca} ${v.modelo}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text('Placas: ${v.placas}'),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () => Navigator.pop(context, v),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text(
                    'Cancelar Operación',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _procesarCodigo(String codigo) async {
    try {
      final supabase = Supabase.instance.client;
      // CONSULTA CORREGIDA: Especifica el join a través de la columna de clave foránea alumno_id
      final dataList = await supabase
          .from('vehiculos')
          .select('*, alumno_id:alumnos(*)')
          .eq('alumno_id.matricula', codigo)
          .order('created_at', ascending: false);

      if (dataList.isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Vehículo no encontrado"),
              backgroundColor: Colors.red,
            ),
          );
        return;
      }

      final List<Vehiculo> vehiculos = dataList
          .map((data) => Vehiculo.fromJson(data))
          .toList();

      Vehiculo? vehiculoSeleccionado;

      if (vehiculos.length > 1) {
        // Mostrar selector si hay más de uno
        vehiculoSeleccionado = await _mostrarSelectorVehiculos(vehiculos);
      } else {
        // Seleccionar automáticamente si solo hay uno
        vehiculoSeleccionado = vehiculos.first;
      }

      if (vehiculoSeleccionado == null) return; // Cancelado por el guardia

      final ultimo = await supabase
          .from('registros_acceso')
          .select()
          .eq('vehiculo_id', vehiculoSeleccionado.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      String accion = (ultimo != null && ultimo['tipo_movimiento'] == 'ENTRADA')
          ? 'SALIDA'
          : 'ENTRADA';

      if (!mounted) return;
      _mostrarFicha(vehiculoSeleccionado, accion);
    } catch (e) {
      print(e);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    }
  }

  void _mostrarFicha(Vehiculo v, String accion) {
    final esEntrada = accion == 'ENTRADA';
    final colorEstado = esEntrada
        ? Colors.green.shade700
        : Colors.orange.shade800;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: colorEstado.withOpacity(0.1),
              child: Icon(
                esEntrada ? Icons.login : Icons.logout,
                size: 40,
                color: colorEstado,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "REGISTRAR $accion",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: colorEstado,
                letterSpacing: 1,
              ),
            ),
            const Divider(height: 40),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _FilaDato(Icons.badge, "Matrícula", v.matriculaAlumno),
                  const Divider(),
                  _FilaDato(
                    Icons.directions_car_filled,
                    "Vehículo",
                    "${v.marca} ${v.modelo}",
                  ),
                  const Divider(),
                  _FilaDato(
                    Icons.pin_drop,
                    "Placas",
                    v.placas,
                    esDatoPrincipal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorEstado,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  await Supabase.instance.client
                      .from('registros_acceso')
                      .insert({'vehiculo_id': v.id, 'tipo_movimiento': accion});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$accion Exitosa"),
                      backgroundColor: colorEstado,
                    ),
                  );
                },
                child: Text(
                  "CONFIRMAR $accion",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Escáner de Seguridad"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("TEST ANDROID"),
        icon: const Icon(Icons.bug_report),
        backgroundColor: Colors.red,
        onPressed: () => _procesarCodigo("MAX001"),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _cameraController, onDetect: _onDetect),
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    height: 280,
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              height: 280,
              width: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.qr_code_scanner, color: Colors.white54, size: 50),
                  SizedBox(height: 10),
                  Text(
                    "Escaneando...",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;
  final bool esDatoPrincipal;
  const _FilaDato(
    this.icon,
    this.titulo,
    this.valor, {
    this.esDatoPrincipal = false,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: esDatoPrincipal ? 20 : 16,
                    fontWeight: esDatoPrincipal
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: Colors.black87,
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
