import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../page/Clasificaciones/clasificaciones.dart';
import '../../page/Frecuencias/frecuencias.dart';
import '../../page/TiposExtintores/tipos_extintores.dart';
import '../../page/Extintores/extintores.dart';
import '../../page/Logs/logs.dart';
import '../Home/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login.dart';
import '../Logs/logs_informativos.dart';
import '../../api/auth.dart';

class MenuLateral extends StatelessWidget {
  final String currentPage; // Variable para identificar la página actual

  // Constructor para recibir la página actual
  MenuLateral({required this.currentPage});

  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn'); // Remueve el estado de sesión
      LogsInformativos("Sesión cerrada correctamente", {}); // Log informativo
      AuthService authService =
          AuthService(); // Instancia el servicio de autenticación
      await authService.logoutApi(); // Llama a la API para cerrar sesión
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => LoginPage()), // Navega a la página de login
        (route) => false, // Elimina todas las rutas previas
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error al cerrar sesión')), // Muestra error en caso de fallo
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
            height: 80, // Reduciendo el tamaño
            color: Colors.blue,
            child: Center(
              child: Text(
                '',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          _buildListTile(
            context,
            Icons.home,
            'Inicio',
            HomePage(),
          ),
          _buildListTile(
            context,
            FontAwesomeIcons.list,
            'Clasificaciones',
            ClasificacionesPage(),
          ),
          _buildListTile(
            context,
            Icons.calendar_today,
            'Frecuencias',
            FrecuenciasPage(),
          ),
          // Menú principal para Extintores con opciones desplegables
          ExpansionTile(
            leading: Icon(FontAwesomeIcons.fireAlt),
            title: Text(
              'Extintores',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
            dense: true,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero), // Elimina la línea inferior
            collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero), // Elimina la línea superior
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Column(
                  children: [
                    _buildListTile(
                      context,
                      FontAwesomeIcons.fireExtinguisher,
                      'Extintores',
                      ExtintoresPage(),
                    ),
                    _buildListTile(
                      context,
                      FontAwesomeIcons.wrench,
                      'Tipos de extintores',
                      TiposExtintoresPage(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _buildListTile(
            context,
            FontAwesomeIcons.fileLines,
            'Logs',
            LogsPage(),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Cerrar sesión'),
            onTap: () {
              _logout(context);
            },
          ),
        ],
      ),
    );
  }

  // Método para construir el ListTile con el color correspondiente
  Widget _buildListTile(
      BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(
        icon,
        color: currentPage == title
            ? Colors.white
            : null, // Cambia el color del ícono si es la página activa
      ),
      title: Text(
        title,
        style: TextStyle(
          color: currentPage == title
              ? Colors.white
              : null, // Cambia el color del texto si es la página activa
        ),
      ),
      tileColor: currentPage == title
          ? Colors.blue
          : null, // Cambia el color de fondo si es la página activa
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => page), // Navega a la página correspondiente
        );
      },
    );
  }
}
