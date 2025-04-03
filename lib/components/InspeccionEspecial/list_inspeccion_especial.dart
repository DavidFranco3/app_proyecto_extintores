import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Usando font_awesome_flutter
import 'acciones.dart';
import '../Generales/list_view.dart'; // Asegúrate de que el archivo correcto esté importado
import '../Generales/formato_fecha.dart';
import '../../page/GraficaDatosInspecciones/grafica_datos_inspecciones.dart';

class TblInspeccionEspecial extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> inspeccionAnual;
  final Function onCompleted;

  TblInspeccionEspecial(
      {Key? key,
      required this.showModal,
      required this.inspeccionAnual,
      required this.onCompleted})
      : super(key: key);

  @override
  _TblInspeccionEspecialState createState() => _TblInspeccionEspecialState();
}

class _TblInspeccionEspecialState extends State<TblInspeccionEspecial> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;
  bool isLoading = false;

  // Función para abrir el modal de registro con el formulario de Acciones
  void openGraficaPage(Map<String, dynamic> row) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              GraficaDatosInspeccionesPage(idInspeccion: row["id"])),
    ).then((_) {
      // Actualizar inspecciones al regresar de la página
    });
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
                  'Eliminar inspeccion anual',
                  overflow: TextOverflow.ellipsis,
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
      {'name': 'Titulo'},
      {'name': 'Cliente'},
      {'name': 'Creado el'},
    ];

    int totalRegistros = widget.inspeccionAnual.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
                datos: widget.inspeccionAnual.asMap().entries.map((entry) {
                  int index = totalRegistros - entry.key;
                  Map<String, dynamic> row = entry.value;
                  return {
                    'Registro': index,
                    'Titulo': row['titulo'],
                    'Cliente': row['cliente'],
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
                      } else if (value == 'grafica') {
                        openGraficaPage(row['_originalRow']);
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
                        value: 'grafica',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.chartLine,
                              color: Colors.red,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Ver Gráfica'),
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
