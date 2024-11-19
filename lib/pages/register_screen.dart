import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:ImageRecognition/services/auth_service.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:ImageRecognition/pages/terms_conditions_screen.dart';

class RegistroScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const RegistroScreen({super.key, required this.cameras});

  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {

  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _userNameControllers = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _givenNameController = TextEditingController();
  final TextEditingController _familyNameController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? errorMessage;
  String? _phoneError;
  PhoneNumber _phoneNumber = PhoneNumber();
  bool _isFormValid = false;


  // Método para actualizar la validez del formulario
  void _updateFormValidity() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isFormValid = true;
      });
    } else {
      setState(() {
        _isFormValid = false;
      });
    }
  }

    @override
  void initState() {
    super.initState();
    // Asegurarse de que el formulario se valide al iniciar
    _userNameControllers.addListener(_updateFormValidity);
    _emailController.addListener(_updateFormValidity);
    _passwordController.addListener(_updateFormValidity);
    // _phoneController.addListener(_updateFormValidity);
    _givenNameController.addListener(_updateFormValidity);
    _familyNameController.addListener(_updateFormValidity);
  }


  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es requerido';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ingrese un correo electrónico válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  // Opcional: Agregar un método de validación personalizado
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un número de teléfono';
    }
    // if (value.length < 10) {
    //   return 'El número debe tener al menos 10 dígitos';
    // }
    return null;
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // En lugar de crear el usuario directamente, navegamos a términos y condiciones
      if (!mounted) return;
      final String countryDialCode = _phoneNumber.dialCode ?? ''; // Obtén el código de país
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TerminosCondiciones(
            username: _userNameControllers.text,
            cameras: widget.cameras,
            email: _emailController.text,
            password: _passwordController.text,
            countryDialCode: countryDialCode,
            numberPhone: _phoneController.text,
            givenName: _givenNameController.text,
            familyName: _familyNameController.text,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _userNameControllers,
      decoration: InputDecoration(
        labelText: 'Nombre de usuario',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El nombre de usuario es requerido';
        }
        if (value.length < 3) {
          return 'El nombre de usuario debe tener al menos 3 caracteres';
        }
        return null;
      },
    );
  }


  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _givenNameController,
            decoration: InputDecoration(
              labelText: 'Nombres',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Campo requerido' : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _familyNameController,
            decoration: InputDecoration(
              labelText: 'Apellidos',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Campo requerido' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: _validateEmail,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: Icon(Icons.lock_outline),
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
      validator: _validatePassword,
    );
  }

Widget _buildPhoneField() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      border: Border.all(
        color: _phoneError != null ? Colors.red : Colors.grey.shade400,
        width: 1.0,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: InternationalPhoneNumberInput(
      onInputChanged: (PhoneNumber number) {
        setState(() {
          _phoneNumber = number;

          // Solo actualiza el controlador de texto si el número es válido.
          if (number.phoneNumber != null && number.phoneNumber!.startsWith(_phoneNumber.dialCode ?? '')) {
            _phoneController.text = number.phoneNumber!.substring(_phoneNumber.dialCode!.length); // Remueve el código del país si ya está presente
          } else {
            _phoneController.text = number.phoneNumber ?? '';
          }
        });
      },
      onInputValidated: (bool isValid) {
        setState(() {
          _phoneError = isValid ? null : 'Número de teléfono inválido';
        });
      },
      selectorConfig: SelectorConfig(
        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
        showFlags: true,
        useEmoji: true,
        setSelectorButtonAsPrefixIcon: true,
      ),
      textFieldController: _phoneController,
      spaceBetweenSelectorAndTextField: 0,
      ignoreBlank: false,
      autoValidateMode: AutovalidateMode.disabled,
      keyboardType: TextInputType.number, // Aseguramos teclado numérico
      inputBorder: InputBorder.none,
      inputDecoration: InputDecoration(
        contentPadding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
        border: InputBorder.none,
        hintText: 'Número de teléfono',
        errorStyle: const TextStyle(height: 0),
      ),
      searchBoxDecoration: InputDecoration(
        labelText: 'Buscar país',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}



  Widget _buildErrorMessageWidget() {
    if (errorMessage == null) return Container();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        errorMessage!,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: isLoading || !_isFormValid ? null : _signUp,  // Desactivar botón si el formulario no es válido
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Color.fromARGB(255, 157, 152, 152),  // Cambiar color de fondo del botón si es necesario
      ),
      child: isLoading
          ? const SizedBox(
              width: 21,  // Ajustar el tamaño del CircularProgressIndicator
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white, // Cambiar el color del circulo de carga
                strokeWidth: 2, // Ajustar grosor si es necesario
              ),
            )
          : const Text(
              'Registrarse',
              style: TextStyle(
                fontSize: 18, // Aumentar el tamaño de la fuente
                fontWeight: FontWeight.bold,
                color: Colors.white, // Cambiar el color del texto
              ),
            ),
    );
  }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Crear cuenta',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete sus datos para registrarse',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 32),
                    _buildUsernameField(),
                    const SizedBox(height: 32),
                    _buildNameFields(),
                    const SizedBox(height: 16),
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 16),
                    _buildPhoneField(),
                    const SizedBox(height: 24),
                    _buildErrorMessageWidget(),
                    const SizedBox(height: 24),
                    _buildRegisterButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
 

}