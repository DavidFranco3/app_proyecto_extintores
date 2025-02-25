import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../api/inspecciones.dart';
import '../Logs/logs_informativos.dart';

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
        });
        LogsInformativos(
            "Se ha eliminado la inspeccion ${data['id']} correctamente", {});
        _showDialog(
            "inspeccion eliminada correctamente", Icons.check, Colors.green);
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usuarioController,
            decoration: InputDecoration(labelText: 'Usuario'),
            enabled: !isEliminar,
            validator: isEliminar
                ? null
                : (value) =>
                    value?.isEmpty ?? true ? 'El usuario es obligatorio' : null,
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
