import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/inspecciones_proximas.dart';
import '../../components/InspeccionesProximas/list_inspecciones_proximas.dart';
import '../LlenarEncuesta/llenar_encuesta.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class InspeccionesProximasPage extends StatefulWidget {
  @override
  _InspeccionesProximasPageState createState() => _InspeccionesProximasPageState();
}

class _InspeccionesProximasPageState extends State<InspeccionesProximasPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspeccionesProximas = [];

  @override
  void initState() {
    super.initState();
    getInspeccionesProximas();
  }

  Future<void> getInspeccionesProximas() async {
    try {
      final inspeccionesProximasService = InspeccionesProximasService();
      final List<dynamic> response =
          await inspeccionesProximasService.listarInspeccionesProximas();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataInspeccionesProximas = formatModelInspeccionesProximas(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataInspeccionesProximas = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      print("Error al obtener las inspeccionesProximas: $e");
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
              onCompleted: getInspeccionesProximas,
              accion: "registrar",
              data: null)),
    ).then((_) {
      getInspeccionesProximas(); // Actualizar inspeccionesProximas al regresar de la página
    });
  }

// Cierra el modal
  void closeModal() {
    setState(() {
      showModal = false; // Cierra el modal
    });
  }

  // Función para formatear los datos de las inspeccionesProximas
  List<Map<String, dynamic>> formatModelInspeccionesProximas(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'idFrecuencia': item['idFrecuencia'],
        'idEncuesta': item['idEncuesta'],
        'cuestionario': item['cuestionario']['nombre'],
        'frecuencia': item['frecuencia']['nombre'],
        'proximaInspeccion': item['nuevaInspeccion'],
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
      drawer: MenuLateral(currentPage: "InspeccionesProximas"), // Usa el menú lateral
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
                      "Inspecciones Proximas",
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
                  child: TblInspeccionesProximas(
                    showModal: () {
                      Navigator.pop(context); // Esto cierra el modal
                    },
                    inspeccionesProximas: dataInspeccionesProximas,
                    onCompleted: getInspeccionesProximas,
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
