import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../components/Extintores/list_extintores.dart';
import '../../components/Extintores/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';

class ExtintoresPage extends ConsumerStatefulWidget {
  const ExtintoresPage({super.key});

  @override
  ConsumerState<ExtintoresPage> createState() => _ExtintoresPageState();
}

class _ExtintoresPageState extends ConsumerState<ExtintoresPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(extintoresProvider).cargarExtintores();
    });
  }

  // Función para abrir el modal de registro
  void openRegistroModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Acciones(
            showModal: () {
              if (mounted) Navigator.pop(context);
            },
            onCompleted: () => ref.read(extintoresProvider).cargarExtintores(),
            accion: "registrar",
            data: null,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Extintores"),
      body: Consumer(
        builder: (context, ref, child) {
          final controller = ref.watch(extintoresProvider);
          if (controller.loading && controller.dataExtintores.isEmpty) {
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
                      "Extintores",
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
                child: TblExtintores(
                  showModal: () {
                    if (mounted) Navigator.pop(context);
                  },
                  extintores: controller.dataExtintores,
                  onCompleted: () => controller.cargarExtintores(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
