import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EscanerPage extends StatefulWidget {
  const EscanerPage({super.key});

  @override
  State<EscanerPage> createState() => _EscanerPageState();
}

class _EscanerPageState extends State<EscanerPage> {
  final MobileScannerController _cameraController = MobileScannerController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final codigo = capture.barcodes.first.rawValue;

    if (codigo == null || codigo.trim().isEmpty) return;

    _isProcessing = true;

    try {
      await _cameraController.stop();
      await _procesarCodigo(codigo.trim());
    } finally {
      if (mounted) {
        await _cameraController.start();
      }
      _isProcessing = false;
    }
  }

  Future<void> _procesarCodigo(String codigo) async {
    try {
      if (codigo.toUpperCase().startsWith('PASE:')) {
        await _procesarQrPase(codigo);
      } else {
        await _procesarPorMatricula(codigo);
      }
    } catch (e) {
      _mostrarMensaje('Error: $e', Colors.red);
    }
  }

  Future<void> _procesarQrPase(String codigo) async {
    final partes = codigo.split(':');

    if (partes.length != 3) {
      _mostrarMensaje('QR inválido.', Colors.red);
      return;
    }

    final paseId = partes[1];
    final codigoSeguro = partes[2];

    final paseDoc = await _db.collection('pases_qr').doc(paseId).get();

    if (!paseDoc.exists) {
      _mostrarMensaje('Pase QR no encontrado.', Colors.red);
      return;
    }

    final paseData = paseDoc.data()!;

    if (paseData['codigoSeguro'] != codigoSeguro) {
      _mostrarMensaje('Código QR no válido.', Colors.red);
      return;
    }

    final estadoPase = (paseData['estado'] ?? '').toString().toLowerCase();

    if (estadoPase != 'activo') {
      _mostrarMensaje('Este pase QR no está activo.', Colors.red);
      return;
    }

    final fechaExpiracionRaw = paseData['fechaExpiracion'];

    if (fechaExpiracionRaw is Timestamp) {
      final fechaExpiracion = fechaExpiracionRaw.toDate();

      if (DateTime.now().isAfter(fechaExpiracion)) {
        await _db.collection('pases_qr').doc(paseId).update({
          'estado': 'vencido',
          'actualizadoEn': FieldValue.serverTimestamp(),
        });

        _mostrarMensaje('Este pase QR está vencido.', Colors.red);
        return;
      }
    }

    final alumnoUid = (paseData['alumnoUid'] ?? '').toString();
    final vehiculoId = (paseData['vehiculoId'] ?? '').toString();

    final usuarioValido = await _validarUsuarioAlumno(alumnoUid);

    if (!usuarioValido) return;

    final vehiculoDoc = await _db.collection('vehiculos').doc(vehiculoId).get();

    if (!vehiculoDoc.exists) {
      _mostrarMensaje('Vehículo no encontrado.', Colors.red);
      return;
    }

    final vehiculo = _VehiculoEscaneado.fromFirestore(vehiculoDoc);

    final vehiculoValido = _validarVehiculo(vehiculo);

    if (!vehiculoValido) return;

    final accion = await _obtenerSiguienteMovimiento(vehiculo.id);

    if (!mounted) return;

    await _mostrarFicha(vehiculo: vehiculo, accion: accion, paseId: paseId);
  }

  Future<void> _procesarPorMatricula(String codigo) async {
    final matricula = codigo.trim().toUpperCase();

    final vehiculosSnap = await _db
        .collection('vehiculos')
        .where('matriculaAlumno', isEqualTo: matricula)
        .get();

    if (vehiculosSnap.docs.isEmpty) {
      _mostrarMensaje('Vehículo no encontrado.', Colors.red);
      return;
    }

    final vehiculos = vehiculosSnap.docs
        .map((doc) => _VehiculoEscaneado.fromFirestore(doc))
        .where((v) => v.activo)
        .toList();

    if (vehiculos.isEmpty) {
      _mostrarMensaje('El vehículo está desactivado.', Colors.red);
      return;
    }

    _VehiculoEscaneado? vehiculoSeleccionado;

    if (vehiculos.length > 1) {
      vehiculoSeleccionado = await _mostrarSelectorVehiculos(vehiculos);
    } else {
      vehiculoSeleccionado = vehiculos.first;
    }

    if (vehiculoSeleccionado == null) return;

    final usuarioValido = await _validarUsuarioAlumno(
      vehiculoSeleccionado.alumnoUid,
    );

    if (!usuarioValido) return;

    final vehiculoValido = _validarVehiculo(vehiculoSeleccionado);

    if (!vehiculoValido) return;

    final accion = await _obtenerSiguienteMovimiento(vehiculoSeleccionado.id);

    if (!mounted) return;

    await _mostrarFicha(
      vehiculo: vehiculoSeleccionado,
      accion: accion,
      paseId: null,
    );
  }

  Future<bool> _validarUsuarioAlumno(String alumnoUid) async {
    if (alumnoUid.isEmpty) {
      _mostrarMensaje('El pase no tiene alumno asignado.', Colors.red);
      return false;
    }

    final usuarioDoc = await _db.collection('usuarios').doc(alumnoUid).get();

    if (!usuarioDoc.exists) {
      _mostrarMensaje('El alumno no existe en usuarios.', Colors.red);
      return false;
    }

    final usuario = usuarioDoc.data()!;

    final activo = usuario['activo'] == true;
    final rol = (usuario['rol'] ?? '').toString().toLowerCase();

    if (!activo) {
      _mostrarMensaje('El alumno está desactivado.', Colors.red);
      return false;
    }

    if (rol != 'alumno') {
      _mostrarMensaje('El QR no pertenece a un alumno.', Colors.red);
      return false;
    }

    return true;
  }

  bool _validarVehiculo(_VehiculoEscaneado vehiculo) {
    if (!vehiculo.activo) {
      _mostrarMensaje('El vehículo está desactivado.', Colors.red);
      return false;
    }

    if (vehiculo.estado.toLowerCase() != 'aprobado') {
      _mostrarMensaje(
        'El vehículo no está aprobado. Estado: ${vehiculo.estado}',
        Colors.red,
      );
      return false;
    }

    return true;
  }

  Future<String> _obtenerSiguienteMovimiento(String vehiculoId) async {
    final accesosSnap = await _db
        .collection('accesos')
        .where('vehiculoId', isEqualTo: vehiculoId)
        .get();

    if (accesosSnap.docs.isEmpty) {
      return 'entrada';
    }

    final accesos = accesosSnap.docs.toList();

    accesos.sort((a, b) {
      final fechaA = a.data()['fechaHora'];
      final fechaB = b.data()['fechaHora'];

      if (fechaA is! Timestamp && fechaB is! Timestamp) return 0;
      if (fechaA is! Timestamp) return 1;
      if (fechaB is! Timestamp) return -1;

      return fechaB.toDate().compareTo(fechaA.toDate());
    });

    final ultimoMovimiento = (accesos.first.data()['tipoMovimiento'] ?? '')
        .toString()
        .toLowerCase();

    return ultimoMovimiento == 'entrada' ? 'salida' : 'entrada';
  }

  Future<Map<String, String>> _obtenerDatosSeguridad() async {
    final user = _auth.currentUser;

    if (user == null) {
      return {'uid': '', 'nombre': 'Seguridad', 'caseta': 'No especificada'};
    }

    String nombre = 'Seguridad';
    String caseta = 'No especificada';

    final usuarioDoc = await _db.collection('usuarios').doc(user.uid).get();

    if (usuarioDoc.exists) {
      final data = usuarioDoc.data()!;
      nombre = (data['nombre'] ?? nombre).toString();
    }

    final perfilDoc = await _db
        .collection('perfiles_seguridad')
        .doc(user.uid)
        .get();

    if (perfilDoc.exists) {
      final data = perfilDoc.data()!;
      caseta = (data['casetaAsignada'] ?? caseta).toString();
      nombre = (data['nombreCompleto'] ?? nombre).toString();
    }

    return {'uid': user.uid, 'nombre': nombre, 'caseta': caseta};
  }

  Future<void> _registrarAcceso({
    required _VehiculoEscaneado vehiculo,
    required String accion,
    required String? paseId,
  }) async {
    final datosSeguridad = await _obtenerDatosSeguridad();

    await _db.collection('accesos').add({
      'paseId': paseId ?? '',
      'alumnoUid': vehiculo.alumnoUid,
      'vehiculoId': vehiculo.id,
      'matriculaAlumno': vehiculo.matriculaAlumno,
      'nombreAlumno': vehiculo.nombreAlumno,
      'placas': vehiculo.placas,
      'tipoMovimiento': accion.toLowerCase(),
      'resultado': 'permitido',
      'seguridadUid': datosSeguridad['uid'],
      'nombreSeguridad': datosSeguridad['nombre'],
      'caseta': datosSeguridad['caseta'],
      'fechaHora': FieldValue.serverTimestamp(),
      'observacion': 'Acceso registrado desde escáner QR',
    });

    if (paseId != null && paseId.isNotEmpty) {
      await _db.collection('pases_qr').doc(paseId).update({
        'ultimoUso': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<_VehiculoEscaneado?> _mostrarSelectorVehiculos(
    List<_VehiculoEscaneado> vehiculos,
  ) async {
    return await showModalBottomSheet<_VehiculoEscaneado>(
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
                'Múltiples vehículos encontrados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Seleccione el vehículo que está ingresando o saliendo.',
                style: TextStyle(color: Colors.grey[600]),
              ),

              const Divider(height: 30),

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: vehiculos.map((v) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('Placas: ${v.placas}'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () => Navigator.pop(context, v),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text(
                    'Cancelar operación',
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

  Future<void> _mostrarFicha({
    required _VehiculoEscaneado vehiculo,
    required String accion,
    required String? paseId,
  }) async {
    final esEntrada = accion.toLowerCase() == 'entrada';

    final colorEstado = esEntrada
        ? Colors.green.shade700
        : Colors.orange.shade800;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.82,
            minChildSize: 0.55,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(25, 16, 25, 25),
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
                        radius: 36,
                        backgroundColor: colorEstado.withOpacity(0.1),
                        child: Icon(
                          esEntrada ? Icons.login : Icons.logout,
                          size: 38,
                          color: colorEstado,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'REGISTRAR ${accion.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: colorEstado,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            _FilaDato(
                              Icons.badge,
                              'Matrícula',
                              vehiculo.matriculaAlumno,
                            ),
                            const Divider(),
                            _FilaDato(
                              Icons.person,
                              'Alumno',
                              vehiculo.nombreAlumno,
                            ),
                            const Divider(),
                            _FilaDato(
                              Icons.directions_car_filled,
                              'Vehículo',
                              '${vehiculo.marca} ${vehiculo.modelo}',
                            ),
                            const Divider(),
                            _FilaDato(
                              Icons.pin_drop,
                              'Placas',
                              vehiculo.placas,
                              esDatoPrincipal: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
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
                            try {
                              await _registrarAcceso(
                                vehiculo: vehiculo,
                                accion: accion,
                                paseId: paseId,
                              );

                              if (!mounted) return;

                              Navigator.of(sheetContext).pop(true);

                              _mostrarMensaje(
                                '${accion.toUpperCase()} exitosa',
                                colorEstado,
                              );
                            } catch (e) {
                              _mostrarMensaje(
                                'Error al registrar acceso: $e',
                                Colors.red,
                              );
                            }
                          },
                          child: Text(
                            'CONFIRMAR ${accion.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _mostrarMensaje(String mensaje, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Escáner de Seguridad'),
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
        label: const Text('TEST MATRÍCULA'),
        icon: const Icon(Icons.bug_report),
        backgroundColor: Colors.red,
        onPressed: () => _procesarCodigo('23670001'),
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
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white54, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'Escaneando...',
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

class _VehiculoEscaneado {
  final String id;
  final String alumnoUid;
  final String matriculaAlumno;
  final String nombreAlumno;
  final String placas;
  final String marca;
  final String modelo;
  final String color;
  final String estado;
  final bool activo;

  _VehiculoEscaneado({
    required this.id,
    required this.alumnoUid,
    required this.matriculaAlumno,
    required this.nombreAlumno,
    required this.placas,
    required this.marca,
    required this.modelo,
    required this.color,
    required this.estado,
    required this.activo,
  });

  factory _VehiculoEscaneado.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return _VehiculoEscaneado(
      id: doc.id,
      alumnoUid: (data['alumnoUid'] ?? '').toString(),
      matriculaAlumno: (data['matriculaAlumno'] ?? '').toString(),
      nombreAlumno: (data['nombreAlumno'] ?? '').toString(),
      placas: (data['placas'] ?? '').toString(),
      marca: (data['marca'] ?? '').toString(),
      modelo: (data['modelo'] ?? '').toString(),
      color: (data['color'] ?? '').toString(),
      estado: (data['estado'] ?? 'pendiente').toString(),
      activo: data['activo'] == true,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
