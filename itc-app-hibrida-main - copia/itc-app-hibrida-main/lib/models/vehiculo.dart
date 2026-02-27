class Vehiculo {
  final String id;
  final String matriculaAlumno;
  final String marca;
  final String modelo;
  final String placas;
  final String? color;

  Vehiculo({
    required this.id,
    required this.matriculaAlumno,
    required this.marca,
    required this.modelo,
    required this.placas,
    this.color,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'],
      matriculaAlumno: json['alumnos'] != null ? json['alumnos']['matricula'] : 'Desconocido',
      marca: json['marca'],
      modelo: json['modelo'],
      placas: json['placas'],
      color: json['color'],
    );
  }
}