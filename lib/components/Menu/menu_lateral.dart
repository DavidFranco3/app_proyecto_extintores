import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../page/Clasificaciones/clasificaciones.dart'; // Asegúrate de importar el archivo donde tienes el ClasificacionesPage
import '../../page/Frecuencias/frecuencias.dart';
import '../../page/TiposExtintores/tipos_extintores.dart';
import '../../page/Logs/logs.dart';
import '../Home/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login.dart';
import '../Logs/logs_informativos.dart';
import '../../api/auth.dart';

class MenuLateral extends StatelessWidget {
  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn'); // Remueve el estado de sesión
      LogsInformativos("Sesión cerrada correctamente", {}); // Log informativo
      AuthService authService = AuthService(); // Instancia el servicio de autenticación
      await authService.logoutApi(); // Llama a la API para cerrar sesión
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()), // Navega a la página de login
        (route) => false, // Elimina todas las rutas previas
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión')), // Muestra error en caso de fallo
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 80, // 🔽 Reduciendo el tamaño
            color: Colors.blue,
            child: Center(
              child: Text(
                '',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Inicio'),
            onTap: () {
              Navigator.pop(context); // Cierra el menú lateral
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()), // Navega a la página de Inicio
              );
            },
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.list), // Ícono para Clasificaciones
            title: Text('Clasificaciones'),
            onTap: () {
              Navigator.pop(context); // Cierra el menú lateral
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ClasificacionesPage()), // Navega a la página de Clasificaciones
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today), // Ícono de calendario para Frecuencias
            title: Text('Frecuencias'),
            onTap: () {
              Navigator.pop(context); // Cierra el menú lateral
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FrecuenciasPage()), // Navega a la página de Frecuencias
              );
            },
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.fireExtinguisher), // Ícono de extintor para Tipos de extintores
            title: Text('Tipos de extintores'),
            onTap: () {
              Navigator.pop(context); // Cierra el menú lateral
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TiposExtintoresPage()), // Navega a la página de Tipos de extintores
              );
            },
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.fileLines), // Ícono para Logs
            title: Text('Logs'),
            onTap: () {
              Navigator.pop(context); // Cierra el menú lateral
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LogsPage()), // Navega a la página de Logs
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Cerrar sesión'),
            onTap: () {
              _logout(context); // Llama a la función de logout
            },
          ),
        ],
      ),
    );
  }
}
