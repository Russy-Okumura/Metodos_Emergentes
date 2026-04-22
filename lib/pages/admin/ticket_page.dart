import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class TicketPage extends StatelessWidget {
  final String matricula;
  final String nombre;
  final String autoDesc;

  const TicketPage({
    super.key,
    required this.matricula,
    required this.nombre,
    required this.autoDesc,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B396A),
      appBar: AppBar(
        title: const Text("Pase Generado"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 350),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "ACCESO AUTORIZADO",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    QrImageView(
                      data: matricula,
                      version: QrVersions.auto,
                      size: 220.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF1B396A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      matricula,
                      style: GoogleFonts.robotoMono(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: const Color(0xFF1B396A),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 30.0,
                        vertical: 10,
                      ),
                      child: Divider(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30.0,
                        vertical: 10,
                      ),
                      child: Column(
                        children: [
                          Text(
                            "ALUMNO",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            nombre,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "VEHÍCULO",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            autoDesc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "Válido para ingreso al ITC",
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle),
                label: const Text("Finalizar y Volver"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B396A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
