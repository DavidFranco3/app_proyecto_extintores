import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../Logs/logs_informativos.dart';
import '../Generales/flushbar_helper.dart';
import 'package:prueba/components/Header/header.dart';
import 'package:prueba/components/Menu/menu_lateral.dart';
import '../Generales/premium_button.dart';
import '../Load/load.dart';
import '../Generales/premium_inputs.dart';
import 'package:provider/provider.dart';
import '../../controllers/inspecciones_controller.dart';

class Acciones extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  const Acciones(
      {super.key,
      required this.showModal,
      required this.onCompleted,
      required this.accion,
      required this.data});

  @override
  State<Acciones> createState() => _AccionesState();
}

class _AccionesState extends State<Acciones> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  late TextEditingController _usuarioController;
  late TextEditingController _clienteController;
  late TextEditingController _encuestaController;

  @override
  void initState() {
    super.initState();
    debugPrint(widget.data.toString());
    _usuarioController = TextEditingController();
    _clienteController = TextEditingController();
    _encuestaController = TextEditingController();

    if (widget.accion == 'editar' || widget.accion == 'eliminar') {
      var usuarioData = widget.data['usuario'];
      var clienteData = widget.data['cliente'];
      var encuestaData = widget.data['cuestionario'] ?? widget.data['encuesta'];

      _usuarioController.text = usuarioData is Map
          ? (usuarioData['nombre'] ?? '')
          : (usuarioData?.toString() ?? '');
      _clienteController.text = clienteData is Map
          ? (clienteData['nombre'] ?? '')
          : (clienteData?.toString() ?? '');
      _encuestaController.text = encuestaData is Map
          ? (encuestaData['nombre'] ?? '')
          : (encuestaData?.toString() ?? '');
    }

    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _clienteController.dispose();
    _encuestaController.dispose();
    super.dispose();
  }

  // Corregimos la función para que acepte un parámetro bool
  void closeRegistroModal() {
    widget.showModal(); // Llama a setShow con el valor booleano
    widget.onCompleted();
  }

  void _eliminarInspeccion(String id, data) async {
    setState(() {
      _isLoading = true;
    });

    final controller = context.read<InspeccionesController>();
    final isOnline = !controller.isOffline;

    // We use the controller for both online and offline delete logic
    final wasSent = await controller.deshabilitar(id, {'estado': 'false'});

    setState(() {
      _isLoading = false;
    });

    if (wasSent) {
      logsInformativos("Se ha eliminado la inspeccion $id correctamente", {});
      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Eliminación exitosa",
          message: "Se han eliminado correctamente los datos",
          backgroundColor: Colors.green,
        );
      }
    } else if (!isOnline) {
      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Sin conexión",
          message: "Inspeccion eliminada localmente (se sincronizará después)",
          backgroundColor: Colors.orange,
        );
      }
    } else {
      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Error",
          message: "No se pudo eliminar la inspección",
          backgroundColor: Colors.red,
        );
      }
    }

    widget.onCompleted();
    widget.showModal();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      var formData = {
        'usuario': _usuarioController.text,
        'cliente': _clienteController.text,
        'encuesta': _encuestaController.text,
      };

      _eliminarInspeccion(widget.data['id'], formData);
    }
  }

  String get buttonLabel {
    if (widget.accion == 'registrar') {
      return 'Guardar';
    } else if (widget.accion == 'editar') {
      return 'Actualizar';
    } else {
      return 'Eliminar';
    }
  }

  bool get isEliminar => widget.accion == 'eliminar';

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer:
          MenuLateral(currentPage: "Tabla Inspecciones"), // Usa el menú lateral
      body: _isLoading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${capitalize(widget.accion)} inspeccion',
                        style: TextStyle(
                          fontSize: 24, // Tamaño grande
                          fontWeight: FontWeight.bold, // Negrita
                        ),
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const PremiumSectionTitle(
                          title: "Detalles de la Inspección",
                          icon: FontAwesomeIcons.clipboardCheck,
                        ),
                        PremiumCardField(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _usuarioController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Usuario Responsable',
                                  prefixIcon: FontAwesomeIcons.userCheck,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'El usuario es obligatorio'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _clienteController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Cliente / Empresa',
                                  prefixIcon: FontAwesomeIcons.building,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'El cliente es obligatorio'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _encuestaController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Encuesta Aplicada',
                                  prefixIcon: FontAwesomeIcons.rectangleList,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'La encuesta es obligatoria'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: PremiumActionButton(
                                onPressed: closeRegistroModal,
                                label: 'Cancelar',
                                icon: Icons.close,
                                style: PremiumButtonStyle.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PremiumActionButton(
                                onPressed: _onSubmit,
                                label: buttonLabel,
                                icon: isEliminar
                                    ? FontAwesomeIcons.trash
                                    : (widget.accion == 'editar'
                                        ? FontAwesomeIcons.penToSquare
                                        : FontAwesomeIcons.floppyDisk),
                                isLoading: _isLoading,
                                style: isEliminar
                                    ? PremiumButtonStyle.danger
                                    : PremiumButtonStyle.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
