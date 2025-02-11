import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter
import 'acciones.dart';
import '../Modal/BasicModal/basic_modal.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import 'package:intl/intl.dart';

class TblFrecuencias extends StatefulWidget {
  final List<Map<String, dynamic>> frecuencias;
  final Function onCompleted;

  TblFrecuencias({Key? key, required this.frecuencias, required this.onCompleted}) : super(key: key);

  @override
  _TblFrecuenciasState createState() => _TblFrecuenciasState();
}

class _TblFrecuenciasState extends State<TblFrecuencias> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

  // Para mostrar el modal de edición
  void editarFrecuencia(Widget content) {
    setState(() {
      titulosModal = "Editar frecuencia";
      contentModal = content;
      showModal = true;
    });
  }

  // Para mostrar el modal de eliminación
  void eliminarFrecuencia(Widget content) {
    setState(() {
      titulosModal = "Eliminar frecuencia";
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
      {'name': 'Dias de duracion'},
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
              datos: widget.frecuencias.map((row) {
                return {
                  'Nombre': row['nombre'],
                  'Dias de duracion': row['cantidadDias'],
                  'Creado el': row['createdAt'] ?? '',
                  'Actualizado el': row['updatedAt'] ?? '',
                  'Acciones': (row) => Row(
                        children: [
                          IconButton(
                            icon: FaIcon(FontAwesomeIcons.pen,
                                color: Colors.amber),
                            onPressed: () {
                              editarFrecuencia(
                                Acciones(
                                  showModal: () {
                                    Navigator.pop(
                                        context); // Esto cierra el modal
                                  },
                                  onCompleted: widget.onCompleted,
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
                              eliminarFrecuencia(
                                Acciones(
                                  showModal: () {
                                    Navigator.pop(
                                        context); // Esto cierra el modal
                                  },
                                  onCompleted: widget.onCompleted,
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
