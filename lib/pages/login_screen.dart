import 'package:ImageRecognition/pages/init_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ImageRecognition/pages/register_screen.dart';
import 'package:ImageRecognition/services/auth_service.dart';
import 'package:ImageRecognition/pages/recover_password_screen.dart';
import 'package:ImageRecognition/pages/confirmation_screen.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class LoginScreen extends StatefulWidget {

  final List<CameraDescription> cameras;
  const LoginScreen({super.key, required this.cameras});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  bool _obscurePassword = true;


  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        // Obtener los atributos del usuario para verificar su estado
        final userDetails = await _authService.getUserDetails();
        
        // Verificar si el usuario está confirmado
        if (userDetails['email_verified'] == 'true') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => InitScreen(cameras: widget.cameras),
            ),
          );
        } else {
          // Si el usuario no está confirmado, redirigir a la pantalla de confirmación
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ConfirmacionScreen(
                cameras: widget.cameras,
                email: user.username, // Amplify usa el email como username
              ),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor confirma tu cuenta antes de continuar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al verificar usuario: $e');
    }
  }


  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Inicio de sesión exitoso!')),
        );
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => InitScreen(cameras: widget.cameras),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage('https://wallpapers.com/images/hd/full-moon-pictures-ts9bqjxyipu9y6b5.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 100),
                          logo(),
                          const SizedBox(height: 20),
                          nombre(),
                          const SizedBox(height: 60),
                          campoEmail(),
                          const SizedBox(height: 16),
                          campoPassword(),
                          errorMensaje(),
                          const SizedBox(height: 24),
                          botonIniciarSesion(),
                          const SizedBox(height: 16),
                          botonOlvidoPassword(context),
                        ],
                      ),
                    ),
                    const Expanded(
                      child: SizedBox(),
                    ),
                    botonCrearCuenta(context, cameras: widget.cameras),
                    const SizedBox(height: 16), // Padding bottom para el botón
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


// Modificar el método iniciarSesion
Future<void> iniciarSesion() async {
  setState(() {
    isLoading = true;
    errorMessage = null;
  });
  
  try {
    await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    
    if (mounted) {
      try {
        final user = await _authService.getCurrentUser();
        final userDetails = await _authService.getUserDetails();
        
        if (userDetails['email_verified'] == 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Inicio de sesión exitoso!')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => InitScreen(
                cameras: widget.cameras,
              ),
            ),
            (Route<dynamic> route) => false,
          );
        } else {
          // Si el usuario no está confirmado, redirigir a la pantalla de confirmación
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ConfirmacionScreen(
                cameras: widget.cameras,
                email: user.username,
              ),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor confirma tu cuenta antes de continuar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        setState(() {
          errorMessage = 'Error al obtener información del usuario';
        });
      }
    }
  } on AuthException catch (e) {
    setState(() {
      if (e.message.contains('User not confirmed')) {
        // Si el error es específicamente de usuario no confirmado
        errorMessage = 'Usuario no confirmado. Por favor verifica tu cuenta.';
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ConfirmacionScreen(
              cameras: widget.cameras,
              email: _emailController.text.trim(),
            ),
          ),
        );
      } else {
        errorMessage = 'Usuario o contraseña incorrectos';
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Error al iniciar sesión'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


Future<void> verificarUsuarioActivo() async {
  try {
    final user = await _authService.getCurrentUser();
    if (mounted && user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => InitScreen(cameras: widget.cameras),
        ),
      );
    }
  } catch (e) {
    print('No hay sesión activa: $e');
  }
}


Widget logo() {
  return Image.network(
    'https://cdn5.vectorstock.com/i/1000x1000/50/69/face-recognition-vector-21825069.jpg',
    width: 100,
    height: 100,
  );
}

Widget nombre() {
  return const Text(
    'Image Recognition',
    style: TextStyle(
      color: Colors.white,
      fontSize: 35.0,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget campoEmail() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: TextFormField(
      controller: _emailController,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: 'Email',
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(Icons.email),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su email';
        }
        return null;
      },
    ),
  );
}


Widget campoPassword() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: 'Contraseña',
        fillColor: Colors.white,
        filled: true,
        prefixIcon: Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su contraseña';
        }
        return null;
      },
    ),
  );
}

Widget errorMensaje() {
  return errorMessage != null
      ? Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              errorMessage!,
              style: TextStyle(color: const Color.fromARGB(255, 198, 187, 81)),
              textAlign: TextAlign.center,
            ),
          ),
        )
      : SizedBox.shrink();
}



Widget botonIniciarSesion() {
  return SizedBox(
    width: 200,
    height: 50,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        // Aquí puedes cambiar el color del botón:
        backgroundColor: const Color.fromARGB(255, 200, 60, 22), // Color naranja

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: isLoading ? null : iniciarSesion,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 18,
                // También puedes cambiar el color del texto si lo deseas:
                color: Colors.white,
                // Opcionalmente añadir negrita:
                // fontWeight: FontWeight.bold,
              ),
            ),
    ),
  );
}

Widget botonOlvidoPassword(BuildContext context) {
  return TextButton(
    onPressed: () async {
      if (_emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingrese su email primero')),
        );
        return;
      }
      try {
        await _authService.resetPassword(
          username: _emailController.text.trim(),
        );
        
        if (mounted) {
          // Navegamos a la pantalla de recuperación
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecuperarPasswordScreen(
                cameras: widget.cameras,
                email: _emailController.text.trim(),
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al solicitar recuperación: $e')),
        );
      }
    },
    child: Text(
      '¿Olvidaste tu contraseña?',
      style: TextStyle(color: Colors.white),
    ),
  );
}


// Widget loginConRedes(BuildContext context) {
//   return Column(
//     children: [
//       const SizedBox(height: 20),
//       const Text(
//         'O continúa con',
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: 16,
//         ),
//       ),
//       const SizedBox(height: 20),
//       SocialLoginButton(
//         icon: Icons.facebook,
//         color: Color(0xFF1877F2), // Facebook blue
//         onPressed: () => _handleSocialLogin(_authService.signInWithFacebook),
//         label: 'Continuar con Facebook',
//       ),
//       const SizedBox(height: 12),
//       SocialLoginButton(
//         icon: Icons.g_mobiledata,
//         color: Color(0xFFDB4437), // Google red
//         onPressed: () => _handleSocialLogin(_authService.signInWithGoogle),
//         label: 'Continuar con Google',
//       ),
//     ],
//   );
// }

// Future<void> _handleSocialLogin(Future<void> Function() socialSignIn) async {
//   setState(() {
//     isLoading = true;
//     errorMessage = null;
//   });

//   try {
//     await socialSignIn();
    
//     if (mounted) {
//       final user = await _authService.getCurrentUser();
//       final email = user?.username ?? '';
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('¡Inicio de sesión exitoso!')),
//       );
      
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(
//           builder: (context) => TerminosCondiciones(
//             cameras: widget.cameras,
//             email: email,
//           ),
//         ),
//         (Route<dynamic> route) => false,
//       );
//     }
//   } catch (e) {
//     setState(() {
//       errorMessage = 'Error en el inicio de sesión social';
//     });
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error al iniciar sesión: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   } finally {
//     setState(() {
//       isLoading = false;
//     });
//   }
// }
}


Widget botonCrearCuenta(BuildContext context, {required List<CameraDescription> cameras}) {
  return TextButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistroScreen(cameras: cameras), // Pasa las cámaras aquí
        ),
      );
    },
    child: Text(
      'Crear cuenta nueva',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        decoration: TextDecoration.underline, // Texto subrayado
      ),
    ),
  );
}

