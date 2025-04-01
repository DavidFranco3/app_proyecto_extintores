import 'package:flutter/material.dart';
import '../../api/auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login.dart';
import '../Logs/logs_informativos.dart';
import '../../api/usuarios.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({Key? key}) : super(key: key);

  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      LogsInformativos("Sesion cerrada correctamente", {});
      AuthService authService = AuthService();
      authService.logoutApi();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false, // Elimina todas las rutas previas
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión')),
      );
    }
  }

    Future<Map<String, dynamic>> obtenerDatosComunes() async {
    try {
      final authService = AuthService();
      final usuarioService = UsuariosService();
      final String? token = await authService.getTokenApi();

      // Verificar si el token es nulo
      if (token == null) {
        throw Exception("Token de usuario no disponible");
      }

      // Obtener el ID del usuario
      final idUsuario = await authService.obtenerIdUsuarioLogueado(token);
      Map<String, dynamic>? user = await usuarioService.obtenerUsuario2(idUsuario);

      // Devolver los datos comunes en un mapa
      return {'usuario': user?["nombre"]};
    } catch (e) {
      print("❌ Error al obtener los datos comunes: $e");
      rethrow; // Propaga el error a la función que lo llamó
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 112, 114, 113), // Color del header
      title: Row(
        children: [
          Spacer(), // Empuja los elementos a la derecha
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              icon: FaIcon(FontAwesomeIcons.circleUser, color: Colors.white),
              items: [
                DropdownMenuItem<String>(
                  value: "logout",
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.rightFromBracket, size: 18),
                      SizedBox(width: 10),
                      Text("Cerrar sesión"),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == "logout") {
                  _cerrarSesion(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
