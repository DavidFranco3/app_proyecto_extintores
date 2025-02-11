import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../api/clasificaciones.dart';
import '../Logs/logs_informativos.dart';

class Acciones extends StatefulWidget {
final VoidCallback showModal;
  final String accion;
  final dynamic data;

  Acciones({required this.showModal, required this.accion, required this.data});

  @override
  _AccionesState createState() => _AccionesState();
}

class _AccionesState extends State<Acciones> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
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
        });
        LogsInformativos(
            "Se ha registrado la clasificacion ${data['nombre']} correctamente",
            dataTemp);
        _showDialog(
            "Clasificacion agregada correctamente", Icons.check, Colors.green);
      } else {
        // Maneja el caso en que el statusCode no sea 200
        setState(() {
          _isLoading = false;
        });
        _showDialog(
            "Error al agregar la clasificación", Icons.error, Colors.red);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showDialog("Oops...", Icons.error, Colors.red,
          error.toString()); // Muestra el error de manera más explícita
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
        });
        LogsInformativos(
            "Se ha modificado la clasificacion ${data['nombre']} correctamente",
            dataTemp);
        _showDialog("Clasificacion actualizada correctamente", Icons.check,
            Colors.green);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showDialog("Oops...", Icons.error, Colors.red, error.toString());
    }
  }

  void _eliminarClasificacion(String id) async {
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
        });
        LogsInformativos(
            "Se ha eliminado la clasificacion $id correctamente", {});
        _showDialog(
            "Clasificacion eliminada correctamente", Icons.check, Colors.green);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showDialog("Oops...", Icons.error, Colors.red, error.toString());
    }
  }

  void _showDialog(String title, IconData icon, Color color,
      [String message = '']) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: 10),
              Text(message),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                closeRegistroModal();
              },
            ),
          ],
        );
      },
    );
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
        _eliminarClasificacion(widget.data['id']);
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
