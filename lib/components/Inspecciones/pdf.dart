import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart'; // For BuildContext, Colors
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

import '../../api/inspecciones.dart'; // Import service
import '../Generales/flushbar_helper.dart'; // Import flushbar
import '../../utils/pdf_utils.dart';
import '../../utils/pdf_theme.dart';
import '../Common/pdf_components.dart';

class PdfGenerator {
  // Private method to generate PDF bytes
  static Future<Uint8List> _generatePdfBytes(Map<String, dynamic> data) async {
    final pdf = pw.Document(theme: PdfTheme.theme);

    // --- 1. Load Local Assets ---
    final Future<Uint8List> logoNfpaFuture =
        PdfUtils.loadAssetImage('lib/assets/img/logo_nfpa.png');
    final Future<Uint8List> logoAppFuture =
        PdfUtils.loadAssetImage('lib/assets/img/logo_app.png');
    final Future<Uint8List> formulaImgFuture =
        PdfUtils.loadAssetImage('lib/assets/img/formula.png');
    final Future<Uint8List> certificadoImgFuture =
        PdfUtils.loadAssetImage('lib/assets/img/certificado.png');

    // --- 2. Download Remote Images (Parallel) ---
    final imagenes = data['imagenes'] as List<dynamic>;
    final imagenesFinales = data['imagenes_finales'] as List<dynamic>? ?? [];

    // Helper to safely get image data
    Future<Uint8List?> getImg(List<dynamic> list, int index) async {
      if (index < list.length) {
        return PdfUtils.downloadImage(list[index]['sharedLink']);
      }
      return null;
    }

    // Helper to safely get comment
    String getComment(List<dynamic> list, int index) {
      if (index < list.length) {
        return list[index]['comentario'] ?? 'Sin comentario';
      }
      return 'Sin comentario';
    }

    // Helper to safely get value (valor)
    double getValue(List<dynamic> list, int index) {
      if (index < list.length) {
        final val = list[index]['valor'];
        double? result;
        if (val is num) result = val.toDouble();
        if (val is String) result = double.tryParse(val);

        if (result != null && !result.isNaN && result >= 0) {
          return result;
        }
      }
      return 0.0;
    }

    final logoClienteFuture = PdfUtils.downloadImage(data['imagen_cliente']);
    final firmaFuture = PdfUtils.downloadImage(data["firma_usuario"]);

    // Wait for all essential assets
    final results = await Future.wait([
      logoNfpaFuture, // 0
      logoAppFuture, // 1
      formulaImgFuture, // 2
      certificadoImgFuture, // 3
      logoClienteFuture, // 4
      firmaFuture, // 5
    ]);

    final logoNfpa = results[0]!;
    final logoApp = results[1]!;
    final formulaImg = results[2]!;
    final certificadoImg = results[3]!;
    final logoCliente = results[4] ?? Uint8List(0);
    final firma = results[5] ?? Uint8List(0);

    // Download content images
    List<Uint8List?> contentImages =
        await Future.wait(List.generate(7, (i) => getImg(imagenes, i)));

    List<Uint8List?> finalImages =
        await Future.wait(List.generate(3, (i) => getImg(imagenesFinales, i)));

    // --- 3. Calculations ---
    final val3 = getValue(imagenes, 2);
    final val4 = getValue(imagenes, 3);
    final val5 = getValue(imagenes, 4);
    final val6 = getValue(imagenes, 5);
    final val7 = getValue(imagenes, 6); // Pressure residual

    // Safe sqrt helper
    double safeSqrt(double val) => (val <= 0 || val.isNaN) ? 0 : sqrt(val);

    final double caudal1 = 129.84 * 0.95 * pow(0.5, 2) * safeSqrt(val3);
    final double caudal2 = 129.84 * 0.95 * pow(0.5, 2) * safeSqrt(val4);
    final double caudal3 = 129.84 * 0.95 * pow(0.5, 2) * safeSqrt(val5);
    final double caudal4 = 129.84 * 0.95 * pow(0.5, 2) * safeSqrt(val6);
    final double sumaCaudales = caudal1 + caudal2 + caudal3 + caudal4;

    // Helper for safe formatting
    String formatDouble(double val) {
      if (val.isNaN || val.isInfinite) return '0.00';
      return val.toStringAsFixed(2);
    }

    // --- 4. Build PDF ---

    // Page 1
    pdf.addPage(
      pw.Page(
        theme: PdfTheme.theme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfComponents.buildHeader(
                  logoBytes: logoCliente, logoIsoBytes: logoNfpa),
              pw.SizedBox(height: 10),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  PdfUtils.removeAccents(
                      '${PdfUtils.capitalizeWords(data["municipio"] ?? "")}, ${PdfUtils.capitalizeWords(data["estadoDom"] ?? "")} a ${PdfUtils.formatDate(data["createdAt"] ?? "")}'),
                  style: PdfTheme.bodyStyle,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                  PdfUtils.removeAccents('Atn: ${data["responsableCliente"]}'),
                  style: PdfTheme.bodyStyle
                      .copyWith(fontWeight: pw.FontWeight.bold)),
              pw.Text(PdfUtils.removeAccents(data["puestoCliente"] ?? ""),
                  style: PdfTheme.bodyStyle),
              pw.Text(PdfUtils.removeAccents(data["cliente"] ?? ""),
                  style: PdfTheme.bodyStyle
                      .copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Row(children: [
                pw.Text('Asunto: ',
                    style: PdfTheme.bodyStyle
                        .copyWith(fontWeight: pw.FontWeight.bold)),
                pw.Text('Reporte de opinión técnica.',
                    style: PdfTheme.bodyStyle),
              ]),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  "PRUEBA DE CAUDAL MANGUERA DE 1½ x 30 M (HIDRANTE CLASE II)",
                  style: PdfTheme.titleStyle.copyWith(fontSize: 14),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: PdfTheme.bodyStyle.copyWith(fontSize: 12),
                  children: [
                    pw.TextSpan(
                        text:
                            "Dando cumplimiento, tanto a lo especificado en "),
                    pw.TextSpan(
                        text:
                            "NFPA 24 Standard for the Installation of Private Fire Service Mains",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: " y "),
                    pw.TextSpan(
                        text:
                            "NFPA 25 Standard for the Inspection, Testing, and Maintenance of Water-Based Fire Protection Systems,",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(
                        text:
                            " como a lo solicitado por el departamento de Protección Civil, el día "),
                    pw.TextSpan(
                        text: PdfUtils.formatDate(data["createdAt"]),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(
                        text: PdfUtils.removeAccents(
                            " se realizó una prueba de caudal al sistema contra incendio instalado actualmente en la empresa ${data["cliente"]}, la prueba se realizó en la manguera de 1½ x 30 m más alejada al punto de alimentación del sistema.")),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: PdfTheme.bodyStyle.copyWith(fontSize: 12),
                  children: [
                    pw.TextSpan(
                        text:
                            "La prueba consistió en la medición de la presión de velocidad, mediante un tubo Pitot "),
                    pw.TextSpan(
                        text:
                            "diseñado específicamente para la medición de caudal, tomada en la salida de las descargas del "),
                    pw.TextSpan(
                        text:
                            "cabezal de pruebas (Figura 1) suministrado por "),
                    pw.TextSpan(
                        text: "AGGO Fire Consultant ",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(
                        text:
                            "el cual divide el caudal en cuatro salidas para posteriormente reducir el diámetro de cada descarga "),
                    pw.TextSpan(
                        text:
                            "a un orificio de ½ de diámetro con el objetivo de hacer mediciones más precisas y exactas."),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              if (contentImages[0] != null)
                pw.Center(
                    child: pw.Image(pw.MemoryImage(contentImages[0]!),
                        height: 250, fit: pw.BoxFit.contain)),
              pw.SizedBox(height: 5),
              pw.Center(
                  child: pw.Text(getComment(imagenes, 0),
                      style: PdfTheme.bodyStyle)),
              pw.Spacer(),
              PdfComponents.buildFooter(
                  logoAppBytes: logoApp, pageNumber: 1, totalPages: 5),
            ],
          );
        },
      ),
    );

    // Page 2
    pdf.addPage(
      pw.Page(
        theme: PdfTheme.theme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfComponents.buildHeader(
                  logoBytes: logoCliente, logoIsoBytes: logoNfpa),
              pw.SizedBox(height: 10),
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: PdfTheme.bodyStyle.copyWith(fontSize: 12),
                  children: [
                    pw.TextSpan(
                        text:
                            "El manómetro del tubo Pitot se encuentra dentro de la vigencia de la calibración del mismo ya que su última calibración se realizó el ${data["calibracion"] ?? data["createdAt"] ?? ""} (Figura 2). "),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              if (contentImages[1] != null)
                pw.Center(
                    child: pw.Image(pw.MemoryImage(contentImages[1]!),
                        height: 300, fit: pw.BoxFit.contain)),
              pw.SizedBox(height: 5),
              pw.Center(
                  child: pw.Text(getComment(imagenes, 1),
                      style: PdfTheme.bodyStyle)),
              pw.SizedBox(height: 12),
              pw.Text(
                  "La presión de velocidad registrada con el tubo Pitot se convierte en caudal mediante la siguiente formula: ",
                  style: PdfTheme.bodyStyle.copyWith(fontSize: 12)),
              pw.SizedBox(height: 12),
              pw.Image(pw.MemoryImage(formulaImg),
                  height: 100, fit: pw.BoxFit.contain),
              pw.Spacer(),
              PdfComponents.buildFooter(
                  logoAppBytes: logoApp, pageNumber: 2, totalPages: 5),
            ],
          );
        },
      ),
    );

    // Page 3
    pdf.addPage(pw.Page(
        theme: PdfTheme.theme,
        build: (context) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfComponents.buildHeader(
                    logoBytes: logoCliente, logoIsoBytes: logoNfpa),
                pw.SizedBox(height: 10),
                pw.RichText(
                  textAlign: pw.TextAlign.justify,
                  text: pw.TextSpan(
                    style: PdfTheme.bodyStyle.copyWith(fontSize: 12),
                    children: [
                      pw.TextSpan(
                          text: "De acuerdo a la sección C.4.7.2 de la "),
                      pw.TextSpan(
                          text:
                              "NFPA 24 Standard for the Installation of Private Fire Service Mains and Their Appurtenances",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.TextSpan(
                          text:
                              ", en caso de utilizar un Stream Straightener, el coeficiente de descarga C sugerido es 0.95."),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                    "Por lo tanto, los resultados de la prueba quedan de la siguiente forma: ",
                    style: PdfTheme.bodyStyle.copyWith(fontSize: 12)),
                pw.SizedBox(height: 10),

                // Table
                pw.Table(
                    border:
                        pw.TableBorder.all(color: PdfColors.black, width: 1),
                    children: [
                      // Header
                      pw.TableRow(
                          decoration:
                              pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            _paddedText('Descarga', bold: true),
                            _paddedText('Coeficiente\nde descarga', bold: true),
                            _paddedText('Diametro\n(in)', bold: true),
                            _paddedText('Presión de\nvelocidad (psi)',
                                bold: true),
                            _paddedText('Caudal\n(gpm)', bold: true),
                          ]),
                      // Rows
                      _buildDataRow('1', '0.95', '½', '$val3 (Figura 3)',
                          formatDouble(caudal1)),
                      _buildDataRow('1', '0.95', '½', '$val4 (Figura 4)',
                          formatDouble(caudal2)),
                      _buildDataRow('1', '0.95', '½', '$val5 (Figura 5)',
                          formatDouble(caudal3)),
                      _buildDataRow('1', '0.95', '½', '$val6 (Figura 6)',
                          formatDouble(caudal4)),
                      // Total
                      pw.TableRow(
                          decoration:
                              pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
                            pw.SizedBox(),
                            pw.SizedBox(),
                            pw.SizedBox(),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(8),
                              child: pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text('Total:',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10)),
                              ),
                            ),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(8),
                              child: pw.Text(formatDouble(sumaCaudales),
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10)),
                            ),
                          ]),
                    ]),

                pw.SizedBox(height: 10),

                // Images Grid for Page 3
                pw.Row(children: [
                  if (contentImages[2] != null)
                    pw.Expanded(
                        child: pw.Column(children: [
                      pw.Image(pw.MemoryImage(contentImages[2]!),
                          height: 110, fit: pw.BoxFit.contain),
                      pw.Text(getComment(imagenes, 2),
                          style: PdfTheme.bodyStyle),
                    ])),
                  if (contentImages[3] != null)
                    pw.Expanded(
                        child: pw.Column(children: [
                      pw.Image(pw.MemoryImage(contentImages[3]!),
                          height: 110, fit: pw.BoxFit.contain),
                      pw.Text(getComment(imagenes, 3),
                          style: PdfTheme.bodyStyle),
                    ])),
                ]),
                pw.SizedBox(height: 5),
                pw.Row(children: [
                  if (contentImages[4] != null)
                    pw.Expanded(
                        child: pw.Column(children: [
                      pw.Image(pw.MemoryImage(contentImages[4]!),
                          height: 110, fit: pw.BoxFit.contain),
                      pw.Text(getComment(imagenes, 4),
                          style: PdfTheme.bodyStyle),
                    ])),
                  if (contentImages[5] != null)
                    pw.Expanded(
                        child: pw.Column(children: [
                      pw.Image(pw.MemoryImage(contentImages[5]!),
                          height: 110, fit: pw.BoxFit.contain),
                      pw.Text(getComment(imagenes, 5),
                          style: PdfTheme.bodyStyle),
                    ])),
                ]),

                pw.Spacer(),
                PdfComponents.buildFooter(
                    logoAppBytes: logoApp, pageNumber: 3, totalPages: 5),
              ]);
        }));

    // Page 4
    pdf.addPage(pw.Page(
        theme: PdfTheme.theme,
        build: (context) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfComponents.buildHeader(
                    logoBytes: logoCliente, logoIsoBytes: logoNfpa),
                pw.SizedBox(height: 10),
                pw.Text("RESUMEN DE PRUEBA CAUDAL",
                    style: PdfTheme.titleStyle.copyWith(fontSize: 14)),
                pw.SizedBox(height: 12),
                pw.Table(
                    border:
                        pw.TableBorder.all(color: PdfColors.black, width: 1),
                    children: [
                      pw.TableRow(
                          decoration:
                              pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            _paddedText('Descripcion', bold: true),
                            _paddedText('Parámetro de referencia mínimo',
                                bold: true),
                            _paddedText('Resultado de la prueba', bold: true),
                          ]),
                      pw.TableRow(children: [
                        _paddedText('Caudal'),
                        _paddedText('100 gpm'),
                        _paddedText('${formatDouble(sumaCaudales)} gpm')
                      ]),
                      pw.TableRow(children: [
                        _paddedText('Presión residual'),
                        _paddedText('65 psi'),
                        _paddedText('$val7 psi (Figura 7)')
                      ]),
                    ]),
                pw.SizedBox(height: 12),
                if (contentImages[6] != null)
                  pw.Center(
                      child: pw.Image(pw.MemoryImage(contentImages[6]!),
                          height: 350, fit: pw.BoxFit.contain)),
                pw.SizedBox(height: 5),
                pw.Center(
                    child: pw.Text(getComment(imagenes, 6),
                        style: PdfTheme.bodyStyle)),
                pw.Spacer(),
                PdfComponents.buildFooter(
                    logoAppBytes: logoApp, pageNumber: 4, totalPages: 5),
              ]);
        }));

    // Page 5
    pdf.addPage(pw.Page(
        theme: PdfTheme.theme,
        build: (context) {
          return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfComponents.buildHeader(
                    logoBytes: logoCliente, logoIsoBytes: logoNfpa),
                pw.SizedBox(height: 10),
                pw.RichText(
                  textAlign: pw.TextAlign.justify,
                  text: pw.TextSpan(
                    style: PdfTheme.bodyStyle.copyWith(fontSize: 12),
                    children: [
                      pw.TextSpan(
                          text: PdfUtils.removeAccents(
                              "De acuerdo a la revisión y a la prueba realizada al sistema contra incendio de la empresa ${data["cliente"]}, se concluye que, ")),
                      pw.TextSpan(
                          text: "SI CUMPLE ",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.TextSpan(
                          text: "con los parámetros mínimos especificados en "),
                      pw.TextSpan(
                          text:
                              "NFPA 25 Standard for the Inspection, Testing, and Maintenance of WaterBased Fire Protection Systems",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Center(
                    child: pw.Image(pw.MemoryImage(certificadoImg),
                        height: 300, fit: pw.BoxFit.contain)),
                pw.SizedBox(height: 12),
                pw.Text(
                    "Sin más por el momento me despido de usted, agradeciendo las atenciones dadas a la presente. ",
                    style: PdfTheme.bodyStyle.copyWith(fontSize: 12),
                    textAlign: pw.TextAlign.justify),
                pw.SizedBox(height: 20),
                pw.Center(
                    child: pw.Text("Atentamente", style: PdfTheme.bodyStyle)),
                if (firma.isNotEmpty)
                  pw.Center(
                      child: pw.Image(pw.MemoryImage(firma),
                          height: 80, fit: pw.BoxFit.contain)),
                pw.Center(
                    child: pw.Text(
                        PdfUtils.removeAccents(data["usuario"] ?? ""),
                        style: PdfTheme.bodyStyle
                            .copyWith(fontWeight: pw.FontWeight.bold))),
                pw.Center(
                    child: pw.Text(
                        PdfUtils.removeAccents("AGGO Fire Consultant"),
                        style: PdfTheme.bodyStyle)),
                pw.Spacer(),
                PdfComponents.buildFooter(
                    logoAppBytes: logoApp, pageNumber: 5, totalPages: 5),
              ]);
        }));

    // Final certificate images pages
    for (var fImg in finalImages) {
      if (fImg != null) {
        pdf.addPage(pw.Page(
            build: (context) => pw.Center(
                child:
                    pw.Image(pw.MemoryImage(fImg), fit: pw.BoxFit.contain))));
      }
    }

    return pdf.save();
  }

  // Helper method: Guardar PDF (Renamed from generatePDF to match legacy call signature)
  static Future<void> guardarPDF(Map<String, dynamic> data) async {
    try {
      final bytes = await _generatePdfBytes(data);

      final outputDirectory = await getExternalStorageDirectory();
      if (outputDirectory != null) {
        final filePath =
            "${outputDirectory.path}/${data["cliente"]}_$dateStr-Cer.pdf";
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        debugPrint("PDF Saved: $filePath");
        await OpenFile.open(filePath);
      }
    } catch (e) {
      debugPrint("Error saving PDF: $e");
    }
  }

  // New method: Enviar PDF al Backend
  static Future<void> enviarPdfAlBackend(
      BuildContext context, Map<String, dynamic> data) async {
    try {
      final bytes = await _generatePdfBytes(data);
      final outputDirectory = await getExternalStorageDirectory();

      if (outputDirectory != null) {
        final filePath =
            "${outputDirectory.path}/${data["cliente"]}_$dateStr-Cer.pdf";
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        final inspeccionesService = InspeccionesService();
        // Using sendEmail2 which accepts a file path, as verified in api/inspecciones.dart
        var response =
            await inspeccionesService.sendEmail2(data["id"], file.path);

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
      debugPrint('Error sending PDF: $e');
      showCustomFlushbar(
        context: context,
        title: "Error",
        message: "Error al generar o enviar el PDF: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  static String get dateStr => PdfUtils.formatDateShort(DateTime.now());

  static pw.Widget _paddedText(String text, {bool bold = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : null)),
    );
  }

  static pw.TableRow _buildDataRow(
      String col1, String col2, String col3, String col4, String col5) {
    return pw.TableRow(children: [
      _paddedText(col1),
      _paddedText(col2),
      _paddedText(col3),
      _paddedText(col4),
      _paddedText(col5),
    ]);
  }
}
