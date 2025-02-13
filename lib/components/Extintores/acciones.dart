import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../api/extintores.dart';
import '../../api/tipos_extintores.dart';
import '../Logs/logs_informativos.dart';
import 'package:flutter/services.dart';

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
    widget.showModal(); // Llama a setShow con el valor booleano
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
        });
        LogsInformativos(
            "Se ha registrado la extintor ${data['nombre']} correctamente",
            dataTemp);
        _showDialog(
            "Extintor agregada correctamente", Icons.check, Colors.green);
      } else {
        // Maneja el caso en que el statusCode no sea 200
        setState(() {
          _isLoading = false;
        });
        _showDialog("Error al agregar la extintor", Icons.error, Colors.red);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showDialog("Oops...", Icons.error, Colors.red,
          error.toString()); // Muestra el error de manera más explícita
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
        });
        LogsInformativos(
            "Se ha modificado la extintor ${data['nombre']} correctamente",
            dataTemp);
        _showDialog(
            "Extintor actualizada correctamente", Icons.check, Colors.green);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showDialog("Oops...", Icons.error, Colors.red, error.toString());
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
        });
        LogsInformativos(
            "Se ha eliminado la extintor ${data['nombre']} correctamente", {});
        _showDialog(
            "Extintor eliminada correctamente", Icons.check, Colors.green);
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
                widget.onCompleted();
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _numeroSerieController,
            decoration: InputDecoration(labelText: 'Numero de serie'),
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
            decoration: InputDecoration(labelText: 'Tipo de extintor'),
            items: dataTiposExtintores.map((tipo) {
              return DropdownMenuItem<String>(
                value: tipo['id'],
                child: Text(tipo['nombre']), // Muestra el nombre en el select
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
            decoration: InputDecoration(labelText: 'Última recarga'),
            enabled: !isEliminar,
            readOnly: true, // Para que el usuario no escriba manualmente
            onTap: () async {
              // Muestra el selector de fecha
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime
                    .now(), // Fecha inicial, puedes ajustarla si lo necesitas
                firstDate: DateTime(1900), // Fecha mínima seleccionable
                lastDate: DateTime(2100), // Fecha máxima seleccionable
                locale: Locale(
                    'es', 'ES'), // Aquí se asegura que la fecha esté en español
              );

              if (pickedDate != null) {
                // Si se seleccionó una fecha, actualiza el controlador
                _ultimaRecargaController.text = "${pickedDate.toLocal()}"
                    .split(' ')[0]; // Formatea la fecha a 'YYYY-MM-DD'
              }
            },
            validator: isEliminar
                ? null
                : (value) => value?.isEmpty ?? true
                    ? 'La última recarga es obligatoria'
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
