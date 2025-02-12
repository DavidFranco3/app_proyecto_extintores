import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../page/Clasificaciones/clasificaciones.dart'; // Asegúrate de importar el archivo donde tienes el ClasificacionesPage
import '../../page/Frecuencias/frecuencias.dart';
import '../../page/TiposExtintores/tipos_extintores.dart';
import '../Home/home.dart';

class MenuLateral extends StatelessWidget {
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
                MaterialPageRoute(builder: (context) => HomePage()), // Navega a la página de Clasificaciones
              );
              // Aquí puedes agregar la acción para ir al inicio, si lo deseas
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
            leading: Icon(Icons.logout),
            title: Text('Cerrar sesión'),
            onTap: () {
              Navigator.pop(context); // Cierra el menú lateral
              // Aquí podrías llamar a tu función de logout
            },
          ),
        ],
      ),
    );
  }
}
