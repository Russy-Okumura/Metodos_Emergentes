// lib/models/registro_dashboard.dart
class RegistroDashboard {
  final String registroId;
  final String vehiculoId;
  final String alumnoId;
  final String tipoMovimiento;
  final DateTime createdAt;
  final String matriculaAlumno;
  final String nombreAlumno;
  final String marcaVehiculo;
  final String modeloVehiculo;
  final String placasVehiculo;

  RegistroDashboard({
    required this.registroId,
    required this.vehiculoId,
    required this.alumnoId,
    required this.tipoMovimiento,
    required this.createdAt,
    required this.matriculaAlumno,
    required this.nombreAlumno,
    required this.marcaVehiculo,
    required this.modeloVehiculo,
    required this.placasVehiculo,
  });

  factory RegistroDashboard.fromJson(Map<String, dynamic> json) {
    // La respuesta de Supabase ya viene anidada: registro -> vehiculos -> alumnos
    final vehiculo = json['vehiculos'] as Map<String, dynamic>;
    final alumno = vehiculo['alumnos'] as Map<String, dynamic>;

    return RegistroDashboard(
      registroId: json['id']?.toString() ?? '',
      vehiculoId: vehiculo['id']?.toString() ?? '',
      alumnoId: alumno['id']?.toString() ?? '',
      tipoMovimiento: json['tipo_movimiento'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      matriculaAlumno: alumno['matricula'] as String,
      nombreAlumno: alumno['nombre_completo'] as String,
      marcaVehiculo: vehiculo['marca'] as String,
      modeloVehiculo: vehiculo['modelo'] as String,
      placasVehiculo: vehiculo['placas'] as String,
    );
  }

  String get formattedDate =>
      createdAt.toLocal().toString().substring(0, 16).replaceFirst(' ', ' ');
}
