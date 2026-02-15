import 'package:flutter/material.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import '../Generales/formato_fecha.dart';

class TblInspeccionesProximas extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> inspeccionesProximas;
  final Function onCompleted;

  const TblInspeccionesProximas(
      {super.key,
      required this.showModal,
      required this.inspeccionesProximas,
      required this.onCompleted});

  @override
  State<TblInspeccionesProximas> createState() => _TblInspeccionesProximasState();
}

class _TblInspeccionesProximasState extends State<TblInspeccionesProximas> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Registro'},
      {'name': 'Cliente'},
      {'name': 'Periodo'},
      {'name': 'Encuesta'},
      {'name': 'Proxima inspeccion'},
      {'name': 'Creado el'},
    ];

      int totalRegistros = widget.inspeccionesProximas.length;


    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Envolvemos el SizedBox dentro de Expanded
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.inspeccionesProximas.asMap().entries.map((entry) {
                int index = totalRegistros - entry.key;
                Map<String, dynamic> row = entry.value;
                return {
                  'Registro': index,
                  'Cliente': row['cliente'],
                  'Periodo': row['frecuencia'],
                  'Encuesta': row['cuestionario'],
                  'Proxima inspeccion': formatDate(row['proximaInspeccion']),
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

