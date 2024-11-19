import 'package:amplify_flutter/amplify_flutter.dart';

class AuthService {
  Future<void> signUp({
    required String userName,
    required String password,
    required String email,
    required String countryCode, // Nuevo parámetro para el código del país
    required String numberPhone,
    required String givenName,
    required String familyName,
    required bool termsAccepted,
  }) async {
    try {

      final phoneNumber = '$countryCode$numberPhone';
      // Crear el mapa de atributos correctamente tipado
      final userAttributes = <AuthUserAttributeKey, String>{
        AuthUserAttributeKey.preferredUsername : userName,
        AuthUserAttributeKey.email: email,
        AuthUserAttributeKey.zoneinfo: 'Phone:${phoneNumber.toString()}',
        AuthUserAttributeKey.givenName: givenName,
        AuthUserAttributeKey.familyName: familyName,
        AuthUserAttributeKey.website: 'termsAccepted:${termsAccepted.toString()}',  // Guardamos termsAccepted como string
      };

      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: userAttributes,
        ),
      );
      
      safePrint('Result: ${result.isSignUpComplete}');
    } on AuthException catch (e) {
      safePrint('Error signing up: ${e.message}');
      rethrow;
    }
  }

  // Método de inicio de sesión
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      safePrint('Result: ${result.isSignedIn}');
    } catch (e) {
      safePrint('Error signing in: $e');
      rethrow;
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      safePrint('Error signing out: $e');
      rethrow;
    }
  }

  // Método para solicitar restablecimiento de contraseña
  Future<void> resetPassword({required String username}) async {
    try {
      await Amplify.Auth.resetPassword(username: username);
    } catch (e) {
      safePrint('Error resetting password: $e');
      rethrow;
    }
  }

  Future<void> resendConfirmationCode({required String email}) async {
  try {
    await Amplify.Auth.resendSignUpCode(username: email);
  } catch (e) {
    safePrint('Error reenviando el código: $e');
  }
}


  // Método para confirmar el restablecimiento de contraseña
  Future<void> confirmPasswordReset({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
    } catch (e) {
      safePrint('Error confirming password reset: $e');
      rethrow;
    }
  }

  // Add social sign-in methods
  Future<void> signInWithGoogle() async {
    try {
      final result = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.google,
      );
      if (result.isSignedIn) {
        await _fetchAndSaveUserAttributes();
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      final result = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.facebook,
      );
      if (result.isSignedIn) {
        await _fetchAndSaveUserAttributes();
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> _fetchAndSaveUserAttributes() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      // Here you can process and store user attributes as needed
      // For example: email, name, profile picture, etc.
    } catch (e) {
      print('Error fetching user attributes: $e');
    }
  }

  String _handleAuthError(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Sign in failed':
          return 'Invalid credentials';
        case 'User not confirmed':
          return 'Please confirm your email first';
        default:
          return error.message;
      }
    }
    return 'An unexpected error occurred';
  }


  // Método para obtener el usuario actual
  Future<AuthUser> getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user;
    } catch (e) {
      safePrint('Error getting current user: $e');
      rethrow;
    }
  }

Future<Map<String, String>> getUserDetails() async {
  try {
    final user = await Amplify.Auth.getCurrentUser();
    final attributes = await Amplify.Auth.fetchUserAttributes();
    return {
      'username': user.username,
      for (var attr in attributes) attr.userAttributeKey.key: attr.value,
    };
  } catch (e) {
    safePrint('Error fetching user details: $e');
    throw Exception('Unable to fetch user details');
  }
}

}



