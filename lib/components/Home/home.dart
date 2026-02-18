import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../Menu/menu_lateral.dart';
import '../Header/header.dart';
import '../Generales/premium_inputs.dart';
import '../../controllers/home_controller.dart';
import '../../page/InspeccionesPantalla1/inspecciones_pantalla_1.dart';
import '../../page/InspeccionesProximas/inspecciones_proximas.dart';
import '../../page/Clientes/clientes.dart';
import '../../page/Extintores/extintores.dart';
import '../../page/SeleccionarInspeccionesClientes/seleccionar_inspecciones_clientes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Iniciar carga de datos al entrar al Home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeController>().init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();

    return Scaffold(
      appBar: const Header(),
      drawer: const MenuLateral(currentPage: "Inicio"),
      body: controller.loading
          ? _buildSkeleton(context)
          : RefreshIndicator(
              onRefresh: controller.cargarDatos,
              color: Theme.of(context).primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      // 1. Bienvenida
                      const SizedBox(height: 10),
                      Text(
                        "Hola, ${controller.nombreUsuario} 👋",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          "Aquí tienes el resumen de tus actividades.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const PremiumSectionTitle(
                        title: "Acciones Rápidas",
                        icon: FontAwesomeIcons.bolt,
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActions(context),

                      const SizedBox(height: 25),

                      // 2. Tarjetas de Resumen (Metrics)
                      Row(
                        children: [
                          Expanded(
                            child: PremiumMetricCard(
                              title: "Hechas",
                              count:
                                  controller.dataInspecciones.length.toString(),
                              icon: FontAwesomeIcons.clipboardCheck,
                              color: Theme.of(context).colorScheme.secondary,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const InspeccionesPantalla1Page()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: PremiumMetricCard(
                              title: "Próximas",
                              count: controller.dataInspeccionesProximas.length
                                  .toString(),
                              icon: FontAwesomeIcons.calendarCheck,
                              color: const Color(0xFF727119),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const InspeccionesProximasPage()),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      const PremiumSectionTitle(
                        title: "Próximas a Vencer (3 días)",
                        icon: FontAwesomeIcons.calendarDay,
                      ),
                      const SizedBox(height: 8),

                      // 4. Lista de Próximas
                      if (controller.dataInspeccionesProximas2.isEmpty)
                        const PremiumEmptyState(
                          message:
                              "No hay inspecciones próximas en los siguientes 3 días.",
                          icon: FontAwesomeIcons.calendarXmark,
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount:
                              controller.dataInspeccionesProximas2.length,
                          itemBuilder: (context, index) {
                            final item =
                                controller.dataInspeccionesProximas2[index];
                            return _buildProximaCard(context, item);
                          },
                        ),

                      const SizedBox(height: 25),

                      const PremiumSectionTitle(
                        title: "Actividad Reciente",
                        icon: FontAwesomeIcons.clockRotateLeft,
                      ),
                      const SizedBox(height: 8),
                      if (controller.recentLogs.isEmpty)
                        const PremiumEmptyState(
                          message: "No hay actividad reciente registrada.",
                          icon: FontAwesomeIcons.fileLines,
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.recentLogs.length,
                          itemBuilder: (context, index) {
                            final log = controller.recentLogs[index];
                            return _buildLogCard(context, log);
                          },
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PremiumActionIcon(
            label: "Clientes",
            icon: FontAwesomeIcons.building,
            color: Colors.blue,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ClientesPage())),
          ),
          const SizedBox(width: 20),
          PremiumActionIcon(
            label: "Extintores",
            icon: FontAwesomeIcons.fireExtinguisher,
            color: Colors.red,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ExtintoresPage())),
          ),
          const SizedBox(width: 20),
          PremiumActionIcon(
            label: "Nueva Insp.",
            icon: FontAwesomeIcons.circlePlus,
            color: Colors.green,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ClienteInspeccionesApp())),
          ),
        ],
      ),
    );
  }

  Widget _buildProximaCard(BuildContext context, Map<String, dynamic> item) {
    return PremiumCardField(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF727119).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const FaIcon(
            FontAwesomeIcons.clock,
            color: Color(0xFF727119),
            size: 18,
          ),
        ),
        title: Text(
          item['cuestionario'] ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Vence: ${item['proximaInspeccion'].toString().split(' ')[0]}",
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {},
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, Map<String, dynamic> log) {
    return PremiumCardField(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            FontAwesomeIcons.circleExclamation,
            size: 14,
            color: Colors.blueGrey,
          ),
        ),
        title: Text(
          log['descripcion'] ?? 'Acción',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${log['usuario'] is Map ? (log['usuario']['nombre'] ?? 'Usuario') : (log['usuario'] ?? 'Usuario')} • ${DateFormat('dd/MM HH:mm').format(DateTime.parse(log['createdAt']).toLocal())}",
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]!
          : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 200, height: 30, color: Colors.white),
            const SizedBox(height: 10),
            Container(width: 250, height: 15, color: Colors.white),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                  3,
                  (index) => Column(
                        children: [
                          Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle)),
                          const SizedBox(height: 10),
                          Container(width: 50, height: 10, color: Colors.white),
                        ],
                      )),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                    child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)))),
                const SizedBox(width: 15),
                Expanded(
                    child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)))),
              ],
            ),
            const SizedBox(height: 30),
            ...List.generate(
                3,
                (index) => Container(
                      height: 70,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                    )),
          ],
        ),
      ),
    );
  }
}
