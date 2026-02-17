import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/inspecciones.dart';
import '../Logs/logs_informativos.dart';
import '../Generales/flushbar_helper.dart';
import 'package:prueba/components/Header/header.dart';
import 'package:prueba/components/Menu/menu_lateral.dart';
import '../Generales/premium_button.dart';
import '../Load/load.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../Generales/premium_inputs.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class Acciones extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  const Acciones(
      {super.key,
      required this.showModal,
      required this.onCompleted,
      required this.accion,
      required this.data});

  @override
  State<Acciones> createState() => _AccionesState();
}

class _AccionesState extends State<Acciones> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  late TextEditingController _usuarioController;
  late TextEditingController _clienteController;
  late TextEditingController _encuestaController;

  @override
  void initState() {
    super.initState();
    debugPrint(widget.data.toString());
    _usuarioController = TextEditingController();
    _clienteController = TextEditingController();
    _encuestaController = TextEditingController();

    if (widget.accion == 'editar' || widget.accion == 'eliminar') {
      var usuarioData = widget.data['usuario'];
      var clienteData = widget.data['cliente'];
      var encuestaData = widget.data['cuestionario'] ?? widget.data['encuesta'];

      _usuarioController.text = usuarioData is Map
          ? (usuarioData['nombre'] ?? '')
          : (usuarioData?.toString() ?? '');
      _clienteController.text = clienteData is Map
          ? (clienteData['nombre'] ?? '')
          : (clienteData?.toString() ?? '');
      _encuestaController.text = encuestaData is Map
          ? (encuestaData['nombre'] ?? '')
          : (encuestaData?.toString() ?? '');
    }

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });

    sincronizarOperacionesPendientes();

    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> event) {
      if (event.any((result) => result != ConnectivityResult.none)) {
        sincronizarOperacionesPendientes();
      }
    });
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _clienteController.dispose();
    _encuestaController.dispose();
    super.dispose();
  }

  // Corregimos la función para que acepte un parámetro bool
  void closeRegistroModal() {
    widget.showModal(); // Llama a setShow con el valor booleano
    widget.onCompleted();
  }

  Future<void> sincronizarOperacionesPendientes() async {
    final conectado = await verificarConexion();
    if (!conectado) return;

    final box = Hive.box('operacionesOfflineInspecciones');
    final operacionesRaw = box.get('operaciones', defaultValue: []);

    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    final inspeccionesService = InspeccionesService();
    final List<String> operacionesExitosas = [];

    for (var operacion in List.from(operaciones)) {
      try {
        if (operacion['accion'] == 'eliminar') {
          final response = await inspeccionesService
              .actualizaDeshabilitarInspecciones(
                  operacion['id'], {'estado': 'false'});

          if (response['status'] == 200) {
            final inspeccionesBox = Hive.box('inspeccionesBox');
            final actualesRaw =
                inspeccionesBox.get('inspecciones', defaultValue: []);

            final actuales = (actualesRaw as List)
                .map<Map<String, dynamic>>(
                    (item) => Map<String, dynamic>.from(item))
                .toList();

            final index = actuales
                .indexWhere((element) => element['id'] == operacion['id']);
            if (index != -1) {
              actuales[index] = {
                ...actuales[index],
                'estado': 'false',
                'updatedAt': DateTime.now().toString(),
              };
              await inspeccionesBox.put('inspecciones', actuales);
            }
          }

          operacionesExitosas.add(operacion['operacionId']);
        }
      } catch (e) {
        debugPrint('Error sincronizando operación: $e');
      }
    }

    // 🔥 Si TODAS las operaciones se sincronizaron correctamente, limpia por completo:
    if (operacionesExitosas.length == operaciones.length) {
      await box.put('operaciones', []);
      debugPrint("✔ Todas las operaciones sincronizadas. Limpieza completa.");
    } else {
      // 🔄 Si alguna falló, conserva solo las pendientes
      final nuevasOperaciones = operaciones
          .where((op) => !operacionesExitosas.contains(op['operacionId']))
          .toList();
      await box.put('operaciones', nuevasOperaciones);
      debugPrint(
          "❗ Algunas operaciones no se sincronizaron, se conservarán localmente.");
    }

    // ✅ Actualizar lista completa desde API
    try {
      final List<dynamic> dataAPI =
          await inspeccionesService.listarInspecciones();

      final formateadas = dataAPI
          .map<Map<String, dynamic>>((item) => {
                'id': item['_id'],
                'idUsuario': item['idUsuario'],
                'idCliente': item['idCliente'],
                'idEncuesta': item['idEncuesta'],
                'idRama': item['cuestionario']['idRama'],
                'idClasificacion': item['cuestionario']['idClasificacion'],
                'idFrecuencia': item['cuestionario']['idFrecuencia'],
                'idCuestionario': item['cuestionario']['_id'],
                'encuesta': item['encuesta'],
                'imagenes': item?['imagenes'] ?? [],
                'imagenesCloudinary': item?['imagenesCloudinary'] ?? [],
                'imagenes_finales': item?['imagenesFinales'] ?? [],
                'imagenes_finales_cloudinary':
                    item?['imagenesFinalesCloudinary'] ?? [],
                'comentarios': item['comentarios'],
                'preguntas': item['encuesta'],
                'descripcion': item['descripcion'],
                'usuario': item['usuario']['nombre'],
                'cliente': item['cliente']['nombre'],
                'puestoCliente': item['cliente']['puesto'],
                'responsableCliente': item['cliente']['responsable'],
                'estadoDom': item['cliente']['direccion']['estadoDom'],
                'municipio': item['cliente']['direccion']['municipio'],
                'imagen_cliente': item['cliente']['imagen'],
                'imagen_cliente_cloudinary': item['cliente']
                    ['imagenCloudinary'],
                'firma_usuario': item['usuario']['firma'],
                'firma_usuario_cloudinary': item['usuario']['firmaCloudinary'],
                'cuestionario': item['cuestionario']['nombre'],
                'usuarios': item['usuario'],
                'inspeccion_eficiencias': item['inspeccionEficiencias'],
                'estado': item['estado'],
                'createdAt': item['createdAt'],
                'updatedAt': item['updatedAt'],
              })
          .toList();

      final inspeccionesBox = Hive.box('inspeccionesBox');
      await inspeccionesBox.put('inspecciones', formateadas);
    } catch (e) {
      debugPrint('Error actualizando datos después de sincronización: $e');
    }
  }

  void _eliminarInspeccion(String id, data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {'estado': "false"};

    if (!conectado) {
      final box = Hive.box('operacionesOfflineInspecciones');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'eliminar',
        'id': id,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final inspeccionesBox = Hive.box('inspeccionesBox');
      final actualesRaw = inspeccionesBox.get('inspecciones', defaultValue: []);

      final actuales = (actualesRaw as List)
          .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final index = actuales.indexWhere((element) => element['id'] == id);
      if (index != -1) {
        actuales[index] = {
          ...actuales[index],
          'estado': 'false',
          'updatedAt': DateTime.now().toString(),
        };
        await inspeccionesBox.put('inspecciones', actuales);
      }

      setState(() {
        _isLoading = false;
      });
      widget.onCompleted();
      widget.showModal();
      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Sin conexión",
          message:
              "Inspeccion eliminada localmente y se sincronizará cuando haya internet",
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final inspeccionesService = InspeccionesService();
      var response = await inspeccionesService
          .actualizaDeshabilitarInspecciones(id, dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        logsInformativos(
            "Se ha eliminado la inspeccion ${data['id']} correctamente", {});
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Eliminación exitosa",
            message:
                "Se han eliminado correctamente los datos de la frecuencia",
            backgroundColor: Colors.green,
          );
        }
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Oops...",
          message: error.toString(),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      var formData = {
        'usuario': _usuarioController.text,
        'cliente': _clienteController.text,
        'encuesta': _encuestaController.text,
      };

      _eliminarInspeccion(widget.data['id'], formData);
    }
  }

  String get buttonLabel {
    if (widget.accion == 'registrar') {
      return 'Guardar';
    } else if (widget.accion == 'editar') {
      return 'Actualizar';
    } else {
      return 'Eliminar';
    }
  }

  bool get isEliminar => widget.accion == 'eliminar';

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer:
          MenuLateral(currentPage: "Tabla Inspecciones"), // Usa el menú lateral
      body: _isLoading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${capitalize(widget.accion)} inspeccion',
                        style: TextStyle(
                          fontSize: 24, // Tamaño grande
                          fontWeight: FontWeight.bold, // Negrita
                        ),
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const PremiumSectionTitle(
                          title: "Detalles de la Inspección",
                          icon: FontAwesomeIcons.clipboardCheck,
                        ),
                        PremiumCardField(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _usuarioController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Usuario Responsable',
                                  prefixIcon: FontAwesomeIcons.userCheck,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'El usuario es obligatorio'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _clienteController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Cliente / Empresa',
                                  prefixIcon: FontAwesomeIcons.building,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'El cliente es obligatorio'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _encuestaController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Encuesta Aplicada',
                                  prefixIcon: FontAwesomeIcons.rectangleList,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'La encuesta es obligatoria'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: PremiumActionButton(
                                onPressed: closeRegistroModal,
                                label: 'Cancelar',
                                icon: Icons.close,
                                style: PremiumButtonStyle.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PremiumActionButton(
                                onPressed: _onSubmit,
                                label: buttonLabel,
                                icon: isEliminar
                                    ? FontAwesomeIcons.trash
                                    : (widget.accion == 'editar'
                                        ? FontAwesomeIcons.penToSquare
                                        : FontAwesomeIcons.floppyDisk),
                                isLoading: _isLoading,
                                style: isEliminar
                                    ? PremiumButtonStyle.danger
                                    : PremiumButtonStyle.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
