import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'acciones.dart';
import '../Generales/list_view.dart';
import '../Generales/premium_button.dart';
import '../Generales/formato_fecha.dart';
import '../Generales/sweet_alert.dart';
import '../Generales/flushbar_helper.dart';
import '../../controllers/tipos_extintores_controller.dart';

class TblTiposExtintores extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> tiposExtintores;
  final Function onCompleted;

  const TblTiposExtintores(
      {super.key,
      required this.showModal,
      required this.tiposExtintores,
      required this.onCompleted});

  @override
  State<TblTiposExtintores> createState() => _TblTiposExtintoresState();
}

class _TblTiposExtintoresState extends State<TblTiposExtintores> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;

  void openEditarModal(Map<String, dynamic> row) {
    // Navegar a la página de edición en lugar de mostrar un modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Acciones(
          showModal: () {
            if (mounted) Navigator.pop(context); // Cierra la pantalla
          },
          onCompleted: widget.onCompleted,
          accion: "editar",
          data: row,
        ),
      ),
    );
  }

  void openEliminarModal(Map<String, dynamic> row) async {
    final confirmed = await SweetAlert.show(
      context: context,
      title: '¿Estás seguro?',
      message:
          'Esta acción deshabilitará el tipo de extintor "${row['nombre']}".',
      confirmLabel: 'Sí, eliminar',
      cancelLabel: 'Cancelar',
      icon: FontAwesomeIcons.trashCan,
    );

    if (confirmed == true) {
      if (!mounted) return;

      final controller = context.read<TiposExtintoresController>();
      final success =
          await controller.deshabilitar(row['id'], {'estado': 'false'});

      if (success && mounted) {
        showCustomFlushbar(
          context: context,
          title: "Eliminación exitosa",
          message: "El tipo de extintor ha sido deshabilitado correctamente.",
          backgroundColor: Colors.green,
        );
        widget.onCompleted();
      } else if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Error",
          message: "No se pudo deshabilitar el tipo de extintor.",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Registro'},
      {'name': 'Nombre'},
      {'name': 'Descripción'},
      {'name': 'Creado el'},
    ];

    int totalRegistros = widget.tiposExtintores.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Envolvemos el SizedBox dentro de Expanded
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.tiposExtintores.asMap().entries.map((entry) {
                int index = totalRegistros - entry.key;
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
