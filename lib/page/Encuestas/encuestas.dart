import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/encuesta_inspeccion.dart';
import '../../components/Encuestas/list_encuestas.dart';
import '../CrearEncuesta/crearEncuesta.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class EncuestasPage extends StatefulWidget {
  @override
  _EncuestasPageState createState() => _EncuestasPageState();
}

class _EncuestasPageState extends State<EncuestasPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataEncuestas = [];

  @override
  void initState() {
    super.initState();
    getEncuestas();
  }

  Future<void> getEncuestas() async {
    try {
      final encuestaInspeccionService = EncuestaInspeccionService();
      final List<dynamic> response =
          await encuestaInspeccionService.listarEncuestaInspeccion();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataEncuestas = formatModelEncuestas(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataEncuestas = []; // Lista vacía
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

  bool showModal = false; // Estado que maneja la visibilidad del modal

  // Función para abrir el modal de registro con el formulario de Acciones
  void openRegistroPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CrearEncuestaScreen(
              showModal: () {
                Navigator.pop(context); // Esto cierra el modal
              },
              onCompleted: getEncuestas,
              accion: "registrar",
              data: null)),
    ).then((_) {
      getEncuestas(); // Actualizar encuestas al regresar de la página
    });
  }

// Cierra el modal
  void closeModal() {
    setState(() {
      showModal = false; // Cierra el modal
    });
  }

  // Función para formatear los datos de las encuestas
  List<Map<String, dynamic>> formatModelEncuestas(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'idFrecuencia': item['idFrecuencia'],
        'idClasificacion': item['idClasificacion'],
        'frecuencia': item['frecuencia']['nombre'],
        'clasificacion': item['clasificacion']['nombre'],
        'preguntas': item['preguntas'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(), // Usa el header con menú de usuario
      drawer: MenuLateral(currentPage: "Encuestas"), // Usa el menú lateral
      body: loading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Centra el encabezado
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
                // Centra el botón de registrar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed:
                          openRegistroPage, // Abre el modal con el formulario de acciones
                      icon: Icon(FontAwesomeIcons.plus),
                      label: Text("Registrar"),
                    ),
                  ),
                ),
                Expanded(
                  child: TblEncuestas(
                    showModal: () {
                      Navigator.pop(context); // Esto cierra el modal
                    },
                    encuestas: dataEncuestas,
                    onCompleted: getEncuestas,
                  ),
                ),
              ],
            ),
      // Modal: Se muestra solo si `showModal` es true
      floatingActionButton: showModal
          ? FloatingActionButton(
              onPressed: closeModal, // Cierra el modal
              child: Icon(Icons.close),
            )
          : null,
    );
  }
}

class Pregunta {
  String titulo;
  String observaciones;
  List<String> opciones;

  Pregunta({
    required this.titulo,
    required this.observaciones,
    required this.opciones,
  });

  Map<String, dynamic> toJson() {
    return {
      "titulo": titulo,
      "observaciones": observaciones,
      "opciones": opciones,
    };
  }

  factory Pregunta.fromJson(Map<String, dynamic> json) {
    return Pregunta(
      titulo: json['titulo'] ?? '',
      observaciones: json['observaciones'] ?? '',
      opciones: List<String>.from(json['opciones'] ?? []),
    );
  }
}
