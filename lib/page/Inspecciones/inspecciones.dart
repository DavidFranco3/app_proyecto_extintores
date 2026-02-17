import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../api/inspecciones.dart';
import '../../components/Inspecciones/list_inspecciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';
import '../InspeccionesPantalla2/inspecciones_pantalla_2.dart';

class InspeccionesPage extends StatefulWidget {
  final VoidCallback showModal;
  final dynamic data;
  final dynamic data2;

  const InspeccionesPage({
    super.key,
    required this.showModal,
    required this.data,
    required this.data2,
  });

  @override
  State<InspeccionesPage> createState() => _InspeccionesPageState();
}

class _InspeccionesPageState extends State<InspeccionesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspecciones = [];

  bool esOffline = false;

  @override
  void initState() {
    super.initState();
    cargarInspecciones();
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> cargarInspecciones() async {
    final conectado = await verificarConexion();
    if (conectado) {
      esOffline = false;
      await getInspeccionesDesdeAPI();
    } else {
      esOffline = true;
      await getInspeccionesDesdeHive();
    }
  }

  Future<void> getInspeccionesDesdeAPI() async {
    try {
      final inspeccionesService = InspeccionesService();
      final List<dynamic> response =
          await inspeccionesService.listarInspeccionesDatos(widget.data["id"]);

      if (response.isNotEmpty) {
        final formateadas = formatModelInspecciones(response);

        final box = Hive.box('inspeccionesBox');
        await box.put('inspecciones_${widget.data["id"]}', formateadas);

        setState(() {
          dataInspecciones = formateadas;
          loading = false;
        });
      } else {
        setState(() {
          dataInspecciones = [];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error al obtener inspecciones: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getInspeccionesDesdeHive() async {
    final box = Hive.box('inspeccionesBox');
    final List<dynamic>? guardadas =
        box.get('inspecciones_${widget.data["id"]}');

    if (guardadas != null) {
      setState(() {
        dataInspecciones = guardadas
            .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item as Map))
            .where((item) => item['estado'] == "true")
            .toList();
        loading = false;
      });
    } else {
      setState(() {
        dataInspecciones = [];
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> formatModelInspecciones(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'idUsuario': item['idUsuario'],
        'idCliente': item['idCliente'],
        'idEncuesta': item['idEncuesta'],
        'idRama': item['cuestionario']?['idRama'],
        'idClasificacion': item['cuestionario']?['idClasificacion'],
        'idFrecuencia': item['cuestionario']?['idFrecuencia'],
        'idCuestionario': item['cuestionario']?['_id'],
        'encuesta': item['encuesta'],
        'imagenes': item?['imagenes'] ?? [],
        'imagenesCloudinary': item?['imagenesCloudinary'] ?? [],
        'imagenes_finales': item?['imagenesFinales'] ?? [],
        'imagenes_finales_cloudinary': item?['imagenesFinalesCloudinary'] ?? [],
        'comentarios': item['comentarios'],
        'preguntas': item['encuesta'],
        'descripcion': item['descripcion'],
        'usuario': item['usuario']?['nombre'] ?? 'Sin usuario',
        'cliente': item['cliente']?['nombre'] ?? 'Sin cliente',
        'puestoCliente': item['cliente']?['puesto'] ?? 'Sin puesto',
        'responsableCliente':
            item['cliente']?['responsable'] ?? 'Sin responsable',
        'estadoDom':
            item['cliente']?['direccion']?['estadoDom'] ?? 'Sin estado',
        'municipio':
            item['cliente']?['direccion']?['municipio'] ?? 'Sin municipio',
        'imagen_cliente': item['cliente']?['imagen'],
        'imagen_cliente_cloudinary': item['cliente']?['imagenCloudinary'],
        'firma_usuario': item['usuario']?['firma'],
        'firma_usuario_cloudinary': item['usuario']?['firmaCloudinary'],
        'cuestionario': item['cuestionario']?['nombre'] ?? 'Sin cuestionario',
        'usuarios': item['usuario'],
        'inspeccion_eficiencias': item['inspeccionEficiencias'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  void returnPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspeccionesPantalla2Page(
          showModal: () {
            if (mounted) Navigator.pop(context);
          },
          data: widget.data2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Historial de actividades"),
      body: loading
          ? Load()
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Historial de actividades",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: PremiumActionButton(
                              onPressed: returnPage,
                              label: "Regresar",
                              icon: FontAwesomeIcons.arrowLeft,
                              style: PremiumButtonStyle.secondary,
                              isFullWidth: true,
                            ),
                          ),
                        ],
                      ),
                      if (esOffline) ...[
                        const SizedBox(height: 8),
                        const Text(
                          "Modo offline: mostrando datos locales",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.orange, fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        "Cliente: ${widget.data["cliente"]}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF34495E),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TblInspecciones(
                    showModal: () {
                      if (mounted) Navigator.pop(context);
                    },
                    inspecciones: dataInspecciones,
                    onCompleted: cargarInspecciones,
                  ),
                ),
              ],
            ),
    );
  }
}
