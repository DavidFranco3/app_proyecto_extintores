import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../api/clientes.dart';
import '../../api/models/cliente_model.dart';
import '../../api/inspecciones.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../components/Generales/premium_button.dart';
import '../../components/Generales/premium_inputs.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dropdown_search/dropdown_search.dart';

void main() => runApp(MaterialApp(home: ClienteInspeccionesApp()));

class ClienteInspeccionesApp extends StatefulWidget {
  const ClienteInspeccionesApp({super.key});

  @override
  State<ClienteInspeccionesApp> createState() => _ClienteInspeccionesAppState();
}

class _ClienteInspeccionesAppState extends State<ClienteInspeccionesApp> {
  bool isLoading = false;
  List<Map<String, dynamic>> dataClientes = [];
  List<Map<String, dynamic>> dataInspecciones = [];
  String? clienteSeleccionado;
  DateTime? fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  Future<void> cargarClientes() async {
    final conectado = await verificarConexion();
    if (conectado) {
      debugPrint("Conectado a internet");
      await getClientesDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando desde Hive...");
      await getClientesDesdeHive();
    }
  }

  Future<void> cargarInspecciones(String idCliente) async {
    final conectado = await verificarConexion();
    if (conectado) {
      debugPrint("Conectado a internet");
      await getInspeccionesDesdeAPI(idCliente);
    } else {
      debugPrint("Sin conexión, cargando desde Hive...");
      await getInspeccionesDesdeHive();
    }
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> getClientesDesdeAPI() async {
    try {
      final clientesService = ClientesService();
      final List<dynamic> response = await clientesService.listarClientes();

      if (response.isNotEmpty) {
        final formateadas = formatModelClientes(response);

        final box = Hive.box('clientesBox');
        await box.put('clientes', formateadas);

        if (mounted) {
          setState(() {
            dataClientes = formateadas;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            dataClientes = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al obtener los clientes: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> getClientesDesdeHive() async {
    final box = Hive.box('clientesBox');
    final List<dynamic>? guardados = box.get('clientes');

    if (guardados != null) {
      if (mounted) {
        setState(() {
          dataClientes = guardados
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item as Map))
              .toList();
          isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          dataClientes = [];
          isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> formatModelClientes(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      final Map<String, dynamic> raw = (item is ClienteModel)
          ? item.toJson()
          : Map<String, dynamic>.from(item as Map);

      dataTemp.add({
        'id': raw['_id'],
        'nombre': raw['nombre'],
        'correo': raw['correo'],
        'telefono': raw['telefono'],
        'calle': raw['direccion']['calle'],
        'nExterior': raw['direccion']['nExterior']?.isNotEmpty ?? false
            ? raw['direccion']['nExterior']
            : 'S/N',
        'nInterior': raw['direccion']['nInterior']?.isNotEmpty ?? false
            ? raw['direccion']['nInterior']
            : 'S/N',
        'colonia': raw['direccion']['colonia'],
        'estadoDom': raw['direccion']['estadoDom'],
        'municipio': raw['direccion']['municipio'],
        'cPostal': raw['direccion']['cPostal'],
        'referencia': raw['direccion']['referencia'],
        'estado': raw['estado']?.toString() ?? 'true',
        'createdAt': raw['createdAt'],
        'updatedAt': raw['updatedAt'],
      });
    }
    return dataTemp;
  }

  Future<void> getInspeccionesDesdeAPI(String idCliente) async {
    setState(() {
      isLoading = true;
      dataInspecciones = [];
    });

    try {
      final inspeccionesService = InspeccionesService();
      final List<dynamic> response =
          await inspeccionesService.listarInspeccionesPorCliente(idCliente);

      if (response.isNotEmpty) {
        setState(() {
          dataInspecciones = formatModelInspecciones(response);
        });
      } else {
        setState(() {
          dataInspecciones = [];
        });
      }
    } catch (e) {
      debugPrint("Error al obtener las inspecciones: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> getInspeccionesDesdeHive() async {
    final box = Hive.box('inspeccionesClientesBox');
    final List<dynamic>? guardadas = box.get('inspecciones');

    if (guardadas != null) {
      final locales = List<Map<String, dynamic>>.from(guardadas
          .map((e) => Map<String, dynamic>.from(e))
          .where((item) => item['estado'] == "true"));

      setState(() {
        dataInspecciones = locales;
      });
    }
  }

  List<Map<String, dynamic>> formatModelInspecciones(List<dynamic> data) {
    return data
        .map((item) => {
              'id': item['_id'],
              'cuestionario': item['cuestionario']['nombre'],
              'frecuencia': item['cuestionario']['frecuencia']['nombre'],
              'createdAt': item['createdAt'],
            })
        .toList();
  }

  Future<void> seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != fechaSeleccionada) {
      setState(() {
        fechaSeleccionada = picked;
      });
    }
  }

  Future<void> handleDownloadMultiplePDFs() async {
    setState(() => isLoading = true);

    final inspeccionesService = InspeccionesService();
    final dio = Dio();
    final tempDir = await getTemporaryDirectory();

    try {
      List<String> pdfPaths = [];

      List<Map<String, dynamic>> inspeccionesFiltradas =
          fechaSeleccionada == null
              ? dataInspecciones
              : dataInspecciones.where((inspeccion) {
                  final fechaInspeccion =
                      DateTime.parse(inspeccion['createdAt']);
                  return fechaInspeccion.year == fechaSeleccionada!.year &&
                      fechaInspeccion.month == fechaSeleccionada!.month &&
                      fechaInspeccion.day == fechaSeleccionada!.day;
                }).toList();

      for (var inspeccion in inspeccionesFiltradas) {
        String url = inspeccionesService.urlDownloadPDF(inspeccion["id"]);
        if (url.isEmpty) continue;

        String tempPath = "${tempDir.path}/temp_${inspeccion["id"]}.pdf";
        await dio.download(url, tempPath);
        pdfPaths.add(tempPath);
      }

      if (pdfPaths.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No hay inspecciones en la fecha seleccionada.')),
        );
        return;
      }

      PdfDocument outputDocument = PdfDocument();
      for (String path in pdfPaths) {
        List<int> bytes = await File(path).readAsBytes();
        PdfDocument inputDocument = PdfDocument(inputBytes: bytes);

        for (int i = 0; i < inputDocument.pages.count; i++) {
          final template = inputDocument.pages[i].createTemplate();
          final templateSize = template.size;
          final newPage = outputDocument.pages.add();
          final graphics = newPage.graphics;
          final pageSize = newPage.getClientSize();

          final dx = (pageSize.width - templateSize.width) / 2;
          final topMargin = 18;
          final dy = ((pageSize.height - templateSize.height) / 2) - topMargin;

          graphics.drawPdfTemplate(
              template, Offset(dx, dy.clamp(0, double.infinity)));
        }

        inputDocument.dispose();
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final finalPath = "${appDocDir.path}/Inspecciones_Unidas.pdf";

      List<int> bytes = await outputDocument.save();
      File(finalPath).writeAsBytesSync(bytes);
      outputDocument.dispose();

      OpenFile.open(finalPath);
    } catch (e) {
      debugPrint("Error al combinar los PDF: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> inspeccionesFiltradas = fechaSeleccionada == null
        ? dataInspecciones
        : dataInspecciones.where((inspeccion) {
            final fechaInspeccion = DateTime.parse(inspeccion['createdAt']);
            return fechaInspeccion.year == fechaSeleccionada!.year &&
                fechaInspeccion.month == fechaSeleccionada!.month &&
                fechaInspeccion.day == fechaSeleccionada!.day;
          }).toList();

    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Seleccionar actividad"),
      body: isLoading
          ? Load()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: PremiumSectionTitle(title: "Seleccionar cliente"),
                  ),
                  const SizedBox(height: 15),
                  PremiumCardField(
                    child: DropdownSearch<Map<String, dynamic>>(
                      items: (filter, _) => dataClientes
                          .where((cliente) => cliente['nombre']
                              .toString()
                              .toLowerCase()
                              .contains(filter.toLowerCase()))
                          .toList(),
                      itemAsString: (item) => item['nombre'] ?? '',
                      compareFn: (item1, item2) => item1['id'] == item2['id'],
                      selectedItem: clienteSeleccionado != null
                          ? dataClientes.firstWhere(
                              (element) => element['id'] == clienteSeleccionado,
                              orElse: () => {})
                          : null,
                      onChanged: (nuevoCliente) {
                        setState(() {
                          clienteSeleccionado = nuevoCliente?['id'];
                          fechaSeleccionada = null;
                        });
                        if (nuevoCliente != null) {
                          cargarInspecciones(nuevoCliente['id']);
                        }
                      },
                      dropdownBuilder: (context, selectedItem) {
                        return Text(
                          selectedItem?['nombre'] ?? "Seleccionar cliente",
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedItem == null
                                ? Colors.grey
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                      decoratorProps: DropDownDecoratorProps(
                        decoration: PremiumInputs.decoration(
                          labelText: "Cliente",
                          prefixIcon: FontAwesomeIcons.user,
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
                              item['nombre'] ?? '',
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
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: PremiumSectionTitle(
                        title: fechaSeleccionada == null
                            ? "Todas las fechas"
                            : "Fecha: ${DateFormat('dd/MM/yyyy').format(fechaSeleccionada!)}"),
                  ),
                  const SizedBox(height: 10),
                  PremiumActionButton(
                    onPressed: () => seleccionarFecha(context),
                    label: "Filtrar por Fecha",
                    icon: FontAwesomeIcons.calendarDays,
                    style: PremiumButtonStyle.secondary,
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 20),
                  if (clienteSeleccionado != null) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child:
                          PremiumSectionTitle(title: "Actividades Encontradas"),
                    ),
                    if (inspeccionesFiltradas.isNotEmpty)
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: inspeccionesFiltradas.length,
                        itemBuilder: (context, index) {
                          final inspeccion = inspeccionesFiltradas[index];
                          final fecha = DateTime.parse(inspeccion['createdAt']);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PremiumCardField(
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                      FontAwesomeIcons.fileContract,
                                      color: Color(0xFF1565C0),
                                      size: 20),
                                ),
                                title: Text(
                                  "${inspeccion['cuestionario']}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(FontAwesomeIcons.clock,
                                            size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('yyyy-MM-dd HH:mm')
                                              .format(fecha),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Frecuencia: ${inspeccion['frecuencia']}",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 14, color: Colors.grey),
                                onTap: () {
                                  // Accion al tocar (si se requiere navegar o algo)
                                },
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(FontAwesomeIcons.folderOpen,
                                  size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 10),
                              Text("No hay actividades registradas",
                                  style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (inspeccionesFiltradas.isNotEmpty)
                      PremiumActionButton(
                        onPressed: handleDownloadMultiplePDFs,
                        label: "Descargar PDF Combinado",
                        icon: FontAwesomeIcons.filePdf,
                        isFullWidth: true,
                      ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
