import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({Key? key}) : super(key: key);

  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');

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

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue, // Color del header
      title: Row(
        children: [
          Spacer(), // Empuja los elementos a la derecha
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              icon: FaIcon(FontAwesomeIcons.userCircle, color: Colors.white),
              items: [
                DropdownMenuItem<String>(
                  value: "logout",
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.signOutAlt, size: 18),
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
