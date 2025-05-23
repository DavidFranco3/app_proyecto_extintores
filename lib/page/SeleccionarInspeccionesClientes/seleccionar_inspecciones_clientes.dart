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

void main() => runApp(MaterialApp(home: ClienteInspeccionesApp()));

class ClienteInspeccionesApp extends StatefulWidget {
  @override
  _ClienteInspeccionesAppState createState() => _ClienteInspeccionesAppState();
}

class _ClienteInspeccionesAppState extends State<ClienteInspeccionesApp> {
  bool isLoading = false;
  List<Map<String, dynamic>> dataClientes = [];
  List<Map<String, dynamic>> dataInspecciones = [];
  String? clienteSeleccionado; // ID del cliente
  Map<String, bool> estadosInspecciones = {};

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
      estadosInspecciones = {};
      dataInspecciones = [];
    });

    try {
      final inspeccionesService = InspeccionesService();
      final List<dynamic> response =
          await inspeccionesService.listarInspeccionesPorCliente(idCliente);

      if (response.isNotEmpty) {
        List<Map<String, dynamic>> inspecciones =
            formatModelInspecciones(response);
        setState(() {
          dataInspecciones = inspecciones;
          estadosInspecciones = {
            for (var item in inspecciones) item['id']: false,
          };
        });
      } else {
        setState(() {
          dataInspecciones = [];
          estadosInspecciones = {};
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
              'idUsuario': item['idUsuario'],
              'idCliente': item['idCliente'],
              'idEncuesta': item['idEncuesta'],
              'encuesta': item['encuesta'],
              'imagenes': item['imagenes'],
              'comentarios': item['comentarios'],
              'usuario': item['usuario']['nombre'],
              'cliente': item['cliente']['nombre'],
              'imagen_cliente': item['cliente']['imagen'],
              'firma_usuario': item['usuario']['firma'],
              'cuestionario': item['cuestionario']['nombre'],
              'frecuencia': item['cuestionario']['frecuencia']['nombre'],
              'usuarios': item['usuario'],
              'estado': item['estado'],
              'createdAt': item['createdAt'],
              'updatedAt': item['updatedAt'],
            })
        .toList();
  }

  Future<void> handleDownloadMultiplePDFs() async {
    setState(() => isLoading = true);

    final inspeccionesService = InspeccionesService();
    final dio = Dio();
    final tempDir = await getTemporaryDirectory();

    try {
      List<String> pdfPaths = [];

      for (var inspeccion in dataInspecciones) {
        if (estadosInspecciones[inspeccion['id']] == true) {
          String url = inspeccionesService.urlDownloadPDF(inspeccion["id"]);
          if (url.isEmpty) continue;

          String tempPath = "${tempDir.path}/temp_${inspeccion["id"]}.pdf";

          // Descargar el PDF individual
          await dio.download(url, tempPath);
          pdfPaths.add(tempPath);
        }
      }

      if (pdfPaths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se seleccionaron inspecciones.')),
        );
        return;
      }

      // Crear un documento PDF vacío para combinar
      PdfDocument outputDocument = PdfDocument();

      for (String path in pdfPaths) {
        // Leer cada PDF descargado
        List<int> bytes = await File(path).readAsBytes();
        PdfDocument inputDocument = PdfDocument(inputBytes: bytes);

        // Importar todas las páginas del PDF actual al documento de salida
        for (int i = 0; i < inputDocument.pages.count; i++) {
          final template = inputDocument.pages[i].createTemplate();
          final templateSize = template.size;

          final newPage = outputDocument.pages.add();
          final graphics = newPage.graphics;
          final pageSize = newPage.getClientSize();

          // Centrado horizontal y margen superior personalizado
          final dx = (pageSize.width - templateSize.width) / 2;
          final topMargin =
              18; // Puedes ajustar este valor si quieres más o menos espacio
          final dy = ((pageSize.height - templateSize.height) / 2) - topMargin;

          graphics.drawPdfTemplate(
              template, Offset(dx, dy.clamp(0, double.infinity)));
        }

        inputDocument.dispose();
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final finalPath = "${appDocDir.path}/Inspecciones_Unidas.pdf";

      // Guardar el PDF combinado en archivo
      List<int> bytes = await outputDocument.save();
      File(finalPath).writeAsBytesSync(bytes);
      outputDocument.dispose();

      print("PDF combinado guardado en: $finalPath");
      OpenFile.open(finalPath);
    } catch (e) {
      print("Error al combinar los PDF: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Seleccionar actividad"),
      body: isLoading
          ? Load()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Center(
                    child: DropdownButton<String>(
                      hint: Text('Selecciona un cliente'),
                      value: clienteSeleccionado,
                      onChanged: (nuevoClienteId) {
                        setState(() {
                          clienteSeleccionado = nuevoClienteId;
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
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: clienteSeleccionado != null &&
                            dataInspecciones.isNotEmpty
                        ? Scrollbar(
                            child: ListView.builder(
                              itemCount: dataInspecciones.length,
                              itemBuilder: (context, index) {
                                final inspeccion = dataInspecciones[index];
                                return CheckboxListTile(
                                  title: Text(inspeccion['cuestionario'] + "-" + inspeccion['frecuencia']),
                                  value:
                                      estadosInspecciones[inspeccion['id']] ??
                                          false,
                                  onChanged: (nuevoValor) {
                                    setState(() {
                                      estadosInspecciones[inspeccion['id']] =
                                          nuevoValor!;
                                    });
                                  },
                                );
                              },
                            ),
                          )
                        : SizedBox(),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                      onPressed: handleDownloadMultiplePDFs,
                      child: Text('Descargar PDF combinado'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
