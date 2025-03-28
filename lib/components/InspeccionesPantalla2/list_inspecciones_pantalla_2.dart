import 'package:flutter/material.dart';
import '../Generales/list_view.dart';
import 'package:intl/intl.dart';
import '../../page/Inspecciones/inspecciones.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter

class TblInspeccionesPantalla2 extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> inspecciones;
  final Function onCompleted;
  final dynamic data;

  TblInspeccionesPantalla2(
      {Key? key,
      required this.showModal,
      required this.inspecciones,
      required this.onCompleted,
      required this.data})
      : super(key: key);

  @override
  _TblInspeccionesPantalla2State createState() =>
      _TblInspeccionesPantalla2State();
}

class _TblInspeccionesPantalla2State extends State<TblInspeccionesPantalla2> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;
  bool isLoading = false;

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

  // Función para abrir el modal de registro con el formulario de Acciones
  void openPantalla2Page(Map<String, dynamic> row) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => InspeccionesPage(
              showModal: () {
                Navigator.pop(context); // Esto cierra el modal
              },
              data: row,
              data2: widget.data)),
    ).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Periodo'},
      {'name': 'Creado el'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Envolvemos el SizedBox dentro de Expanded
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.inspecciones.asMap().entries.map((entry) {
                Map<String, dynamic> row = entry.value;
                return {
                  'Registro': row['index'],
                  'Periodo': row['frecuencia'],
                  'Creado el': formatDate(row['createdAt'] ?? ''),
                  '_originalRow': row,
                };
              }).toList(),
              columnas: columnas,
              accionesBuilder: (row) {
                return Row(
                  children: [
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.chevronRight,
                          color: const Color.fromARGB(255, 6, 47, 214)),
                      onPressed: () => openPantalla2Page(row['_originalRow']),
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
