import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../controllers/inspecciones_controller.dart';
import '../../components/Inspecciones/list_inspecciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';
import '../InspeccionesPantalla2/inspecciones_pantalla_2.dart';

class InspeccionesInspectorPage extends StatefulWidget {
  final VoidCallback showModal;
  final dynamic data;
  final dynamic data2;

  const InspeccionesInspectorPage({
    super.key,
    required this.showModal,
    required this.data,
    required this.data2,
  });

  @override
  State<InspeccionesInspectorPage> createState() =>
      _InspeccionesInspectorPageState();
}

class _InspeccionesInspectorPageState extends State<InspeccionesInspectorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InspeccionesController>().cargarInspecciones(
            widget.data["id"],
            cacheBox: 'inspeccionesInspectorBox',
          );
    });
  }

  void returnPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspeccionesPantalla2Page(
          showModal: () {
            if (mounted) Navigator.pop(context);
          },
          data: widget.data2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Historial de actividades"),
      body: Consumer<InspeccionesController>(
        builder: (context, controller, child) {
          if (controller.loading && controller.dataInspecciones.isEmpty) {
            return Load();
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    "Actividades",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: PremiumActionButton(
                        onPressed: returnPage,
                        label: "Regresar",
                        icon: FontAwesomeIcons.arrowLeft,
                        style: PremiumButtonStyle.secondary,
                        isFullWidth: true,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    "Cliente: ${widget.data["cliente"]}",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              Expanded(
                child: TblInspecciones(
                  showModal: () {
                    if (mounted) Navigator.pop(context);
                  },
                  inspecciones: controller.dataInspecciones,
                  onCompleted: () => controller.cargarInspecciones(
                    widget.data["id"],
                    cacheBox: 'inspeccionesInspectorBox',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
