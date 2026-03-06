import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../providers/app_providers.dart';
import '../../components/Encuestas/list_encuestas.dart';
import '../CrearEncuestaPantalla1/crear_encuesta_pantalla_1.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';
import '../../components/Generales/premium_inputs.dart';

class EncuestasPage extends ConsumerStatefulWidget {
  const EncuestasPage({super.key});

  @override
  ConsumerState<EncuestasPage> createState() => _EncuestasPageState();
}

class _EncuestasPageState extends ConsumerState<EncuestasPage> {
  TextEditingController nombreController = TextEditingController();
  TextEditingController clasificacionController = TextEditingController();
  TextEditingController ramaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(encuestasProvider).cargarTodo();
    });
  }

  void openRegistroPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEncuestaPantalla1Screen(
          showModal: () {
            if (mounted) Navigator.pop(context);
          },
          onCompleted: () => ref.read(encuestasProvider).cargarEncuestas(),
          accion: "registrar",
          data: null,
          nombreController: nombreController,
          ramaController: ramaController,
          clasificacionController: clasificacionController,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      ref.read(encuestasProvider).cargarEncuestas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Crear actividad"),
      body: Consumer(
        builder: (context, ref, child) {
          final controller = ref.watch(encuestasProvider);
          if (controller.loading && controller.dataEncuestas.isEmpty) {
            return Load();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Crear actividad",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PremiumActionButton(
                      onPressed: openRegistroPage,
                      label: "Registrar",
                      icon: FontAwesomeIcons.plus,
                    ),
                  ],
                ),
              ),
              const Divider(indent: 20, endIndent: 20, height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    // Dropdown para Filtrar por Frecuencia
                    DropdownSearch<Map<String, dynamic>>(
                      key: const Key('frecuenciaDropdown'),
                      compareFn: (item, sItem) => item['id'] == sItem['id'],
                      enabled: controller.dataFrecuencias.isNotEmpty,
                      items: (filter, _) {
                        return controller.dataFrecuencias
                            .where((f) => f['nombre']
                                .toString()
                                .toLowerCase()
                                .contains(filter.toLowerCase()))
                            .toList();
                      },
                      itemAsString: (f) => f['nombre'].toString(),
                      selectedItem: controller.dataFrecuencias
                          .cast<Map<String, dynamic>?>()
                          .firstWhere(
                            (f) =>
                                f?['nombre'] == controller.selectedFrecuencia,
                            orElse: () => null,
                          ),
                      onChanged: controller.dataFrecuencias.isEmpty
                          ? null
                          : (Map<String, dynamic>? value) {
                              controller.setFrecuencia(value?['nombre']);
                            },
                      dropdownBuilder: (context, selectedItem) => Text(
                        selectedItem?['nombre'] ?? "Seleccione Frecuencia",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            color: selectedItem == null
                                ? Colors.grey
                                : Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color),
                      ),
                      decoratorProps: DropDownDecoratorProps(
                        decoration: PremiumInputs.decoration(
                          labelText: "Frecuencia",
                          prefixIcon: FontAwesomeIcons.calendarDay,
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        fit: FlexFit.loose,
                        itemBuilder:
                            (context, item, isSelected, isItemDisabled) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(
                              item['nombre']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Dropdown para Filtrar por Clasificación
                    DropdownSearch<Map<String, dynamic>>(
                      key: const Key('clasificacionDropdown'),
                      compareFn: (item, sItem) => item['id'] == sItem['id'],
                      enabled: controller.dataClasificaciones.isNotEmpty,
                      items: (filter, _) {
                        return controller.dataClasificaciones
                            .where((c) => c['nombre']
                                .toString()
                                .toLowerCase()
                                .contains(filter.toLowerCase()))
                            .toList();
                      },
                      itemAsString: (c) => c['nombre'].toString(),
                      selectedItem: controller.dataClasificaciones
                          .cast<Map<String, dynamic>?>()
                          .firstWhere(
                            (c) =>
                                c?['nombre'] ==
                                controller.selectedClasificacion,
                            orElse: () => null,
                          ),
                      onChanged: controller.dataClasificaciones.isEmpty
                          ? null
                          : (Map<String, dynamic>? value) {
                              controller.setClasificacion(value?['nombre']);
                            },
                      dropdownBuilder: (context, selectedItem) => Text(
                        selectedItem?['nombre'] ?? "Seleccione Clasificación",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            color: selectedItem == null
                                ? Colors.grey
                                : Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color),
                      ),
                      decoratorProps: DropDownDecoratorProps(
                        decoration: PremiumInputs.decoration(
                          labelText: "Clasificación",
                          prefixIcon: FontAwesomeIcons.layerGroup,
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        fit: FlexFit.loose,
                        itemBuilder:
                            (context, item, isSelected, isItemDisabled) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(
                              item['nombre']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: TblEncuestas(
                  showModal: () {
                    if (mounted) Navigator.pop(context);
                  },
                  encuestas: controller.filteredEncuestas,
                  onCompleted: () => controller.cargarEncuestas(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
