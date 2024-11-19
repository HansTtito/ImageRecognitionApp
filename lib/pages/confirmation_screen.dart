import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:ImageRecognition/pages/login_screen.dart';
import 'package:camera/camera.dart';
import 'package:ImageRecognition/services/auth_service.dart';

class ConfirmacionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String email;

  ConfirmacionScreen({super.key, required this.cameras, required this.email}); // Asegurarse de que el constructor reciba cámaras

  @override
  _ConfirmacionScreenState createState() => _ConfirmacionScreenState();
}

class _ConfirmacionScreenState extends State<ConfirmacionScreen> {
  final _confirmationCodeController = TextEditingController();

  final AuthService _authService = AuthService();  // Instanciamos AuthService

  // Función para confirmar el registro con el código recibido
  Future<void> _confirmRegistration() async {
    try {
      final confirmResult = await Amplify.Auth.confirmSignUp(
        username: widget.email,
        confirmationCode: _confirmationCodeController.text.trim(),
      );

      if (confirmResult.isSignUpComplete) {
        // Si la confirmación fue exitosa, redirigir a la pantalla de inicio de sesión
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(cameras: widget.cameras), // Pasar cameras
          ),
        );
      } else {
        _showError("La confirmación no fue exitosa. Intenta nuevamente.");
      }
    } catch (e) {
      _showError("Error al confirmar registro: $e");
    }
  }

  // Función para reenviar el código de confirmación
  Future<void> _resendCode() async {
    try {
      await _authService.resendConfirmationCode(email: widget.email);  // Usamos el método de AuthService
      _showMessage("El código de confirmación ha sido reenviado a tu correo.");
    } catch (e) {
      _showError("Error al reenviar el código: $e");
    }
  }


  // Mostrar mensaje de éxito
  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Mostrar mensaje de error
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Correo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Puedes manejar la acción de retroceso aquí, por ejemplo, simplemente regresar a la pantalla anterior
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Ingresa el código de confirmación enviado a tu correo.'),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmationCodeController,
              decoration: const InputDecoration(labelText: 'Código de Confirmación'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _confirmRegistration,
              child: const Text('Confirmar'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _resendCode,
              child: const Text('Reenviar código'),
            ),
          ],
        ),
      ),
    );
  }


}
