import 'package:flutter/material.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import 'package:intl/intl.dart';

class TblInspeccionesProximas extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> inspeccionesProximas;
  final Function onCompleted;

  TblInspeccionesProximas(
      {Key? key,
      required this.showModal,
      required this.inspeccionesProximas,
      required this.onCompleted})
      : super(key: key);

  @override
  _TblInspeccionesProximasState createState() => _TblInspeccionesProximasState();
}

class _TblInspeccionesProximasState extends State<TblInspeccionesProximas> {
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

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Cliente'},
      {'name': 'Frecuencia'},
      {'name': 'Encuesta'},
      {'name': 'Proxima inspeccion'},
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
              datos: widget.inspeccionesProximas.map((row) {
                return {
                  'Cliente': row['cliente'],
                  'Frecuencia': row['frecuencia'],
                  'Encuesta': row['cuestionario'],
                  'Proxima inspeccion': formatDate(row['proximaInspeccion']),
                  'Creado el': formatDate(row['createdAt'] ?? ''),
                  'Actualizado el': formatDate(row['updatedAt'] ?? ''),
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
