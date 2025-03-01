import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/inspecciones.dart';
import '../../components/Inspecciones/list_inspecciones.dart';
import '../LlenarEncuesta/llenar_encuesta.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class InspeccionesPage extends StatefulWidget {
  @override
  _InspeccionesPageState createState() => _InspeccionesPageState();
}

class _InspeccionesPageState extends State<InspeccionesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspecciones = [];

  @override
  void initState() {
    super.initState();
    getInspecciones();
  }

  Future<void> getInspecciones() async {
    try {
      final inspeccionesService = InspeccionesService();
      final List<dynamic> response =
          await inspeccionesService.listarInspecciones();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataInspecciones = formatModelInspecciones(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataInspecciones = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      print("Error al obtener las inspecciones: $e");
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
          builder: (context) => EncuestaPage(
              showModal: () {
                Navigator.pop(context); // Esto cierra el modal
              },
              onCompleted: getInspecciones,
              accion: "registrar",
              data: null)),
    ).then((_) {
      getInspecciones(); // Actualizar inspecciones al regresar de la página
    });
  }

// Cierra el modal
  void closeModal() {
    setState(() {
      showModal = false; // Cierra el modal
    });
  }

  // Función para formatear los datos de las inspecciones
  List<Map<String, dynamic>> formatModelInspecciones(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'idUsuario': item['idUsuario'],
        'idCliente': item['idCliente'],
        'idEncuesta': item['idEncuesta'],
        'encuesta': item['encuesta'],
        'imagenes': item['imagenes'],
        'comentarios': item['comentarios'],
        'usuario': item['usuario']['nombre'],
        'cliente': item['cliente']['nombre'],
        'cuestionario': item['cuestionario']['nombre'],
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
      drawer: MenuLateral(currentPage: "Inspección"), // Usa el menú lateral
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
                      "Inspecciones",
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
                  child: TblInspecciones(
                    showModal: () {
                      Navigator.pop(context); // Esto cierra el modal
                    },
                    inspecciones: dataInspecciones,
                    onCompleted: getInspecciones,
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
