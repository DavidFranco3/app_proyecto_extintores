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
import '../../api/inspecciones.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
    return data
        .map((item) => {
              'id': item['_id'],
              'nombre': item['nombre'],
            })
        .toList();
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
      drawer: MenuLateral(currentPage: "Periodos"), // Usa el menú lateral
      body: isLoading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButton<String>(
                    hint: Text('Selecciona un cliente'),
                    value: clienteSeleccionado,
                    onChanged: (nuevoClienteId) {
                      setState(() {
                        clienteSeleccionado = nuevoClienteId;
                        fechaSeleccionada = null;
                      });
                      if (nuevoClienteId != null) {
                        cargarInspecciones(nuevoClienteId);
                      }
                    },
                    items:
                        dataClientes.map<DropdownMenuItem<String>>((cliente) {
                      return DropdownMenuItem<String>(
                        value: cliente['id'],
                        child: Text(cliente['nombre']),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => seleccionarFecha(context),
                        child: const Text('Elegir Fecha'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: clienteSeleccionado != null &&
                            inspeccionesFiltradas.isNotEmpty
                        ? Scrollbar(
                            child: ListView.builder(
                              itemCount: inspeccionesFiltradas.length,
                              itemBuilder: (context, index) {
                                final inspeccion = inspeccionesFiltradas[index];
                                return ListTile(
                                  title: Text(
                                    "${inspeccion['cuestionario']} - ${inspeccion['frecuencia']}",
                                  ),
                                  subtitle: Text(
                                    DateFormat('yyyy-MM-dd HH:mm').format(
                                      DateTime.parse(inspeccion['createdAt']),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(child: Text('No hay inspecciones')),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: handleDownloadMultiplePDFs,
                    child: Text('Descargar PDF combinado'),
                  ),
                ],
              ),
            ),
    );
  }
}

