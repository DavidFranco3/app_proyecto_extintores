import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter
import 'acciones.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import '../../page/CrearEncuesta/crearEncuesta.dart'; // Asegúrate de que el archivo correcto esté importado
import 'package:intl/intl.dart';

class TblEncuestas extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> encuestas;
  final Function onCompleted;

  TblEncuestas(
      {Key? key,
      required this.showModal,
      required this.encuestas,
      required this.onCompleted})
      : super(key: key);

  @override
  _TblEncuestasState createState() => _TblEncuestasState();
}

class _TblEncuestasState extends State<TblEncuestas> {
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

  void openEditarPage(row) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CrearEncuestaScreen(
              showModal: () {
                Navigator.pop(context); // Esto cierra el modal
              },
              onCompleted: widget.onCompleted,
              accion: "editar",
              data: row)),
    ).then((_) {
      widget.onCompleted(); // Actualizar encuestas al regresar de la página
    });
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
                  'Eliminar Encuesta',
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
              child: Column(
                children: [
                  // Aquí agregamos un widget GestureDetector para que cuando el usuario toque fuera del formulario, el teclado se cierre.
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context)
                          .unfocus(); // Cierra el teclado al tocar fuera
                    },
                    child: Acciones(
                      showModal: widget.showModal,
                      onCompleted: widget.onCompleted,
                      accion: "eliminar",
                      data: row,
                    ),
                  ),
                ],
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
      {'name': 'Frecuencia'},
      {'name': 'Clasificacion'},
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
              datos: widget.encuestas.map((row) {
                return {
                  'Nombre': row['nombre'],
                  'Frecuencia': row['frecuencia'],
                  'Clasificacion': row['clasificacion'],
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
                      icon: FaIcon(FontAwesomeIcons.pen,
                          color: const Color.fromARGB(255, 6, 47, 214)),
                      onPressed: () => openEditarPage(row['_originalRow']),
                    ),
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                      onPressed: () => openEliminarModal(row['_originalRow']),
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
