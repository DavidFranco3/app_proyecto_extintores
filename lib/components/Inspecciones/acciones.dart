import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../api/inspecciones.dart';
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
  late TextEditingController _usuarioController;
  late TextEditingController _clienteController;
  late TextEditingController _encuestaController;

  @override
  void initState() {
    super.initState();
    print(widget.data);
    _usuarioController = TextEditingController();
    _clienteController = TextEditingController();
    _encuestaController = TextEditingController();

    if (widget.accion == 'editar' || widget.accion == 'eliminar') {
      _usuarioController.text = widget.data['usuario'] ?? '';
      _clienteController.text = widget.data['cliente'] ?? '';
      _encuestaController.text = widget.data['cuestionario'] ?? '';
    }

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
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

  void _eliminarClasificacion(String id, data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {'estado': "false"};

    try {
      final inspeccionesService = InspeccionesService();
      var response = await inspeccionesService
          .actualizaDeshabilitarInspecciones(id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha eliminado la inspeccion ${data['id']} correctamente", {});
        showCustomFlushbar(
          context: context,
          title: "Eliminacion exitosa",
          message: "Se han eliminado correctamente los datos de la inspeccion",
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
        'usuario': _usuarioController.text,
        'cliente': _clienteController.text,
        'encuesta': _encuestaController.text,
      };

      _eliminarClasificacion(widget.data['id'], formData);
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
                        TextFormField(
                          controller: _usuarioController,
                          decoration: InputDecoration(labelText: 'Usuario'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'El usuario es obligatorio'
                                  : null,
                        ),
                        TextFormField(
                          controller: _clienteController,
                          decoration: InputDecoration(labelText: 'Cliente'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'El cliente es obligatorio'
                                  : null,
                        ),
                        TextFormField(
                          controller: _encuestaController,
                          decoration: InputDecoration(labelText: 'Encuesta'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'La encuesta es obligatoria'
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
