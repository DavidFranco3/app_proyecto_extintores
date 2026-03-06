import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../components/Ramas/list_ramas.dart';
import '../../components/Ramas/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';

class RamasPage extends ConsumerStatefulWidget {
  const RamasPage({super.key});

  @override
  ConsumerState<RamasPage> createState() => _RamasPageState();
}

class _RamasPageState extends ConsumerState<RamasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ramasProvider).cargarRamas();
    });
  }

  // Navegar a pantalla de registro
  void openRegistroModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Acciones(
          showModal: () {
            if (mounted) Navigator.pop(context);
          },
          onCompleted: () => ref.read(ramasProvider).cargarRamas(),
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
      drawer: MenuLateral(currentPage: "Tipos de sistemas"),
      body: Consumer(
        builder: (context, ref, child) {
          final controller = ref.watch(ramasProvider);
          if (controller.loading && controller.dataRamas.isEmpty) {
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
                      "Tipos de sistemas",
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
                child: TblRamas(
                  showModal: () {
                    if (mounted) Navigator.pop(context);
                  },
                  ramas: controller.dataRamas,
                  onCompleted: () => controller.cargarRamas(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
