import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../page/Clasificaciones/clasificaciones.dart';
import '../../page/Frecuencias/frecuencias.dart';
import '../../page/TiposExtintores/tipos_extintores.dart';
import '../../page/Extintores/extintores.dart';
import '../../page/Logs/logs.dart';
import '../../page/Clientes/clientes.dart';
import '../../page/Encuestas/encuestas.dart';
import '../../page/InspeccionesPantalla1/inspecciones_pantalla_1.dart';
import '../../page/LlenarEncuesta/llenar_encuesta.dart';
import '../../page/Usuarios/usuarios.dart';
import '../../page/ProgramaInspecciones/programa_inspecciones.dart';
import '../../page/InspeccionesProximas/inspecciones_proximas.dart';
import '../../page/GraficaInspecciones/grafica_inspecciones.dart';
import '../../page/InspeccionEspecial/inspeccion_especial.dart';
import '../../page/ReporteFinal/reporte_final.dart';
import '../../page/Ramas/ramas.dart';
import '../../page/SeleccionarInspeccionesClientes/seleccionar_inspecciones_clientes.dart';
import '../Home/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/login.dart';
import '../Logs/logs_informativos.dart';
import '../../api/auth.dart';
import '../../api/usuarios.dart';
import '../../page/SeleccionPreguntas/seleccion_preguntas.dart';

class MenuLateral extends StatefulWidget {
  final String currentPage;

  MenuLateral({required this.currentPage});

  @override
  _MenuLateralState createState() => _MenuLateralState();
}

class _MenuLateralState extends State<MenuLateral> {
  String? tipoUsuario;

  @override
  void initState() {
    super.initState();
    _obtenerTipoUsuario();
  }

  Future<void> _obtenerTipoUsuario() async {
    try {
      final authService = AuthService();
      final usuarioService = UsuariosService();
      final token = await authService.getTokenApi();

      if (token == null) throw Exception("Token de autenticación es nulo");
      final idUsuario = await authService.obtenerIdUsuarioLogueado(token);
      Map<String, dynamic>? user =
          await usuarioService.obtenerUsuario2(idUsuario);

      if (user == null)
        throw Exception("No se pudieron obtener los datos del usuario.");

      setState(() {
        tipoUsuario = user['tipo'];
      });
    } catch (e) {
      print('Error al obtener tipo de usuario: $e');
    }
  }

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
      child: SizedBox(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 90, // Reduciendo el tamaño
              color: const Color.fromARGB(255, 112, 114, 113),
              child: Center(
                child: Text(
                  '',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            // Verifica el tipo de usuario para mostrar el menú correspondiente
            if (tipoUsuario == 'administrador') ...[
              _buildListTile(
                context,
                Icons.home,
                'Inicio',
                HomePage(),
              ),
              _buildListTile(
                context,
                Icons.person,
                'Clientes',
                ClientesPage(),
              ),
              _buildListTile(
                context,
                Icons.fact_check,
                'Actividad anual',
                InspeccionEspecialPage(),
              ),
              _buildListTile(
                context,
                Icons.sticky_note_2,
                'Reporte de actividades y pruebas',
                ReporteFinalPage(),
              ),
              _buildListTile(
                context,
                Icons.manage_accounts,
                'Configuración de Cliente',
                EncuestasJerarquicasWidget(),
              ),
              // Submenú de Inspecciones
              ExpansionTile(
                leading: Icon(Icons.check_box_outline_blank),
                title: Text(
                  'Actividades',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                ),
                dense: true,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero), // Elimina la línea inferior
                collapsedShape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero), // Elimina la línea superior
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Column(
                      children: [
                        _buildListTile(
                          context,
                          Icons.poll, // Icono relacionado con encuestas
                          'Crear actividad',
                          EncuestasPage(),
                        ),
                        _buildListTile(
                          context,
                          Icons
                              .assignment, // Icono relacionado con inspecciones
                          'Aplicar actividad',
                          EncuestaPage(),
                        ),
                        _buildListTile(
                          context,
                          Icons
                              .report_problem, // Ícono representativo de inspección
                          'Historial de actividades',
                          InspeccionesPantalla1Page(),
                        ),
                        _buildListTile(
                          context,
                          Icons
                              .report_problem, // Ícono representativo de inspección
                          'Seleccionar actividad',
                          ClienteInspeccionesApp(),
                        ),
                        _buildListTile(
                          context,
                          Icons
                              .next_week_sharp, // Ícono representativo de inspección
                          'Actividades próximas',
                          InspeccionesProximasPage(),
                        ),
                        _buildListTile(
                          context,
                          Icons.date_range, // Ícono representativo de programa
                          'Programa de actividades',
                          ProgramaInspeccionesPage(),
                        ),
                        _buildListTile(
                          context,
                          Icons.show_chart, // Ícono representativo de gráfico
                          'Gráfico de actividades',
                          GraficaInspeccionesPage(),
                        ),
                      ],
                    ),
                  ),
                ],
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
                'Periodos',
                FrecuenciasPage(),
              ),
              _buildListTile(
                context,
                Icons.devices,
                'Tipos de sistemas',
                RamasPage(),
              ),
              // Menú principal para Extintores con opciones desplegables
              ExpansionTile(
                leading: Icon(FontAwesomeIcons.fireFlameCurved),
                title: Text(
                  'Extintores',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                ),
                dense: true,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero), // Elimina la línea inferior
                collapsedShape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero), // Elimina la línea superior
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
                FontAwesomeIcons.person,
                'Usuarios',
                UsuariosPage(),
              ),
              _buildListTile(
                context,
                FontAwesomeIcons.fileLines,
                'Logs',
                LogsPage(),
              ),
            ]
            // Menú para Inspector
            else if (tipoUsuario == 'inspector') ...[
              _buildListTile(
                context,
                Icons.home,
                'Inicio',
                HomePage(),
              ),
              _buildListTile(
                context,
                Icons.poll, // Icono relacionado con encuestas
                'Crear actividad',
                EncuestasPage(),
              ),
              _buildListTile(
                context,
                Icons.assignment, // Icono relacionado con inspecciones
                'Aplicar actividad',
                EncuestaPage(),
              ),
              _buildListTile(
                context,
                Icons.report_problem, // Ícono representativo de inspección
                'Historial de actividades',
                InspeccionesPantalla1Page(),
              ),
              _buildListTile(
                context,
                Icons.next_week_sharp, // Ícono representativo de inspección
                'Actividades proximas',
                InspeccionesProximasPage(),
              ),
              _buildListTile(
                context,
                Icons.date_range, // Ícono representativo de programa
                'Programa de actividades',
                ProgramaInspeccionesPage(),
              ),
              _buildListTile(
                context,
                Icons.show_chart, // Ícono representativo de gráfico
                'Gráfico de actividades',
                GraficaInspeccionesPage(),
              ),
            ],
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Cerrar sesión'),
              onTap: () {
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir el ListTile con el color correspondiente
  Widget _buildListTile(
      BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(
        icon,
        color: widget.currentPage == title
            ? Colors.white
            : null, // Cambia el color del ícono si es la página activa
      ),
      title: Text(
        title,
        style: TextStyle(
          color: widget.currentPage == title
              ? Colors.white
              : null, // Cambia el color del texto si es la página activa
        ),
      ),
      tileColor: widget.currentPage == title
          ? Color.fromARGB(255, 233, 71, 66)
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
