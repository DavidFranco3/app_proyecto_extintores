import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'acciones.dart';
import '../Generales/list_view.dart';
import '../Generales/premium_button.dart';
import '../Generales/formato_fecha.dart';
import '../Generales/sweet_alert.dart';
import '../Generales/flushbar_helper.dart';
import '../../controllers/ramas_controller.dart';

class TblRamas extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> ramas;
  final Function onCompleted;

  const TblRamas(
      {super.key,
      required this.showModal,
      required this.ramas,
      required this.onCompleted});

  @override
  State<TblRamas> createState() => _TblRamasState();
}

class _TblRamasState extends State<TblRamas> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

  void openEliminarModal(Map<String, dynamic> row) async {
    final confirmed = await SweetAlert.show(
      context: context,
      title: '¿Estás seguro?',
      message: 'Esta acción deshabilitará la rama "${row['nombre']}".',
      confirmLabel: 'Sí, eliminar',
      cancelLabel: 'Cancelar',
      icon: FontAwesomeIcons.trashCan,
    );

    if (confirmed == true) {
      if (!mounted) return;

      final controller = context.read<RamasController>();
      final success =
          await controller.deshabilitar(row['id'], {'estado': 'false'});

      if (success && mounted) {
        showCustomFlushbar(
          context: context,
          title: "Eliminación exitosa",
          message: "La rama ha sido deshabilitada correctamente.",
          backgroundColor: Colors.green,
        );
        widget.onCompleted();
      } else if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Error",
          message: "No se pudo deshabilitar la rama.",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void openEditarModal(Map<String, dynamic> row) {
    // Navegar a la página de edición en lugar de mostrar un modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Acciones(
          showModal: widget.showModal,
          onCompleted: widget.onCompleted,
          accion: "editar",
          data: row,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Registro'},
      {'name': 'Nombre'},
      {'name': 'Creado el'},
    ];

    int totalRegistros = widget.ramas.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.ramas.asMap().entries.map((entry) {
                int index = totalRegistros - entry.key;
                Map<String, dynamic> row = entry.value;
                return {
                  'Registro': index,
                  'Nombre': row['nombre'],
                  'Creado el': formatDate(row['createdAt'] ?? ''),
                  '_originalRow': row,
                };
              }).toList(),
              columnas: columnas,
              accionesBuilder: (Map<String, dynamic> row) {
                return PremiumTableActions(
                  onSelected: (String value) {
                    if (value == 'editar') {
                      openEditarModal(row['_originalRow']);
                    } else if (value == 'eliminar') {
                      openEliminarModal(row['_originalRow']);
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
