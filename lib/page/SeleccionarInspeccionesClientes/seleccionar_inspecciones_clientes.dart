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

void main() => runApp(MaterialApp(home: ClienteInspeccionesApp()));

class ClienteInspeccionesApp extends StatefulWidget {
  @override
  _ClienteInspeccionesAppState createState() => _ClienteInspeccionesAppState();
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
    getClientes();
  }

  Future<void> getClientes() async {
    setState(() => isLoading = true);
    try {
      final clientesService = ClientesService();
      final List<dynamic> response = await clientesService.listarClientes();
      if (response.isNotEmpty) {
        setState(() {
          dataClientes = formatModelClientes(response);
        });
      } else {
        setState(() {
          dataClientes = [];
        });
      }
    } catch (e) {
      print("Error al obtener los clientes: $e");
    } finally {
      setState(() => isLoading = false);
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

  Future<void> getInspecciones(String idCliente) async {
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
      print("Error al obtener las inspecciones: $e");
    } finally {
      setState(() => isLoading = false);
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
      print("Error al combinar los PDF: $e");
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
                        getInspecciones(nuevoClienteId);
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
