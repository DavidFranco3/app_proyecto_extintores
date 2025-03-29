import 'package:flutter/material.dart';
import '../../api/frecuencias.dart';
import '../../api/clasificaciones.dart';
import '../../api/ramas.dart';
import '../../api/encuesta_inspeccion.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Logs/logs_informativos.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../components/Generales/flushbar_helper.dart';
import '../CrearEncuestaPantalla2/crear_encuesta_pantalla_2.dart';
import '../../components/Generales/pregunta.dart';

class CrearEncuestaScreen extends StatefulWidget {
  final VoidCallback showModal;
  final String accion;
  final dynamic data;
  final String nombre;
  final String rama;
  final String clasificacion;
  final String categoria;
  final List<Map<String, String>> secciones;
  final Function onCompleted;

  @override
  CrearEncuestaScreen({
    required this.showModal,
    required this.accion,
    required this.data,
    required this.nombre,
    required this.rama,
    required this.clasificacion,
    required this.categoria,
    required this.secciones,
    required this.onCompleted,
  });

  _CrearEncuestaScreenState createState() => _CrearEncuestaScreenState();
}

class _CrearEncuestaScreenState extends State<CrearEncuestaScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Pregunta> preguntas = [];
  TextEditingController preguntaController = TextEditingController();
  TextEditingController categoriaController = TextEditingController();
  TextEditingController nombreController = TextEditingController();
  TextEditingController frecuenciaController = TextEditingController();
  TextEditingController ramaController = TextEditingController();
  TextEditingController clasificacionController = TextEditingController();
  List<String> opcionesTemp = ["Si", "No"];
  List<Map<String, dynamic>> dataFrecuencias = [];
  List<Map<String, dynamic>> dataClasificaciones = [];
  List<Map<String, dynamic>> dataRamas = [];
  bool loading = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getFrecuencias();
    getClasificaciones();
    getRamas();
    List<Pregunta> preguntasss = (widget.data?["preguntas"] as List<dynamic>?)
            ?.map((pregunta) => Pregunta(
                  titulo: pregunta["titulo"] ?? "",
                  categoria: pregunta["categoria"] ?? "",
                  opciones: List<String>.from(pregunta["opciones"] ?? []),
                ))
            .toList() ??
        [];

    if (widget.accion == 'editar') {
      preguntas = preguntasss;
      nombreController.text = widget.data['nombre'] ?? '';
      frecuenciaController.text = widget.data['idFrecuencia'] ?? '';
      ramaController.text = widget.data['idRama'] ?? '';
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
      print("Error al obtener las encuestas: $e");
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

  Future<void> getRamas() async {
    try {
      final ramasService = RamasService();
      final List<dynamic> response = await ramasService.listarRamas();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataRamas = formatModelRamas(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataRamas = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      print("Error al obtener las ramas: $e");
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
      });
    }
  }

  // Función para formatear los datos de las clasificaciones
  List<Map<String, dynamic>> formatModelRamas(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
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
          categoria: widget.categoria,
          opciones: List.from(opcionesTemp)));
      preguntaController.clear();
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
      'idRama': data['idRama'],
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
          returnPrincipalPage();
        });
        LogsInformativos(
            "Se ha registrado la encuesta ${data['nombre']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "La encuesta fue agregada correctamente",
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
          message: "Hubo un error al agregar la encuesta",
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

  void _editarEncuesta(String id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {
      'nombre': data['nombre'],
      'idFrecuencia': data['idFrecuencia'],
      'idRama': data['idRama'],
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
          returnPrincipalPage();
        });
        LogsInformativos(
            "Se ha actualizado la encuesta ${data['nombre']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Actualizacion exitosa",
          message: "Los datos de la encuesta fueron actualizados correctamente",
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
          message: "Hubo un error al actualizar la encuesta",
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
      "nombre": widget.nombre,
      "idFrecuencia": widget.data["id"],
      "idClasificacion": widget.clasificacion,
      "idRama": widget.rama,
      "preguntas": preguntas.map((pregunta) => pregunta.toJson()).toList(),
    };
    if (widget.accion == "registrar") {
      _guardarEncuesta(formData);
    } else {
      _editarEncuesta(widget.data["id"], formData);
    }
    // Aquí podrías enviar la encuesta a Firebase o una API
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
      MaterialPageRoute(
          builder: (context) => CrearEncuestaPantalla2Screen(
              showModal: widget.showModal,
              //final Function onCompleted;
              accion: widget.accion,
              data: widget.data,
              nombre: widget.nombre,
              rama: widget.rama,
              clasificacion: widget.clasificacion,
              secciones: widget.secciones,
              preguntas: preguntas,
              onCompleted: widget.onCompleted)),
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
          MenuLateral(currentPage: "Crear Inspeccion"), // Usa el menú lateral
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
                          "Crear Inspeccion",
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
                                      "Categoria: ${preguntas[index].categoria}\n"
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
