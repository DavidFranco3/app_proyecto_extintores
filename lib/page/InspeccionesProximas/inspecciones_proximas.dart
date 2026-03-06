import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../components/InspeccionesProximas/list_inspecciones_proximas.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class InspeccionesProximasPage extends ConsumerStatefulWidget {
  const InspeccionesProximasPage({super.key});

  @override
  ConsumerState<InspeccionesProximasPage> createState() =>
      _InspeccionesProximasPageState();
}

class _InspeccionesProximasPageState
    extends ConsumerState<InspeccionesProximasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inspeccionesProximasProvider).cargarInspeccionesProximas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Actividades próximas"),
      body: Builder(
        builder: (context) {
          final controller = ref.watch(inspeccionesProximasProvider);
          if (controller.loading &&
              controller.dataInspeccionesProximas.isEmpty) {
            return Load();
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Center(
                  child: Text(
                    "Actividades próximas",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C3E50),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TblInspeccionesProximas(
                  showModal: () {
                    if (mounted) Navigator.pop(context);
                  },
                  inspeccionesProximas: controller.dataInspeccionesProximas,
                  onCompleted: () => controller.cargarInspeccionesProximas(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
