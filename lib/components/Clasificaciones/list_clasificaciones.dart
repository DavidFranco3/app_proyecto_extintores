import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter
import './acciones.dart';
import '../Modal/BasicModal/basic_modal.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import 'package:intl/intl.dart';

class TblClasificaciones extends StatefulWidget {
  final List<Map<String, dynamic>> clasificaciones;

  TblClasificaciones({Key? key, required this.clasificaciones})
      : super(key: key);

  @override
  _TblClasificacionesState createState() => _TblClasificacionesState();
}

class _TblClasificacionesState extends State<TblClasificaciones> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

  // Para mostrar el modal de edición
  void editarClasificacion(Widget content) {
    setState(() {
      titulosModal = "Editar clasificacion";
      contentModal = content;
      showModal = true;
    });
  }

  // Para mostrar el modal de eliminación
  void eliminarClasificacion(Widget content) {
    setState(() {
      titulosModal = "Eliminar clasificacion";
      contentModal = content;
      showModal = true;
    });
  }

  // Función para formatear fechas
  String formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year} ${parsedDate.hour}:${parsedDate.minute}:${parsedDate.second}';
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Nombre'},
      {'name': 'Descripción'},
      {'name': 'Creado el'},
      {'name': 'Actualizado el'},
      {'name': 'Acciones'}
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Envolvemos el SizedBox dentro de Expanded
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.clasificaciones.map((row) {
                return {
                  'Nombre': row['nombre'],
                  'Descripción': row['descripcion'],
                  'Creado el': row['createdAt'] ?? '',
                  'Actualizado el': row['updatedAt'] ?? '',
                  'Acciones': (row) => Row(
                        children: [
                          IconButton(
                            icon: FaIcon(FontAwesomeIcons.pen,
                                color: Colors.amber),
                            onPressed: () {
                              editarClasificacion(
                                Acciones(
                                  showModal: () {
                                    Navigator.pop(
                                        context); // Esto cierra el modal
                                  },
                                  accion: 'editar',
                                  data: row,
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: FaIcon(FontAwesomeIcons.trash,
                                color: Colors.red),
                            onPressed: () {
                              eliminarClasificacion(
                                Acciones(
                                  showModal: () {
                                    Navigator.pop(
                                        context); // Esto cierra el modal
                                  },
                                  accion: 'eliminar',
                                  data: row,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                };
              }).toList(),
              columnas: columnas,
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
