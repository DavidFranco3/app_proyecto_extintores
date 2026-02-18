import 'package:flutter/material.dart';
import '../../api/auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login.dart';
import '../Logs/logs_informativos.dart';
import '../../api/usuarios.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      logsInformativos("Sesion cerrada correctamente", {});
      AuthService authService = AuthService();
      authService.logoutApi();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false, // Elimina todas las rutas previas
      );
    } catch (e) {
      if (!context.mounted) return;
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

      if (token == null) {
        throw Exception("Token de usuario no disponible");
      }

      final idUsuario = authService.obtenerIdUsuarioLogueado(token);
      Map<String, dynamic>? user =
          await usuarioService.obtenerUsuario2(idUsuario);

      return {'usuario': user?["nombre"]};
    } catch (e) {
      debugPrint("❌ Error al obtener los datos comunes: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 4,
      shadowColor: Colors.black45,
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2C3E50), // Navy Blue
              Color(0xFF707271), // Dynamic Grey
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Image.asset(
        'lib/assets/img/logo_login.png',
        height: 35,
        fit: BoxFit.contain,
        color: Colors.white,
      ),
      actions: [
        // 👤 Perfil
        PopupMenuButton<String>(
          icon: const FaIcon(
            FontAwesomeIcons.solidCircleUser,
            color: Colors.white,
            size: 26,
          ),
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          onSelected: (value) {
            if (value == "logout") {
              _cerrarSesion(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: "logout",
              child: Row(
                children: const [
                  FaIcon(
                    FontAwesomeIcons.rightFromBracket,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Cerrar sesión",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
