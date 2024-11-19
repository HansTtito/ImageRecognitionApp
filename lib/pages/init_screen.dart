import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ImageRecognition/pages/gallery_screen.dart';
import 'package:ImageRecognition/pages/camera_screen.dart'; // Importa CameraScreen
import 'package:ImageRecognition/pages/login_screen.dart';  // Importa LoginScreen
import 'package:ImageRecognition/services/auth_service.dart';
import 'package:ImageRecognition/pages/user_profile_screen.dart';

class InitScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const InitScreen({super.key, required this.cameras});

  @override
  _InitScreenState createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  List<Map<String, dynamic>> folders = [];
  int _selectedIndex = 0;
  late List<Widget> _pages;  // Lista de vistas
  final AuthService _authService = AuthService();
  String _preferredUsername = '';  // Define la variable para el nombre de usuario
  String? _email;  // Define la variable para el correo electrónico
  String? _phoneNumber;  // Define la variable para el correo electrónico

  // Método para manejar el cierre de sesión
  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await _authService.signOut();
      if (context.mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión cerrada correctamente')),
        );
        
        // Navegar a la pantalla de login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen(cameras: widget.cameras)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  void _onImageCaptured(int folderIndex, XFile image) {
    setState(() {
      folders[folderIndex]['images'].add(image);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay cámaras, mostrar indicador de carga
    if (widget.cameras.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<Map<String, String>>(
      future: _authService.getUserDetails(),  // Llama al futuro para obtener los datos del usuario
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (snapshot.hasData) {
          final userData = snapshot.data!;  // Aquí es donde obtienes los datos del usuario
          _preferredUsername = userData['preferred_username'] ?? 'Usuario';
          _email = userData['email']!;
          _phoneNumber = userData['zoneinfo'] ?? 'Número no disponible';

          _pages = [
            VistaUsuario(userName: _preferredUsername, email: _email, phoneNumber: _phoneNumber,),
            GalleryScreen(email: _email),
            CameraScreen(cameras: widget.cameras, email: _email,),
          ];

          return Scaffold(
            appBar: AppBar(
              title: _preferredUsername.isEmpty
                  ? const Text('Cargando...') 
                  : Text('Hola $_preferredUsername'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () => _handleSignOut(context),
                ),
              ],
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_2_sharp),
                  label: 'User',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.photo),
                  label: 'Choose Photos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.camera_alt),
                  label: 'Image Recognition',
                ),
              ],
            ),
          );
        }

        // Si no hay datos disponibles
        return const Scaffold(
          body: Center(child: Text('No se encontraron datos')),
        );
      },
    );
  }
}
