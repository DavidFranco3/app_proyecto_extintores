import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../page/Clasificaciones/clasificaciones.dart'; // Asegúrate de importar el archivo donde tienes el ClasificacionesPage
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
