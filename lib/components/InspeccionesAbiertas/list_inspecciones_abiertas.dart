import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:prueba/page/EditarEncuesta/editar_encuesta.dart';
import 'acciones.dart';
import '../Generales/list_view.dart';
import '../Generales/formato_fecha.dart';

class TblInspecciones extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> inspecciones;
  final Function onCompleted;

  TblInspecciones(
      {Key? key,
      required this.showModal,
      required this.inspecciones,
      required this.onCompleted})
      : super(key: key);

  @override
  _TblInspeccionesState createState() => _TblInspeccionesState();
}

class _TblInspeccionesState extends State<TblInspecciones> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;
  bool isLoading = false;

  void openEliminarModal(row) {
    // Navegar a la página de eliminación en lugar de mostrar un modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Acciones(
          showModal: widget.showModal,
          onCompleted: widget.onCompleted,
          accion: "eliminar",
          data: row,
        ),
      ),
    );
  }

    void openContinuarEncuestaPage(Map<String, dynamic> row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditarEncuestaPage(),
      ),
    ).then((_) {
      // Puedes agregar lógica aquí si necesitas hacer algo cuando regresas de la página
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Inspector'},
      {'name': 'Encuesta'},
      {'name': 'Comentarios'},
      {'name': 'Creado el'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Envolvemos el SizedBox dentro de Expanded
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
                datos: widget.inspecciones.asMap().entries.map((entry) {
                  Map<String, dynamic> row = entry.value;
                  return {
                    'Inspector': row['usuario'],
                    'Encuesta': row['cuestionario'],
                    'Comentarios': row['comentarios'],
                    'Creado el': formatDate(row['createdAt'] ?? ''),
                    '_originalRow': row,
                  };
                }).toList(),
                columnas: columnas,
                accionesBuilder: (row) {
                  return PopupMenuButton<String>(
                    icon: FaIcon(
                      FontAwesomeIcons.bars,
                      color: Color.fromARGB(255, 27, 40, 223),
                    ), // Icono del menú
                    onSelected: (String value) {
                      if (value == 'eliminar') {
                        openEliminarModal(row['_originalRow']);
                      } else if (value == 'editar') {
                        openContinuarEncuestaPage(row['_originalRow']);
                      } 
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.trash,
                              color: Colors.red,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'editar',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.filePdf,
                              color: Colors.blue,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Continuar encuesta'),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
          ),
        ),
      ],
    );
  }
}
