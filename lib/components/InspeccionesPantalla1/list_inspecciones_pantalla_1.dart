import 'package:flutter/material.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import '../Generales/formato_fecha.dart';
import '../../page/InspeccionesPantalla2/inspecciones_pantalla_2.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter

class TblInspeccionesPantalla1 extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> clientes;
  final Function onCompleted;

  TblInspeccionesPantalla1(
      {Key? key,
      required this.showModal,
      required this.clientes,
      required this.onCompleted})
      : super(key: key);

  @override
  _TblInspeccionesPantalla1State createState() =>
      _TblInspeccionesPantalla1State();
}

class _TblInspeccionesPantalla1State extends State<TblInspeccionesPantalla1> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

  // Función para abrir el modal de registro con el formulario de Acciones
  void openPantalla2Page(Map<String, dynamic> row) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => InspeccionesPantalla2Page(
              showModal: () {
                Navigator.pop(context); // Esto cierra el modal
              },
              data: row)),
    ).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Registro'},
      {'name': 'Nombre'},
      {'name': 'Dirección'},
      {'name': 'Creado el'}
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.clientes.asMap().entries.map((entry) {
                Map<String, dynamic> row = entry.value;
                return {
                  'Registro':
                      row['index'], // Muestra "Registro 1", "Registro 2", etc.
                  'Nombre': row['nombre'],
                  'Dirección': "C " +
                      row['calle'] +
                      " " +
                      row['nExterior'] +
                      " LOC " +
                      row['colonia'] +
                      " " +
                      row['cPostal'] +
                      " " +
                      row['municipio'] +
                      " , " +
                      row['estadoDom'],
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
