import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class GenerarPdfPage {
  static String fechaFormateada = DateFormat('dd-MM-yy').format(DateTime.now());

  static Future<Uint8List> loadImageFromAssets(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    return Uint8List.fromList(byteData.buffer.asUint8List());
  }

  static Future<void> generarPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // ------- logo cliente por URL -------
    final imageUrlLogo = data['imagen_cliente']?.replaceAll("dl=0", "dl=1");
    Uint8List imageBytesLogo = Uint8List(0);
    if (imageUrlLogo != null && imageUrlLogo.isNotEmpty) {
      final responseLogo = await http.get(Uri.parse(imageUrlLogo));
      if (responseLogo.statusCode == 200) {
        imageBytesLogo = responseLogo.bodyBytes;
      }
    }

    // ------- funcion descarga imagen -------
    Future<Uint8List?> descargarImagen(String imageUrl) async {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        return null;
      }
    }

    // ------- logos locales -------
    final imageBytes00 = await loadImageFromAssets('lib/assets/img/logo_nfpa.png');
    final imageBytes000 = await loadImageFromAssets('lib/assets/img/logo_app.png');

    // ------- carga de imagenes de data['imagenes'] -------
    List<pw.ImageProvider> imageList = [];
    for (var imagen in data['imagenes']) {
      final imageUrl = imagen['sharedLink']?.replaceAll("dl=0", "dl=1");
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final imageBytes = await descargarImagen(imageUrl);
        if (imageBytes != null) {
          imageList.add(pw.MemoryImage(imageBytes));
        }
      }
    }

    // ===============================================
    // AGRUPAR POR COMENTARIO y crear filas de 2 en 2
    // ===============================================
    Map<String, List<int>> comentarioAgrupado = {};
    for (int i = 0; i < data['imagenes'].length; i++) {
      String comentario = data['imagenes'][i]['comentario'] ?? '';
      comentarioAgrupado.putIfAbsent(comentario, () => []);
      comentarioAgrupado[comentario]!.add(i);
    }

    List<List<int>> filasAgrupadas = [];
    comentarioAgrupado.forEach((comentario, indices) {
      for (int i = 0; i < indices.length; i += 2) {
        int primero = indices[i];
        int? segundo = (i + 1 < indices.length) ? indices[i + 1] : null;
        if (segundo != null) {
          filasAgrupadas.add([primero, segundo]);
        } else {
          filasAgrupadas.add([primero]);
        }
      }
    });

    // ===============================================
    // PAGINADOR AUTOMÁTICO
    // ===============================================
    List<List<List<int>>> paginas = [];
    List<List<int>> paginaActual = [];
    double alturaUsada = 0;
    const double alturaMaxima = 700;

    for (var fila in filasAgrupadas) {
      double alturaFila = (fila.length > 1) ? 130 : 100;
      if (alturaUsada + alturaFila > alturaMaxima) {
        paginas.add(paginaActual);
        paginaActual = [];
        alturaUsada = 0;
      }
      paginaActual.add(fila);
      alturaUsada += alturaFila;
    }
    if (paginaActual.isNotEmpty) {
      paginas.add(paginaActual);
    }

    // ===============================================
    // GENERAR PÁGINAS DEL PDF
    // ===============================================
    for (int pageIndex = 0; pageIndex < paginas.length; pageIndex++) {
      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Column(
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(pw.MemoryImage(imageBytesLogo), width: 150, height: 40),
                      pw.Image(pw.MemoryImage(imageBytes00), width: 150, height: 40),
                    ],
                  ),
                ),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    for (var fila in paginas[pageIndex])
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text('${fila[0] + 1}'),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                if (imageList.length > fila[0])
                                  pw.Image(imageList[fila[0]], width: 120, height: 90),
                                if (fila.length > 1 && imageList.length > fila[1])
                                  pw.SizedBox(width: 10),
                                if (fila.length > 1 && imageList.length > fila[1])
                                  pw.Image(imageList[fila[1]], width: 120, height: 90),
                              ],
                            ),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(data['imagenes'][fila[0]]['comentario'] ?? ''),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Align(
                      alignment: pw.Alignment.bottomLeft,
                      child: pw.Text(
                        'Av. Universidad No. 277 A, Col. Granjas Banthi\n'
                            'San Juan del Río, Querétaro, C.P. 76806\n'
                            'Tel: 427 268 5050\n'
                            'e-mail: ingenieria@aggofc.com',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Align(
                      alignment: pw.Alignment.bottomCenter,
                      child: pw.Text(
                        'Página ${pageIndex + 1} de ${paginas.length}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.Align(
                      alignment: pw.Alignment.bottomRight,
                      child: pw.Image(pw.MemoryImage(imageBytes000), width: 150, height: 40),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    // ===============================================
    // GUARDAR Y ABRIR
    // ===============================================
    final output = await getTemporaryDirectory();
    final filePath = "${output.path}/${data["cliente"]}_$fechaFormateada-Prub.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(filePath);
  }
}
