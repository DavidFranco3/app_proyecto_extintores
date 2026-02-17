import 'package:flutter/material.dart';
import '../Menu/menu_lateral.dart';
import '../Header/header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../components/Load/load.dart';
import '../../api/inspecciones.dart';
import '../../api/inspecciones_proximas.dart';
import '../../page/InspeccionesPantalla1/inspecciones_pantalla_1.dart';
import '../../page/InspeccionesProximas/inspecciones_proximas.dart';
import '../../api/tokens.dart';
import '../../api/notificaciones.dart';
import '../../api/auth.dart';
import '../../api/usuarios.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspecciones = [];
  List<Map<String, dynamic>> dataInspeccionesProximas = [];
  List<Map<String, dynamic>> dataInspeccionesProximas2 = [];
  List<Map<String, dynamic>> dataTokens = [];
  String nombreUsuario = "Usuario";

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    await Future.wait([
      getInspecciones(),
      getInspeccionesProximas(),
      getTokens(),
      _obtenerNombreUsuario(),
    ]);
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _obtenerNombreUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final usuarioService = UsuariosService();

      // Intentar obtener del caché primero
      String? nombre = prefs.getString('nombreUsuario');
      if (nombre != null) {
        setState(() => nombreUsuario = nombre);
      }

      final tieneInternet = await verificarConexion();
      if (tieneInternet) {
        final token = await authService.getTokenApi();
        if (token != null) {
          final idUsuario = authService.obtenerIdUsuarioLogueado(token);
          final user = await usuarioService.obtenerUsuario2(idUsuario);
          if (user != null && user['nombre'] != null) {
            if (mounted) {
              setState(() => nombreUsuario = user['nombre']);
            }
            await prefs.setString('nombreUsuario', user['nombre']);
          }
        }
      }
    } catch (e) {
      debugPrint("Error obteniendo nombre de usuario: $e");
    }
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  // ---------------- TOKENS ----------------
  Future<void> getTokens() async {
    final conectado = await verificarConexion();

    if (conectado) {
      await getTokensDesdeAPI();
    } else {
      await getTokensDesdeHive();
    }
  }

  Future<void> getTokensDesdeAPI() async {
    try {
      final tokensService = TokensService();
      final List<dynamic> response = await tokensService.listarTokens();

      final List<dynamic> filteredResponse = response.where((item) {
        return item['usuario']['tipo'] == 'inspector';
      }).toList();

      // Guardar en Hive
      final box = Hive.box('tokensBox');
      await box.put('tokens', filteredResponse);

      if (mounted) {
        setState(() {
          dataTokens = formatModelTokens(filteredResponse);
        });
      }
    } catch (e) {
      debugPrint("Error al obtener los tokens: $e");
    }
  }

  Future<void> getTokensDesdeHive() async {
    try {
      final box = Hive.box('tokensBox');
      final guardados = box.get('tokens');

      if (guardados is List && mounted) {
        setState(() {
          dataTokens = formatModelTokens(
            guardados.map((e) => Map<String, dynamic>.from(e)).toList(),
          );
        });
      }
    } catch (e) {
      debugPrint("Error leyendo tokens desde Hive: $e");
    }
  }

  // ---------------- INSPECCIONES ----------------
  Future<void> getInspecciones() async {
    final conectado = await verificarConexion();

    if (conectado) {
      await getInspeccionesDesdeAPI();
    } else {
      await getInspeccionesDesdeHive();
    }
  }

  Future<void> getInspeccionesDesdeAPI() async {
    try {
      final inspeccionesService = InspeccionesService();
      final List<dynamic> response =
          await inspeccionesService.listarInspecciones();

      // Guardar en Hive
      final box = Hive.box('inspeccionesBox');
      await box.put('inspecciones', response);

      if (mounted) {
        setState(() {
          dataInspecciones = formatModelInspecciones(response);
        });
      }
    } catch (e) {
      debugPrint("Error al obtener inspecciones: $e");
    }
  }

  Future<void> getInspeccionesDesdeHive() async {
    try {
      final box = Hive.box('inspeccionesBox');
      final guardados = box.get('inspecciones');

      if (guardados is List && mounted) {
        setState(() {
          dataInspecciones = formatModelInspecciones(
            guardados.map((e) => Map<String, dynamic>.from(e)).toList(),
          );
        });
      }
    } catch (e) {
      debugPrint("Error leyendo inspecciones desde Hive: $e");
    }
  }

  // ---------------- INSPECCIONES PRÓXIMAS ----------------
  Future<void> getInspeccionesProximas() async {
    final conectado = await verificarConexion();

    if (conectado) {
      await getInspeccionesProximasDesdeAPI();
    } else {
      await getInspeccionesProximasDesdeHive();
    }
  }

  Future<void> getInspeccionesProximasDesdeAPI() async {
    try {
      final service = InspeccionesProximasService();
      final List<dynamic> response = await service.listarInspeccionesProximas();

      final formattedData = formatModelInspeccionesProximas(response);

      // Guardar en Hive
      final box = Hive.box('inspeccionesProximasBox');
      await box.put('inspeccionesProximas', formattedData);

      // Filtrado de próximas 3 días
      final fechaActual = DateTime.now();
      final inspeccionesFiltradas = formattedData.where((item) {
        final proximaFecha = DateTime.parse(item['proximaInspeccion']);
        return proximaFecha.difference(fechaActual).inDays <= 3 &&
            proximaFecha.isAfter(fechaActual);
      }).toList();

      if (mounted) {
        setState(() {
          dataInspeccionesProximas = formattedData;
          dataInspeccionesProximas2 = inspeccionesFiltradas;
        });
      }
    } catch (e) {
      debugPrint("Error al obtener inspecciones próximas: $e");
    }
  }

  Future<void> getInspeccionesProximasDesdeHive() async {
    try {
      final box = Hive.box('inspeccionesProximasBox');
      final guardados = box.get('inspeccionesProximas');

      if (guardados is List && mounted) {
        final lista =
            guardados.map((e) => Map<String, dynamic>.from(e)).toList();

        final fechaActual = DateTime.now();
        final inspeccionesFiltradas = lista.where((item) {
          final proximaFecha = DateTime.parse(item['proximaInspeccion']);
          return proximaFecha.difference(fechaActual).inDays <= 3 &&
              proximaFecha.isAfter(fechaActual);
        }).toList();

        setState(() {
          dataInspeccionesProximas = lista;
          dataInspeccionesProximas2 = inspeccionesFiltradas;
        });
      }
    } catch (e) {
      debugPrint("Error leyendo inspecciones próximas desde Hive: $e");
    }
  }

  // Función para formatear los datos de las inspecciones
  List<Map<String, dynamic>> formatModelTokens(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'idUsuario': item['idUsuario'],
        'token': item['token'],
        'usuario': item['usuario']?['nombre'] ?? 'Sin usuario',
        'tipo': item['usuario']?['tipo'] ?? 'Sin tipo',
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  // Función para formatear los datos de las inspecciones
  List<Map<String, dynamic>> formatModelInspecciones(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'idUsuario': item['idUsuario'],
        'idCliente': item['idCliente'],
        'idEncuesta': item['idEncuesta'],
        'encuesta': item['encuesta'],
        'imagenes': item['imagenes'],
        'comentarios': item['comentarios'],
        'usuario': item['usuario']?['nombre'] ?? 'Sin usuario',
        'cliente': item['cliente']?['nombre'] ?? 'Sin cliente',
        'cuestionario': item['cuestionario']?['nombre'] ?? 'Sin cuestionario',
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  // Función para formatear los datos de las inspeccionesProximas
  List<Map<String, dynamic>> formatModelInspeccionesProximas(
      List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'idFrecuencia': item['idFrecuencia'],
        'idEncuesta': item['idEncuesta'],
        'cuestionario': item['cuestionario']?['nombre'] ?? 'Sin nombre',
        'frecuencia': item['frecuencia']?['nombre'] ?? 'Sin frecuencia',
        'proximaInspeccion': item['nuevaInspeccion'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  Timer? _notificationTimer; // Para evitar múltiples timers

// ✅ Enviar solicitud HTTP al backend de forma eficiente
  Future<void> enviarNotificacionAlBackend() async {
    final notificacionesService = NotificacionesService();
    List<Future<void>> requests = [];

    for (var tokenData in dataTokens) {
      for (var inspeccionData in dataInspeccionesProximas2) {
        final formData = {
          "titulo": "Recordatorio de inspección",
          "token": tokenData["token"],
          "mensaje":
              "Se debe realizar la inspección de ${inspeccionData["cuestionario"]["nombre"]}"
        };

        // Agregar la solicitud a la lista para ejecutarlas en paralelo
        requests.add(notificacionesService.enviarNotificacion(formData));
      }
    }

    try {
      await Future.wait(requests); // Ejecutar todas las solicitudes en paralelo
    } catch (e) {
      debugPrint("Error al enviar notificaciones: $e");
    }
  }

// ✅ Programar la llamada al backend cada 24 horas evitando múltiples timers
  void scheduleDailyNotification() {
    if (_notificationTimer != null && _notificationTimer!.isActive) {
      return; // Evita que se cree otro timer si ya hay uno activo
    }

    _notificationTimer = Timer.periodic(Duration(hours: 24), (_) async {
      await enviarNotificacionAlBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Inicio"),
      body: loading
          ? Load()
          : SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Bienvenida
                    Text(
                      "Hola, $nombreUsuario 👋",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Aquí tienes el resumen de tus actividades.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 20),

                    // 2. Tarjetas de Resumen (Metrics)
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: "Hechas",
                            count: dataInspecciones.length.toString(),
                            icon: FontAwesomeIcons.clipboardCheck,
                            color: const Color.fromARGB(255, 3, 4, 6),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      InspeccionesPantalla1Page(),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: _buildSummaryCard(
                            title: "Próximas",
                            count: dataInspeccionesProximas.length.toString(),
                            icon: FontAwesomeIcons.calendarCheck,
                            color: const Color.fromARGB(255, 114, 113, 25),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      InspeccionesProximasPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 25),

                    // 3. Título Próximas a Vencer
                    Text(
                      "Próximas a Vencer (3 días)",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 15),

                    // 4. Lista de Próximas
                    dataInspeccionesProximas2.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Icon(FontAwesomeIcons.calendarXmark,
                                    color: Colors.grey, size: 40),
                                SizedBox(height: 10),
                                Text(
                                  "No hay inspecciones próximas",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: dataInspeccionesProximas2.length,
                            itemBuilder: (context, index) {
                              final item = dataInspeccionesProximas2[index];
                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        const Color.fromARGB(255, 114, 113, 25)
                                            .withValues(alpha: 0.2),
                                    child: FaIcon(
                                      FontAwesomeIcons.clock,
                                      color: const Color.fromARGB(
                                          255, 114, 113, 25),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    item['cuestionario'] ?? 'Sin nombre',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "Vence: ${item['proximaInspeccion'].toString().split(' ')[0]}",
                                  ),
                                  trailing: Icon(Icons.arrow_forward_ios,
                                      size: 16, color: Colors.grey),
                                  onTap: () {
                                    // Navegar a detalle si es necesario
                                  },
                                ),
                              );
                            },
                          ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            Spacer(),
            Text(
              count,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
