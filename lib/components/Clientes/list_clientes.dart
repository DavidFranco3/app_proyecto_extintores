import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter
import 'acciones.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import 'package:intl/intl.dart';

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

  void openEditarModal(row) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Editar cliente',
                  style: TextStyle(
                    fontSize: 24, // Tamaño más pequeño
                    fontWeight: FontWeight.bold, // Negrita
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Aquí agregamos un widget GestureDetector para que cuando el usuario toque fuera del formulario, el teclado se cierre.
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context)
                          .unfocus(); // Cierra el teclado al tocar fuera
                    },
                    child: Acciones(
                      showModal: widget.showModal,
                      onCompleted: widget.onCompleted,
                      accion: "editar",
                      data: row,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void openEliminarModal(row) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Eliminar cliente',
                  style: TextStyle(
                    fontSize: 24, // Tamaño más pequeño
                    fontWeight: FontWeight.bold, // Negrita
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Aquí agregamos un widget GestureDetector para que cuando el usuario toque fuera del formulario, el teclado se cierre.
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context)
                          .unfocus(); // Cierra el teclado al tocar fuera
                    },
                    child: Acciones(
                      showModal: widget.showModal,
                      onCompleted: widget.onCompleted,
                      accion: "eliminar",
                      data: row,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Registro'},
      {'name': 'Nombre'},
      {'name': 'Email'},
      {'name': 'Telefono'},
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
                  'Telefono': row['telefono'],
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
