import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../api/encuesta_inspeccion.dart';
import '../Logs/logs_informativos.dart';
import '../Generales/flushbar_helper.dart';
import 'package:prueba/components/Header/header.dart';
import 'package:prueba/components/Menu/menu_lateral.dart';
import '../Generales/premium_button.dart';
import '../Load/load.dart';

class Acciones extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  const Acciones({
    super.key,
    required this.showModal,
    required this.onCompleted,
    required this.accion,
    required this.data,
  });

  @override
  State<Acciones> createState() => _AccionesState();
}

class _AccionesState extends State<Acciones> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  late TextEditingController _nombreController;
  late TextEditingController _frecuenciaController;
  late TextEditingController _clasificacionController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _frecuenciaController = TextEditingController();
    _clasificacionController = TextEditingController();

    if (widget.accion == 'editar' || widget.accion == 'eliminar') {
      _nombreController.text = widget.data['nombre'] ?? '';
      _frecuenciaController.text = widget.data['frecuencia'] ?? '';
      _clasificacionController.text = widget.data['clasificacion'] ?? '';
    }

    Future.delayed(Duration(seconds: 1), () {
      setState(() => _isLoading = false);
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

  @override
  void dispose() {
    _nombreController.dispose();
    _frecuenciaController.dispose();
    _clasificacionController.dispose();
    super.dispose();
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  void closeRegistroModal() {
    widget.showModal();
    widget.onCompleted();
  }

  Future<void> sincronizarOperacionesPendientes() async {
    final conectado = await verificarConexion();
    if (!conectado) return;

    final box = Hive.box('operacionesOfflineEncuestas');
    final operacionesRaw = box.get('operaciones', defaultValue: []);

    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    final servicio = EncuestaInspeccionService();
    final List<String> operacionesExitosas = [];

    for (var operacion in List.from(operaciones)) {
      try {
        if (operacion['accion'] == 'eliminar') {
          final response = await servicio.deshabilitarEncuestaInspeccion(
              operacion['id'], operacion['data']);

          if (response['status'] == 200) {
            operacionesExitosas.add(operacion['operacionId']);
          }
        }
        // Aquí puedes añadir más acciones como "registrar" o "editar" si lo necesitas después
      } catch (e) {
        debugPrint('Error sincronizando operación: $e');
      }
    }

    if (operacionesExitosas.length == operaciones.length) {
      await box.put('operaciones', []);
      debugPrint("✔ Todas las operaciones sincronizadas. Limpieza completa.");
    } else {
      final nuevas = operaciones
          .where((op) => !operacionesExitosas.contains(op['operacionId']))
          .toList();
      await box.put('operaciones', nuevas);
      debugPrint("❗ Algunas operaciones no se sincronizaron. Se conservarán.");
    }
  }

  void _eliminarClasificacion(String id, Map<String, dynamic> data) async {
    setState(() => _isLoading = true);

    final conectado = await verificarConexion();
    final dataTemp = {'estado': "false"};

    if (!conectado) {
      final box = Hive.box('operacionesOfflineEncuestas');
      final operaciones = box.get('operaciones', defaultValue: []);

      final nuevaOperacion = {
        'operacionId': DateTime.now().millisecondsSinceEpoch.toString(),
        'accion': 'eliminar',
        'id': id,
        'data': dataTemp,
      };

      operaciones.add(nuevaOperacion);
      await box.put('operaciones', operaciones);

      setState(() => _isLoading = false);
      closeRegistroModal();
      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Sin conexión",
          message:
              "Encuesta marcada para eliminación. Se sincronizará cuando haya internet.",
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final servicio = EncuestaInspeccionService();
      final response =
          await servicio.deshabilitarEncuestaInspeccion(id, dataTemp);

      if (response['status'] == 200) {
        setState(() => _isLoading = false);
        closeRegistroModal();
        logsInformativos(
            "Se eliminó la encuesta ${data['nombre']} correctamente", {});
        if (!mounted) return;
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Eliminación exitosa",
            message: "Los datos de la encuesta fueron eliminados correctamente",
            backgroundColor: Colors.green,
          );
        }
      }
    } catch (error) {
      setState(() => _isLoading = false);
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
      final formData = {
        'nombre': _nombreController.text,
        'frecuencia': _frecuenciaController.text,
        'clasificacion': _clasificacionController.text,
      };

      if (widget.accion == 'eliminar') {
        _eliminarClasificacion(widget.data['id'], formData);
      }
    }
  }

  String get buttonLabel {
    if (widget.accion == 'registrar') return 'Guardar';
    if (widget.accion == 'editar') return 'Actualizar';
    return 'Eliminar';
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
      drawer: MenuLateral(currentPage: "Encuestas"),
      body: _isLoading
          ? Load()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${capitalize(widget.accion)} encuesta',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(labelText: 'Nombre'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'El nombre es obligatorio'
                                  : null,
                        ),
                        TextFormField(
                          controller: _frecuenciaController,
                          decoration: InputDecoration(labelText: 'Periodo'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'La frecuencia es obligatoria'
                                  : null,
                        ),
                        TextFormField(
                          controller: _clasificacionController,
                          decoration:
                              InputDecoration(labelText: 'Clasificación'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'La clasificación es obligatoria'
                                  : null,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PremiumActionButton(
                              onPressed: closeRegistroModal,
                              label: 'Cancelar',
                              icon: Icons.close,
                              style: PremiumButtonStyle.secondary,
                            ),
                            const SizedBox(width: 20),
                            PremiumActionButton(
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
