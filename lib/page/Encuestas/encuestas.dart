import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../controllers/encuestas_controller.dart';
import '../../components/Encuestas/list_encuestas.dart';
import '../CrearEncuestaPantalla1/crear_encuesta_pantalla_1.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';

class EncuestasPage extends StatefulWidget {
  const EncuestasPage({super.key});

  @override
  State<EncuestasPage> createState() => _EncuestasPageState();
}

class _EncuestasPageState extends State<EncuestasPage> {
  TextEditingController nombreController = TextEditingController();
  TextEditingController clasificacionController = TextEditingController();
  TextEditingController ramaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EncuestasController>().cargarTodo();
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
          onCompleted: () =>
              context.read<EncuestasController>().cargarEncuestas(),
          accion: "registrar",
          data: null,
          nombreController: nombreController,
          ramaController: ramaController,
          clasificacionController: clasificacionController,
        ),
      ),
    ).then((_) {
      context.read<EncuestasController>().cargarEncuestas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Crear actividad"),
      body: Consumer<EncuestasController>(
        builder: (context, controller, child) {
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
                    DropdownSearch<String>(
                      key: const Key('frecuenciaDropdown'),
                      enabled: controller.dataFrecuencias.isNotEmpty,
                      items: (filter, _) {
                        return controller.dataFrecuencias
                            .where((f) => f['nombre']
                                .toString()
                                .toLowerCase()
                                .contains(filter.toLowerCase()))
                            .map((f) => f['nombre'].toString())
                            .toList();
                      },
                      selectedItem: controller.selectedFrecuencia,
                      onChanged: controller.dataFrecuencias.isEmpty
                          ? null
                          : (String? value) {
                              controller.setFrecuencia(value);
                            },
                      dropdownBuilder: (context, selectedItem) => Text(
                        selectedItem ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            color: selectedItem == null
                                ? Colors.grey
                                : Colors.black),
                      ),
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Frecuencia",
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                      popupProps: const PopupProps.menu(showSearchBox: true),
                    ),

                    const SizedBox(height: 8),

                    // Dropdown para Filtrar por Clasificación
                    DropdownSearch<String>(
                      key: const Key('clasificacionDropdown'),
                      enabled: controller.dataClasificaciones.isNotEmpty,
                      items: (filter, _) {
                        return controller.dataClasificaciones
                            .where((c) => c['nombre']
                                .toString()
                                .toLowerCase()
                                .contains(filter.toLowerCase()))
                            .map((c) => c['nombre'].toString())
                            .toList();
                      },
                      selectedItem: controller.selectedClasificacion,
                      onChanged: controller.dataClasificaciones.isEmpty
                          ? null
                          : (String? value) {
                              controller.setClasificacion(value);
                            },
                      dropdownBuilder: (context, selectedItem) => Text(
                        selectedItem ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            color: selectedItem == null
                                ? Colors.grey
                                : Colors.black),
                      ),
                      decoratorProps: const DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: "Clasificación",
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                      popupProps: const PopupProps.menu(showSearchBox: true),
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
