import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/ramas.dart';
import '../Logs/logs_informativos.dart';
import '../Generales/flushbar_helper.dart';
import 'package:prueba/components/Header/header.dart';
import 'package:prueba/components/Menu/menu_lateral.dart';
import '../Generales/premium_button.dart';
import '../Load/load.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../Generales/premium_inputs.dart';

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

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();

    if (widget.accion == 'editar' || widget.accion == 'eliminar') {
      _nombreController.text = widget.data['nombre'] ?? '';
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

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  // Corregimos la función para que acepte un parámetro bool
  void closeRegistroModal() {
    widget.showModal(); // Llama a setShow con el valor booleano
    widget.onCompleted();
  }

  Future<void> sincronizarOperacionesPendientes() async {
    final conectado = await verificarConexion();
    if (!conectado) return;

    final box = Hive.box('operacionesOfflineRamas');
    final operacionesRaw = box.get('operaciones', defaultValue: []);

    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    final ramasService = RamasService();
    final List<String> operacionesExitosas = [];

    for (var operacion in List.from(operaciones)) {
      try {
        if (operacion['accion'] == 'registrar') {
          final response = await ramasService.registrarRamas(operacion['data']);

          if (response['status'] == 200 && response['data'] != null) {
            final ramasBox = Hive.box('ramasBox');
            final actualesRaw = ramasBox.get('ramas', defaultValue: []);

            final actuales = (actualesRaw as List)
                .map<Map<String, dynamic>>(
                    (item) => Map<String, dynamic>.from(item))
                .toList();

            actuales.removeWhere((element) => element['id'] == operacion['id']);

            actuales.add({
              'id': response['data']['_id'],
              'nombre': response['data']['nombre'],
              'descripcion': response['data']['descripcion'],
              'estado': response['data']['estado'],
              'createdAt': response['data']['createdAt'],
              'updatedAt': response['data']['updatedAt'],
            });

            await ramasBox.put('ramas', actuales);
          }

          operacionesExitosas.add(operacion['operacionId']);
        } else if (operacion['accion'] == 'editar') {
          final response = await ramasService.actualizarRamas(
              operacion['id'], operacion['data']);

          if (response['status'] == 200) {
            final ramasBox = Hive.box('ramasBox');
            final actualesRaw = ramasBox.get('ramas', defaultValue: []);

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
              await ramasBox.put('ramas', actuales);
            }
          }

          operacionesExitosas.add(operacion['operacionId']);
        } else if (operacion['accion'] == 'eliminar') {
          final response = await ramasService
              .deshabilitarRamas(operacion['id'], {'estado': 'false'});

          if (response['status'] == 200) {
            final ramasBox = Hive.box('ramasBox');
            final actualesRaw = ramasBox.get('ramas', defaultValue: []);

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
              await ramasBox.put('ramas', actuales);
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
      final List<dynamic> dataAPI = await ramasService.listarRamas();

      final formateadas = dataAPI
          .map<Map<String, dynamic>>((item) => {
                'id': item['_id'],
                'nombre': item['nombre'],
                'estado': item['estado'],
                'createdAt': item['createdAt'],
                'updatedAt': item['updatedAt'],
              })
          .toList();

      final ramasBox = Hive.box('ramasBox');
      await ramasBox.put('ramas', formateadas);
    } catch (e) {
      debugPrint('Error actualizando datos después de sincronización: $e');
    }
  }

  void _guardarRama(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'nombre': data['nombre'],
      'estado': "true",
    };

    if (!conectado) {
      final box = Hive.box('operacionesOfflineRamas');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'registrar',
        'id': null,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final ramasBox = Hive.box('ramasBox');
      final actualesRaw = ramasBox.get('ramas', defaultValue: []);

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
      await ramasBox.put('ramas', actuales);

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
              "Rama guardada localmente y se sincronizará cuando haya internet",
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final ramasService = RamasService();
      var response = await ramasService.registrarRamas(dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        logsInformativos(
            "Se ha registrado la rama ${data['nombre']} correctamente", {});
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Registro exitoso",
            message: "La rama fue agregada correctamente",
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
            message: "No se pudo guardar la rama",
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

  void _editarRama(String id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'nombre': data['nombre'],
    };

    if (!conectado) {
      final box = Hive.box('operacionesOfflineRamas');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'editar',
        'id': id,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final ramasBox = Hive.box('ramasBox');
      final actualesRaw = ramasBox.get('ramas', defaultValue: []);

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
        await ramasBox.put('ramas', actuales);
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
              "Rama actualizada localmente y se sincronizará cuando haya internet",
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final ramasService = RamasService();
      var response = await ramasService.actualizarRamas(id, dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        logsInformativos(
            "Se ha actualizado la rama ${data['nombre']} correctamente", {});
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Actualización exitosa",
            message: "Los datos de la rama fueron actualizados correctamente",
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

  void _eliminarRama(String id, data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {'estado': "false"};

    if (!conectado) {
      final box = Hive.box('operacionesOfflineRamas');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'eliminar',
        'id': id,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final ramasBox = Hive.box('ramasBox');
      final actualesRaw = ramasBox.get('ramas', defaultValue: []);

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
        await ramasBox.put('ramas', actuales);
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
              "Rama eliminada localmente y se sincronizará cuando haya internet",
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final ramasService = RamasService();
      var response = await ramasService.deshabilitarRamas(id, dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        logsInformativos(
            "Se ha eliminado la rama ${data['id']} correctamente", {});
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Eliminación exitosa",
            message: "Se han eliminado correctamente los datos de la rama",
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
      };

      if (widget.accion == 'registrar') {
        _guardarRama(formData);
      } else if (widget.accion == 'editar') {
        _editarRama(widget.data['id'], formData);
      } else if (widget.accion == 'eliminar') {
        _eliminarRama(widget.data['id'], formData);
      }
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
          MenuLateral(currentPage: "Tipos de sistema"), // Usa el menú lateral
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
                        '${capitalize(widget.accion)} tipo de sistema',
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
                          title: "Información del Sistema",
                          icon: FontAwesomeIcons.networkWired,
                        ),
                        PremiumCardField(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nombreController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Nombre del Tipo de Sistema',
                                  prefixIcon: FontAwesomeIcons.sitemap,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'El nombre es obligatorio'
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
