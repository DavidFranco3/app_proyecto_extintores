import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../api/inspeccion_anual.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../Generales/flushbar_helper.dart';
import '../../utils/pdf_utils.dart';
import '../../components/Generales/premium_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GraficaLineas extends StatefulWidget {
  final List<Map<String, dynamic>> encuestaAbierta;

  const GraficaLineas({super.key, required this.encuestaAbierta});

  @override
  State<GraficaLineas> createState() => _GraficaLineasState();
}

class _GraficaLineasState extends State<GraficaLineas> {
  // Función para formatear fechas
  static String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      final localDate = parsedDate.toLocal();
      final dateFormat = DateFormat("EEEE d 'de' MMMM 'de' yyyy", 'es_ES');
      return dateFormat.format(localDate);
    } catch (e) {
      return date;
    }
  }

  // Load logo for PDF
  Future<Uint8List> loadImageFromAssets(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    return byteData.buffer.asUint8List();
  }

  // Asignamos un color distinto para cada pregunta
  Color getColorForPregunta(String pregunta) {
    final colores = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.yellow,
    ];
    // Find index of question in the first dataset
    if (widget.encuestaAbierta.isNotEmpty) {
      final preguntas = widget.encuestaAbierta[0]["datos"] as List;
      final index = preguntas.indexWhere((e) => e['pregunta'] == pregunta);
      if (index != -1) {
        return colores[index % colores.length];
      }
    }
    return Colors.grey;
  }

  PdfColor getPdfColorForPregunta(String pregunta) {
    final color = getColorForPregunta(pregunta);
    return PdfColor.fromInt(color.toARGB32());
  }

  Future<pw.Document> _generatePdfDocument() async {
    final pdf = pw.Document();

    if (widget.encuestaAbierta.isEmpty) return pdf;

    final data = widget.encuestaAbierta[0];
    final preguntas = data["datos"] as List;
    Uint8List? logoBytes;
    try {
      logoBytes = await loadImageFromAssets('lib/assets/img/logo_app.png');
    } catch (e) {
      debugPrint("Error loading logo: $e");
    }

    // We need to find min/max for axes
    double maxY = 0;
    int maxX = 0;

    final List<pw.Dataset> lineBars = [];

    for (var i = 0; i < preguntas.length; i++) {
      final preguntaData = preguntas[i];
      final respuestasString = preguntaData['valores'] as String;
      final respuestas = respuestasString.split(',').map((valor) {
        final v = double.tryParse(valor.trim()) ?? 0;
        return (v.isNaN || v.isInfinite) ? 0.0 : v;
      }).toList();

      if (respuestas.length > maxX) maxX = respuestas.length;

      final points = <pw.PointChartValue>[];
      for (int x = 0; x < respuestas.length; x++) {
        final y = respuestas[x];
        if (y > maxY) maxY = y;
        points.add(pw.PointChartValue(x.toDouble(), y));
      }

      lineBars.add(
        pw.LineDataSet(
          color: getPdfColorForPregunta(preguntaData['pregunta']),
          data: points,
          isCurved: true,
          pointColor: getPdfColorForPregunta(preguntaData['pregunta']),
          drawPoints: true,
        ),
      );
    }

    // Build PDF content
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (logoBytes != null)
                      pw.Image(pw.MemoryImage(logoBytes), width: 120),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                              PdfUtils.removeAccents(
                                  formatDate(data["createdAt"].toString())),
                              style: const pw.TextStyle(fontSize: 10)),
                          pw.Text(
                              PdfUtils.removeAccents(
                                  data["cliente"].toString()),
                              style: const pw.TextStyle(fontSize: 10)),
                        ])
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Legend
              pw.Wrap(
                spacing: 10,
                runSpacing: 5,
                children: preguntas.map((p) {
                  return pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                    pw.Container(
                        width: 10,
                        height: 10,
                        color:
                            getPdfColorForPregunta(p['pregunta'].toString())),
                    pw.SizedBox(width: 4),
                    pw.Text(PdfUtils.removeAccents(p['pregunta'].toString()),
                        style: const pw.TextStyle(fontSize: 10)),
                  ]);
                }).toList(),
              ),

              pw.SizedBox(height: 20),

              // Chart
              pw.SizedBox(
                height: 300,
                child: pw.Chart(
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis(
                        List.generate(maxX < 2 ? 2 : maxX, (index) => index),
                        format: (v) => v.toInt().toString()),
                    yAxis: pw.FixedAxis(
                      [0, 20, 40, 60, 80, 100, if (maxY > 100) maxY],
                    ),
                  ),
                  datasets: lineBars,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> _downloadPdf() async {
    try {
      final pdf = await _generatePdfDocument();
      final outputDirectory = await getExternalStorageDirectory();

      if (outputDirectory != null) {
        final filePath =
            "${outputDirectory.path}/graficos_lineas_${widget.encuestaAbierta[0]["id"]}.pdf";
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());
        debugPrint("PDF guardado en: $filePath");
        await OpenFile.open(filePath);
      }
    } catch (e) {
      debugPrint("Error al guardar y abrir el PDF: $e");
    }
  }

  Future<void> _enviarPdfAlBackend(BuildContext context) async {
    try {
      final pdf = await _generatePdfDocument();
      final outputDirectory = await getExternalStorageDirectory();

      if (outputDirectory != null) {
        final filePath =
            "${outputDirectory.path}/graficos_lineas_${widget.encuestaAbierta[0]["id"]}.pdf";
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        final inspeccionAnualService = InspeccionAnualService();
        var response = await inspeccionAnualService.sendEmail(
            widget.encuestaAbierta[0]["id"], file.path);

        if (!context.mounted) return;
        if (response['status'] == 200) {
          showCustomFlushbar(
            context: context,
            title: "Correo enviado",
            message: "El PDF fue enviado exitosamente al correo del cliente",
            backgroundColor: Colors.green,
          );
        } else {
          showCustomFlushbar(
            context: context,
            title: "Error al enviar el correo",
            message: "Hubo un problema al enviar el PDF por correo",
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      debugPrint('Error al enviar el PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.encuestaAbierta.isEmpty) {
      return const Center(child: Text("No hay datos para mostrar"));
    }

    // We assume we are showing the first one as per original code logic
    final data = widget.encuestaAbierta[0];
    final preguntas = data["datos"] as List;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 40)),
                      bottomTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 30)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData:
                        preguntas.map<LineChartBarData>((preguntaData) {
                      final respuestasString =
                          preguntaData['valores'] as String;
                      final respuestas = respuestasString
                          .split(',')
                          .map((valor) => double.tryParse(valor.trim()) ?? 0)
                          .toList();

                      final spots = respuestas.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value);
                      }).toList();

                      return LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 3,
                        color: getColorForPregunta(preguntaData['pregunta']),
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: false),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  PremiumActionButton(
                    icon: FontAwesomeIcons.filePdf,
                    label: "Generar PDF",
                    onPressed: _downloadPdf,
                  ),
                  PremiumActionButton(
                    icon: FontAwesomeIcons.paperPlane,
                    label: "Enviar PDF",
                    onPressed: () => _enviarPdfAlBackend(context),
                    style: PremiumButtonStyle.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
