import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart'; // Importa la librería PdfColors
import 'dart:math';
import '../../api/inspecciones.dart';
import 'package:flutter/material.dart';
import '../Generales/flushbar_helper.dart';

class PdfGenerator {
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

  static Future<Uint8List> loadImageFromAssets(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);

    // Convertir List<int> a Uint8List
    return Uint8List.fromList(byteData.buffer.asUint8List());
  }

  static Future<void> generatePDF(Map<String, dynamic> data) async {
    try {
      final pdf = pw.Document();
      print("imagen cliente ${data["imagen_cliente"]}");

      // Verificar URL de la imagen
      final imageUrl =
          data['imagenes'][0]['sharedLink']?.replaceAll("dl=0", "dl=1");
      print("Link de la imagen: $imageUrl");

      if (imageUrl == null || imageUrl.isEmpty) {
        print("URL de la imagen no válida");
        return;
      }

      // Descargar la imagen
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final Uint8List imageBytes = response.bodyBytes;
        print("Imagen descargada correctamente");

        // Verificar comentario
        final comentario =
            data['imagenes'][0]['comentario'] ?? 'Sin comentario';
        print("Comentario: $comentario");

        // Verificar comentario
        final valor = data['imagenes'][0]['valor'] ?? '0';
        print("valor: $valor");

        // Verificar URL de la imagen
        final imageUrl2 =
            data['imagenes'][1]['sharedLink']?.replaceAll("dl=0", "dl=1");
        print("Link de la imagen: $imageUrl2");

        if (imageUrl2 == null || imageUrl2.isEmpty) {
          print("URL de la imagen no válida");
          return;
        }

        // Descargar la imagen
        final response2 = await http.get(Uri.parse(imageUrl2));
        if (response2.statusCode == 200) {
          final Uint8List imageBytes2 = response2.bodyBytes;
          print("Imagen descargada correctamente");

          // Verificar comentario
          final comentario2 =
              data['imagenes'][1]['comentario'] ?? 'Sin comentario';
          print("Comentario: $comentario2");

          final valor2 = data['imagenes'][1]['valor'] ?? '0';
          print("valor: $valor2");

          final imageUrl3 =
              data['imagenes'][2]['sharedLink']?.replaceAll("dl=0", "dl=1");
          print("Link de la imagen: $imageUrl3");

          if (imageUrl3 == null || imageUrl3.isEmpty) {
            print("URL de la imagen no válida");
            return;
          }

          // Descargar la imagen
          final response3 = await http.get(Uri.parse(imageUrl3));
          if (response3.statusCode == 200) {
            final Uint8List imageBytes3 = response3.bodyBytes;
            print("Imagen descargada correctamente");

            // Verificar comentario
            final comentario3 =
                data['imagenes'][2]['comentario'] ?? 'Sin comentario';
            print("Comentario: $comentario3");

            final valor3 = data['imagenes'][2]['valor'] ?? 0;
            print("valor: $valor3");

            final imageUrl4 =
                data['imagenes'][3]['sharedLink']?.replaceAll("dl=0", "dl=1");
            print("Link de la imagen: $imageUrl4");

            if (imageUrl4 == null || imageUrl4.isEmpty) {
              print("URL de la imagen no válida");
              return;
            }

            // Descargar la imagen
            final response4 = await http.get(Uri.parse(imageUrl4));
            if (response4.statusCode == 200) {
              final Uint8List imageBytes4 = response4.bodyBytes;
              print("Imagen descargada correctamente");

              // Verificar comentario
              final comentario4 =
                  data['imagenes'][3]['comentario'] ?? 'Sin comentario';
              print("Comentario: $comentario4");

              final valor4 = data['imagenes'][3]['valor'] ?? 0;
              print("valor: $valor4");

              final imageUrl5 =
                  data['imagenes'][4]['sharedLink']?.replaceAll("dl=0", "dl=1");
              print("Link de la imagen: $imageUrl5");

              if (imageUrl5 == null || imageUrl5.isEmpty) {
                print("URL de la imagen no válida");
                return;
              }

              // Descargar la imagen
              final response5 = await http.get(Uri.parse(imageUrl5));
              if (response5.statusCode == 200) {
                final Uint8List imageBytes5 = response5.bodyBytes;
                print("Imagen descargada correctamente");

                // Verificar comentario
                final comentario5 =
                    data['imagenes'][4]['comentario'] ?? 'Sin comentario';
                print("Comentario: $comentario5");

                final valor5 = data['imagenes'][4]['valor'] ?? 0;
                print("valor: $valor5");

                final imageUrl6 = data['imagenes'][5]['sharedLink']
                    ?.replaceAll("dl=0", "dl=1");
                print("Link de la imagen: $imageUrl6");

                if (imageUrl6 == null || imageUrl6.isEmpty) {
                  print("URL de la imagen no válida");
                  return;
                }

                // Descargar la imagen
                final response6 = await http.get(Uri.parse(imageUrl6));
                if (response6.statusCode == 200) {
                  final Uint8List imageBytes6 = response6.bodyBytes;
                  print("Imagen descargada correctamente");

                  // Verificar comentario
                  final comentario6 =
                      data['imagenes'][5]['comentario'] ?? 'Sin comentario';
                  print("Comentario: $comentario6");

                  final valor6 = data['imagenes'][5]['valor'] ?? 0;
                  print("valor: $valor6");

                  final imageUrl7 = data['imagenes'][6]['sharedLink']
                      ?.replaceAll("dl=0", "dl=1");
                  print("Link de la imagen: $imageUrl7");

                  if (imageUrl7 == null || imageUrl7.isEmpty) {
                    print("URL de la imagen no válida");
                    return;
                  }

                  // Descargar la imagen
                  final response7 = await http.get(Uri.parse(imageUrl7));
                  if (response7.statusCode == 200) {
                    final Uint8List imageBytes7 = response7.bodyBytes;
                    print("Imagen descargada correctamente");

                    // Verificar comentario
                    final comentario7 =
                        data['imagenes'][6]['comentario'] ?? 'Sin comentario';
                    print("Comentario: $comentario7");

                    final valor7 = data['imagenes'][6]['valor'] ?? 0;
                    print("valor: $valor7");

                    final imageUrlLogo =
                        data['imagen_cliente']?.replaceAll("dl=0", "dl=1");
                    print("Link de la imagen: $imageUrlLogo");

                    if (imageUrlLogo == null || imageUrlLogo.isEmpty) {
                      print("URL de la imagen no válida");
                      return;
                    }

                    // Descargar la imagen
                    final responseLogo =
                        await http.get(Uri.parse(imageUrlLogo));
                    if (responseLogo.statusCode == 200) {
                      final Uint8List imageBytesLogo = responseLogo.bodyBytes;
                      print("Imagen descargada correctamente");

                      final imageUrlFirma =
                          data["firma_usuario"]?.replaceAll("dl=0", "dl=1");
                      print("Link de la imagen: $imageUrlFirma");

                      if (imageUrlFirma == null || imageUrlFirma.isEmpty) {
                        print("URL de la imagen no válida");
                        return;
                      }

                      // Descargar la imagen
                      final responseFirma =
                          await http.get(Uri.parse(imageUrlFirma));
                      if (responseFirma.statusCode == 200) {
                        final Uint8List imageBytesFirma =
                            responseFirma.bodyBytes;
                        print("Imagen descargada correctamente");

                        final double caudal1 =
                            129.84 * 0.95 * pow(0.5, 2) * sqrt(valor3);
                        final double caudal2 =
                            129.84 * 0.95 * pow(0.5, 2) * sqrt(valor4);
                        final double caudal3 =
                            129.84 * 0.95 * pow(0.5, 2) * sqrt(valor5);
                        final double caudal4 =
                            129.84 * 0.95 * pow(0.5, 2) * sqrt(valor6);
                        final double sumaCaudales =
                            caudal1 + caudal2 + caudal3 + caudal4;

                        final imageBytes0 = await loadImageFromAssets(
                            'lib/assets/img/formula.png');
                        final imageBytes00 = await loadImageFromAssets(
                            'lib/assets/img/logo_nfpa.png');
                        final imageBytes000 = await loadImageFromAssets(
                            'lib/assets/img/logo_app.png');
                        final imageBytes0000 = await loadImageFromAssets(
                            'lib/assets/img/certificado.png');

                        // Crear el contenido del PDF
                        pdf.addPage(
                          pw.Page(
                            build: (pw.Context context) {
                              return pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Header(
                                    level: 0,
                                    child: pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Image(
                                          pw.MemoryImage(imageBytesLogo),
                                          width:
                                              150, // Ajusta al tamaño deseado del logo
                                          height: 40, // Altura fija
                                        ),
                                        pw.Image(
                                          pw.MemoryImage(imageBytes00),
                                          width:
                                              150, // Ajusta al tamaño deseado de la imagen con "00"
                                          height: 40, // Altura fija
                                        ),
                                      ],
                                    ),
                                  ),
                                  pw.Text(
                                    "PRUEBA DE CAUDAL MANGUERA DE 1½ x 30 M (HIDRANTE CLASE II)",
                                    style: pw.TextStyle(
                                      fontSize:
                                          14, // Tamaño de letra más grande
                                      fontWeight: pw.FontWeight.bold, // Negrita
                                    ),
                                  ),

                                  // Espacio para separar el título del resto del texto
                                  pw.SizedBox(height: 12),

                                  // Primer párrafo
                                  pw.RichText(
                                    text: pw.TextSpan(
                                      style: pw.TextStyle(
                                          fontSize:
                                              12), // Estilo para el texto normal
                                      children: [
                                        pw.TextSpan(
                                          text:
                                              "Dando cumplimiento, tanto a lo especificado en ", // Texto normal
                                        ),
                                        pw.TextSpan(
                                          text:
                                              "NFPA 24 Standard for the Installation of Private Fire Service Mains", // Texto en negrita
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold),
                                        ),
                                        pw.TextSpan(
                                          text: " y ", // Texto normal
                                        ),
                                        pw.TextSpan(
                                          text:
                                              "NFPA 25 Standard for the Inspection, Testing, and Maintenance of Water-Based Fire Protection Systems,", // Texto en negrita
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold),
                                        ),
                                        pw.TextSpan(
                                          text:
                                              "como a lo solicitado por el departamento de Protección Civil, el día ", // Texto normal
                                        ),
                                        pw.TextSpan(
                                          text: formatDate(data[
                                              "createdAt"]), // Texto en negrita
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold),
                                        ),
                                        pw.TextSpan(
                                          text:
                                              " se realizó una prueba de caudal al sistema contra incendio instalado actualmente en la empresa ${data["cliente"]}, la prueba se realizó en la manguera de 1½ x 30 m más alejada al punto de alimentación del sistema.", // Texto normal
                                        ),
                                      ],
                                    ),
                                    textAlign: pw.TextAlign
                                        .justify, // Justificar el texto
                                  ),

                                  // Espacio para separar párrafos (opcional)
                                  pw.SizedBox(height: 12),

                                  // Segundo párrafo
                                  pw.RichText(
                                    text: pw.TextSpan(
                                      style: pw.TextStyle(fontSize: 12),
                                      children: [
                                        pw.TextSpan(
                                          text:
                                              "La prueba consistió en la medición de la presión de velocidad, mediante un tubo Pitot ", // Texto normal
                                        ),
                                        pw.TextSpan(
                                          text:
                                              "diseñado específicamente para la medición de caudal, tomada en la salida de las descargas del ", // Texto normal
                                        ),
                                        pw.TextSpan(
                                          text:
                                              "cabezal de pruebas (Figura 1) suministrado por ", // Texto normal
                                        ),
                                        pw.TextSpan(
                                          text:
                                              "AGGO Fire Consultant ", // Texto normal
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold),
                                        ),
                                        pw.TextSpan(
                                          text:
                                              "el cual divide el caudal en cuatro salidas para posteriormente reducir el diámetro de cada descarga ", // Texto normal
                                        ),
                                        pw.TextSpan(
                                          text:
                                              "a un orificio de ½ de diámetro con el objetivo de hacer mediciones más precisas y exactas.", // Texto normal
                                        ),
                                      ],
                                    ),
                                    textAlign: pw.TextAlign
                                        .justify, // Justificar el texto
                                  ),
                                  // Agregar la imagen descargada al PDF
                                  pw.SizedBox(height: 12),
                                  pw.Center(
                                    child: pw.Image(
                                      pw.MemoryImage(imageBytes),
                                      width: 500, // Ajusta al ancho completo de la página
                                      height: 350, // Altura fija
                                    ),
                                  ),
                                  pw.SizedBox(
                                      height:
                                          10), // Espacio entre imagen y comentario
                                  pw.Center(
                                    child: pw.Text(comentario,
                                        style: pw.TextStyle(fontSize: 12)),
                                  ),
                                  pw.Spacer(), // Esto asegura que haya espacio suficiente para el pie de página

                                  // Pie de página en la parte inferior
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment
                                        .spaceBetween, // Espaciado entre los elementos
                                    children: [
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomLeft, // Alinea a la izquierda
                                        child: pw.Text(
                                          'Av. Universidad No. 277 A, Col. Granjas Banthi\n'
                                          'San Juan del Río, Querétaro, C.P. 76806\n'
                                          'Tel: 427 268 5050\n'
                                          'e-mail: ingenieria@aggofc.com',
                                          style: pw.TextStyle(fontSize: 10),
                                          textAlign: pw.TextAlign
                                              .left, // Alinea el texto a la izquierda
                                        ),
                                      ),
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomCenter, // Alinea al centro
                                        child: pw.Text(
                                          'Pagina 1 de 5',
                                          style: pw.TextStyle(fontSize: 10),
                                          textAlign: pw.TextAlign
                                              .center, // Alinea el texto al centro
                                        ),
                                      ),
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomRight, // Alinea al centro
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
                              );
                            },
                          ),
                        );
                        pdf.addPage(
                          pw.Page(
                            build: (pw.Context context) {
                              return pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Header(
                                    level: 0,
                                    child: pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Image(
                                          pw.MemoryImage(imageBytesLogo),
                                          width:
                                              150, // Ajusta al tamaño deseado del logo
                                          height: 40, // Altura fija
                                        ),
                                        pw.Image(
                                          pw.MemoryImage(imageBytes000),
                                          width:
                                              150, // Ajusta al tamaño deseado de la imagen con "00"
                                          height: 40, // Altura fija
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Primer párrafo
                                  pw.RichText(
                                    text: pw.TextSpan(
                                      style: pw.TextStyle(
                                          fontSize:
                                              12), // Estilo para el texto normal
                                      children: [
                                        pw.TextSpan(
                                          text:
                                              "El manómetro del tubo Pitot se encuentra dentro de la vigencia de la calibración del mismo ya que su última calibración se realizó el ${data["createdAt"]} (Figura 2). ", // Texto normal
                                        ),
                                      ],
                                    ),
                                    textAlign: pw.TextAlign
                                        .justify, // Justificar el texto
                                  ),

                                  // Agregar la imagen descargada al PDF
                                  pw.SizedBox(height: 12),
                                  pw.Center(
                                    child: pw.Image(
                                      pw.MemoryImage(imageBytes2),
                                      width: double
                                          .infinity, // Ajusta al ancho completo de la página
                                      height: 340, // Altura fija
                                    ),
                                  ),
                                  pw.SizedBox(
                                      height:
                                          10), // Espacio entre imagen y comentario
                                  pw.Center(
                                    child: pw.Text(comentario2,
                                        style: pw.TextStyle(fontSize: 12)),
                                  ),
                                  pw.SizedBox(height: 12),

                                  pw.RichText(
                                    text: pw.TextSpan(
                                      style: pw.TextStyle(
                                          fontSize:
                                              12), // Estilo para el texto normal
                                      children: [
                                        pw.TextSpan(
                                          text:
                                              "La presión de velocidad registrada con el tubo Pitot se convierte en caudal mediante la siguiente formula: ", // Texto normal
                                        ),
                                      ],
                                    ),
                                    textAlign: pw.TextAlign
                                        .justify, // Justificar el texto
                                  ),
                                  pw.SizedBox(height: 12),
                                  pw.Image(
                                    pw.MemoryImage(imageBytes0),
                                    width: double
                                        .infinity, // Ajusta al ancho completo de la página
                                    height: 160, // Altura fija
                                  ),

                                  pw.Spacer(), // Esto asegura que haya espacio suficiente para el pie de página

                                  // Pie de página en la parte inferior
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment
                                        .spaceBetween, // Espaciado entre los elementos
                                    children: [
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomLeft, // Alinea a la izquierda
                                        child: pw.Text(
                                          'Av. Universidad No. 277 A, Col. Granjas Banthi\n'
                                          'San Juan del Río, Querétaro, C.P. 76806\n'
                                          'Tel: 427 268 5050\n'
                                          'e-mail: ingenieria@aggofc.com',
                                          style: pw.TextStyle(fontSize: 10),
                                          textAlign: pw.TextAlign
                                              .left, // Alinea el texto a la izquierda
                                        ),
                                      ),
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomCenter, // Alinea al centro
                                        child: pw.Text(
                                          'Pagina 2 de 5',
                                          style: pw.TextStyle(fontSize: 10),
                                          textAlign: pw.TextAlign
                                              .center, // Alinea el texto al centro
                                        ),
                                      ),
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomRight, // Alinea al centro
                                        child: pw.Image(
                                          pw.MemoryImage(imageBytes00),
                                          width:
                                              150, // Ajusta al tamaño deseado de la imagen con "00"
                                          height: 40, // Altura fija
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        );

                        pdf.addPage(
                          pw.Page(
                            build: (pw.Context context) {
                              return pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Header(
                                    level: 0,
                                    child: pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Image(
                                          pw.MemoryImage(imageBytesLogo),
                                          width:
                                              150, // Ajusta al tamaño deseado del logo
                                          height: 40, // Altura fija
                                        ),
                                        pw.Image(
                                          pw.MemoryImage(imageBytes00),
                                          width:
                                              150, // Ajusta al tamaño deseado de la imagen con "00"
                                          height: 40, // Altura fija
                                        ),
                                      ],
                                    ),
                                  ),
                                  pw.RichText(
                                    text: pw.TextSpan(
                                      style: pw.TextStyle(fontSize: 12),
                                      children: [
                                        pw.TextSpan(
                                          text:
                                              "De acuerdo a la sección C.4.7.2 de la ", // Texto normal
                                        ),
                                        pw.TextSpan(
                                          text:
                                              "NFPA 24 Standard for the Installation of Private Fire Service Mains and Their Appurtenances", // Texto en negrita
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold),
                                        ),
                                        pw.TextSpan(
                                          text:
                                              ", en caso de utilizar un Stream Straightener, el coeficiente de descarga C sugerido es 0.95.", // Texto normal
                                        ),
                                      ],
                                    ),
                                    textAlign: pw.TextAlign
                                        .justify, // Justificar el texto
                                  ),

                                  pw.SizedBox(height: 12),

                                  pw.RichText(
                                    text: pw.TextSpan(
                                      style: pw.TextStyle(fontSize: 12),
                                      children: [
                                        pw.TextSpan(
                                          text:
                                              "Por lo tanto, los resultados de la prueba quedan de la siguiente forma: ", // Texto normal
                                        ),
                                      ],
                                    ),
                                    textAlign: pw.TextAlign
                                        .justify, // Justificar el texto
                                  ),

                                  pw.SizedBox(height: 12),

                                  // Tabla
                                  pw.Table(
                                    border: pw.TableBorder.all(
                                        width: 1,
                                        color: PdfColors
                                            .black), // Usa PdfColors directamente
                                    children: [
                                      // Fila de encabezado
                                      pw.TableRow(
                                        children: [
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              'Descarga',
                                              style: pw.TextStyle(
                                                  fontWeight:
                                                      pw.FontWeight.bold),
                                            ),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              'Coeficiente de descarga',
                                              style: pw.TextStyle(
                                                  fontWeight:
                                                      pw.FontWeight.bold),
                                            ),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              'Diametro (in)',
                                              style: pw.TextStyle(
                                                  fontWeight:
                                                      pw.FontWeight.bold),
                                            ),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              'Presión de velocidad (psi)',
                                              style: pw.TextStyle(
                                                  fontWeight:
                                                      pw.FontWeight.bold),
                                            ),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              'Caudal (gpm)',
                                              style: pw.TextStyle(
                                                  fontWeight:
                                                      pw.FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Fila de datos
                                      pw.TableRow(
                                        children: [
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('1'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('0.95'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('½'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(valor3.toString() +
                                                '(Figura 3)'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              caudal1.toStringAsFixed(
                                                  2), // muestra 2 decimales
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Otra fila de datos
                                      pw.TableRow(
                                        children: [
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('1'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('0.95'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('½'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(valor4.toString() +
                                                '(Figura 4)'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              caudal2.toStringAsFixed(
                                                  2), // muestra 2 decimales
                                            ),
                                          ),
                                        ],
                                      ),

                                      pw.TableRow(
                                        children: [
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('1'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('0.95'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('½'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(valor5.toString() +
                                                '(Figura 5)'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              caudal3.toStringAsFixed(
                                                  2), // muestra 2 decimales
                                            ),
                                          ),
                                        ],
                                      ),

                                      pw.TableRow(
                                        children: [
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('1'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('0.95'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('½'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(valor6.toString() +
                                                '(Figura 6)'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              caudal4.toStringAsFixed(
                                                  2), // muestra 2 decimales
                                            ),
                                          ),
                                        ],
                                      ),

                                      pw.TableRow(
                                        decoration: pw.BoxDecoration(
                                            color: PdfColors.grey300),
                                        children: [
                                          pw.SizedBox(), // Espacio vacío para las primeras tres columnas
                                          pw.SizedBox(),
                                          pw.SizedBox(),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Align(
                                              alignment:
                                                  pw.Alignment.centerRight,
                                              child: pw.Text(
                                                'Total:',
                                                style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              sumaCaudales.toStringAsFixed(
                                                  2), // Suma total de caudal
                                              style: pw.TextStyle(
                                                  fontWeight:
                                                      pw.FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  pw.SizedBox(height: 12),

                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.start,
                                    children: [
                                      pw.Expanded(
                                        child: pw.Column(
                                          children: [
                                            pw.Image(
                                                pw.MemoryImage(imageBytes3),
                                                width: double.infinity,
                                                height: 130),
                                            pw.SizedBox(height: 10),
                                            pw.Text(comentario3,
                                                style:
                                                    pw.TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      pw.Expanded(
                                        child: pw.Column(
                                          children: [
                                            pw.Image(
                                                pw.MemoryImage(imageBytes4),
                                                width: double.infinity,
                                                height: 130),
                                            pw.SizedBox(height: 10),
                                            pw.Text(comentario4,
                                                style:
                                                    pw.TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.SizedBox(height: 12),
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.start,
                                    children: [
                                      pw.Expanded(
                                        child: pw.Column(
                                          children: [
                                            pw.Image(
                                                pw.MemoryImage(imageBytes5),
                                                width: double.infinity,
                                                height: 130),
                                            pw.SizedBox(height: 10),
                                            pw.Text(comentario5,
                                                style:
                                                    pw.TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      pw.Expanded(
                                        child: pw.Column(
                                          children: [
                                            pw.Image(
                                                pw.MemoryImage(imageBytes6),
                                                width: double.infinity,
                                                height: 130),
                                            pw.SizedBox(height: 10),
                                            pw.Text(comentario6,
                                                style:
                                                    pw.TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.Spacer(), // Esto asegura que haya espacio suficiente para el pie de página

                                  // Pie de página en la parte inferior
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment
                                        .spaceBetween, // Espaciado entre los elementos
                                    children: [
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomLeft, // Alinea a la izquierda
                                        child: pw.Text(
                                          'Av. Universidad No. 277 A, Col. Granjas Banthi\n'
                                          'San Juan del Río, Querétaro, C.P. 76806\n'
                                          'Tel: 427 268 5050\n'
                                          'e-mail: ingenieria@aggofc.com',
                                          style: pw.TextStyle(fontSize: 10),
                                          textAlign: pw.TextAlign
                                              .left, // Alinea el texto a la izquierda
                                        ),
                                      ),
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomCenter, // Alinea al centro
                                        child: pw.Text(
                                          'Pagina 3 de 5',
                                          style: pw.TextStyle(fontSize: 10),
                                          textAlign: pw.TextAlign
                                              .center, // Alinea el texto al centro
                                        ),
                                      ),
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomRight, // Alinea al centro
                                        child: pw.Image(
                                          pw.MemoryImage(imageBytes00),
                                          width:
                                              150, // Ajusta al tamaño deseado de la imagen con "00"
                                          height: 40, // Altura fija
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        );

                        pdf.addPage(
                          pw.Page(
                            build: (pw.Context context) {
                              return pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Header(
                                    level: 0,
                                    child: pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Image(
                                          pw.MemoryImage(imageBytesLogo),
                                          width:
                                              150, // Ajusta al tamaño deseado del logo
                                          height: 40, // Altura fija
                                        ),
                                        pw.Image(
                                          pw.MemoryImage(imageBytes00),
                                          width:
                                              150, // Ajusta al tamaño deseado de la imagen con "00"
                                          height: 40, // Altura fija
                                        ),
                                      ],
                                    ),
                                  ),
                                  pw.Text(
                                    "RESUMEN DE PRUEBA CAUDAL",
                                    style: pw.TextStyle(
                                      fontSize:
                                          14, // Tamaño de letra más grande
                                      fontWeight: pw.FontWeight.bold, // Negrita
                                    ),
                                  ),
                                  // Espacio para separar el título del resto del texto
                                  pw.SizedBox(height: 12),

                                  pw.Table(
                                    border: pw.TableBorder.all(
                                        width: 1,
                                        color: PdfColors
                                            .black), // Usa PdfColors directamente
                                    children: [
                                      // Fila de encabezado
                                      pw.TableRow(
                                        children: [
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              'Descripcion',
                                              style: pw.TextStyle(
                                                  fontWeight:
                                                      pw.FontWeight.bold),
                                            ),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              'Parámetro de referencia mínimo',
                                              style: pw.TextStyle(
                                                  fontWeight:
                                                      pw.FontWeight.bold),
                                            ),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(
                                              'Resultado de la prueba',
                                              style: pw.TextStyle(
                                                  fontWeight:
                                                      pw.FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Fila de datos
                                      pw.TableRow(
                                        children: [
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('Caudal'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('100 gpm'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(sumaCaudales
                                                    .toStringAsFixed(2) +
                                                ' gpm'),
                                          ),
                                        ],
                                      ),

                                      pw.TableRow(
                                        children: [
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('Presión residual'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text('65 psi'),
                                          ),
                                          pw.Padding(
                                            padding: pw.EdgeInsets.all(8),
                                            child: pw.Text(valor7.toString() +
                                                ' psi (Figura 7)'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  pw.SizedBox(height: 12),
                                  pw.Center(
                                    child: pw.Image(
                                      pw.MemoryImage(imageBytes7),
                                      width: double
                                          .infinity, // Ajusta al ancho completo de la página
                                      height: 410, // Altura fija
                                    ),
                                  ),
                                  pw.SizedBox(
                                      height:
                                          10), // Espacio entre imagen y comentario
                                  pw.Center(
                                    child: pw.Text(comentario7,
                                        style: pw.TextStyle(fontSize: 12)),
                                  ),
                                  pw.Spacer(), // Esto asegura que haya espacio suficiente para el pie de página

                                  // Pie de página en la parte inferior
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment
                                        .spaceBetween, // Espaciado entre los elementos
                                    children: [
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomLeft, // Alinea a la izquierda
                                        child: pw.Text(
                                          'Av. Universidad No. 277 A, Col. Granjas Banthi\n'
                                          'San Juan del Río, Querétaro, C.P. 76806\n'
                                          'Tel: 427 268 5050\n'
                                          'e-mail: ingenieria@aggofc.com',
                                          style: pw.TextStyle(fontSize: 10),
                                          textAlign: pw.TextAlign
                                              .left, // Alinea el texto a la izquierda
                                        ),
                                      ),
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomCenter, // Alinea al centro
                                        child: pw.Text(
                                          'Pagina 4 de 5',
                                          style: pw.TextStyle(fontSize: 10),
                                          textAlign: pw.TextAlign
                                              .center, // Alinea el texto al centro
                                        ),
                                      ),
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomRight, // Alinea al centro
                                        child: pw.Image(
                                          pw.MemoryImage(imageBytes00),
                                          width:
                                              150, // Ajusta al tamaño deseado de la imagen con "00"
                                          height: 40, // Altura fija
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                        pdf.addPage(
                          pw.Page(
                            build: (pw.Context context) {
                              return pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Header(
                                    level: 0,
                                    child: pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Image(
                                          pw.MemoryImage(imageBytesLogo),
                                          width:
                                              150, // Ajusta al tamaño deseado del logo
                                          height: 40, // Altura fija
                                        ),
                                        pw.Image(
                                          pw.MemoryImage(imageBytes00),
                                          width:
                                              150, // Ajusta al tamaño deseado de la imagen con "00"
                                          height: 40, // Altura fija
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Primer párrafo
                                  pw.RichText(
                                    text: pw.TextSpan(
                                      style: pw.TextStyle(
                                          fontSize:
                                              12), // Estilo para el texto normal
                                      children: [
                                        pw.TextSpan(
                                          text:
                                              "De acuerdo a la revisión y a la prueba realizada al sistema contra incendio de la empresa ${data["cliente"]}, se concluye que, ", // Texto normal
                                        ),
                                        pw.TextSpan(
                                          text:
                                              "SI CUMPLE ", // Texto en negrita
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold),
                                        ),
                                        pw.TextSpan(
                                          text:
                                              "con los parámetros mínimosespecificados en ", // Texto normal
                                        ),
                                        pw.TextSpan(
                                          text:
                                              "NFPA 25 Standard for the Inspection, Testing, and Maintenance of WaterBased Fire Protection Systems", // Texto en negrita
                                          style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    textAlign: pw.TextAlign
                                        .justify, // Justificar el texto
                                  ),
                                  // Agregar la imagen descargada al PDF
                                  pw.SizedBox(height: 12),
                                  pw.Center(
                                    child: pw.Image(
                                      pw.MemoryImage(imageBytes0000),
                                      width: double
                                          .infinity, // Ajusta al ancho completo de la página
                                      height: 350, // Altura fija
                                    ),
                                  ),
                                  pw.SizedBox(
                                      height:
                                          12), // Espacio entre imagen y comentario
                                  pw.RichText(
                                    text: pw.TextSpan(
                                      style: pw.TextStyle(
                                          fontSize:
                                              12), // Estilo para el texto normal
                                      children: [
                                        pw.TextSpan(
                                          text:
                                              "Sin más por el momento me despido de usted, agradeciendo las atenciones dadas a la presente. ", // Texto normal
                                        ),
                                      ],
                                    ),
                                    textAlign: pw.TextAlign
                                        .justify, // Justificar el texto
                                  ),
                                  // Agregar la imagen descargada al PDF
                                  pw.SizedBox(height: 10),
                                  pw.Center(
                                    child: pw.Text("Atentamente",
                                        style: pw.TextStyle(fontSize: 12)),
                                  ),
                                  pw.Center(
                                    child: pw.Image(
                                      pw.MemoryImage(imageBytesFirma),
                                      width: double
                                          .infinity, // Ajusta al ancho completo de la página
                                      height: 80, // Altura fija
                                    ),
                                  ),
                                  pw.Center(
                                    child: pw.Text(data["usuario"],
                                        style: pw.TextStyle(fontSize: 12)),
                                  ),
                                  pw.Center(
                                    child: pw.Text("AGGO Fire Consultant",
                                        style: pw.TextStyle(fontSize: 12)),
                                  ),
                                  pw.SizedBox(height: 10),
                                  pw.Spacer(), // Esto asegura que haya espacio suficiente para el pie de página

                                  // Pie de página en la parte inferior
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment
                                        .spaceBetween, // Espaciado entre los elementos
                                    children: [
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomLeft, // Alinea a la izquierda
                                        child: pw.Text(
                                          'Av. Universidad No. 277 A, Col. Granjas Banthi\n'
                                          'San Juan del Río, Querétaro, C.P. 76806\n'
                                          'Tel: 427 268 5050\n'
                                          'e-mail: ingenieria@aggofc.com',
                                          style: pw.TextStyle(fontSize: 10),
                                          textAlign: pw.TextAlign
                                              .left, // Alinea el texto a la izquierda
                                        ),
                                      ),
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomCenter, // Alinea al centro
                                        child: pw.Text(
                                          'Pagina 5 de 5',
                                          style: pw.TextStyle(fontSize: 10),
                                          textAlign: pw.TextAlign
                                              .center, // Alinea el texto al centro
                                        ),
                                      ),
                                      pw.Align(
                                        alignment: pw.Alignment
                                            .bottomRight, // Alinea al centro
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
                              );
                            },
                          ),
                        );
                        // Obtener el directorio donde guardar el archivo
                        final outputDirectory =
                            await getExternalStorageDirectory();
                        if (outputDirectory != null) {
                          final file = File(
                              "${outputDirectory.path}/ENCUESTA_INSPECCION_${data["id"]}.pdf");

                          // Guardar el archivo en el dispositivo
                          await file.writeAsBytes(await pdf.save());

                          print("PDF guardado en: ${file.path}");
                        } else {
                          print(
                              "No se pudo obtener el directorio de almacenamiento.");
                        }
                      } else {
                        print(
                            "Error al descargar la imagen: ${response.statusCode}");
                      }
                    } else {
                      print(
                          "Error al descargar la imagen: ${response.statusCode}");
                    }
                  } else {
                    print(
                        "Error al descargar la imagen: ${response.statusCode}");
                  }
                } else {
                  print("Error al descargar la imagen: ${response.statusCode}");
                }
              } else {
                print("Error al descargar la imagen: ${response.statusCode}");
              }
            } else {
              print("Error al descargar la imagen: ${response.statusCode}");
            }
          } else {
            print("Error al descargar la imagen: ${response.statusCode}");
          }
        } else {
          print("Error al descargar la imagen: ${response.statusCode}");
        }
      } else {
        print("Error al descargar la imagen: ${response.statusCode}");
      }
    } catch (e) {
      print("Error al generar y guardar el PDF: $e");
    }
  }

// Función estática para enviar el PDF al servidor
  static Future<void> enviarPdfAlBackend(
      BuildContext context, Map<String, dynamic> data) async {
    try {
      final inspeccionesService = InspeccionesService();
      // Llamar a la función para generar y guardar el PDF
      await generatePDF(
          data); // No necesitamos el retorno, solo lo generamos y guardamos

      // Leer el archivo PDF generado como bytes
      final outputDirectory = await getExternalStorageDirectory();
      if (outputDirectory != null) {
        final file = File(
            "${outputDirectory.path}/ENCUESTA_INSPECCION_${data["id"]}.pdf");
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

  static Future<void> guardarPDF(Map<String, dynamic> data) async {
    try {
      await generatePDF(data);
      // Leer el archivo PDF generado como bytes
      final outputDirectory = await getExternalStorageDirectory();
      if (outputDirectory != null) {
        final file = File(
            "${outputDirectory.path}/ENCUESTA_INSPECCION_${data["id"]}.pdf");
        // Abrir el PDF con el visor predeterminado
        await OpenFile.open(file.path);
      }
    } catch (e) {
      print('Error al enviar el PDF: $e');
    }
  }
}
