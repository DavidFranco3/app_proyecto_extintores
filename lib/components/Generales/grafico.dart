import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart'; // Necesario para RenderRepaintBoundary
import 'package:flutter/services.dart'; // Importante para ImageByteFormat

class GraficaBarras extends StatefulWidget {
  final List<Map<String, dynamic>> dataInspecciones;

  GraficaBarras({required this.dataInspecciones});

  @override
  _GraficaBarrasState createState() => _GraficaBarrasState();
}

class _GraficaBarrasState extends State<GraficaBarras> {
  late PageController _pageController;
  int paginaActual = 0;
  GlobalKey _repaintKey = GlobalKey();

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

  // Método para capturar el gráfico como imagen
  Future<Uint8List> _captureImage() async {
    RenderRepaintBoundary boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png); // Aquí usamos ImageByteFormat.png
    return byteData!.buffer.asUint8List();
  }

  // Método para guardar el PDF
  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    // Capturar la imagen del gráfico
    final image = await _captureImage();

    // Obtener directorio de documentos
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/grafica.pdf");

    // Crear el PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(
              pw.MemoryImage(image),
            ),
          );
        },
      ),
    );

    // Guardar el PDF
    await file.writeAsBytes(await pdf.save());
    print("PDF guardado en: ${file.path}");
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
                var si = preguntaActual['si'];
                var no = preguntaActual['no'];

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 70,
                              getTitlesWidget: (value, meta) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: SizedBox(
                                    width: 250,
                                    child: Text(
                                      preguntaActual['pregunta'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(toY: si.toDouble(), color: Colors.blue),
                              BarChartRodData(toY: no.toDouble(), color: Colors.red),
                            ],
                          ),
                        ],
                      ),
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
        ],
      ),
    );
  }
}
