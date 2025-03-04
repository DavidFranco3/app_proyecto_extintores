import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Logs/logs_informativos.dart';
import '../../api/auth.dart';
import '../../api/usuarios.dart';
import '../../utils/validations.dart';
import '../Home/home.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  final AuthService authService = AuthService();
  final UsuariosService usuarioService = UsuariosService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Completa todos los campos.");
      return;
    }

    if (!isEmailValid(email)) {
      _showMessage("Correo no válido.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await authService.login({
        'email': email,
        'password': password,
      });

      final token = response['token'];
      if (token == null) {
        throw Exception("Token no recibido.");
      }

      final decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['id'] ?? decodedToken['_'];

      if (userId == null) {
        throw Exception("No se pudo obtener el ID del usuario.");
      }

      print('User ID decoded: $userId');

      final userResponse = await usuarioService.obtenerUsuario(userId);
      final Map<String, dynamic> userData = json.decode(userResponse.body);

      final userName = userData['nombre'] ?? 'Usuario';

      print('User Name: $userName');
      _showMessage("Bienvenido $userName");
      LogsInformativos("Se ha iniciado sesion con el usuario $userName", {});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (ex) {
      print('Error en login: $ex');
      _showMessage("Error al iniciar sesión.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 150,
                height: 150,
                child: Image.asset(
                  'lib/assets/img/logo_login.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.person),
                  hintText: 'Usuario',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  icon: const Icon(Icons.lock),
                  hintText: 'Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Iniciar sesión'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
