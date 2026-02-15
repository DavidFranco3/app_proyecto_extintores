import 'package:flutter/material.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import '../Generales/formato_fecha.dart';

class TblLogs extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> logs;
  final Function onCompleted;

  const TblLogs(
      {super.key,
      required this.showModal,
      required this.logs,
      required this.onCompleted});

  @override
  State<TblLogs> createState() => _TblLogsState();
}

class _TblLogsState extends State<TblLogs> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

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

