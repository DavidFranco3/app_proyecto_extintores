import 'package:flutter/material.dart';
import '../../api/frecuencias.dart';
import '../../api/clasificaciones.dart';
import '../../api/ramas.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../Encuestas/encuestas.dart';
import '../CrearEncuestaPantalla2/crear_encuesta_pantalla_2.dart';
import '../../components/Generales/pregunta.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CrearEncuestaPantalla1Screen extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;
  final TextEditingController nombreController;
  final TextEditingController clasificacionController;
  final TextEditingController ramaController;

  @override
  CrearEncuestaPantalla1Screen(
      {required this.showModal,
      required this.onCompleted,
      required this.accion,
      required this.data,
      required this.nombreController,
      required this.clasificacionController,
      required this.ramaController});

  _CrearEncuestaPantalla1ScreenState createState() =>
      _CrearEncuestaPantalla1ScreenState();
}

class _CrearEncuestaPantalla1ScreenState
    extends State<CrearEncuestaPantalla1Screen> {
  final _formKey = GlobalKey<FormState>();
  List<Pregunta> preguntas = [];
  TextEditingController frecuenciaController = TextEditingController();
  List<String> opcionesTemp = ["Si", "No"];
  List<Map<String, dynamic>> dataFrecuencias = [];
  List<Map<String, dynamic>> dataClasificaciones = [];
  List<Map<String, dynamic>> dataRamas = [];
  bool loading = true;
  bool _isLoading = false;
  final List<Map<String, String>> secciones = [];

  @override
  void initState() {
    super.initState();
    getFrecuencias();
    getClasificaciones();
    getRamas();
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

  void returnPrincipalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EncuestasPage()),
    ).then((_) {
      // Actualizar encuestas al regresar de la página
    });
  }

  // Función para abrir el modal de registro con el formulario de Acciones
  void openPantalla2Page(Map<String, dynamic> row) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CrearEncuestaPantalla2Screen(
              showModal: () {
                Navigator.pop(context); // Esto cierra el modal
              },
              accion: "registrar",
              data: row,
              nombreController: widget.nombreController,
              ramaController: widget.ramaController,
              clasificacionController: widget.clasificacionController,
              secciones: secciones,
              preguntas: preguntas,
              onCompleted: widget.onCompleted)),
    ).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _formKey,
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Crear Inspeccion"),
      body: loading
          ? Load()
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: returnPrincipalPage,
                          icon: Icon(FontAwesomeIcons
                              .arrowLeft), // Ícono de flecha hacia la izquierda
                          label: _isLoading
                              ? SpinKitFadingCircle(
                                  color: const Color.fromARGB(255, 241, 8, 8),
                                  size: 24,
                                )
                              : Text("Regresar"),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: widget.nombreController,
                              decoration: InputDecoration(labelText: "Nombre"),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El nombre es obligatorio';
                                }
                                return null;
                              },
                            ),
                            DropdownButtonFormField<String>(
                              value: widget.ramaController.text.isEmpty
                                  ? null
                                  : widget.ramaController.text,
                              decoration: InputDecoration(labelText: 'Rama'),
                              isExpanded: true,
                              items: dataRamas.map((tipo) {
                                return DropdownMenuItem<String>(
                                  value: tipo['id'],
                                  child: Text(tipo['nombre']),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  widget.ramaController.text = newValue!;
                                });
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'La rama es obligatoria'
                                      : null,
                            ),
                            DropdownButtonFormField<String>(
                              value: widget.clasificacionController.text.isEmpty
                                  ? null
                                  : widget.clasificacionController.text,
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
                                  widget.clasificacionController.text = newValue!;
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
                    // Agregar un botón por cada elemento de dataFrecuencias
                    // Agregar un botón por cada elemento de dataFrecuencias
                    SizedBox(height: 10),
                    Column(
                      children: dataFrecuencias.map((frecuencia) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0), // Espaciado entre botones
                          child: SizedBox(
                            width: double
                                .infinity, // Hace que el botón ocupe todo el ancho disponible
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      10), // Bordes redondeados
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical:
                                        16), // Aumenta el tamaño vertical del botón
                              ),
                              onPressed: () => {
                                openPantalla2Page(frecuencia)
                                // Acción que deseas realizar cuando se presiona el botón
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Centra el contenido dentro del Row
                                children: [
                                  Expanded(
                                    child: Text(frecuencia['nombre'],
                                        textAlign:
                                            TextAlign.center, // Centra el texto
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors
                                              .black, // ), // Tamaño de texto
                                        )),
                                  ),
                                  Icon(
                                    Icons
                                        .chevron_right, // Icono que aparece a la derecha
                                    size: 24, // Tamaño del ícono
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
