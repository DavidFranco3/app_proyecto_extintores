import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter
import 'acciones.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import 'package:intl/intl.dart';

class TblTiposExtintores extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> tiposExtintores;
  final Function onCompleted;

  TblTiposExtintores(
      {Key? key,
      required this.showModal,
      required this.tiposExtintores,
      required this.onCompleted})
      : super(key: key);

  @override
  _TblTiposExtintoresState createState() => _TblTiposExtintoresState();
}

class _TblTiposExtintoresState extends State<TblTiposExtintores> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

  // Función para formatear fechas
  String formatDate(String date) {
    // Parseamos la fecha guardada en la base de datos
    final parsedDate = DateTime.parse(date);

    // Convertimos la fecha a la hora local
    final localDate = parsedDate.toLocal();

    // Ahora formateamos la fecha en formato de 12 horas (con AM/PM)
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm:ss a'); // Formato 12 horas
    return dateFormat.format(localDate);
  }

  void openEditarModal(row) {
    // Navegar a la página de edición en lugar de mostrar un modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Acciones(
          showModal: () {
            Navigator.pop(context); // Cierra la pantalla
          },
          onCompleted: widget.onCompleted,
          accion: "editar",
          data: row,
        ),
      ),
    );
  }

  void openEliminarModal(row) {
    // Navegar a la página de eliminación en lugar de mostrar un modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Acciones(
          showModal: () {
            Navigator.pop(context); // Cierra la pantalla
          },
          onCompleted: widget.onCompleted,
          accion: "eliminar",
          data: row,
        ),
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

    int totalRegistros = widget.tiposExtintores.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Envolvemos el SizedBox dentro de Expanded
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.tiposExtintores.asMap().entries.map((entry) {
                int index = totalRegistros - entry.key;
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
                      color: Color.fromARGB(255, 27, 40,
                          223)), // Este es el botón faBars que muestra el menú
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
