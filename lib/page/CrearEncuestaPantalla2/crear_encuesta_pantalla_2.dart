import 'package:flutter/material.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../CrearEncuesta/crear_encuesta.dart';
import '../CrearEncuestaPantalla1/crear_encuesta_pantalla_1.dart';
import '../../components/Generales/pregunta.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../components/Generales/flushbar_helper.dart';
import '../../components/Logs/logs_informativos.dart';
import '../../api/encuesta_inspeccion.dart';

class CrearEncuestaPantalla2Screen extends StatefulWidget {
  final VoidCallback showModal;
  //final Function onCompleted;
  final String accion;
  final dynamic data;
  final TextEditingController nombreController;
  final TextEditingController clasificacionController;
  final TextEditingController ramaController;
  final List<Map<String, String>> secciones;
  final List<Pregunta> preguntas;
  final Function onCompleted;

  @override
  CrearEncuestaPantalla2Screen(
      {required this.showModal,
      //required this.onCompleted,
      required this.accion,
      required this.data,
      required this.nombreController,
      required this.clasificacionController,
      required this.ramaController,
      required this.secciones,
      required this.preguntas,
      required this.onCompleted});

  _CrearEncuestaPantalla2ScreenState createState() =>
      _CrearEncuestaPantalla2ScreenState();
}

class _CrearEncuestaPantalla2ScreenState
    extends State<CrearEncuestaPantalla2Screen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nombreSeccionController = TextEditingController();
  bool loading = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    loading = false;
  }

  // Función para abrir el modal de registro con el formulario de Acciones
  void openPantalla2Page(String seccion, List<Map<String, String>> secciones) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CrearEncuestaScreen(
              showModal: () {
                Navigator.pop(context); // Esto cierra el modal
              },
              accion: "registrar",
              data: widget.data,
              nombreController: widget.nombreController,
              ramaController: widget.ramaController,
              clasificacionController: widget.clasificacionController,
              categoria: seccion,
              secciones: secciones,
              onCompleted: widget.onCompleted,
              preguntas: widget.preguntas)),
    ).then((_) {});
  }

  // Función para abrir el formulario de creación de sección
  void _crearSeccion() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Crear Sección"),
          content: TextField(
            controller: nombreSeccionController,
            decoration: InputDecoration(labelText: "Nombre de la Sección"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo sin guardar
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                // Guardamos la nueva sección
                setState(() {
                  widget.secciones
                      .add({"nombre": nombreSeccionController.text});
                });
                nombreSeccionController.clear();
                Navigator.of(context)
                    .pop(); // Cerrar el diálogo después de guardar
              },
              child: Text("Guardar"),
            ),
          ],
        );
      },
    );
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

  void _publicarEncuesta() {
    var formData = {
      "nombre": widget.nombreController.text,
      "idFrecuencia": widget.data["id"],
      "idClasificacion": widget.clasificacionController.text,
      "idRama": widget.ramaController.text,
      "preguntas":
          widget.preguntas.map((pregunta) => pregunta.toJson()).toList(),
    };
    if (widget.accion == "registrar") {
      _guardarEncuesta(formData);
    }
    // Aquí podrías enviar la encuesta a Firebase o una API
  }

  // Función para regresar a la página principal
  void returnPrincipalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CrearEncuestaPantalla1Screen(
                showModal: widget.showModal,
                onCompleted: widget.onCompleted,
                accion: widget.accion,
                data: widget.data,
                nombreController: widget.nombreController,
                ramaController: widget.ramaController,
                clasificacionController: widget.clasificacionController,
              )),
    ).then((_) {
      // Actualizar encuestas al regresar de la página
    });
  }

  String get buttonLabel {
    if (widget.accion == 'registrar') {
      return 'Guardar';
    } else {
      return 'Actualizar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _formKey,
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Crear inspección"),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Crear inspección",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Inspección ${widget.data["nombre"]}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _crearSeccion,
                              icon: Icon(FontAwesomeIcons.plus),
                              label: Text("Crear Sección"),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: returnPrincipalPage,
                              icon: Icon(FontAwesomeIcons.arrowLeft),
                              label: _isLoading
                                  ? SpinKitFadingCircle(
                                      color:
                                          const Color.fromARGB(255, 241, 8, 8),
                                      size: 24,
                                    )
                                  : Text("Regresar"),
                            ),
                          ],
                        ),
                        SizedBox(height: 20), // Espacio entre filas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _publicarEncuesta,
                              icon: Icon(FontAwesomeIcons.plus),
                              label: _isLoading
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SpinKitFadingCircle(
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        SizedBox(width: 8),
                                        Text("Cargando..."),
                                      ],
                                    )
                                  : Text(buttonLabel),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Mostrar los botones de las secciones creadas
                    Column(
                      children: widget.secciones.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, String> seccion = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 8), // Reducir el alto del botón
                              ),
                              onPressed: () => {
                                // Acción cuando se presiona el botón de la sección
                                openPantalla2Page(
                                    seccion["nombre"]!, widget.secciones)
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      seccion['nombre'] ?? "",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 24,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      // Primero, eliminamos las preguntas asociadas a la categoría eliminada
                                      setState(() {
                                        // Eliminar las preguntas que pertenezcan a la categoría que estamos eliminando
                                        widget.preguntas.removeWhere(
                                            (pregunta) =>
                                                pregunta.categoria ==
                                                seccion["nombre"]);

                                        // Luego, eliminamos la sección
                                        widget.secciones.removeAt(index);
                                      });
                                    },
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
