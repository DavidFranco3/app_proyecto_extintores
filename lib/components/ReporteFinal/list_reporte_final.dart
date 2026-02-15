import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import '../Generales/formato_fecha.dart';
import './pdf2.dart';

class TblReporteFinal extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> reporteFinal;
  final Function onCompleted;

  const TblReporteFinal(
      {super.key,
      required this.showModal,
      required this.reporteFinal,
      required this.onCompleted});

  @override
  State<TblReporteFinal> createState() => _TblReporteFinalState();
}

class _TblReporteFinalState extends State<TblReporteFinal> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Descripción'},
      {'name': 'Creado el'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.reporteFinal.asMap().entries.map((entry) {
                Map<String, dynamic> row = entry.value;
                return {
                  'Descripción': row['descripcion'],
                  'Creado el': formatDate(row['createdAt'] ?? ''),
                  '_originalRow': row,
                };
              }).toList(),
              columnas: columnas,
                              accionesBuilder: (Map<String, dynamic> row) {
                  return PopupMenuButton<String>(
                    icon: FaIcon(
                      FontAwesomeIcons.bars,
                      color: Color.fromARGB(255, 27, 40, 223),
                    ), // Icono del menú
                    onSelected: (String value) {
                      if (value == 'guardarPdf3') {
                        GenerarPdfPage.generarPdf(row['_originalRow']);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'guardarPdf3',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.filePdf,
                              color: Colors.blue,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Guardar PDF 3'),
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


