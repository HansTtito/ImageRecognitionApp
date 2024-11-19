import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ImageRecognition/services/auth_service.dart';
import 'package:ImageRecognition/pages/confirmation_screen.dart';

class TerminosCondiciones extends StatelessWidget {
  final List<CameraDescription> cameras;
  final String username;
  final String email;
  final String password;
  final String numberPhone;
  final String givenName;
  final String familyName;
  final String countryDialCode;
  final AuthService _authService = AuthService();

  TerminosCondiciones({
    super.key, 
    required this.username,
    required this.cameras, 
    required this.email,
    required this.password,
    required this.numberPhone,
    required this.givenName,
    required this.familyName,
    required this.countryDialCode,
  });

  Future<void> _handleAcceptTerms(BuildContext context) async {
    try {
      // Registrar usuario con términos aceptados
      await _authService.signUp(
        userName: username,
        password: password,
        email: email,
        countryCode: countryDialCode,
        numberPhone: numberPhone,
        givenName: givenName,
        familyName: familyName,
        termsAccepted: true,
      );

      if (context.mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada exitosamente')),
        );
        
        // Navegar a la pantalla de confirmación
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmacionScreen(
              cameras: cameras,
              email: email
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la cuenta: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 69, 74, 79),
        title: const Text('Términos y condiciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Términos y condiciones',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTermsContent(),
                const SizedBox(height: 24),
                _buildAcceptButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          '1. Uso de la aplicación',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Al utilizar esta aplicación, aceptas que la información proporcionada será utilizada para mejorar tu experiencia...',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 16),
        Text(
          '2. Privacidad y datos personales',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Nos comprometemos a proteger tu información personal de acuerdo con nuestra política de privacidad...',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 16),
        Text(
          '3. Responsabilidades',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'El usuario se compromete a hacer un uso adecuado de la aplicación y sus servicios...',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 250,
        child: ElevatedButton(
          onPressed: () => _handleAcceptTerms(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 69, 74, 79),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Aceptar y continuar',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}