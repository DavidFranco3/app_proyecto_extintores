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

class InspeccionesPage extends StatefulWidget {
  final VoidCallback showModal;
  final dynamic data;
  final dynamic data2;

  const InspeccionesPage({
    super.key,
    required this.showModal,
    required this.data,
    required this.data2,
  });

  @override
  State<InspeccionesPage> createState() => _InspeccionesPageState();
}

class _InspeccionesPageState extends State<InspeccionesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<InspeccionesController>()
          .cargarInspecciones(widget.data["id"]);
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Historial de actividades",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
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
                    if (controller.isOffline) ...[
                      const SizedBox(height: 8),
                      const Text(
                        "Modo offline: mostrando datos locales",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      "Cliente: ${widget.data["cliente"]}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF34495E),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TblInspecciones(
                  showModal: () {
                    if (mounted) Navigator.pop(context);
                  },
                  inspecciones: controller.dataInspecciones,
                  onCompleted: () =>
                      controller.cargarInspecciones(widget.data["id"]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
