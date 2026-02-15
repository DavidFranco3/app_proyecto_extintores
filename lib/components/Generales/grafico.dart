import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart' show rootBundle;

class GraficaBarras extends StatefulWidget {
  final List<Map<String, dynamic>> dataInspecciones;

  const GraficaBarras({super.key, required this.dataInspecciones});

  @override
  State<GraficaBarras> createState() => _GraficaBarrasState();
}

class _GraficaBarrasState extends State<GraficaBarras> {
  // Load logo for PDF
  Future<Uint8List> loadImageFromAssets(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List();
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    // Load generic logo/assets if needed
    Uint8List? logoBytes;
    try {
      logoBytes = await loadImageFromAssets('lib/assets/img/logo_app.png');
    } catch (e) {
      debugPrint("Error loading logo: $e");
    }

    // Split data into chunks to avoid overflow per page (e.g., 4 charts per page)
    const int itemsPerPage = 6;
    for (var i = 0; i < widget.dataInspecciones.length; i += itemsPerPage) {
      final chunk = widget.dataInspecciones.skip(i).take(itemsPerPage).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoBytes != null)
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    margin: const pw.EdgeInsets.only(bottom: 20),
                    child: pw.Image(pw.MemoryImage(logoBytes), width: 100),
                  ),
                pw.Header(
                  level: 0,
                  child: pw.Text("Reporte de Inspecciones",
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                ...chunk.map((item) {
                  final si = (item['si'] ?? 0).toDouble();
                  final no = (item['no'] ?? 0).toDouble();
                  final total = si + no;

                  // Simple Bar representation in PDF
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 15),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(item['pregunta'],
                            style: pw.TextStyle(
                                fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              flex: (si * 100).toInt(),
                              child: si > 0
                                  ? pw.Container(
                                      height: 15,
                                      color: PdfColors.blue,
                                      alignment: pw.Alignment.centerLeft,
                                      child: pw.Padding(
                                        padding:
                                            const pw.EdgeInsets.only(left: 4),
                                        child: pw.Text("Si: ${si.toInt()}",
                                            style: const pw.TextStyle(
                                                color: PdfColors.white,
                                                fontSize: 8)),
                                      ),
                                    )
                                  : pw.Container(),
                            ),
                            pw.Expanded(
                              flex: (no * 100).toInt(),
                              child: no > 0
                                  ? pw.Container(
                                      height: 15,
                                      color: PdfColors.red,
                                      alignment: pw.Alignment.centerLeft,
                                      child: pw.Padding(
                                        padding:
                                            const pw.EdgeInsets.only(left: 4),
                                        child: pw.Text("No: ${no.toInt()}",
                                            style: const pw.TextStyle(
                                                color: PdfColors.white,
                                                fontSize: 8)),
                                      ),
                                    )
                                  : pw.Container(),
                            ),
                            if (total == 0)
                              pw.Text("Sin datos",
                                  style: const pw.TextStyle(
                                      fontSize: 10, color: PdfColors.grey)),
                          ],
                        ),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );
    }

    try {
      final outputDirectory = await getExternalStorageDirectory();
      if (outputDirectory != null) {
        final filePath =
            "${outputDirectory.path}/reporte_graficos_${DateTime.now().millisecondsSinceEpoch}.pdf";
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());
        debugPrint("PDF guardado en: $filePath");
        await OpenFile.open(filePath);
      } else {
        debugPrint("No se pudo obtener el directorio de almacenamiento.");
      }
    } catch (e) {
      debugPrint("Error al guardar y abrir el PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataInspecciones.isEmpty) {
      return const Center(
          child:
              Text("No hay datos disponibles", style: TextStyle(fontSize: 18)));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Exportar PDF"),
                onPressed: _generatePdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: widget.dataInspecciones.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              var preguntaActual = widget.dataInspecciones[index];
              var si = (preguntaActual['si'] ?? 0).toDouble();
              var no = (preguntaActual['no'] ?? 0).toDouble();

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        preguntaActual['pregunta'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (si > no ? si : no) + 1, // Add some headroom
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (val, meta) =>
                                        Text(val.toInt().toString())),
                              ),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    switch (value.toInt()) {
                                      case 0:
                                        return const Text("Sí",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold));
                                      case 1:
                                        return const Text("No",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold));
                                      default:
                                        return Container();
                                    }
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(
                                show: true, drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              BarChartGroupData(
                                x: 0,
                                barRods: [
                                  BarChartRodData(
                                    toY: si,
                                    color: Colors.blue,
                                    width: 40,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6)),
                                  ),
                                ],
                              ),
                              BarChartGroupData(
                                x: 1,
                                barRods: [
                                  BarChartRodData(
                                    toY: no,
                                    color: Colors.red,
                                    width: 40,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6)),
                                  ),
                                ],
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
      ],
    );
  }
}
