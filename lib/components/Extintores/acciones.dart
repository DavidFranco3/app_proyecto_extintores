import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../api/extintores.dart';
import '../../api/tipos_extintores.dart';
import '../Logs/logs_informativos.dart';
import '../Generales/flushbar_helper.dart';
import 'package:prueba/components/Header/header.dart';
import 'package:prueba/components/Menu/menu_lateral.dart';
import '../Load/load.dart';

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
    getTiposExtintores();
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
  }

  Future<void> getTiposExtintores() async {
    try {
      final tiposExtintoresService = TiposExtintoresService();
      final List<dynamic> response =
          await tiposExtintoresService.listarTiposExtintores();

      if (response.isNotEmpty) {
        setState(() {
          dataTiposExtintores = formatModelTiposExtintores(response);
          loading = false;
        });
      } else {
        print('Error: La respuesta está vacía o no es válida.');
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      print("Error al obtener las tiposExtintores: $e");
      setState(() {
        loading = false;
      });
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

  void _guardarExtintor(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {
      'numeroSerie': data['numeroSerie'],
      'idTipoExtintor': data['idTipoExtintor'],
      'capacidad': data['capacidad'],
      'ultimaRecarga': data['ultimaRecarga'],
      'estado': "true",
    };

    try {
      final extintoresService = ExtintoresService();
      var response = await extintoresService.registraExtintores(dataTemp);
      // Verifica el statusCode correctamente, según cómo esté estructurada la respuesta
      if (response['status'] == 200) {
        // Asumiendo que 'response' es un Map que contiene el código de estado
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha registrado la extintor ${data['numeroSerie']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "El extintor fue agregado correctamente",
          backgroundColor: Colors.green,
        );
      } else {
        // Maneja el caso en que el statusCode no sea 200
        setState(() {
          _isLoading = false;
        });
        showCustomFlushbar(
          context: context,
          title: "Hubo un problema",
          message: "Hubo un error al agregar la clasificacion",
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

    var dataTemp = {
      'numeroSerie': data['numeroSerie'],
      'idTipoExtintor': data['idTipoExtintor'],
      'capacidad': data['capacidad'],
      'ultimaRecarga': data['ultimaRecarga'],
    };

    try {
      final extintoresService = ExtintoresService();
      var response = await extintoresService.actualizarExtintores(id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha modificado la extintor ${data['numeroSerie']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Actualizacion exitosa",
          message: "Los datos del extintor fueron agregados correctamente",
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

    var dataTemp = {'estado': "false"};

    try {
      final extintoresService = ExtintoresService();
      var response =
          await extintoresService.actualizaDeshabilitarExtintores(id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha eliminado la extintor ${data['numeroSerie']} correctamente",
            {});
        showCustomFlushbar(
          context: context,
          title: "Eliminacion exitosa",
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
      drawer: MenuLateral(currentPage: "Crear Inspeccion"), // Usa el menú lateral
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
                          value: _idTipoExtintorController.text.isEmpty
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
