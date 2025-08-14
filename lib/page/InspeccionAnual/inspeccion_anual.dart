import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../api/clientes.dart';
import '../../api/inspeccion_anual.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Logs/logs_informativos.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../InspeccionEspecial/inspeccion_especial.dart';
import 'package:flutter/services.dart';
import '../../components/Generales/flushbar_helper.dart';

class InspeccionAnualPage extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;
  InspeccionAnualPage({
    required this.showModal,
    required this.onCompleted,
    required this.accion,
    required this.data,
  });

  _InspeccionAnualPageState createState() => _InspeccionAnualPageState();
}

class _InspeccionAnualPageState extends State<InspeccionAnualPage> {
  final _formKey = GlobalKey<FormState>();
  List<Pregunta> preguntas = [];
  TextEditingController preguntaController = TextEditingController();
  TextEditingController observacionController = TextEditingController();
  TextEditingController nombreController = TextEditingController();
  TextEditingController clienteController = TextEditingController();
  List<Map<String, dynamic>> dataClientes = [];
  bool loading = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getClientes();
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion == ConnectivityResult.none) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> getClientes() async {
    final conectado = await verificarConexion();

    if (conectado) {
      await getClientesDesdeAPI();
    } else {
      print("Sin conexión, cargando clientes desde Hive...");
      await getClientesDesdeHive();
    }
  }

  Future<void> getClientesDesdeAPI() async {
    try {
      final clientesService = ClientesService();
      final List<dynamic> response = await clientesService.listarClientes();

      if (response.isNotEmpty) {
        final formateados = formatModelClientes(response);

        final box = Hive.box('clientesBox');
        await box.put('clientes', formateados);

        setState(() {
          dataClientes = formateados;
          loading = false;
        });
      } else {
        setState(() {
          dataClientes = [];
          loading = false;
        });
      }
    } catch (e) {
      print("Error al obtener los clientes: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getClientesDesdeHive() async {
    try {
      final box = Hive.box('clientesBox');
      final List<dynamic>? guardados = box.get('clientes');

      if (guardados != null) {
        setState(() {
          dataClientes = (guardados as List)
              .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
              .where((item) => item['estado'] == "true")
              .toList();
          loading = false;
        });
      } else {
        setState(() {
          dataClientes = [];
          loading = false;
        });
      }
    } catch (e) {
      print("Error leyendo clientes desde Hive: $e");
      setState(() {
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> formatModelClientes(List<dynamic> data) {
    return data.map((item) => {
          'id': item['_id'],
          'nombre': item['nombre'],
          'imagen': item['imagen'],
          'correo': item['correo'],
          'telefono': item['telefono'],
          'calle': item['direccion']['calle'],
          'nExterior': item['direccion']['nExterior']?.isNotEmpty ?? false
              ? item['direccion']['nExterior']
              : 'S/N',
          'nInterior': item['direccion']['nInterior']?.isNotEmpty ?? false
              ? item['direccion']['nInterior']
              : 'S/N',
          'colonia': item['direccion']['colonia'],
          'estadoDom': item['direccion']['estadoDom'],
          'municipio': item['direccion']['municipio'],
          'cPostal': item['direccion']['cPostal'],
          'referencia': item['direccion']['referencia'],
          'estado': item['estado'],
          'createdAt': item['createdAt'],
          'updatedAt': item['updatedAt'],
        }).toList();
  }

  void _agregarPregunta() {
    setState(() {
      preguntas.add(Pregunta(
          pregunta: preguntaController.text,
          valores: observacionController.text));
      preguntaController.clear();
      observacionController.clear();
    });
  }

  void _eliminarPregunta(int index) {
    setState(() {
      preguntas.removeAt(index);
    });
  }

  void _guardarEncuesta(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {
      'titulo': data['nombre'],
      'idCliente': data['cliente'],
      'datos': data['preguntas'],
      'estado': "true",
    };

    try {
      final inspeccionAnualService = InspeccionAnualService();
      var response =
          await inspeccionAnualService.registrarInspeccionAnual(dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          returnPrincipalPage();
        });
        LogsInformativos(
            "Se ha registrado la inspección anual ${data['nombre']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "La inspección anual fue agregada correctamente",
          backgroundColor: Colors.green,
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        showCustomFlushbar(
          context: context,
          title: "Hubo un problema",
          message: "Hubo un error al agregar la inspección anual",
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

  void _publicarEncuesta() {
    var formData = {
      "nombre": nombreController.text,
      "cliente": clienteController.text,
      "preguntas": preguntas.map((pregunta) => pregunta.toJson()).toList(),
    };
    _guardarEncuesta(formData);
  }

  void returnPrincipalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InspeccionEspecialPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _formKey,
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Inspección anual"),
      body: loading
          ? Load()
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Inspección anual",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _publicarEncuesta,
                        icon: Icon(Icons.add),
                        label: _isLoading
                            ? SpinKitFadingCircle(
                                color: Colors.white, size: 24)
                            : Text("Guardar"),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: returnPrincipalPage,
                        icon: Icon(Icons.arrow_back),
                        label: _isLoading
                            ? SpinKitFadingCircle(
                                color: Colors.red, size: 24)
                            : Text("Regresar"),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: nombreController,
                            decoration: InputDecoration(labelText: "Nombre"),
                          ),
                          DropdownButtonFormField<String>(
                            value: clienteController.text.isEmpty
                                ? null
                                : clienteController.text,
                            decoration:
                                InputDecoration(labelText: 'Cliente'),
                            isExpanded: true,
                            items: dataClientes.map((tipo) {
                              return DropdownMenuItem<String>(
                                value: tipo['id'],
                                child: Text(tipo['nombre']),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                clienteController.text = newValue!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _agregarPregunta,
                    child: Text("Agregar Dato"),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: preguntaController,
                            decoration:
                                InputDecoration(labelText: "Pregunta"),
                          ),
                          TextField(
                            controller: observacionController,
                            decoration: InputDecoration(
                                labelText:
                                    "Valores (separados por coma)"),
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^[0-9,]*$')),
                            ],
                          ),
                          SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: preguntas.length,
                            itemBuilder: (context, index) {
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 5),
                                child: ListTile(
                                  title: Text(preguntas[index].pregunta),
                                  subtitle: Text(
                                      "Valores: ${preguntas[index].valores}\n"),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () =>
                                        _eliminarPregunta(index),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class Pregunta {
  String pregunta;
  String valores;

  Pregunta({required this.pregunta, required this.valores});

  Map<String, dynamic> toJson() {
    return {"pregunta": pregunta, "valores": valores};
  }
}
