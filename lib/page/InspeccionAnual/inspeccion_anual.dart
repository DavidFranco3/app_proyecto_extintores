import 'package:flutter/material.dart';
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
  InspeccionAnualPage(
      {required this.showModal,
      required this.onCompleted,
      required this.accion,
      required this.data});
  _InspeccionAnualPageState createState() => _InspeccionAnualPageState();
}

class _InspeccionAnualPageState extends State<InspeccionAnualPage> {
  final _formKey = GlobalKey<FormState>();
  List<Pregunta> preguntas = [];
  TextEditingController preguntaController = TextEditingController();
  TextEditingController observacionController = TextEditingController();
  TextEditingController nombreController = TextEditingController();
  TextEditingController clienteController = TextEditingController();
  List<String> opcionesTemp = ["Si", "No"];
  List<Map<String, dynamic>> dataClientes = [];
  bool loading = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getClientes();
  }

  Future<void> getClientes() async {
    try {
      final clientesService = ClientesService();
      final List<dynamic> response = await clientesService.listarClientes();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataClientes = formatModelClientes(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataClientes = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      print("Error al obtener los clientes: $e");
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
      });
    }
  }

  List<Map<String, dynamic>> formatModelClientes(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
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
      });
    }
    return dataTemp;
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
      // Verifica el statusCode correctamente, según cómo esté estructurada la respuesta
      if (response['status'] == 200) {
        // Asumiendo que 'response' es un Map que contiene el código de estado
        setState(() {
          _isLoading = false;
          returnPrincipalPage();
        });
        LogsInformativos(
            "Se ha registrado la inspeccion anual ${data['nombre']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "La inspeccion anual fue agregada correctamente",
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
          message: "Hubo un error al agregar la inspeccion anual",
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
    // Aquí podrías enviar la encuesta a Firebase o una API
  }

  String get buttonLabel {
    return 'Guardar inspeccion';
  }

  void returnPrincipalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InspeccionEspecialPage()),
    ).then((_) {
      // Actualizar encuestas al regresar de la página
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _formKey,
      appBar: Header(), // Usa el header con menú de usuario
      drawer:
          MenuLateral(currentPage: "Inspección anual"), // Usa el menú lateral
      body: loading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          "Inspeccion anual",
                          style: TextStyle(
                            fontSize: 24, // Tamaño grande
                            fontWeight: FontWeight.bold, // Negrita
                          ),
                        ),
                      ),
                    ),
                    // Botones centrados
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
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                        SizedBox(width: 16), // Espacio entre los botones
                        ElevatedButton.icon(
                          onPressed: returnPrincipalPage,
                          icon: Icon(Icons.arrow_back),
                          label: _isLoading
                              ? SpinKitFadingCircle(
                                  color: const Color.fromARGB(255, 241, 8, 8),
                                  size: 24)
                              : Text("Regresar"),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10),

                    // Sección General (Nombre, Frecuencia, Clasificación)
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Información General",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: nombreController,
                              decoration: InputDecoration(labelText: "Nombre"),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El nombre es obligatorio';
                                }
                                return null;
                              },
                            ),
                            DropdownButtonFormField<String>(
                              value: clienteController.text.isEmpty
                                  ? null
                                  : clienteController.text,
                              decoration: InputDecoration(labelText: 'Cliente'),
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
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'El cliente es obligatorio'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Botón de "Agregar Pregunta" centrado
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _agregarPregunta,
                          child: Text("Agregar Dato"),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Sección de Preguntas
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Datos",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            TextField(
                              controller: preguntaController,
                              decoration:
                                  InputDecoration(labelText: "Pregunta"),
                            ),
                            TextField(
                              controller: observacionController,
                              decoration: InputDecoration(
                                  labelText:
                                      "Valores (si es más de uno, separarlo con comas)"),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
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
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminarPregunta(index),
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
