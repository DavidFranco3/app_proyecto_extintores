import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../api/inspeccion_anual.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../Generales/flushbar_helper.dart';

class GraficaLineas extends StatefulWidget {
  final List<Map<String, dynamic>> encuestaAbierta;

  const GraficaLineas({super.key, required this.encuestaAbierta});

  @override
  State<GraficaLineas> createState() => _GraficaLineasState();
}

class _GraficaLineasState extends State<GraficaLineas> {
  late PageController _pageController;
  int paginaActual = 0;
  final GlobalKey _chartKey =
      GlobalKey(); // Clave para capturar el gráfico como imagen

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

  // Función para formatear fechas
  static String formatDate(String date) {
    // Parseamos la fecha guardada en la base de datos
    final parsedDate = DateTime.parse(date);

    // Convertimos la fecha a la hora local
    final localDate = parsedDate.toLocal();

    // Configuramos la localización a español
    final dateFormat = DateFormat("EEEE d 'de' MMMM 'de' yyyy",
        'es_ES'); // Día de la semana, día, mes, año en español

    // Formateamos la fecha y la devolvemos
    return dateFormat.format(localDate);
  }

  Future<Uint8List?> _captureChart() async {
    RenderRepaintBoundary? boundary =
        _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }
    return null;
  }

  static Future<Uint8List> loadImageFromAssets(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);

    // Convertir List<int> a Uint8List
    return Uint8List.fromList(byteData.buffer.asUint8List());
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();

    for (var i = 0; i < 1; i++) {
      setState(() {
        paginaActual = i;
      });

      await Future.delayed(
          Duration(milliseconds: 500)); // Esperar a que se renderice el gráfico

      Uint8List? chartImage = await _captureChart();

      final preguntas = widget.encuestaAbierta[0]["datos"];
      final Map<String, PdfColor> leyendaColores = {
        for (var pregunta in preguntas)
          pregunta['pregunta']: PdfColor.fromInt(
              getColorForPregunta(pregunta['pregunta']).toARGB32())
      };

      final imageBytes000 =
          await loadImageFromAssets('lib/assets/img/logo_app.png');

      if (chartImage != null) {
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(
                        pw.MemoryImage(imageBytes000),
                        width:
                            150, // Ajusta al tamaño deseado de la imagen con "00"
                        height: 40, // Altura fija
                      ),
                      pw.Text(
                        formatDate(widget.encuestaAbierta[0]
                            ["createdAt"]), // <-- sin ${}
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign
                            .center, // <-- esto alinea al centro, no a la izquierda
                      ),
                      pw.Text(
                        widget.encuestaAbierta[0]["cliente"], // <-- sin ${}
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign
                            .center, // <-- esto alinea al centro, no a la izquierda
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                ...leyendaColores.entries.map((entry) => pw.Row(
                      children: [
                        pw.Container(
                          width: 20,
                          height: 20,
                          color: entry.value,
                        ),
                        pw.SizedBox(width: 10),
                        pw.Text(entry.key, style: pw.TextStyle(fontSize: 14)),
                      ],
                    )),
                pw.SizedBox(height: 20),
              ],
            ),
          ),
        );

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Image(
                          pw.MemoryImage(imageBytes000),
                          width: 150, // Tamaño deseado
                          height: 40,
                        ),
                        pw.Text(
                          formatDate(widget.encuestaAbierta[0]["createdAt"]),
                          style: pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.Text(
                          widget.encuestaAbierta[0]["cliente"],
                          style: pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10), // Espaciado opcional
                  pw.Image(
                    pw.MemoryImage(chartImage),
                    width: 450, // Puedes ajustar el tamaño aquí si es necesario
                    fit: pw.BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return pdf;
  }

  Future<void> _downloadPdf() async {
    try {
      final pdf =
          await _generatePdf(); // Ahora sí, el documento que acabas de generar

      final outputDirectory = await getExternalStorageDirectory();
      if (outputDirectory != null) {
        final filePath =
            "${outputDirectory.path}/graficos_lineas_${widget.encuestaAbierta[0]["id"]}.pdf";

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

  Future<void> _enviarPdfAlBackend(BuildContext context) async {
    try {
      final pdf = await _generatePdf(); // Ahora sí, documento listo

      final outputDirectory = await getExternalStorageDirectory();
      if (outputDirectory != null) {
        final filePath =
            "${outputDirectory.path}/graficos_lineas_${widget.encuestaAbierta[0]["id"]}.pdf";

        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        final inspeccionAnualService = InspeccionAnualService();
        var response = await inspeccionAnualService.sendEmail(
            widget.encuestaAbierta[0]["id"], file.path);

        debugPrint(response.toString());

        if (response['status'] == 200) {
          if (mounted) {
            showCustomFlushbar(
            context: context,
            title: "Correo enviado",
            message: "El PDF fue enviado exitosamente al correo del cliente",
            backgroundColor: Colors.green,
          );
          }
        } else {
          if (mounted) {
            showCustomFlushbar(
            context: context,
            title: "Error al enviar el correo",
            message: "Hubo un problema al enviar el PDF por correo",
            backgroundColor: Colors.red,
          );
          }
        }
      }
    } catch (e) {
      debugPrint('Error al enviar el PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Envuelve todo el contenido con un SingleChildScrollView
          child: Column(
            children: [
              // RepaintBoundary solo alrededor del gráfico
              RepaintBoundary(
                key: _chartKey, // Clave para capturar la imagen
                child: SizedBox(
                  // Usamos SizedBox para controlar el tamaño del gráfico
                  height: MediaQuery.of(context).size.height *
                      0.6, // Ajustamos la altura
                  child: LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                      ),
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                      lineBarsData: widget.encuestaAbierta[0]["datos"]
                          .map<LineChartBarData>((preguntaData) {
                        final respuestasString =
                            preguntaData['valores'] as String;

                        // Convertimos el string "80,50" => [80.0, 50.0]
                        final respuestas = respuestasString
                            .split(',')
                            .map((valor) => double.tryParse(valor.trim()) ?? 0)
                            .toList();

                        // Generamos los FlSpot para cada respuesta
                        final spots = respuestas.asMap().entries.map((entry) {
                          final index = entry.key.toDouble(); // X
                          final valor = entry.value; // Y
                          return FlSpot(index, valor);
                        }).toList();

                        return LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 3,
                          color: getColorForPregunta(preguntaData['pregunta']),
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(show: false),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Botón para generar PDF (No está dentro de RepaintBoundary, por lo que no se incluye en la captura)
              ElevatedButton.icon(
                icon: Icon(Icons.picture_as_pdf),
                label: Text("Generar PDF"),
                onPressed: () => _downloadPdf(), // Generar PDF
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),

              ElevatedButton.icon(
                icon: Icon(Icons.picture_as_pdf),
                label: Text("Enviar PDF"),
                onPressed: () => _enviarPdfAlBackend(context), // Generar PDF
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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
    final index = widget.encuestaAbierta[0]["datos"]
        .indexWhere((e) => e['pregunta'] == pregunta);
    return colores[index % colores.length];
  }
}


