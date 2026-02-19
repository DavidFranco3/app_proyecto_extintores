import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import './acciones.dart';
import '../Generales/list_view.dart';
import '../Generales/premium_button.dart';
import '../Generales/formato_fecha.dart';
import '../Generales/sweet_alert.dart';
import '../Generales/flushbar_helper.dart';
import '../../controllers/clasificaciones_controller.dart';

class TblClasificaciones extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> clasificaciones;
  final Function onCompleted;

  const TblClasificaciones(
      {super.key,
      required this.showModal,
      required this.clasificaciones,
      required this.onCompleted});

  @override
  State<TblClasificaciones> createState() => _TblClasificacionesState();
}

class _TblClasificacionesState extends State<TblClasificaciones> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

  void openEliminarModal(Map<String, dynamic> row) async {
    final confirmed = await SweetAlert.show(
      context: context,
      title: '¿Estás seguro?',
      message: 'Esta acción deshabilitará la clasificación "${row['nombre']}".',
      confirmLabel: 'Sí, eliminar',
      cancelLabel: 'Cancelar',
      icon: FontAwesomeIcons.trashCan,
    );

    if (confirmed == true) {
      if (!mounted) return;

      final controller = context.read<ClasificacionesController>();
      final success =
          await controller.deshabilitar(row['id'], {'estado': 'false'});

      if (success && mounted) {
        showCustomFlushbar(
          context: context,
          title: "Eliminación exitosa",
          message: "La clasificación ha sido deshabilitada correctamente.",
          backgroundColor: Colors.green,
        );
        widget.onCompleted();
      } else if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Error",
          message: "No se pudo deshabilitar la clasificación.",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void openEditarModal(Map<String, dynamic> row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: Acciones(
              showModal: widget.showModal,
              onCompleted: widget.onCompleted,
              accion: "editar",
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
      {'name': 'Descripción'},
      {'name': 'Creado el'},
    ];

    int totalRegistros = widget.clasificaciones.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.clasificaciones.asMap().entries.map((entry) {
                int index = totalRegistros -
                    entry.key; // Restamos al total para invertir el conteo
                Map<String, dynamic> row = entry.value;
                return {
                  'Registro': index,
                  'Nombre': row['nombre'],
                  'Descripción': row['descripcion'],
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
