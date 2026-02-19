import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../Generales/list_view.dart';
import '../Generales/premium_button.dart';
import '../Generales/formato_fecha.dart';
import '../Generales/sweet_alert.dart';
import '../Generales/flushbar_helper.dart';
import 'lista_preguntas.dart';
import '../../page/CrearEncuestaPantalla1/crear_encuesta_pantalla_1.dart';
import '../../controllers/encuestas_controller.dart';

class TblEncuestas extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> encuestas;
  final Function onCompleted;

  const TblEncuestas({
    super.key,
    required this.showModal,
    required this.encuestas,
    required this.onCompleted,
  });

  @override
  State<TblEncuestas> createState() => _TblEncuestasState();
}

class _TblEncuestasState extends State<TblEncuestas> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

  TextEditingController nombreController = TextEditingController();
  TextEditingController clasificacionController = TextEditingController();
  TextEditingController ramaController = TextEditingController();

  void openRegistroPage(row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEncuestaPantalla1Screen(
          showModal: () {
            if (mounted) Navigator.pop(context);
          },
          onCompleted: widget.onCompleted,
          accion: "editar",
          data: row,
          nombreController: nombreController,
          ramaController: ramaController,
          clasificacionController: clasificacionController,
        ),
      ),
    ).then((_) {
      widget.onCompleted;
    });
  }

  void openEliminarModal(Map<String, dynamic> row) async {
    final confirmed = await SweetAlert.show(
      context: context,
      title: '¿Estás seguro?',
      message: 'Esta acción deshabilitará la encuesta "${row['nombre']}".',
      confirmLabel: 'Sí, eliminar',
      cancelLabel: 'Cancelar',
      icon: FontAwesomeIcons.trashCan,
    );

    if (confirmed == true) {
      if (!mounted) return;

      final controller = context.read<EncuestasController>();
      final success =
          await controller.deshabilitar(row['id'], {'estado': 'false'});

      if (success && mounted) {
        showCustomFlushbar(
          context: context,
          title: "Eliminación exitosa",
          message: "La encuesta ha sido deshabilitada correctamente.",
          backgroundColor: Colors.green,
        );
        widget.onCompleted();
      } else if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Error",
          message: "No se pudo deshabilitar la encuesta.",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void openViewPreguntas(row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: PreguntasVisualPage(
              showModal: () {
                if (mounted)
                  Navigator.pop(
                      context); // Eliminar la lógica de cerrar el modal
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
      {'name': 'Periodo'},
      {'name': 'Clasificacion'},
      {'name': 'Tipo de Sistema'},
      {'name': 'Creado el'},
    ];

    int totalRegistros = widget.encuestas.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Envolvemos el SizedBox dentro de Expanded
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.encuestas.asMap().entries.map((entry) {
                int index = totalRegistros - entry.key;
                Map<String, dynamic> row = entry.value;
                return {
                  'Registro': index,
                  'Nombre': row['nombre'],
                  'Periodo': row['frecuencia'],
                  'Clasificacion': row['clasificacion'],
                  'Tipo de Sistema': row['rama'],
                  'Creado el': formatDate(row['createdAt'] ?? ''),
                  '_originalRow': row,
                };
              }).toList(),
              columnas: columnas,
              accionesBuilder: (Map<String, dynamic> row) {
                return PremiumTableActions(
                  onSelected: (String value) {
                    if (value == 'eliminar') {
                      openEliminarModal(row['_originalRow']);
                    } else if (value == 'visualizar') {
                      openViewPreguntas(row['_originalRow']);
                    } else if (value == "editar") {
                      openRegistroPage(row['_originalRow']);
                    }
                  },
                  items: <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'editar',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.pen,
                              color: Color(0xFFFFC107), size: 16),
                          SizedBox(width: 8),
                          const Text('Editar'),
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
                          const Text('Eliminar'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'visualizar',
                      child: Row(
                        children: [
                          FaIcon(FontAwesomeIcons.eye,
                              color: Color.fromARGB(255, 88, 6, 211), size: 16),
                          SizedBox(width: 8),
                          const Text('Ver preguntas'),
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
