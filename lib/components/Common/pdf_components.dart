import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import '../../utils/pdf_theme.dart';

class PdfComponents {
  static pw.Widget buildHeader({
    required Uint8List logoBytes,
    required Uint8List logoIsoBytes,
  }) {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (logoBytes.isNotEmpty)
            pw.Image(
              pw.MemoryImage(logoBytes),
              width: 150,
              height: 40,
              fit: pw.BoxFit.contain,
            ),
          pw.Spacer(),
          if (logoIsoBytes.isNotEmpty)
            pw.Image(
              pw.MemoryImage(logoIsoBytes),
              width: 150,
              height: 40,
              fit: pw.BoxFit.contain,
            ),
        ],
      ),
    );
  }

  static pw.Widget buildFooter({
    required Uint8List logoAppBytes,
    int? pageNumber,
    int? totalPages,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Align(
          alignment: pw.Alignment.bottomLeft,
          child: pw.Text(
            'Av. Universidad No. 277 A, Col. Granjas Banthi\n'
            'San Juan del Río, Querétaro, C.P. 76806\n'
            'Tel: 427 268 5050\n'
            'e-mail: ingenieria@aggofc.com',
            style: PdfTheme.smallStyle,
            textAlign: pw.TextAlign.left,
          ),
        ),
        if (pageNumber != null && totalPages != null)
          pw.Align(
            alignment: pw.Alignment.bottomCenter,
            child: pw.Text(
              'Página $pageNumber de $totalPages',
              style: PdfTheme.smallStyle,
            ),
          ),
        if (logoAppBytes.isNotEmpty)
          pw.Align(
            alignment: pw.Alignment.bottomRight,
            child: pw.Image(
              pw.MemoryImage(logoAppBytes),
              width: 150,
              height: 40,
              fit: pw.BoxFit.contain,
            ),
          ),
      ],
    );
  }
}
