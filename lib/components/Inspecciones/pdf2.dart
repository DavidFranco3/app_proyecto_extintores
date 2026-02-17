import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

import '../../utils/pdf_utils.dart';
import '../../utils/pdf_theme.dart';
import '../Common/pdf_components.dart';

class GenerarPdfPage {
  static Future<void> generarPdf(Map<String, dynamic> data) async {
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

    // --- 2. Download Images & Prepare Data ---
    final List<Map<String, dynamic>> processedImages = [];

    if (data['imagenes'] != null) {
      // Download all images in parallel
      final futures = (data['imagenes'] as List).map((img) async {
        final bytes = await PdfUtils.downloadImage(img['sharedLink']);
        if (bytes != null) {
          return {
            'bytes': bytes,
            'comentario': img['comentario'] ?? '',
            'originalIndex': (data['imagenes'] as List).indexOf(img)
          };
        }
        return null;
      });

      final downloaded = await Future.wait(futures);
      processedImages.addAll(downloaded.whereType<Map<String, dynamic>>());
    }

    // --- 3. Group by Comment (Preserving Legacy Logic) ---
    // The legacy logic groups by comment and then chunks into pairs [i, i+1]
    // It's a bit specific, we will replicate "group by comment" then "chunk by 2"

    // Grouping
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var img in processedImages) {
      final comment = img['comentario'] as String;
      grouped.putIfAbsent(comment, () => []).add(img);
    }

    // Creating rows (pairs)
    List<List<Map<String, dynamic>>> rows = [];
    grouped.forEach((key, list) {
      for (int i = 0; i < list.length; i += 2) {
        rows.add(list.sublist(i, i + 2 > list.length ? list.length : i + 2));
      }
    });

    // --- 4. Pagination ---
    // Legacy had manual height calculation. We can trust pw.MultiPage to handle this better,
    // but if we want strictly "Table based" layout per page as before, we can use MultiPage with a specific Header/Footer.

    pdf.addPage(pw.MultiPage(
        theme: PdfTheme.theme,
        header: (context) => PdfComponents.buildHeader(
            logoBytes: logoCliente, logoIsoBytes: logoNfpa),
        footer: (context) => PdfComponents.buildFooter(
            logoAppBytes: logoApp,
            pageNumber: context.pageNumber,
            totalPages: context.pagesCount),
        build: (context) {
          return [
            pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                children: rows.map((row) {
                  final img1 = row[0];
                  final img2 = row.length > 1 ? row[1] : null;

                  return pw.TableRow(children: [
                    // Index
                    pw.Padding(
                      padding: pw.EdgeInsets.all(4),
                      child: pw.Text('${(img1['originalIndex'] as int) + 1}',
                          style: PdfTheme.bodyStyle),
                    ),
                    // Images
                    pw.Padding(
                        padding: pw.EdgeInsets.all(4),
                        child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Image(pw.MemoryImage(img1['bytes']),
                                  width: 120,
                                  height: 90,
                                  fit: pw.BoxFit.contain),
                              if (img2 != null) ...[
                                pw.SizedBox(width: 10),
                                pw.Image(pw.MemoryImage(img2['bytes']),
                                    width: 120,
                                    height: 90,
                                    fit: pw.BoxFit.contain),
                              ]
                            ])),
                    // Comment
                    pw.Padding(
                      padding: pw.EdgeInsets.all(4),
                      child: pw.Text(img1['comentario'],
                          style: PdfTheme.bodyStyle),
                    ),
                  ]);
                }).toList())
          ];
        }));

    // --- 5. Save & Open ---
    final output = await getTemporaryDirectory();
    final sanitizedCliente =
        (data["cliente"] ?? "Cliente").replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    final fileName =
        "${sanitizedCliente}_${PdfUtils.formatDateShort(DateTime.now())}-Prub.pdf";
    final filePath = "${output.path}/$fileName";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save(), flush: true);
    await OpenFile.open(filePath);
  }
}
