import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../api/inspecciones.dart';
import '../Generales/flushbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GenerarPdfPage4 {
  static String fechaFormateada = DateFormat('dd-MM-yy').format(DateTime.now());

  static Future<Uint8List> loadImageFromAssets(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    return Uint8List.fromList(byteData.buffer.asUint8List());
  }

  static Future<void> generarPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Cargar imagen del cliente si existe
    final imageUrlLogo = data['imagen_cliente']?.replaceAll("dl=0", "dl=1");
    Uint8List imageBytesLogo = Uint8List(0);
    if (imageUrlLogo != null && imageUrlLogo.isNotEmpty) {
      final responseLogo = await http.get(Uri.parse(imageUrlLogo));
      if (responseLogo.statusCode == 200) {
        imageBytesLogo = responseLogo.bodyBytes;
      }
    }

    // Cargar imagen de eficiencia si existe
    final imageUrlEficiencia =
        data['imagen_eficiencia']?.replaceAll("dl=0", "dl=1");
    Uint8List imageBytesEficiencia = Uint8List(0);
    if (imageUrlEficiencia != null && imageUrlEficiencia.isNotEmpty) {
      final responseEficiencia = await http.get(Uri.parse(imageUrlEficiencia));
      if (responseEficiencia.statusCode == 200) {
        imageBytesEficiencia = responseEficiencia.bodyBytes;
      }
    }

    // Cargar logos locales
    final imageBytes00 =
        await loadImageFromAssets('lib/assets/img/logo_nfpa.png');
    final imageBytes000 =
        await loadImageFromAssets('lib/assets/img/logo_app.png');

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(20),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.bottomCenter,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Av. Universidad No. 277 A, Col. Granjas Banthi\n'
                'San Juan del Río, Querétaro, C.P. 76806\n'
                'Tel: 427 268 5050\n'
                'e-mail: ingenieria@aggofc.com',
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.left,
              ),
              pw.Image(
                pw.MemoryImage(imageBytes000),
                width: 150,
                height: 40,
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Center(
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (imageBytesLogo.isNotEmpty)
                  pw.Image(pw.MemoryImage(imageBytesLogo),
                      width: 150, height: 40),
                pw.Image(pw.MemoryImage(imageBytes00), width: 150, height: 40),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              data['descripcion_problema_eficiencia'] ?? '',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              data['calificacion_eficiencia'] ?? '',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              data['comentarios_eficiencia'] ?? '',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 20),
          if (imageBytesEficiencia.isNotEmpty)
            pw.Center(
              child: pw.Image(
                pw.MemoryImage(imageBytesEficiencia),
                width: 500,
                height: 290,
                fit: pw.BoxFit.contain,
              ),
            ),
        ],
      ),
    );
    // Obtener el directorio donde guardar el archivo
    final outputDirectory = await getExternalStorageDirectory();
    if (outputDirectory != null) {
      final file =
          File("${outputDirectory.path}/${data["cliente"]}_$fechaFormateada-Prob.pdf");

      // Guardar el archivo en el dispositivo
      await file.writeAsBytes(await pdf.save());

      print("PDF guardado en: ${file.path}");
    } else {
      print("No se pudo obtener el directorio de almacenamiento.");
    }
  }

  static Future<void> guardarPDF(Map<String, dynamic> data) async {
    try {
      await generarPdf(data);
      // Leer el archivo PDF generado como bytes
      final outputDirectory = await getExternalStorageDirectory();
      if (outputDirectory != null) {
        final file = File("${outputDirectory.path}/${data["cliente"]}_$fechaFormateada-Prob.pdf");
        // Abrir el PDF con el visor predeterminado
        await OpenFile.open(file.path);
      }
    } catch (e) {
      print('Error al enviar el PDF: $e');
    }
  }

  static Future<void> enviarPdfAlBackend(
      BuildContext context, Map<String, dynamic> data) async {
    try {
      final inspeccionesService = InspeccionesService();
      // Llamar a la función para generar y guardar el PDF
      await generarPdf(
          data); // No necesitamos el retorno, solo lo generamos y guardamos

      // Leer el archivo PDF generado como bytes
      final outputDirectory = await getExternalStorageDirectory();
      if (outputDirectory != null) {
        final file = File("${outputDirectory.path}/${data["cliente"]}_$fechaFormateada-Prob.pdf");
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
      print('Error al enviar el PDF: $e');
    }
  }
}
