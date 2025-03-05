import 'package:flutter/material.dart';
import '../../api/frecuencias.dart';
import '../../api/clasificaciones.dart';
import '../../api/encuesta_inspeccion.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Logs/logs_informativos.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../Encuestas/encuestas.dart';

class CrearEncuestaScreen extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  @override
  CrearEncuestaScreen(
      {required this.showModal,
      required this.onCompleted,
      required this.accion,
      required this.data});

  _CrearEncuestaScreenState createState() => _CrearEncuestaScreenState();
}

class _CrearEncuestaScreenState extends State<CrearEncuestaScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Pregunta> preguntas = [];
  TextEditingController preguntaController = TextEditingController();
  TextEditingController observacionController = TextEditingController();
  TextEditingController nombreController = TextEditingController();
  TextEditingController frecuenciaController = TextEditingController();
  TextEditingController clasificacionController = TextEditingController();
  List<String> opcionesTemp = ["Si", "No"];
  List<Map<String, dynamic>> dataFrecuencias = [];
  List<Map<String, dynamic>> dataClasificaciones = [];
  bool loading = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getFrecuencias();
    getClasificaciones();
    List<Pregunta> preguntasss = (widget.data?["preguntas"] as List<dynamic>?)
            ?.map((pregunta) => Pregunta(
                  titulo: pregunta["titulo"] ?? "",
                  observaciones: pregunta["observaciones"] ?? "",
                  opciones: List<String>.from(pregunta["opciones"] ?? []),
                ))
            .toList() ??
        [];

    if (widget.accion == 'editar') {
      preguntas = preguntasss;
      nombreController.text = widget.data['nombre'] ?? '';
      frecuenciaController.text = widget.data['idFrecuencia'] ?? '';
      clasificacionController.text = widget.data['idClasificacion'] ?? '';
    }
  }

  Future<void> getClasificaciones() async {
    try {
      final clasificacionesService = ClasificacionesService();
      final List<dynamic> response =
          await clasificacionesService.listarClasificaciones();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataClasificaciones = formatModelClasificaciones(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataClasificaciones = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      print("Error al obtener las clasificaciones: $e");
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
      });
    }
  }

  // Función para formatear los datos de las clasificaciones
  List<Map<String, dynamic>> formatModelClasificaciones(List<dynamic> data) {
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

  Future<void> getFrecuencias() async {
    try {
      final frecuenciasService = FrecuenciasService();
      final List<dynamic> response =
          await frecuenciasService.listarFrecuencias();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataFrecuencias = formatModelFrecuencias(response);
          loading = false;
        });
      } else {
        setState(() {
          dataFrecuencias = [];
          loading = false;
        });
      }
    } catch (e) {
      print("Error al obtener las frecuencias: $e");
      setState(() {
        loading = false;
      });
    }
  }

  // Función para formatear los datos de las frecuencias
  List<Map<String, dynamic>> formatModelFrecuencias(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'cantidadDias': item['cantidadDias'],
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
          titulo: preguntaController.text,
          opciones: List.from(opcionesTemp),
          observaciones: observacionController.text));
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
      'nombre': data['nombre'],
      'idFrecuencia': data['idFrecuencia'],
      'idClasificacion': data['idClasificacion'],
      'preguntas': data['preguntas'],
      'estado': "true",
    };

    try {
      final encuestaInspeccionService = EncuestaInspeccionService();
      var response =
          await encuestaInspeccionService.registraEncuestaInspeccion(dataTemp);
      // Verifica el statusCode correctamente, según cómo esté estructurada la respuesta
      if (response['status'] == 200) {
        // Asumiendo que 'response' es un Map que contiene el código de estado
        setState(() {
          _isLoading = false;
        });
        LogsInformativos(
            "Se ha registrado la encuesta ${data['nombre']} correctamente",
            dataTemp);
        _showDialog(
            "Encuesta agregada correctamente", Icons.check, Colors.green);
      } else {
        // Maneja el caso en que el statusCode no sea 200
        setState(() {
          _isLoading = false;
        });
        _showDialog("Error al agregar la encuesta", Icons.error, Colors.red);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showDialog("Oops...", Icons.error, Colors.red,
          error.toString()); // Muestra el error de manera más explícita
    }
  }

  void _editarEncuesta(String id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {
      'nombre': data['nombre'],
      'idFrecuencia': data['idFrecuencia'],
      'idClasificacion': data['idClasificacion'],
      'preguntas': data['preguntas'],
    };

    try {
      final encuestaInspeccionService = EncuestaInspeccionService();
      var response = await encuestaInspeccionService
          .actualizarEncuestaInspeccion(id, dataTemp);
      // Verifica el statusCode correctamente, según cómo esté estructurada la respuesta
      if (response['status'] == 200) {
        // Asumiendo que 'response' es un Map que contiene el código de estado
        setState(() {
          _isLoading = false;
        });
        LogsInformativos(
            "Se ha actualizado la encuesta ${data['nombre']} correctamente",
            dataTemp);
        _showDialog(
            "Encuesta actualizada correctamente", Icons.check, Colors.green);
      } else {
        // Maneja el caso en que el statusCode no sea 200
        setState(() {
          _isLoading = false;
        });
        _showDialog("Error al actualizar la encuesta", Icons.error, Colors.red);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showDialog("Oops...", Icons.error, Colors.red,
          error.toString()); // Muestra el error de manera más explícita
    }
  }

  void _publicarEncuesta() {
    var formData = {
      "nombre": nombreController.text,
      "idFrecuencia": frecuenciaController.text,
      "idClasificacion": clasificacionController.text,
      "preguntas": preguntas.map((pregunta) => pregunta.toJson()).toList(),
    };
    if (widget.accion == "registrar") {
      _guardarEncuesta(formData);
    } else {
      _editarEncuesta(widget.data["id"], formData);
    }
    // Aquí podrías enviar la encuesta a Firebase o una API
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
                returnPrincipalPage();
              },
            ),
          ],
        );
      },
    );
  }

  String get buttonLabel {
    if (widget.accion == 'registrar') {
      return 'Guardar encuesta';
    } else {
      return 'Actualizar encuesta';
    }
  }

  void returnPrincipalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EncuestasPage()),
    ).then((_) {
      // Actualizar encuestas al regresar de la página
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _formKey,
      appBar: Header(), // Usa el header con menú de usuario
      drawer: MenuLateral(currentPage: "Crear Encuesta"), // Usa el menú lateral
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
                          "Encuestas",
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
                        ElevatedButton(
                          onPressed: _isLoading ? null : _publicarEncuesta,
                          child: _isLoading
                              ? SpinKitFadingCircle(
                                  color: Colors.white, size: 24)
                              : Text(buttonLabel),
                        ),
                        ElevatedButton(
                          onPressed: returnPrincipalPage,
                          child: _isLoading
                              ? SpinKitFadingCircle(
                                  color: const Color.fromARGB(255, 241, 8, 8),
                                  size: 24)
                              : Text("Cancelar"),
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
                              value: frecuenciaController.text.isEmpty
                                  ? null
                                  : frecuenciaController.text,
                              decoration:
                                  InputDecoration(labelText: 'Frecuencia'),
                              isExpanded: true,
                              items: dataFrecuencias.map((tipo) {
                                return DropdownMenuItem<String>(
                                  value: tipo['id'],
                                  child: Text(tipo['nombre']),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  frecuenciaController.text = newValue!;
                                });
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'La frecuencia es obligatoria'
                                      : null,
                            ),
                            DropdownButtonFormField<String>(
                              value: clasificacionController.text.isEmpty
                                  ? null
                                  : clasificacionController.text,
                              decoration:
                                  InputDecoration(labelText: 'Clasificación'),
                              isExpanded: true,
                              items: dataClasificaciones.map((tipo) {
                                return DropdownMenuItem<String>(
                                  value: tipo['id'],
                                  child: Text(tipo['nombre']),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  clasificacionController.text = newValue!;
                                });
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'La clasificación es obligatoria'
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
                          child: Text("Agregar Pregunta"),
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
                            Text("Preguntas",
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
                              decoration:
                                  InputDecoration(labelText: "Observaciones"),
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
                                    title: Text(preguntas[index].titulo),
                                    subtitle: Text(
                                      "Observaciones: ${preguntas[index].observaciones}\n"
                                      "Opciones: ${preguntas[index].opciones.join(", ")}",
                                    ),
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
  String titulo;
  String observaciones;
  List<String> opciones;

  Pregunta(
      {required this.titulo,
      required this.observaciones,
      required this.opciones});

  Map<String, dynamic> toJson() {
    return {
      "titulo": titulo,
      "observaciones": observaciones,
      "opciones": opciones,
    };
  }
}
