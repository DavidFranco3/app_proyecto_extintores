import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart'; // For BuildContext, Colors
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

import '../../api/inspecciones.dart';
import '../Generales/flushbar_helper.dart';
import '../../utils/pdf_utils.dart';
import '../../utils/pdf_theme.dart';
import '../Common/pdf_components.dart';

class GenerarPdfPage4 {
  static Future<Uint8List> _generatePdfBytes(Map<String, dynamic> data) async {
    final pdf = pw.Document(theme: PdfTheme.theme);

    // --- 1. Load Assets ---
    final logoNfpaFuture =
        PdfUtils.loadAssetImage('lib/assets/img/logo_nfpa.png');
    final logoAppFuture =
        PdfUtils.loadAssetImage('lib/assets/img/logo_app.png');
    final logoClienteFuture = PdfUtils.downloadImage(data['imagen_cliente']);

    final results =
        await Future.wait([logoNfpaFuture, logoAppFuture, logoClienteFuture]);
    final logoNfpa = results[0] ?? Uint8List(0);
    final logoApp = results[1] ?? Uint8List(0);
    final logoCliente = results[2] ?? Uint8List(0);

    // --- 2. Process Items ---
    final List<dynamic> inspecciones = data['inspeccion_eficiencias'] ?? [];

    // Download images for each item in parallel
    final List<Uint8List?> itemImages = await Future.wait(
        inspecciones.map((item) => PdfUtils.downloadImage(item['imagen'])));

    // --- 3. Build Pages ---
    for (int i = 0; i < inspecciones.length; i++) {
      final item = inspecciones[i];
      final imageBytes = itemImages[i];

      pdf.addPage(pw.Page(
          theme: PdfTheme.theme,
          build: (context) {
            return pw.Column(children: [
              PdfComponents.buildHeader(
                  logoBytes: logoCliente, logoIsoBytes: logoNfpa),
              pw.SizedBox(height: 20),
              pw.Text(item['descripcion'] ?? '',
                  style: PdfTheme.titleStyle, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 10),
              pw.Text(item['calificacion'] ?? '',
                  style: PdfTheme.subtitleStyle,
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 10),
              pw.Text(item['comentarios'] ?? '',
                  style: PdfTheme.bodyStyle, textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 20),
              if (imageBytes != null && imageBytes.isNotEmpty)
                pw.Expanded(
                    child: pw.Center(
                        child: pw.Image(pw.MemoryImage(imageBytes),
                            fit: pw.BoxFit.contain))),
              pw.Spacer(),
              PdfComponents.buildFooter(logoAppBytes: logoApp)
            ]);
          }));
    }

    return await pdf.save();
  }

  static Future<void> guardarPDF(Map<String, dynamic> data) async {
    try {
      final bytes = await _generatePdfBytes(data);
      final outputDirectory = await getExternalStorageDirectory();

      if (outputDirectory != null) {
        final fileName =
            "${data["cliente"]}_${PdfUtils.formatDateShort(DateTime.now())}-Prob.pdf";
        final file = File("${outputDirectory.path}/$fileName");
        await file.writeAsBytes(bytes);
        await OpenFile.open(file.path);
      }
    } catch (e) {
      debugPrint('Error generating PDF: $e');
    }
  }

  static Future<void> enviarPdfAlBackend(
      BuildContext context, Map<String, dynamic> data) async {
    try {
      final bytes = await _generatePdfBytes(data);
      final outputDirectory = await getExternalStorageDirectory();

      if (outputDirectory != null) {
        final fileName =
            "${data["cliente"]}_${PdfUtils.formatDateShort(DateTime.now())}-Prob.pdf";
        final file = File("${outputDirectory.path}/$fileName");
        await file.writeAsBytes(bytes);

        final inspeccionesService = InspeccionesService();
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
}
