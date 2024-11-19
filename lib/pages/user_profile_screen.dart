import 'package:flutter/material.dart';

class VistaUsuario extends StatelessWidget {
  final String? userName;
  final String? email;
  final String? phoneNumber;

  const VistaUsuario({
    super.key, 
    required this.userName, 
    required this.email, 
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil del Usuario"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (userName?.isNotEmpty ?? false) ? userName! : "Sin nombre de usuario",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (email?.isNotEmpty ?? false) ? email! : "Correo no disponible",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  (phoneNumber?.isNotEmpty ?? false) ? phoneNumber! : "Telefono no disponible",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
