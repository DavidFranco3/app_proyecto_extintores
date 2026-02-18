import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/models/cliente_model.dart';
import 'acciones.dart';
import '../Generales/list_view.dart';
import '../Generales/premium_button.dart';
import '../Generales/formato_fecha.dart';

class TblClientes extends StatefulWidget {
  final VoidCallback showModal;
  final List<ClienteModel> clientes;
  final Function onCompleted;

  const TblClientes({
    super.key,
    required this.showModal,
    required this.clientes,
    required this.onCompleted,
  });

  @override
  State<TblClientes> createState() => _TblClientesState();
}

class _TblClientesState extends State<TblClientes> {
  void openEditarModal(ClienteModel row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: Acciones(
              showModal: () {
                if (mounted) Navigator.pop(context);
              },
              onCompleted: widget.onCompleted,
              accion: "editar",
              data: row.toJson(),
            ),
          );
        },
      ),
    );
  }

  void openEliminarModal(ClienteModel row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: Acciones(
              showModal: () {
                if (mounted) Navigator.pop(context);
              },
              onCompleted: widget.onCompleted,
              accion: "eliminar",
              data: row.toJson(),
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
                ClienteModel client = entry.value;
                return {
                  'Registro': index,
                  'Nombre': client.nombre,
                  'Email': client.correo,
                  'Teléfono': client.telefono,
                  'Dirección':
                      "C ${client.calle} ${client.nExterior} LOC ${client.colonia} ${client.cPostal} ${client.municipio} , ${client.estadoDom}",
                  'Creado el': formatDate(client.createdAt),
                  '_originalRow': client,
                };
              }).toList(),
              columnas: columnas,
              accionesBuilder: (Map<String, dynamic> row) {
                final client = row['_originalRow'] as ClienteModel;
                return PremiumTableActions(
                  onSelected: (String value) {
                    if (value == 'editar') {
                      openEditarModal(client);
                    } else if (value == 'eliminar') {
                      openEliminarModal(client);
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
