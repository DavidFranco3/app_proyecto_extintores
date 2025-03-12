import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/rendering.dart';  // ← ESTE IMPORT ES IMPORTANTE
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class GraficaBarras extends StatefulWidget {
  final List<Map<String, dynamic>> dataInspecciones;

  GraficaBarras({required this.dataInspecciones});

  @override
  _GraficaBarrasState createState() => _GraficaBarrasState();
}

class _GraficaBarrasState extends State<GraficaBarras> {
  late PageController _pageController;
  int paginaActual = 0;
  GlobalKey _chartKey = GlobalKey(); // Clave para capturar el gráfico como imagen

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: paginaActual);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _captureChart() async {
    RenderRepaintBoundary? boundary =
        _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }
    return null;
  }

Future<void> _generatePdf() async {
  final pdf = pw.Document();

  for (var i = 0; i < widget.dataInspecciones.length; i++) {
    setState(() {
      paginaActual = i;
    });

    await Future.delayed(Duration(milliseconds: 500)); // Esperar a que se renderice el gráfico

    Uint8List? chartImage = await _captureChart();
    if (chartImage != null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Container(
                width: PdfPageFormat.a4.width * 0.9, // Ajusta al 90% del ancho de la página
                height: PdfPageFormat.a4.height * 0.7, // Ajusta el alto para ocupar más espacio
                alignment: pw.Alignment.center,
                child: pw.Image(
                  pw.MemoryImage(chartImage),
                  fit: pw.BoxFit.contain, // Ajusta la imagen sin recortar
                ),
              ),
            );
          },
        ),
      );
    }
  }

  try {
    // Obtener el directorio donde guardar el archivo
    final outputDirectory = await getExternalStorageDirectory();
    if (outputDirectory != null) {
      // Definir el path donde se guardará el archivo
      final filePath = "${outputDirectory.path}/graficos.pdf";

      // Guardar el archivo en el dispositivo
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      print("PDF guardado en: $filePath");

      // Abrir el PDF con el visor predeterminado
      await OpenFile.open(filePath);
    } else {
      print("No se pudo obtener el directorio de almacenamiento.");
    }
  } catch (e) {
    print("Error al guardar y abrir el PDF: $e");
  }
}



  @override
  Widget build(BuildContext context) {
    if (widget.dataInspecciones.isEmpty) {
      return Scaffold(
        body: Center(child: Text("No hay datos disponibles", style: TextStyle(fontSize: 18))),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.dataInspecciones.length,
              onPageChanged: (index) {
                setState(() {
                  paginaActual = index;
                });
              },
              itemBuilder: (context, index) {
                var preguntaActual = widget.dataInspecciones[index];
                var si = (preguntaActual['si'] ?? 0).toDouble();
                var no = (preguntaActual['no'] ?? 0).toDouble();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RepaintBoundary(
                    key: _chartKey, // Clave para capturar la imagen
                    child: Column(
                      children: [
                        Text(
                          preguntaActual['pregunta'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return Text("Sí", style: TextStyle(fontSize: 14));
                                        case 1:
                                          return Text("No", style: TextStyle(fontSize: 14));
                                        default:
                                          return Container();
                                      }
                                    },
                                  ),
                                ),
                              ),
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [BarChartRodData(toY: si, color: Colors.blue)],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [BarChartRodData(toY: no, color: Colors.red)],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, size: 30),
                onPressed: paginaActual > 0
                    ? () {
                        _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward, size: 30),
                onPressed: paginaActual < widget.dataInspecciones.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.picture_as_pdf),
            label: Text("Generar PDF"),
            onPressed: _generatePdf, // Generar PDF
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
