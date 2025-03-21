import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../api/encuesta_inspeccion.dart';
import '../Logs/logs_informativos.dart';
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
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _frecuenciaController.dispose();
    _clasificacionController.dispose();
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
      final encuestaInspeccionService = EncuestaInspeccionService();
      var response = await encuestaInspeccionService
          .deshabilitarEncuestaInspeccion(id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha eliminado la encuesta ${data['nombre']} correctamente", {});
        showCustomFlushbar(
          context: context,
          title: "Eliminacion exitosa",
          message: "Los datos de la encuesta fueron eliminados correctamente",
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
        'frecuencia': _frecuenciaController.text,
        'clasificacion': _clasificacionController.text,
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
            controller: _frecuenciaController,
            decoration: InputDecoration(labelText: 'Frecuencia'),
            enabled: !isEliminar,
            validator: isEliminar
                ? null
                : (value) => value?.isEmpty ?? true
                    ? 'La frecuencia es obligatoria'
                    : null,
          ),
          TextFormField(
            controller: _clasificacionController,
            decoration: InputDecoration(labelText: 'Clasificacion'),
            enabled: !isEliminar,
            validator: isEliminar
                ? null
                : (value) => value?.isEmpty ?? true
                    ? 'La clasificacion es obligatoria'
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
