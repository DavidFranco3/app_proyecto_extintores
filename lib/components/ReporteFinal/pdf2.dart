import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

class GenerarPdfPage {
  static Future<Uint8List> loadImageFromAssets(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);

    // Convertir List<int> a Uint8List
    return Uint8List.fromList(byteData.buffer.asUint8List());
  }

  static Future<void> generarPdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Función para descargar las imágenes
    Future<Uint8List?> descargarImagen(String imageUrl) async {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        print("Imagen descargada correctamente");
        return response.bodyBytes;
      } else {
        print(
            "Error al descargar la imagen. Código de estado: ${response.statusCode}");
        return null;
      }
    }

    final imageBytes00 =
        await loadImageFromAssets('lib/assets/img/logo_nfpa.png');
    final imageBytes000 =
        await loadImageFromAssets('lib/assets/img/logo_app.png');

    // Lista para almacenar imágenes descargadas
    List<pw.ImageProvider> imageList = [];

    // Descargar todas las imágenes antes de crear el PDF
    for (var imagen in data['imagenes']) {
      final imageUrl = imagen['sharedLink']?.replaceAll("dl=0", "dl=1");
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final imageBytes = await descargarImagen(imageUrl);
        if (imageBytes != null) {
          imageList.add(pw.MemoryImage(imageBytes));
        }
      }
    }

    // Función para dividir la lista de imágenes y comentarios en bloques de 3
    List<List<int>> dividirEnBloques(List<dynamic> lista, int bloqueSize) {
      List<List<int>> bloques = [];
      for (int i = 0; i < lista.length; i += bloqueSize) {
        int end =
            (i + bloqueSize < lista.length) ? i + bloqueSize : lista.length;
        bloques.add(List<int>.generate(end - i, (index) => i + index));
      }
      return bloques;
    }

    // Dividir los datos en bloques de 3
    var bloques = dividirEnBloques(imageList, 3);

    // Calcular el total de páginas
    int totalPages = bloques.length;

    // Generar una página por cada bloque de 3 elementos
    for (int pageIndex = 0; pageIndex < bloques.length; pageIndex++) {
      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Center(
              child: pw.Column(
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Image(
                          pw.MemoryImage(imageBytes00),
                          width:
                              150, // Ajusta al tamaño deseado de la imagen con "00"
                          height: 40, // Altura fija
                        ),
                      ],
                    ),
                  ),
                  pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      // Iteramos sobre el bloque y generamos las filas de la tabla
                      for (int i = 0; i < bloques[pageIndex].length; i++)
                        pw.TableRow(
                          children: [
                            pw.Text(
                                '${bloques[pageIndex][i] + 1}'), // Número aumentativo
                            imageList.isNotEmpty &&
                                    imageList.length > bloques[pageIndex][i]
                                ? pw.Center(
                                    child: pw.Image(
                                        imageList[bloques[pageIndex][i]],
                                        width: 250,
                                        height: 175))
                                : pw.Text("Imagen no disponible"),
                            pw.Text(data['imagenes'][bloques[pageIndex][i]]
                                    ['comentario'] ??
                                ''),
                          ],
                        ),
                    ],
                  ),
                  pw.Spacer(), // Esto asegura que haya espacio suficiente para el pie de página

                  // Pie de página en la parte inferior
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Align(
                        alignment:
                            pw.Alignment.bottomLeft, // Alinea a la izquierda
                        child: pw.Text(
                          'Av. Universidad No. 277 A, Col. Granjas Banthi\n'
                          'San Juan del Río, Querétaro, C.P. 76806\n'
                          'Tel: 427 268 5050\n'
                          'e-mail: ingenieria@aggofc.com',
                          style: pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),
                      pw.Align(
                        alignment:
                            pw.Alignment.bottomCenter, // Alinea al centro
                        child: pw.Text(
                          'Pagina ${pageIndex + 1} de $totalPages',
                          style: pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Align(
                        alignment: pw.Alignment.bottomRight, // Alinea al centro
                        child: pw.Image(
                          pw.MemoryImage(imageBytes000),
                          width:
                              150, // Ajusta al tamaño deseado de la imagen con "00"
                          height: 40, // Altura fija
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Obtener directorio temporal
    final output = await getTemporaryDirectory();
    final filePath = "${output.path}/reporte_de_servicio_${data["id"]}.pdf";

    // Guardar PDF
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // Abrir el archivo con el visor de PDF predeterminado
    await OpenFile.open(filePath);
  }
}
