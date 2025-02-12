import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter
import 'acciones.dart';
import '../Modal/BasicModal/basic_modal.dart';
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Editar tipo de extintor',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Acciones(
                showModal: widget.showModal,
                onCompleted: widget.onCompleted,
                accion: "editar",
                data: row,
              ),
            ),
          ),
        );
      },
    );
  }

  void openEliminarModal(row) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Eliminar tipo de extintor',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Acciones(
                showModal: widget.showModal,
                onCompleted: widget.onCompleted,
                accion: "eliminar",
                data: row,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Nombre'},
      {'name': 'Descripción'},
      {'name': 'Creado el'},
      {'name': 'Actualizado el'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Envolvemos el SizedBox dentro de Expanded
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.tiposExtintores.map((row) {
                return {
                  'Nombre': row['nombre'],
                  'Descripción': row['descripcion'],
                  'Creado el': formatDate(row['createdAt'] ?? ''),
                  'Actualizado el': formatDate(row['updatedAt'] ?? ''),
                  '_originalRow': row,
                };
              }).toList(),
              columnas: columnas,
              accionesBuilder: (row) {
                return Row(
                  children: [
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.pen, color: const Color.fromARGB(255, 6, 47, 214)),
                      onPressed: () =>
                        openEditarModal(row['_originalRow']),
                    ),
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                      onPressed: () =>
                        openEliminarModal(row['_originalRow']),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Modal
        if (showModal)
          BasicModal(
            show: showModal,
            setShow: (bool value) {
              setState(() {
                showModal = value;
              });
            },
            title: titulosModal ?? '',
            child: contentModal ?? Container(),
          ),
      ],
    );
  }
}
