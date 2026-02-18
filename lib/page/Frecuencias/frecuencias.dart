import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../controllers/frecuencias_controller.dart';
import '../../components/Frecuencias/list_frecuencias.dart';
import '../../components/Frecuencias/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';

class FrecuenciasPage extends StatefulWidget {
  const FrecuenciasPage({super.key});

  @override
  State<FrecuenciasPage> createState() => _FrecuenciasPageState();
}

class _FrecuenciasPageState extends State<FrecuenciasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FrecuenciasController>().cargarFrecuencias();
    });
  }

  void openRegistroModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Acciones(
          showModal: () {
            if (mounted) Navigator.pop(context);
          },
          onCompleted: () =>
              context.read<FrecuenciasController>().cargarFrecuencias(),
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
      drawer: MenuLateral(currentPage: "Periodos"),
      body: Consumer<FrecuenciasController>(
        builder: (context, controller, child) {
          if (controller.loading && controller.dataFrecuencias.isEmpty) {
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
                      "Periodos",
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
                      onPressed: openRegistroModal,
                      label: "Registrar",
                      icon: FontAwesomeIcons.plus,
                    ),
                  ],
                ),
              ),
              const Divider(indent: 20, endIndent: 20, height: 32),
              Expanded(
                child: TblFrecuencias(
                  showModal: () {
                    if (mounted) Navigator.pop(context);
                  },
                  frecuencias: controller.dataFrecuencias,
                  onCompleted: () => controller.cargarFrecuencias(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
