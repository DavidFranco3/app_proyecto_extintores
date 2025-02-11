import 'package:flutter/material.dart';

class DataTableCustom extends StatelessWidget {
  final List<Map<String, dynamic>> datos;
  final List<Map<String, dynamic>> columnas;

  DataTableCustom({
    required this.datos,
    required this.columnas,
  });

  @override
  Widget build(BuildContext context) {
    // Imprimir datos y columnas en la consola
    print('Datos: $datos');
    print('Columnas: $columnas');

    return Container(
      height: 400, // Establece una altura fija para el ListView
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
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
                children: columnas.map((col) {
                  final columnName = col['name'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
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
                            row[columnName]?.toString() ?? '',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
