import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../components/Clasificaciones/list_clasificaciones.dart';
import '../../components/Clasificaciones/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';

class ClasificacionesPage extends ConsumerStatefulWidget {
  const ClasificacionesPage({super.key});

  @override
  ConsumerState<ClasificacionesPage> createState() =>
      _ClasificacionesPageState();
}

class _ClasificacionesPageState extends ConsumerState<ClasificacionesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clasificacionesProvider).cargarClasificaciones();
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
              ref.read(clasificacionesProvider).cargarClasificaciones(),
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
      body: Consumer(
        builder: (context, ref, child) {
          final controller = ref.watch(clasificacionesProvider);
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
