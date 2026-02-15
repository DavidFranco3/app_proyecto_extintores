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
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class MenuLateral extends StatefulWidget {
  final String currentPage;

  const MenuLateral({super.key, required this.currentPage});

  @override
  State<MenuLateral> createState() => _MenuLateralState();
}

class _MenuLateralState extends State<MenuLateral> {
  String? tipoUsuario;
  bool? tieneInternet;

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();

    if (tipoConexion.contains(ConnectivityResult.none)) {
      return false;
    }

    final tieneInternet = await InternetConnection().hasInternetAccess;
    return tieneInternet;
  }

  @override
  void initState() {
    super.initState();
    verificarConexion().then((conectado) {
      if (!mounted) return;
      setState(() {
        tieneInternet = conectado;
      });

      _obtenerTipoUsuario().then((_) {
        if (!mounted) return;
        verificarYLogout();
      });
    });
  }

  Future<void> _obtenerTipoUsuario() async {
    final authService = AuthService();
    final usuarioService = UsuariosService();
    final prefs = await SharedPreferences.getInstance();

    try {
      if (tieneInternet == true) {
        final token = await authService.getTokenApi();

        if (token != null) {
          final idUsuario = authService.obtenerIdUsuarioLogueado(token);
          Map<String, dynamic>? user =
              await usuarioService.obtenerUsuario2(idUsuario);

          if (user != null) {
            if (!mounted) return;
            setState(() {
              tipoUsuario = user['tipo'];
            });
            await prefs.setString('tipoUsuario', user['tipo']);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error al obtener tipo de usuario de API: $e');
    }

    // Si no se pudo obtener de la API o no hay internet, intentar obtener del caché
    String? cachedTipo = prefs.getString('tipoUsuario');
    if (mounted && cachedTipo != null) {
      setState(() {
        tipoUsuario = cachedTipo;
      });
    } else {
      if (mounted) {
        setState(() {
          tipoUsuario = null;
        });
      }
    }
  }

  Future<void> verificarYLogout() async {
    if (tipoUsuario == null) {
      // Si el token es null o vacío, se hace logout
      _logout();
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      logsInformativos("Sesión cerrada correctamente", {});
      AuthService authService = AuthService();
      await authService.logoutApi();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tieneInternet == null) {
      // Mientras se verifica conexión, muestra loader
      return Drawer(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Si tipoUsuario no está cargado (y no se pudo recuperar del caché), muestra loader
    if (tipoUsuario == null) {
      return Drawer(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Si hay internet y tipoUsuario cargado, muestra menú filtrado
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 90,
            color: const Color.fromARGB(255, 112, 114, 113),
            child: Center(
              child: Text(
                '',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          if (tipoUsuario == 'administrador') ...[
            _buildListTile(context, Icons.home, 'Inicio', HomePage()),
            _buildListTile(context, Icons.person, 'Clientes', ClientesPage()),
            _buildListTile(context, Icons.fact_check, 'Actividad anual',
                InspeccionEspecialPage()),
            _buildListTile(context, Icons.sticky_note_2,
                'Reporte de actividades y pruebas', ReporteFinalPage()),
            _buildListTile(context, Icons.manage_accounts,
                'Configuración de Cliente', EncuestasJerarquicasWidget()),
            ExpansionTile(
              leading: Icon(Icons.check_box_outline_blank),
              title: Text('Actividades',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              collapsedShape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Column(
                    children: [
                      _buildListTile(context, Icons.poll, 'Crear actividad',
                          EncuestasPage()),
                      _buildListTile(context, Icons.assignment,
                          'Aplicar actividad', EncuestaPage()),
                      _buildListTile(
                          context,
                          Icons.report_problem,
                          'Historial de actividades',
                          InspeccionesPantalla1Page()),
                      _buildListTile(context, Icons.report_problem,
                          'Seleccionar actividad', ClienteInspeccionesApp()),
                      _buildListTile(context, Icons.next_week_sharp,
                          'Actividades próximas', InspeccionesProximasPage()),
                      _buildListTile(
                          context,
                          Icons.date_range,
                          'Programa de actividades',
                          ProgramaInspeccionesPage()),
                      _buildListTile(context, Icons.show_chart,
                          'Gráfico de actividades', GraficaInspeccionesPage()),
                    ],
                  ),
                ),
              ],
            ),
            _buildListTile(context, FontAwesomeIcons.list, 'Clasificaciones',
                ClasificacionesPage()),
            _buildListTile(
                context, Icons.calendar_today, 'Periodos', FrecuenciasPage()),
            _buildListTile(
                context, Icons.devices, 'Tipos de sistemas', RamasPage()),
            ExpansionTile(
              leading: Icon(FontAwesomeIcons.fireFlameCurved),
              title: Text('Extintores',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              collapsedShape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Column(
                    children: [
                      _buildListTile(context, FontAwesomeIcons.fireExtinguisher,
                          'Extintores', ExtintoresPage()),
                      _buildListTile(context, FontAwesomeIcons.wrench,
                          'Tipos de extintores', TiposExtintoresPage()),
                    ],
                  ),
                ),
              ],
            ),
            _buildListTile(
                context, FontAwesomeIcons.person, 'Usuarios', UsuariosPage()),
            _buildListTile(
                context, FontAwesomeIcons.fileLines, 'Logs', LogsPage()),
          ] else if (tipoUsuario == 'inspector') ...[
            _buildListTile(context, Icons.home, 'Inicio', HomePage()),
            _buildListTile(
                context, Icons.poll, 'Crear actividad', EncuestasPage()),
            _buildListTile(
                context, Icons.assignment, 'Aplicar actividad', EncuestaPage()),
            _buildListTile(context, Icons.report_problem,
                'Historial de actividades', InspeccionesPantalla1Page()),
            _buildListTile(context, Icons.next_week_sharp,
                'Actividades proximas', InspeccionesProximasPage()),
            _buildListTile(context, Icons.date_range, 'Programa de actividades',
                ProgramaInspeccionesPage()),
            _buildListTile(context, Icons.show_chart, 'Gráfico de actividades',
                GraficaInspeccionesPage()),
          ],
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Cerrar sesión'),
            onTap: () {
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
      BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(
        icon,
        color: widget.currentPage == title ? Colors.white : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: widget.currentPage == title ? Colors.white : null,
        ),
      ),
      tileColor:
          widget.currentPage == title ? Color.fromARGB(255, 233, 71, 66) : null,
      onTap: () {
        if (widget.currentPage != title) {
          if (mounted) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        } else {
          if (mounted) Navigator.pop(context);
        }
      },
    );
  }
}
