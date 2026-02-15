import 'package:flutter/material.dart';
import '../../api/auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login.dart';
import '../Logs/logs_informativos.dart';
import '../../api/usuarios.dart';

import '../../utils/offline_sync_util.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    // ... logic remains same
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      logsInformativos("Sesion cerrada correctamente", {});
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
      backgroundColor: const Color.fromARGB(255, 112, 114, 113),
      title: Row(
        children: [
          Spacer(),
          // 🔄 Indicador de sincronización offline
          ValueListenableBuilder<int>(
            valueListenable: OfflineSyncUtil().pendingCount,
            builder: (context, count, child) {
              if (count == 0) return SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.cloudArrowUp,
                          color: Colors.white),
                      onPressed: () {
                        OfflineSyncUtil().sincronizarTodo();
                      },
                      tooltip: 'Sincronizar pendientes ($count)',
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
