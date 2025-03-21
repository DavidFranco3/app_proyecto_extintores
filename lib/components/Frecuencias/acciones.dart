import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../api/frecuencias.dart';
import '../Logs/logs_informativos.dart';
import 'package:flutter/services.dart';
import '../Generales/flushbar_helper.dart';

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
  bool _isLoading = false;
  late TextEditingController _nombreController;
  late TextEditingController _cantidadDiasController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _cantidadDiasController = TextEditingController();

    if (widget.accion == 'editar' || widget.accion == 'eliminar') {
      _nombreController.text = widget.data['nombre'] ?? '';
      _cantidadDiasController.text = widget.data['cantidadDias'] ?? '';
    }
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

  void _guardarFrecuencia(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {
      'nombre': data['nombre'],
      'cantidadDias': data['cantidadDias'],
      'estado': "true",
    };

    try {
      final frecuenciasService = FrecuenciasService();
      var response = await frecuenciasService.registraFrecuencias(dataTemp);
      // Verifica el statusCode correctamente, según cómo esté estructurada la respuesta
      if (response['status'] == 200) {
        // Asumiendo que 'response' es un Map que contiene el código de estado
        setState(() {
          _isLoading = false;
        });
        LogsInformativos(
            "Se ha registrado la frecuencia ${data['nombre']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "La frecuencia fue agregada correctamente",
          backgroundColor: Colors.green,
        );
      } else {
        // Maneja el caso en que el statusCode no sea 200
        setState(() {
          _isLoading = false;
          closeRegistroModal();
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

  void _editarFrecuencia(String id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {
      'nombre': data['nombre'],
      'cantidadDias': data['cantidadDias'],
    };

    try {
      final frecuenciasService = FrecuenciasService();
      var response =
          await frecuenciasService.actualizarFrecuencias(id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha modificado la frecuencia ${data['nombre']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Actualizacion exitosa",
          message: "Los datos de la frecuencia fueron agregados correctamente",
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

  void _eliminarFrecuencia(String id, data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {'estado': "false"};

    try {
      final frecuenciasService = FrecuenciasService();
      var response = await frecuenciasService.actualizaDeshabilitarFrecuencias(
          id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha eliminado la frecuencia ${data['nombre']} correctamente",
            {});
        showCustomFlushbar(
          context: context,
          title: "Eliminacion exitosa",
          message: "Se han eliminado correctamente los datos de la frecuencia",
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
        'cantidadDias': _cantidadDiasController.text,
      };

      if (widget.accion == 'registrar') {
        _guardarFrecuencia(formData);
      } else if (widget.accion == 'editar') {
        _editarFrecuencia(widget.data['id'], formData);
      } else if (widget.accion == 'eliminar') {
        _eliminarFrecuencia(widget.data['id'], formData);
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nombreController,
            decoration: InputDecoration(labelText: 'Nombre'),
            enabled: !isEliminar,
            validator: isEliminar
                ? null
                : (value) =>
                    value?.isEmpty ?? true ? 'El nombre es obligatorio' : null,
          ),
          TextFormField(
            controller: _cantidadDiasController,
            decoration: InputDecoration(labelText: 'Cantidad de días'),
            enabled: !isEliminar,
            keyboardType: TextInputType.number, // Establece el teclado numérico
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly, // Permite solo números
            ],
            validator: isEliminar
                ? null
                : (value) => value?.isEmpty ?? true
                    ? 'La cantidad de días es obligatoria'
                    : null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: closeRegistroModal, // Cierra el modal pasando false
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _onSubmit,
                child: _isLoading
                    ? SpinKitFadingCircle(color: Colors.white, size: 24)
                    : Text(buttonLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
