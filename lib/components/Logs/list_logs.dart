import 'package:flutter/material.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import 'package:intl/intl.dart';

class TblLogs extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> logs;
  final Function onCompleted;

  TblLogs(
      {Key? key,
      required this.showModal,
      required this.logs,
      required this.onCompleted})
      : super(key: key);

  @override
  _TblLogsState createState() => _TblLogsState();
}

class _TblLogsState extends State<TblLogs> {
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

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Folio'},
      {'name': 'Usuario'},
      {'name': 'Correo'},
      {'name': 'Dispositivo'},
      {'name': 'IP'},
      {'name': 'Descripción'},
      {'name': 'Detalles'},
      {'name': 'Creado el'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.logs.map((row) {
                return {
                  'Folio': row['folio'],
                  'Usuario': row['usuario'],
                  'Correo': row['correo'],
                  'Dispositivo': row['dispositivo'],
                  'IP': row['ip'],
                  'Descripción': row['descripcion'],
                  'Detalles': row['detalles'],
                  'Creado el': formatDate(row['createdAt'] ?? ''),
                  '_originalRow': row,
                };
              }).toList(),
              columnas: columnas,
            ),
          ),
        ),
      ],
    );
  }
}
