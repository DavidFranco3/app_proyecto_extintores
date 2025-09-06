import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../api/extintores.dart';
import '../../api/tipos_extintores.dart';
import '../Logs/logs_informativos.dart';
import '../Generales/flushbar_helper.dart';
import 'package:prueba/components/Header/header.dart';
import 'package:prueba/components/Menu/menu_lateral.dart';
import '../Load/load.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

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
  bool loading = true;
  List<Map<String, dynamic>> dataTiposExtintores = [];
  late TextEditingController _numeroSerieController;
  late TextEditingController _idTipoExtintorController;
  late TextEditingController _capacidadController;
  late TextEditingController _ultimaRecargaController;

  @override
  void initState() {
    super.initState();
    cargarTiposExtintores();
    _numeroSerieController = TextEditingController();
    _idTipoExtintorController = TextEditingController();
    _capacidadController = TextEditingController();
    _ultimaRecargaController = TextEditingController();

    if (widget.accion == 'editar' || widget.accion == 'eliminar') {
      _numeroSerieController.text = widget.data['numeroSerie'] ?? '';
      _idTipoExtintorController.text = widget.data['idTipoExtintor'] ?? '';
      _capacidadController.text = widget.data['capacidad'] ?? '';
      _ultimaRecargaController.text = widget.data['ultimaRecarga'] ?? '';
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

  Future<void> cargarTiposExtintores() async {
    final conectado = await verificarConexion();
    if (conectado) {
      print("Conectado a internet");
      await getTiposExtintoresDesdeAPI();
    } else {
      print("Sin conexión, cargando desde Hive...");
      await getTiposExtintoresDesdeHive();
    }
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion == ConnectivityResult.none) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> getTiposExtintoresDesdeAPI() async {
    try {
      final tiposExtintoresService = TiposExtintoresService();
      final List<dynamic> response =
          await tiposExtintoresService.listarTiposExtintores();

      if (response.isNotEmpty) {
        final formateadas = formatModelTiposExtintores(response);

        final box = Hive.box('tiposExtintoresBox');
        await box.put('tiposExtintores', formateadas);

        if (mounted) {
          setState(() {
            dataTiposExtintores = formateadas;
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            dataTiposExtintores = [];
            loading = false;
          });
        }
      }
    } catch (e) {
      print("Error al obtener los tipos de extintores: $e");
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getTiposExtintoresDesdeHive() async {
    final box = Hive.box('tiposExtintoresBox');
    final List<dynamic>? guardados = box.get('tiposExtintores');

    if (guardados != null) {
      if (mounted) {
        setState(() {
          dataTiposExtintores = guardados
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item as Map))
              .toList();
          loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          dataTiposExtintores = [];
          loading = false;
        });
      }
    }
  }

  // Función para formatear los datos de las tiposExtintores
  List<Map<String, dynamic>> formatModelTiposExtintores(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'descripcion': item['descripcion'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  @override
  void dispose() {
    _numeroSerieController.dispose();
    _idTipoExtintorController.dispose();
    _capacidadController.dispose();
    _ultimaRecargaController.dispose();
    super.dispose();
  }

  // Corregimos la función para que acepte un parámetro bool
  void closeRegistroModal() {
    widget.showModal();
    widget.onCompleted(); // Llama a setShow con el valor booleano
  }

  Future<void> sincronizarOperacionesPendientes() async {
    final conectado = await verificarConexion();
    if (!conectado) return;

    final box = Hive.box('operacionesOfflineExtintores');
    final operacionesRaw = box.get('operaciones', defaultValue: []);

    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    final extintoresService = ExtintoresService();
    final List<String> operacionesExitosas = [];

    for (var operacion in List.from(operaciones)) {
      try {
        if (operacion['accion'] == 'registrar') {
          final response =
              await extintoresService.registraExtintores(operacion['data']);

          if (response['status'] == 200 && response['data'] != null) {
            final extintoresBox = Hive.box('extintoresBox');
            final actualesRaw =
                extintoresBox.get('extintores', defaultValue: []);

            final actuales = (actualesRaw as List)
                .map<Map<String, dynamic>>(
                    (item) => Map<String, dynamic>.from(item))
                .toList();

            actuales.removeWhere((element) => element['id'] == operacion['id']);

            actuales.add({
              'id': response['data']['_id'],
              'numeroSerie': response['data']['numeroSerie'],
              'idTipoExtintor': response['data']['idTipoExtintor'],
              'capacidad': response['data']['capacidad'],
              'ultimaRecarga': response['data']['ultimaRecarga'],
              'estado': response['data']['estado'],
              'createdAt': response['data']['createdAt'],
              'updatedAt': response['data']['updatedAt'],
            });

            await extintoresBox.put('extintores', actuales);
          }

          operacionesExitosas.add(operacion['operacionId']);
        } else if (operacion['accion'] == 'editar') {
          final response = await extintoresService.actualizarExtintores(
              operacion['id'], operacion['data']);

          if (response['status'] == 200) {
            final extintoresBox = Hive.box('extintoresBox');
            final actualesRaw =
                extintoresBox.get('extintores', defaultValue: []);

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
              await extintoresBox.put('extintores', actuales);
            }
          }

          operacionesExitosas.add(operacion['operacionId']);
        } else if (operacion['accion'] == 'eliminar') {
          final response = await extintoresService
              .actualizaDeshabilitarExtintores(
                  operacion['id'], {'estado': 'false'});

          if (response['status'] == 200) {
            final extintoresBox = Hive.box('extintoresBox');
            final actualesRaw =
                extintoresBox.get('extintores', defaultValue: []);

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
              await extintoresBox.put('extintores', actuales);
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
      
    }

    // ✅ Actualizar lista completa desde API
    try {
      final List<dynamic> dataAPI = await extintoresService.listarExtintores();

      final formateadas = dataAPI
          .map<Map<String, dynamic>>((item) => {
                'id': item['_id'],
                'numeroSerie': item['numeroSerie'],
                'idTipoExtintor': item['idTipoExtintor'],
                'extintor': item['tipoExtintor']['nombre'],
                'capacidad': item['capacidad'],
                'ultimaRecarga': item['ultimaRecarga'],
                'estado': item['estado'],
                'createdAt': item['createdAt'],
                'updatedAt': item['updatedAt'],
              })
          .toList();

      final extintoresBox = Hive.box('extintoresBox');
      await extintoresBox.put('extintores', formateadas);
    } catch (e) {
      print('Error actualizando datos después de sincronización: $e');
    }
  }

  void _guardarExtintor(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'numeroSerie': data['numeroSerie'],
      'idTipoExtintor': data['idTipoExtintor'],
      'capacidad': data['capacidad'],
      'ultimaRecarga': data['ultimaRecarga'],
      'estado': "true",
    };

    if (!conectado) {
      final box = Hive.box('operacionesOfflineExtintores');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'registrar',
        'id': null,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final extintoresBox = Hive.box('extintoresBox');
      final actualesRaw = extintoresBox.get('extintores', defaultValue: []);

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
      await extintoresBox.put('extintores', actuales);

      setState(() {
        _isLoading = false;
      });
      widget.onCompleted();
      widget.showModal();
      showCustomFlushbar(
        context: context,
        title: "Sin conexión",
        message:
            "Extintor guardado localmente y se sincronizará cuando haya internet",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final extintoresService = ExtintoresService();
      var response = await extintoresService.registraExtintores(dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        LogsInformativos(
            "Se ha registrado el extintor ${data['nombre']} correctamente", {});
        showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "El extintor fue agregado correctamente",
          backgroundColor: Colors.green,
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        showCustomFlushbar(
          context: context,
          title: "Error",
          message: "No se pudo guardar el extintor",
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

  void _editarExtintor(String id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'numeroSerie': data['numeroSerie'],
      'idTipoExtintor': data['idTipoExtintor'],
      'capacidad': data['capacidad'],
      'ultimaRecarga': data['ultimaRecarga'],
    };

    if (!conectado) {
      final box = Hive.box('operacionesOfflineExtintores');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'editar',
        'id': id,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final extintoresBox = Hive.box('extintoresBox');
      final actualesRaw = extintoresBox.get('extintores', defaultValue: []);

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
        await extintoresBox.put('extintores', actuales);
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
            "Extintor actualizado localmente y se sincronizará cuando haya internet",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final extintoresService = ExtintoresService();
      var response = await extintoresService.actualizarExtintores(id, dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        LogsInformativos(
            "Se ha actualizado el extintor ${data['nombre']} correctamente",
            {});
        showCustomFlushbar(
          context: context,
          title: "Actualización exitosa",
          message: "Los datos de el extintor fueron actualizados correctamente",
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

  void _eliminarExtintor(String id, data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {'estado': "false"};

    if (!conectado) {
      final box = Hive.box('operacionesOfflineExtintores');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'eliminar',
        'id': id,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final extintoresBox = Hive.box('extintoresBox');
      final actualesRaw = extintoresBox.get('extintores', defaultValue: []);

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
        await extintoresBox.put('extintores', actuales);
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
            "Extintor eliminado localmente y se sincronizará cuando haya internet",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final extintoresService = ExtintoresService();
      var response =
          await extintoresService.actualizaDeshabilitarExtintores(id, dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        LogsInformativos(
            "Se ha eliminado el extintor ${data['id']} correctamente", {});
        showCustomFlushbar(
          context: context,
          title: "Eliminación exitosa",
          message: "Se han eliminado correctamente los datos del extintor",
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
        'numeroSerie': _numeroSerieController.text,
        'idTipoExtintor': _idTipoExtintorController.text,
        'capacidad': _capacidadController.text,
        'ultimaRecarga': _ultimaRecargaController.text,
      };

      if (widget.accion == 'registrar') {
        _guardarExtintor(formData);
      } else if (widget.accion == 'editar') {
        _editarExtintor(widget.data['id'], formData);
      } else if (widget.accion == 'eliminar') {
        _eliminarExtintor(widget.data['id'], formData);
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
          MenuLateral(currentPage: "Crear Inspeccion"), // Usa el menú lateral
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
                        '${capitalize(widget.accion)} extintor',
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
                          controller: _numeroSerieController,
                          decoration:
                              InputDecoration(labelText: 'Numero de serie'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'El numero de serie es obligatorio'
                                  : null,
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _idTipoExtintorController.text.isEmpty
                              ? null
                              : _idTipoExtintorController.text,
                          decoration:
                              InputDecoration(labelText: 'Tipo de extintor'),
                          isExpanded: true,
                          items: dataTiposExtintores.map((tipo) {
                            return DropdownMenuItem<String>(
                              value: tipo['id'],
                              child: Text(tipo[
                                  'nombre']), // Muestra el nombre en el select
                            );
                          }).toList(),
                          onChanged: isEliminar
                              ? null
                              : (newValue) {
                                  setState(() {
                                    _idTipoExtintorController.text = newValue!;
                                  });
                                },
                          validator: isEliminar
                              ? null
                              : (value) => value == null || value.isEmpty
                                  ? 'El tipo de extintor es obligatorio'
                                  : null,
                        ),
                        TextFormField(
                          controller: _capacidadController,
                          decoration: InputDecoration(labelText: 'Capacidad'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'La capacidad es obligatoria'
                                  : null,
                        ),
                        TextFormField(
                          controller: _ultimaRecargaController,
                          decoration:
                              InputDecoration(labelText: 'Última recarga'),
                          enabled: !isEliminar,
                          readOnly:
                              true, // Para que el usuario no escriba manualmente
                          onTap: () async {
                            // Muestra el selector de fecha
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime
                                  .now(), // Fecha inicial, puedes ajustarla si lo necesitas
                              firstDate:
                                  DateTime(1900), // Fecha mínima seleccionable
                              lastDate:
                                  DateTime(2100), // Fecha máxima seleccionable
                              locale: Locale('es',
                                  'ES'), // Aquí se asegura que la fecha esté en español
                            );

                            if (pickedDate != null) {
                              // Si se seleccionó una fecha, actualiza el controlador
                              _ultimaRecargaController.text =
                                  "${pickedDate.toLocal()}".split(' ')[
                                      0]; // Formatea la fecha a 'YYYY-MM-DD'
                            }
                          },
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'La última recarga es obligatoria'
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
