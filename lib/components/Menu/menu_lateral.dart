import 'package:flutter/material.dart';
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
  String nombreUsuario = "Usuario";
  bool? tieneInternet;

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    tieneInternet = await verificarConexion();
    if (mounted) setState(() {});

    await _obtenerDatosUsuario();
    verificarYLogout();
  }

  Future<void> _obtenerDatosUsuario() async {
    final authService = AuthService();
    final usuarioService = UsuariosService();
    final prefs = await SharedPreferences.getInstance();

    // Cargar nombre del caché
    if (mounted) {
      setState(() {
        nombreUsuario = prefs.getString('nombreUsuario') ?? "Usuario";
        tipoUsuario = prefs.getString('tipoUsuario');
      });
    }

    try {
      if (tieneInternet == true) {
        final token = await authService.getTokenApi();
        if (token != null) {
          final idUsuario = authService.obtenerIdUsuarioLogueado(token);
          Map<String, dynamic>? user =
              await usuarioService.obtenerUsuario2(idUsuario);

          if (user != null && mounted) {
            setState(() {
              tipoUsuario = user['tipo'];
              nombreUsuario = user['nombre'] ?? nombreUsuario;
            });
            await prefs.setString('tipoUsuario', user['tipo']);
            await prefs.setString('nombreUsuario', nombreUsuario);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error al obtener datos de usuario: $e');
    }
  }

  Future<void> verificarYLogout() async {
    if (tipoUsuario == null && tieneInternet == true) {
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
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cerrar sesión')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tieneInternet == null) {
      return const Drawer(child: Center(child: CircularProgressIndicator()));
    }

    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                if (tipoUsuario == 'administrador') ...[
                  _buildListTile(context, Icons.dashboard_outlined, 'Inicio',
                      const HomePage()),
                  _buildListTile(context, Icons.people_outline, 'Clientes',
                      const ClientesPage()),
                  _buildListTile(context, Icons.fact_check_outlined,
                      'Actividad anual', const InspeccionEspecialPage()),
                  _buildListTile(context, Icons.description_outlined,
                      'Reporte de actividades', const ReporteFinalPage()),
                  _buildListTile(
                      context,
                      Icons.settings_suggest_outlined,
                      'Configuración Cliente',
                      const EncuestasJerarquicasWidget()),
                  _buildSectionHeader('GESTIÓN'),
                  _buildExpansionTile(
                    context,
                    Icons.assignment_outlined,
                    'Actividades',
                    [
                      _buildSubTile(context, Icons.add_task_outlined,
                          'Crear actividad', const EncuestasPage()),
                      _buildSubTile(context, Icons.edit_note_outlined,
                          'Aplicar actividad', const EncuestaPage()),
                      _buildSubTile(
                          context,
                          Icons.history_outlined,
                          'Historial de actividades',
                          const InspeccionesPantalla1Page()),
                      _buildSubTile(
                          context,
                          Icons.checklist_outlined,
                          'Seleccionar actividad',
                          const ClienteInspeccionesApp()),
                      _buildSubTile(
                          context,
                          Icons.event_repeat_outlined,
                          'Actividades próximas',
                          const InspeccionesProximasPage()),
                      _buildSubTile(
                          context,
                          Icons.calendar_month_outlined,
                          'Programa de actividades',
                          const ProgramaInspeccionesPage()),
                      _buildSubTile(
                          context,
                          Icons.bar_chart_outlined,
                          'Gráfico de actividades',
                          const GraficaInspeccionesPage()),
                    ],
                    initiallyExpanded: [
                      'Crear actividad',
                      'Aplicar actividad',
                      'Historial de actividades',
                      'Seleccionar actividad',
                      'Actividades próximas',
                      'Programa de actividades',
                      'Gráfico de actividades'
                    ].contains(widget.currentPage),
                  ),
                  _buildListTile(context, Icons.category_outlined,
                      'Clasificaciones', const ClasificacionesPage()),
                  _buildListTile(context, Icons.calendar_month_outlined,
                      'Periodos', const FrecuenciasPage()),
                  _buildListTile(context, Icons.account_tree_outlined,
                      'Tipos de sistemas', const RamasPage()),
                  _buildExpansionTile(
                    context,
                    Icons.fire_extinguisher,
                    'Extintores',
                    [
                      _buildSubTile(context, Icons.list_alt_outlined,
                          'Extintores', const ExtintoresPage()),
                      _buildSubTile(
                          context,
                          Icons.format_list_bulleted_outlined,
                          'Tipos de extintores',
                          const TiposExtintoresPage()),
                    ],
                    initiallyExpanded: ['Extintores', 'Tipos de extintores']
                        .contains(widget.currentPage),
                  ),
                  _buildListTile(context, Icons.manage_accounts_outlined,
                      'Usuarios', const UsuariosPage()),
                  _buildListTile(context, Icons.history_edu_outlined, 'Logs',
                      const LogsPage()),
                ] else if (tipoUsuario == 'inspector') ...[
                  _buildListTile(
                      context, Icons.home_outlined, 'Inicio', const HomePage()),
                  _buildListTile(context, Icons.poll_outlined,
                      'Crear actividad', const EncuestasPage()),
                  _buildListTile(context, Icons.assignment_outlined,
                      'Aplicar actividad', const EncuestaPage()),
                  _buildListTile(context, Icons.history_outlined, 'Historial',
                      const InspeccionesPantalla1Page()),
                  _buildListTile(context, Icons.event_available_outlined,
                      'Actividades próximas', const InspeccionesProximasPage()),
                  _buildListTile(context, Icons.calendar_today_outlined,
                      'Programa', const ProgramaInspeccionesPage()),
                  _buildListTile(context, Icons.insights_outlined, 'Gráficas',
                      const GraficaInspeccionesPage()),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Cerrar sesión',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF707271)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Image.asset(
              'lib/assets/img/logo_login.png',
              height: 45,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            nombreUsuario,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            tipoUsuario?.toUpperCase() ?? "",
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildListTile(
      BuildContext context, IconData icon, String title, Widget page) {
    bool isSelected = widget.currentPage == title;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading:
            Icon(icon, color: isSelected ? Colors.white : Colors.blueGrey[700]),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blueGrey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        tileColor: isSelected ? const Color(0xFFE94742) : null,
        onTap: () {
          if (!isSelected) {
            Navigator.pop(context);
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => page));
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildExpansionTile(
      BuildContext context, IconData icon, String title, List<Widget> children,
      {bool initiallyExpanded = false}) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.blueGrey[700]),
      title: Text(title,
          style: TextStyle(
              color: Colors.blueGrey[800],
              fontWeight: FontWeight.w500,
              fontSize: 15)),
      initiallyExpanded: initiallyExpanded,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      childrenPadding: const EdgeInsets.only(left: 10),
      children: children,
    );
  }

  Widget _buildSubTile(
      BuildContext context, IconData icon, String title, Widget page) {
    bool isSelected = widget.currentPage == title;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 2.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : Colors.blueGrey[400],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blueGrey[600],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        tileColor: isSelected ? const Color(0xFFE94742) : null,
        onTap: () {
          if (!isSelected) {
            Navigator.pop(context);
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => page));
          } else {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
