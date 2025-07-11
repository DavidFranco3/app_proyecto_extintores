import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter
import 'acciones.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import '../Generales/formato_fecha.dart';
import 'lista_preguntas.dart';
import '../../page/CrearEncuestaPantalla1/crear_encuesta_pantalla_1.dart';

class TblEncuestas extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> encuestas;
  final Function onCompleted;

  TblEncuestas({
    Key? key,
    required this.showModal,
    required this.encuestas,
    required this.onCompleted,
  }) : super(key: key);

  @override
  _TblEncuestasState createState() => _TblEncuestasState();
}

class _TblEncuestasState extends State<TblEncuestas> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

  TextEditingController nombreController = TextEditingController();
  TextEditingController clasificacionController = TextEditingController();
  TextEditingController ramaController = TextEditingController();

  void openRegistroPage(row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEncuestaPantalla1Screen(
          showModal: () {
            Navigator.pop(context);
          },
          onCompleted: widget.onCompleted,
          accion: "editar",
          data: row,
          nombreController: nombreController,
          ramaController: ramaController,
          clasificacionController: clasificacionController,
        ),
      ),
    ).then((_) {
      widget.onCompleted;
    });
  }

  void openEliminarModal(row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: Acciones(
              showModal: () {
                Navigator.pop(context); // Cierra la página actual
              },
              onCompleted: widget.onCompleted,
              accion: "eliminar",
              data: row,
            ),
          );
        },
      ),
    );
  }

  void openViewPreguntas(row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: PreguntasVisualPage(
              showModal: () {
                Navigator.pop(context); // Eliminar la lógica de cerrar el modal
              },
              onCompleted: widget.onCompleted,
              accion: "eliminar",
              data: row,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Registro'},
      {'name': 'Nombre'},
      {'name': 'Periodo'},
      {'name': 'Clasificacion'},
      {'name': 'Tipo de Sistema'},
      {'name': 'Creado el'},
    ];

    int totalRegistros = widget.encuestas.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Envolvemos el SizedBox dentro de Expanded
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.encuestas.asMap().entries.map((entry) {
                int index = totalRegistros - entry.key;
                Map<String, dynamic> row = entry.value;
                return {
                  'Registro': index,
                  'Nombre': row['nombre'],
                  'Periodo': row['frecuencia'],
                  'Clasificacion': row['clasificacion'],
                  'Tipo de Sistema': row['rama'],
                  'Creado el': formatDate(row['createdAt'] ?? ''),
                  '_originalRow': row,
                };
              }).toList(),
              columnas: columnas,
              accionesBuilder: (row) {
                return PopupMenuButton<String>(
                  icon: FaIcon(FontAwesomeIcons.bars,
                      color: Color.fromARGB(255, 27, 40, 223)),
                  onSelected: (String value) {
                    if (value == 'eliminar') {
                      openEliminarModal(row['_originalRow']);
                    } else if (value == 'visualizar') {
                      openViewPreguntas(row['_originalRow']);
                    } else if (value == "editar") {
                      openRegistroPage(row['_originalRow']);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'editar',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.pen,
                              color: Color(0xFFFFC107), size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.trash,
                              color: Color(0xFFDC3545), size: 16),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'visualizar',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.eye,
                              color: Color.fromARGB(255, 88, 6, 211), size: 16),
                          SizedBox(width: 8),
                          Text('Ver preguntas'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
