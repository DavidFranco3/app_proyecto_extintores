import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter
import 'acciones.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import '../Generales/formato_fecha.dart';

class TblClientes extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> clientes;
  final Function onCompleted;

  TblClientes(
      {Key? key,
      required this.showModal,
      required this.clientes,
      required this.onCompleted})
      : super(key: key);

  @override
  _TblClientesState createState() => _TblClientesState();
}

class _TblClientesState extends State<TblClientes> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

  void openEditarModal(row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: Acciones(
              showModal: () {
                Navigator.pop(context); // Cierra la página actual
              },
              onCompleted: widget.onCompleted,
              accion: "editar",
              data: row,
            ),
          );
        },
      ),
    );
  }

  void openEliminarModal(row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: Acciones(
              showModal: () {
                Navigator.pop(context); // Cierra la página actual
              },
              onCompleted: widget.onCompleted,
              accion: "eliminar",
              data: row,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Registro'},
      {'name': 'Nombre'},
      {'name': 'Email'},
      {'name': 'Teléfono'},
      {'name': 'Dirección'},
      {'name': 'Creado el'}
    ];

    int totalRegistros = widget.clientes.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.clientes.asMap().entries.map((entry) {
                int index = totalRegistros - entry.key;
                Map<String, dynamic> row = entry.value;
                return {
                  'Registro': index, // Muestra "Registro 1", "Registro 2", etc.
                  'Nombre': row['nombre'],
                  'Email': row['correo'],
                  'Teléfono': row['telefono'],
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
                return PopupMenuButton<String>(
                  icon: FaIcon(FontAwesomeIcons.bars,
                      color: Color.fromARGB(255, 27, 40,
                          223)), // Este es el botón faBars que muestra el menú
                  onSelected: (String value) {
                    if (value == 'editar') {
                      openEditarModal(row['_originalRow']);
                    } else if (value == 'eliminar') {
                      openEliminarModal(row['_originalRow']);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'editar',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.pen,
                              color: Color(0xFFFFC107), size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.trash,
                              color: Color(0xFFDC3545), size: 16),
                          SizedBox(width: 8),
                          Text('Eliminar'),
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
