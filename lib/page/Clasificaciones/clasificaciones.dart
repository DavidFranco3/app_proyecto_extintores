import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../controllers/clasificaciones_controller.dart';
import '../../components/Clasificaciones/list_clasificaciones.dart';
import '../../components/Clasificaciones/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';

class ClasificacionesPage extends StatefulWidget {
  const ClasificacionesPage({super.key});

  @override
  State<ClasificacionesPage> createState() => _ClasificacionesPageState();
}

class _ClasificacionesPageState extends State<ClasificacionesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClasificacionesController>().cargarClasificaciones();
    });
  }

  void openRegistroView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => Acciones(
          showModal: () {
            if (mounted) Navigator.pop(context);
          },
          onCompleted: () =>
              context.read<ClasificacionesController>().cargarClasificaciones(),
          accion: "registrar",
          data: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Clasificaciones"),
      body: Consumer<ClasificacionesController>(
        builder: (context, controller, child) {
          if (controller.loading && controller.dataClasificaciones.isEmpty) {
            return Load();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Clasificaciones",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color:
                            Theme.of(context).textTheme.headlineMedium?.color ??
                                const Color(0xFF2C3E50),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PremiumActionButton(
                      onPressed: openRegistroView,
                      label: "Registrar",
                      icon: FontAwesomeIcons.plus,
                    ),
                  ],
                ),
              ),
              const Divider(indent: 20, endIndent: 20, height: 32),
              Expanded(
                child: TblClasificaciones(
                  showModal: () {
                    if (mounted) Navigator.pop(context);
                  },
                  clasificaciones: controller.dataClasificaciones,
                  onCompleted: () => controller.cargarClasificaciones(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
