import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:prueba/components/Header/header.dart';
import 'package:prueba/components/Menu/menu_lateral.dart';
import '../../api/clasificaciones.dart';
import '../Logs/logs_informativos.dart';
import '../Generales/flushbar_helper.dart';
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
    // Cambiar _isLoading a false después de 5 segundos
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
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

  void _guardarClasificacion(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {
      'nombre': data['nombre'],
      'descripcion': data['descripcion'],
      'estado': "true",
    };

    try {
      final clasificacionesService = ClasificacionesService();
      var response =
          await clasificacionesService.registrarClasificaciones(dataTemp);
      // Verifica el statusCode correctamente, según cómo esté estructurada la respuesta
      if (response['status'] == 200) {
        // Asumiendo que 'response' es un Map que contiene el código de estado
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "La clasificacion fue agregada correctamente",
          backgroundColor: Colors.green,
        );
      } else {
        // Maneja el caso en que el statusCode no sea 200
        setState(() {
          _isLoading = false;
        });
        LogsInformativos(
            "Se ha agreado la clasificacion ${data['nombre']} correctamente",
            dataTemp);
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

  void _editarClasificacion(String id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {
      'nombre': data['nombre'],
      'descripcion': data['descripcion'],
    };

    try {
      final clasificacionesService = ClasificacionesService();
      var response =
          await clasificacionesService.actualizarClasificaciones(id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha modificado la clasificacion ${data['nombre']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Actualizacion exitosa",
          message:
              "Los datos de la clasificacion fueron actualizados correctamente",
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

  void _eliminarClasificacion(String id, data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {'estado': "false"};

    try {
      final clasificacionesService = ClasificacionesService();
      var response = await clasificacionesService.deshabilitarClasificaciones(
          id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha eliminado la clasificacion ${data['nombre']} correctamente",
            {});
        showCustomFlushbar(
          context: context,
          title: "Eliminacion exitosa",
          message:
              "Se han eliminado correctamente los datos de la clasificacion",
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
        _guardarClasificacion(formData);
      } else if (widget.accion == 'editar') {
        _editarClasificacion(widget.data['id'], formData);
      } else if (widget.accion == 'eliminar') {
        _eliminarClasificacion(widget.data['id'], formData);
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
          MenuLateral(currentPage: "Clasificaciones"), // Usa el menú lateral
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
                        '${capitalize(widget.accion)} clasificacion',
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
                        // Campo de texto para el nombre
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
                        SizedBox(height: 10), // Espacio entre campos
                        // Campo de texto para la descripción
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
                        SizedBox(height: 20), // Espacio antes de los botones
                        // Botones de acción
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Centra los botones
                          children: [
                            ElevatedButton(
                              onPressed: closeRegistroModal,
                              child: Text('Cancelar'),
                            ),
                            SizedBox(width: 10), // Espacio entre botones
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
