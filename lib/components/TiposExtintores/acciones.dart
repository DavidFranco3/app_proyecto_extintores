import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../api/tipos_extintores.dart';
import '../Logs/logs_informativos.dart';
import '../Generales/flushbar_helper.dart';
import 'package:prueba/components/Header/header.dart';
import 'package:prueba/components/Menu/menu_lateral.dart';
import '../Load/load.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Acciones extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  Acciones(
      {required this.showModal,
      required this.onCompleted,
      required this.accion,
      required this.data});

  @override
  _AccionesState createState() => _AccionesState();
}

class _AccionesState extends State<Acciones> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _descripcionController = TextEditingController();

    if (widget.accion == 'editar' || widget.accion == 'eliminar') {
      _nombreController.text = widget.data['nombre'] ?? '';
      _descripcionController.text = widget.data['descripcion'] ?? '';
    }

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });

    sincronizarOperacionesPendientes();

    Connectivity().onConnectivityChanged.listen((event) {
      if (event != ConnectivityResult.none) {
        sincronizarOperacionesPendientes();
      }
    });
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion == ConnectivityResult.none) return false;
    return await InternetConnection().hasInternetAccess;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
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

    final box = Hive.box('operacionesOfflineTiposExtintores');
    final operacionesRaw = box.get('operaciones', defaultValue: []);

    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    final tiposExtintoresService = TiposExtintoresService();
    final List<String> operacionesExitosas = [];

    for (var operacion in List.from(operaciones)) {
      try {
        if (operacion['accion'] == 'registrar') {
          final response = await tiposExtintoresService
              .registraTiposExtintores(operacion['data']);

          if (response['status'] == 200 && response['data'] != null) {
            final tiposExtintoresBox = Hive.box('tiposExtintoresBox');
            final actualesRaw =
                tiposExtintoresBox.get('tiposExtintores', defaultValue: []);

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

            await tiposExtintoresBox.put('tiposExtintores', actuales);
          }

          operacionesExitosas.add(operacion['operacionId']);
        } else if (operacion['accion'] == 'editar') {
          final response = await tiposExtintoresService
              .actualizarTiposExtintores(operacion['id'], operacion['data']);

          if (response['status'] == 200) {
            final tiposExtintoresBox = Hive.box('tiposExtintoresBox');
            final actualesRaw =
                tiposExtintoresBox.get('tiposExtintores', defaultValue: []);

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
              await tiposExtintoresBox.put('tiposExtintores', actuales);
            }
          }

          operacionesExitosas.add(operacion['operacionId']);
        } else if (operacion['accion'] == 'eliminar') {
          final response = await tiposExtintoresService
              .actualizaDeshabilitarTiposExtintores(
                  operacion['id'], {'estado': 'false'});

          if (response['status'] == 200) {
            final tiposExtintoresBox = Hive.box('tiposExtintoresBox');
            final actualesRaw =
                tiposExtintoresBox.get('tiposExtintores', defaultValue: []);

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
              await tiposExtintoresBox.put('tiposExtintores', actuales);
            }
          }

          operacionesExitosas.add(operacion['operacionId']);
        }
      } catch (e) {
        print('Error sincronizando operación: $e');
      }
    }

    // 🔥 Si TODAS las operaciones se sincronizaron correctamente, limpia por completo:
    if (operacionesExitosas.length == operaciones.length) {
      await box.put('operaciones', []);
      print("✔ Todas las operaciones sincronizadas. Limpieza completa.");
    } else {
      // 🔄 Si alguna falló, conserva solo las pendientes
      final nuevasOperaciones = operaciones
          .where((op) => !operacionesExitosas.contains(op['operacionId']))
          .toList();
      await box.put('operaciones', nuevasOperaciones);
      print(
          "❗ Algunas operaciones no se sincronizaron, se conservarán localmente.");
    }

    // ✅ Actualizar lista completa desde API
    try {
      final List<dynamic> dataAPI =
          await tiposExtintoresService.listarTiposExtintores();

      final formateadas = dataAPI
          .map<Map<String, dynamic>>((item) => {
                'id': item['_id'],
                'nombre': item['nombre'],
                'descripcion': item['descripcion'],
                'estado': item['estado'],
                'createdAt': item['createdAt'],
                'updatedAt': item['updatedAt'],
              })
          .toList();

      final tiposExtintoresBox = Hive.box('tiposExtintoresBox');
      await tiposExtintoresBox.put('tiposExtintores', formateadas);
    } catch (e) {
      print('Error actualizando datos después de sincronización: $e');
    }
  }

  void _guardarTipoExtintor(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'nombre': data['nombre'],
      'descripcion': data['descripcion'],
      'estado': "true",
    };

    if (!conectado) {
      final box = Hive.box('operacionesOfflineTiposExtintores');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'registrar',
        'id': null,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final tiposExtintoresBox = Hive.box('tiposExtintoresBox');
      final actualesRaw =
          tiposExtintoresBox.get('tiposExtintores', defaultValue: []);

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
      await tiposExtintoresBox.put('tiposExtintores', actuales);

      setState(() {
        _isLoading = false;
      });
      widget.onCompleted();
      widget.showModal();
      showCustomFlushbar(
        context: context,
        title: "Sin conexión",
        message:
            "Tipo de extintor guardado localmente y se sincronizará cuando haya internet",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final tiposExtintoresService = TiposExtintoresService();
      var response =
          await tiposExtintoresService.registraTiposExtintores(dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        LogsInformativos(
            "Se ha registrado el tipo de extintor ${data['nombre']} correctamente",
            {});
        showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "El tipo de extintor fue agregado correctamente",
          backgroundColor: Colors.green,
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        showCustomFlushbar(
          context: context,
          title: "Error",
          message: "No se pudo guardar el tipo de extintor",
          backgroundColor: Colors.red,
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      showCustomFlushbar(
        context: context,
        title: "Oops...",
        message: error.toString(),
        backgroundColor: Colors.red,
      );
    }
  }

  void _editarTipoExtintor(String id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'nombre': data['nombre'],
      'descripcion': data['descripcion'],
    };

    if (!conectado) {
      final box = Hive.box('operacionesOfflineTiposExtintores');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'editar',
        'id': id,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final tiposExtintoresBox = Hive.box('tiposExtintoresBox');
      final actualesRaw =
          tiposExtintoresBox.get('tiposExtintores', defaultValue: []);

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
        await tiposExtintoresBox.put('tiposExtintores', actuales);
      }

      setState(() {
        _isLoading = false;
      });
      widget.onCompleted();
      widget.showModal();
      showCustomFlushbar(
        context: context,
        title: "Sin conexión",
        message:
            "Tipo de extintor actualizado localmente y se sincronizará cuando haya internet",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final tiposExtintoresService = TiposExtintoresService();
      var response =
          await tiposExtintoresService.actualizarTiposExtintores(id, dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        LogsInformativos(
            "Se ha actualizado el tipo de extintor ${data['nombre']} correctamente",
            {});
        showCustomFlushbar(
          context: context,
          title: "Actualización exitosa",
          message:
              "Los datos del tipo del extintor fueron actualizados correctamente",
          backgroundColor: Colors.green,
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      showCustomFlushbar(
        context: context,
        title: "Oops...",
        message: error.toString(),
        backgroundColor: Colors.red,
      );
    }
  }

  void _eliminarTipoExtintor(String id, data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {'estado': "false"};

    if (!conectado) {
      final box = Hive.box('operacionesOfflineTiposExtintores');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'eliminar',
        'id': id,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final tiposExtintoresBox = Hive.box('tiposExtintoresBox');
      final actualesRaw =
          tiposExtintoresBox.get('tiposExtintores', defaultValue: []);

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
        await tiposExtintoresBox.put('tiposExtintores', actuales);
      }

      setState(() {
        _isLoading = false;
      });
      widget.onCompleted();
      widget.showModal();
      showCustomFlushbar(
        context: context,
        title: "Sin conexión",
        message:
            "Tipo de extintor eliminada localmente y se sincronizará cuando haya internet",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final tiposExtintoresService = TiposExtintoresService();
      var response = await tiposExtintoresService
          .actualizaDeshabilitarTiposExtintores(id, dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        LogsInformativos(
            "Se ha eliminado el tipo de extintor ${data['id']} correctamente",
            {});
        showCustomFlushbar(
          context: context,
          title: "Eliminación exitosa",
          message:
              "Se han eliminado correctamente los datos del tipo de extintor",
          backgroundColor: Colors.green,
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      showCustomFlushbar(
        context: context,
        title: "Oops...",
        message: error.toString(),
        backgroundColor: Colors.red,
      );
    }
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      var formData = {
        'nombre': _nombreController.text,
        'descripcion': _descripcionController.text,
      };

      if (widget.accion == 'registrar') {
        _guardarTipoExtintor(formData);
      } else if (widget.accion == 'editar') {
        _editarTipoExtintor(widget.data['id'], formData);
      } else if (widget.accion == 'eliminar') {
        _eliminarTipoExtintor(widget.data['id'], formData);
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
      drawer: MenuLateral(
          currentPage: "Tipos de Extintores"), // Usa el menú lateral
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
                        '${capitalize(widget.accion)} tipo de extintor',
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
                          controller: _descripcionController,
                          decoration: InputDecoration(labelText: 'Descripción'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'La descripción es obligatoria'
                                  : null,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed:
                                  closeRegistroModal, // Cierra el modal pasando false
                              child: Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _onSubmit,
                              child: _isLoading
                                  ? SpinKitFadingCircle(
                                      color: Colors.white, size: 24)
                                  : Text(buttonLabel),
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
