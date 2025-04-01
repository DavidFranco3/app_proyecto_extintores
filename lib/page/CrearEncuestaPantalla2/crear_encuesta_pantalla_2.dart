import 'package:flutter/material.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../Encuestas/encuestas.dart';
import '../CrearEncuesta/crear_encuesta.dart';
import '../../components/Generales/pregunta.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CrearEncuestaPantalla2Screen extends StatefulWidget {
  final VoidCallback showModal;
  //final Function onCompleted;
  final String accion;
  final dynamic data;
  final String nombre;
  final String rama;
  final String clasificacion;
  final List<Map<String, String>> secciones;
  final List<Pregunta> preguntas;
  final Function onCompleted;

  @override
  CrearEncuestaPantalla2Screen(
      {required this.showModal,
      //required this.onCompleted,
      required this.accion,
      required this.data,
      required this.nombre,
      required this.rama,
      required this.clasificacion,
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
              nombre: widget.nombre,
              rama: widget.rama,
              clasificacion: widget.clasificacion,
              categoria: seccion,
              secciones: secciones,
              onCompleted: widget.onCompleted)),
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

  // Función para regresar a la página principal
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
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Crear Inspección"),
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
                              "Crear Inspección",
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              _crearSeccion, // Abrir el formulario para crear sección
                          icon: Icon(FontAwesomeIcons.plus), // Ícono de +
                          label: Text("Crear Sección"), // Texto normal
                        ),
                        SizedBox(width: 10), // Espacio entre los botones
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
                                      setState(() {
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
