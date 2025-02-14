import 'package:flutter/material.dart';

class DataTableCustom extends StatelessWidget {
  final List<Map<String, dynamic>> datos;
  final List<Map<String, dynamic>> columnas;
  final Widget Function(Map<String, dynamic>)? accionesBuilder;

  DataTableCustom({
    required this.datos,
    required this.columnas,
    this.accionesBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        itemCount: datos.length,
        itemBuilder: (context, index) {
          final row = datos[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...columnas.map((col) {
                    final columnName = col['name'];
                    return Row(
                      children: [
                        Text(
                          '${columnName}: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row[columnName]?.toString() ?? 'N/A',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  if (accionesBuilder != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: accionesBuilder!(row),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
