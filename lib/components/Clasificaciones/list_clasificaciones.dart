import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter
import './acciones.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import '../Generales/formato_fecha.dart';

class TblClasificaciones extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> clasificaciones;
  final Function onCompleted;

  TblClasificaciones(
      {Key? key,
      required this.showModal,
      required this.clasificaciones,
      required this.onCompleted})
      : super(key: key);

  @override
  _TblClasificacionesState createState() => _TblClasificacionesState();
}

class _TblClasificacionesState extends State<TblClasificaciones> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

  void openEliminarModal(row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: Acciones(
              showModal: widget.showModal,
              onCompleted: widget.onCompleted,
              accion: "eliminar",
              data: row,
            ),
          );
        },
      ),
    );
  }

  void openEditarModal(row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: Acciones(
              showModal: widget.showModal,
              onCompleted: widget.onCompleted,
              accion: "editar",
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
      {'name': 'Descripción'},
      {'name': 'Creado el'},
    ];

    int totalRegistros = widget.clasificaciones.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.clasificaciones.asMap().entries.map((entry) {
                int index = totalRegistros -
                    entry.key; // Restamos al total para invertir el conteo
                Map<String, dynamic> row = entry.value;
                return {
                  'Registro': index,
                  'Nombre': row['nombre'],
                  'Descripción': row['descripcion'],
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
                    if (value == 'editar') {
                      openEditarModal(row['_originalRow']);
                    } else if (value == 'eliminar') {
                      openEliminarModal(row['_originalRow']);
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
