import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PdfUtils {
  /// Loads an image from the asset bundle.
  static Future<Uint8List> loadAssetImage(String path) async {
    try {
      final byteData = await rootBundle.load(path);
      return Uint8List.fromList(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading asset image $path: $e');
      return Uint8List(0);
    }
  }

  /// Downloads an image from a URL.
  /// Handles Dropbox links by replacing 'dl=0' with 'dl=1'.
  static Future<Uint8List?> downloadImage(String? url) async {
    if (url == null || url.isEmpty) return null;

    final correctedUrl = url.replaceAll("dl=0", "dl=1");
    try {
      final response = await http.get(Uri.parse(correctedUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
    }
    return null;
  }

  /// Formats a date string (ISO format) to a readable format.
  /// Example: "Lunes 15 de Enero de 2024"
  static String formatDate(String dateStr) {
    try {
      final parsedDate = DateTime.parse(dateStr);
      final localDate = parsedDate.toLocal();
      // Ensure 'es_ES' locale is initialized in your app or use default
      final dateFormat = DateFormat("EEEE d 'de' MMMM 'de' yyyy", 'es_ES');
      return dateFormat.format(localDate);
    } catch (e) {
      return dateStr;
    }
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd-MM-yy').format(date);
  }

  /// Capitalizes the first letter of each word in a string.
  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Removes accents and special characters for PDF compatibility (Helvetica).
  static String removeAccents(String text) {
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';

    String str = text;
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }

    // Replace other common problematic characters if any
    return str;
  }
}
