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

    // ReporteFinal usually doesn't show client logo in header based on previous code,
    // but checks for it. The original code only used logo_nfpa and logo_app.
    // We will stick to the original design but use the components.

    final results = await Future.wait([logoNfpaFuture, logoAppFuture]);
    final logoNfpa = results[0];
    final logoApp = results[1];

    // --- 2. Download Images ---
    final List<Map<String, dynamic>> processedImages = [];
    if (data['imagenes'] != null) {
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

    // --- 3. Chunk into blocks of 3 ---
    List<List<Map<String, dynamic>>> blocks = [];
    for (int i = 0; i < processedImages.length; i += 3) {
      blocks.add(processedImages.sublist(
          i, i + 3 > processedImages.length ? processedImages.length : i + 3));
    }

    // --- 4. Build Pages ---
    for (int pageIndex = 0; pageIndex < blocks.length; pageIndex++) {
      final block = blocks[pageIndex];

      pdf.addPage(pw.Page(
          theme: PdfTheme.theme,
          build: (context) {
            return pw.Column(children: [
              PdfComponents.buildHeader(
                  logoBytes: Uint8List(0),
                  logoIsoBytes: logoNfpa), // No client logo in original

              pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                  children: block.map((img) {
                    return pw.TableRow(children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('${(img['originalIndex'] as int) + 1}',
                            style: PdfTheme.bodyStyle),
                      ),
                      pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Center(
                              child: pw.Image(pw.MemoryImage(img['bytes']),
                                  width: 250,
                                  height: 175,
                                  fit: pw.BoxFit.contain))),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(img['comentario'],
                            style: PdfTheme.bodyStyle),
                      ),
                    ]);
                  }).toList()),

              pw.Spacer(),
              PdfComponents.buildFooter(
                  logoAppBytes: logoApp,
                  pageNumber: pageIndex + 1,
                  totalPages: blocks.length),
            ]);
          }));
    }

    // --- 5. Save & Open ---
    final output = await getTemporaryDirectory();
    final filePath = "${output.path}/reporte_de_servicio_${data["id"]}.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(filePath);
  }
}
