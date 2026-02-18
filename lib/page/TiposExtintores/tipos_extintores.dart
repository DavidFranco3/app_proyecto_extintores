import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../controllers/tipos_extintores_controller.dart';
import '../../components/TiposExtintores/list_tipos_extintores.dart';
import '../../components/TiposExtintores/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';

class TiposExtintoresPage extends StatefulWidget {
  const TiposExtintoresPage({super.key});

  @override
  State<TiposExtintoresPage> createState() => _TiposExtintoresPageState();
}

class _TiposExtintoresPageState extends State<TiposExtintoresPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TiposExtintoresController>().cargarTiposExtintores();
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
              context.read<TiposExtintoresController>().cargarTiposExtintores(),
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
      drawer: MenuLateral(currentPage: "Tipos de extintores"),
      body: Consumer<TiposExtintoresController>(
        builder: (context, controller, child) {
          if (controller.loading && controller.dataTiposExtintores.isEmpty) {
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
                      "Tipos de extintores",
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
                child: TblTiposExtintores(
                  showModal: () {
                    if (mounted) Navigator.pop(context);
                  },
                  tiposExtintores: controller.dataTiposExtintores,
                  onCompleted: () => controller.cargarTiposExtintores(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
