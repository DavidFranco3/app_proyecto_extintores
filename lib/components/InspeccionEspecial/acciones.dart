import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../api/inspeccion_anual.dart';
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
  late TextEditingController _tituloController;
  late TextEditingController _clienteController;

  @override
  void initState() {
    super.initState();
    print(widget.data);
    _tituloController = TextEditingController();
    _clienteController = TextEditingController();

    if (widget.accion == 'editar' || widget.accion == 'eliminar') {
      _tituloController.text = widget.data['usuario'] ?? '';
      _clienteController.text = widget.data['cliente'] ?? '';
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _clienteController.dispose();
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
      final inspeccionAnualService = InspeccionAnualService();
      var response = await inspeccionAnualService
          .deshabilitarInspeccionAnual(id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha eliminado la inspeccion anual ${data['id']} correctamente", {});
        showCustomFlushbar(
          context: context,
          title: "Eliminacion exitosa",
          message: "Se han eliminado correctamente los datos de la inspeccion especial",
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
        'titulo': _tituloController.text,
        'cliente': _clienteController.text,
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
            controller: _tituloController,
            decoration: InputDecoration(labelText: 'Titulo'),
            enabled: !isEliminar,
            validator: isEliminar
                ? null
                : (value) =>
                    value?.isEmpty ?? true ? 'El titulo es obligatorio' : null,
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
