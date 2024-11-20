import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ImageRecognition/pages/login_screen.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:ImageRecognition/amplifyconfiguration.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  await _configureAmplify();

  runApp(ImageRecognition(cameras: cameras));

}

Future<void> _configureAmplify() async {

  try {
    Amplify.addPlugins([
      AmplifyAuthCognito(),
      AmplifyStorageS3(),
    ]);
    
    await Amplify.configure(amplifyconfig);
    
    print("Amplify configurado exitosamente");

  } catch (e) {

    print('Error configurando Amplify: $e');

  }

}

class ImageRecognition extends StatelessWidget {
  
  final List<CameraDescription> cameras;

  const ImageRecognition({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      
      title: 'Image recognition',
      home: LoginScreen(cameras: cameras),

    );
  }
}
