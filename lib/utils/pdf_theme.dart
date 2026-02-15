import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfTheme {
  static const PdfColor primaryColor = PdfColors.blue900;
  static const PdfColor accentColor = PdfColors.grey700;
  static const PdfColor textColor = PdfColors.black;

  static pw.TextStyle get titleStyle => pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: primaryColor,
      );

  static pw.TextStyle get subtitleStyle => pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: accentColor,
      );

  static pw.TextStyle get bodyStyle => pw.TextStyle(
        fontSize: 10,
        color: textColor,
      );

  static pw.TextStyle get smallStyle => pw.TextStyle(
        fontSize: 8,
        color: PdfColors.grey600,
      );

  static pw.TextStyle get tableHeaderStyle => pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      );

  static pw.ThemeData get theme => pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
}
