import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/frecuencias.dart';
import '../Logs/logs_informativos.dart';
import 'package:flutter/services.dart';
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
  late TextEditingController _nombreController;
  late TextEditingController _cantidadDiasController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _cantidadDiasController = TextEditingController();

    if (widget.accion == 'editar') {
      _nombreController.text = widget.data['nombre'] ?? '';
      _cantidadDiasController.text = widget.data['cantidadDias'] ?? '';
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
    _nombreController.dispose();
    _cantidadDiasController.dispose();
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

    final box = Hive.box('operacionesOfflineFrecuencias');
    final operacionesRaw = box.get('operaciones', defaultValue: []);

    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    final frecuenciasService = FrecuenciasService();
    final List<String> operacionesExitosas = [];

    for (var operacion in List.from(operaciones)) {
      try {
        if (operacion['accion'] == 'registrar') {
          final response =
              await frecuenciasService.registraFrecuencias(operacion['data']);

          if (response['status'] == 200 && response['data'] != null) {
            final frecuenciasBox = Hive.box('frecuenciasBox');
            final actualesRaw =
                frecuenciasBox.get('frecuencias', defaultValue: []);

            final actuales = (actualesRaw as List)
                .map<Map<String, dynamic>>(
                    (item) => Map<String, dynamic>.from(item))
                .toList();

            actuales.removeWhere((element) => element['id'] == operacion['id']);

            actuales.add({
              'id': response['data']['_id'],
              'nombre': response['data']['nombre'],
              'cantidadDias': response['data']['cantidadDias'],
              'estado': response['data']['estado'],
              'createdAt': response['data']['createdAt'],
              'updatedAt': response['data']['updatedAt'],
            });

            await frecuenciasBox.put('frecuencias', actuales);
          }

          operacionesExitosas.add(operacion['operacionId']);
        } else if (operacion['accion'] == 'editar') {
          final response = await frecuenciasService.actualizarFrecuencias(
              operacion['id'], operacion['data']);

          if (response['status'] == 200) {
            final frecuenciasBox = Hive.box('frecuenciasBox');
            final actualesRaw =
                frecuenciasBox.get('frecuencias', defaultValue: []);

            final actuales = (actualesRaw as List)
                .map<Map<String, dynamic>>(
                    (item) => Map<String, dynamic>.from(item))
                .toList();

            final index = actuales
                .indexWhere((element) => element['id'] == operacion['id']);
            if (index != -1) {
              actuales[index] = {
                ...actuales[index],
                ...operacion['data'],
                'updatedAt': DateTime.now().toString(),
              };
              await frecuenciasBox.put('frecuencias', actuales);
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
          await frecuenciasService.listarFrecuencias();

      final formateadas = dataAPI
          .map<Map<String, dynamic>>((item) => {
                'id': item['_id'],
                'nombre': item['nombre'],
                'cantidadDias': item['cantidadDias'],
                'estado': item['estado'],
                'createdAt': item['createdAt'],
                'updatedAt': item['updatedAt'],
              })
          .toList();

      final frecuenciasBox = Hive.box('frecuenciasBox');
      await frecuenciasBox.put('frecuencias', formateadas);
    } catch (e) {
      debugPrint('Error actualizando datos después de sincronización: $e');
    }
  }

  void _guardarFrecuencia(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'nombre': data['nombre'],
      'cantidadDias': data['cantidadDias'],
      'estado': "true",
    };

    if (!conectado) {
      final box = Hive.box('operacionesOfflineFrecuencias');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'registrar',
        'id': null,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final frecuenciasBox = Hive.box('frecuenciasBox');
      final actualesRaw = frecuenciasBox.get('frecuencias', defaultValue: []);

      final actuales = (actualesRaw as List)
          .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map))
          .toList();
      actuales.add({
        'id': DateTime.now().toIso8601String(),
        ...dataTemp,
        'createdAt': DateTime.now().toString(),
        'updatedAt': DateTime.now().toString(),
      });
      await frecuenciasBox.put('frecuencias', actuales);

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
              "Frecuencias guardada localmente y se sincronizará cuando haya internet",
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final frecuenciasService = FrecuenciasService();
      var response = await frecuenciasService.registraFrecuencias(dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        logsInformativos(
            "Se ha registrado la frecuencia ${data['nombre']} correctamente",
            {});
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Registro exitoso",
            message: "La frecuencia fue agregada correctamente",
            backgroundColor: Colors.green,
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Error",
            message: "No se pudo guardar la frecuencia",
            backgroundColor: Colors.red,
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

  void _editarFrecuencia(String id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'nombre': data['nombre'],
      'cantidadDias': data['cantidadDias'],
    };

    if (!conectado) {
      final box = Hive.box('operacionesOfflineFrecuencias');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'editar',
        'id': id,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final frecuenciasBox = Hive.box('frecuenciasBox');
      final actualesRaw = frecuenciasBox.get('frecuencias', defaultValue: []);

      final actuales = (actualesRaw as List)
          .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final index = actuales.indexWhere((element) => element['id'] == id);
      // Actualiza localmente el registro editado
      if (index != -1) {
        actuales[index] = {
          ...actuales[index],
          ...dataTemp,
          'updatedAt': DateTime.now().toString(),
        };
        await frecuenciasBox.put('frecuencias', actuales);
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
              "Frecuencia actualizada localmente y se sincronizará cuando haya internet",
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final frecuenciasService = FrecuenciasService();
      var response =
          await frecuenciasService.actualizarFrecuencias(id, dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        logsInformativos(
            "Se ha actualizado la frecuencia ${data['nombre']} correctamente",
            {});
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Actualización exitosa",
            message:
                "Los datos de la frecuencia fueron actualizados correctamente",
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
        'nombre': _nombreController.text,
        'cantidadDias': _cantidadDiasController.text,
      };

      if (widget.accion == 'registrar') {
        _guardarFrecuencia(formData);
      } else if (widget.accion == 'editar') {
        _editarFrecuencia(widget.data['id'], formData);
      }
    }
  }

  String get buttonLabel {
    if (widget.accion == 'registrar') {
      return 'Guardar';
    } else {
      return 'Actualizar';
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
      drawer: MenuLateral(currentPage: "Periodos"), // Usa el menú lateral
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
                        '${capitalize(widget.accion)} periodo',
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
                          title: "Detalles del Periodo",
                          icon: FontAwesomeIcons.clock,
                        ),
                        PremiumCardField(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nombreController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Nombre del Periodo',
                                  prefixIcon: FontAwesomeIcons.font,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'El nombre es obligatorio'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _cantidadDiasController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Duración en Días',
                                  prefixIcon: FontAwesomeIcons.calendarDays,
                                  hintText: 'Ej. 30, 180, 365',
                                ),
                                enabled: !isEliminar,
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'La cantidad de días es obligatoria'
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
