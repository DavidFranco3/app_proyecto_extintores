import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';  // Importación necesaria

class CloudinaryService {
  static const String API_CLOUDINARY = 'https://api.cloudinary.com/v1_1/omarlestrella/image/upload';
  static const String UPLOAD_PRESET = 'cancun';

  // Subir archivo a Cloudinary
  Future<Map<String, dynamic>> subeArchivosCloudinary(File imagen, String carpeta, {int calidad = 65}) async {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imagen.uri.pathSegments.last}';
    final String folder = carpeta;

    final request = http.MultipartRequest('POST', Uri.parse(API_CLOUDINARY))
      ..fields['upload_preset'] = UPLOAD_PRESET
      ..fields['public_id'] = '$folder/$fileName'
      ..fields['folder'] = folder
      ..fields['cloud_name'] = 'omarlestrella'
      ..fields['quality'] = calidad.toString(); // Agregar calidad como parámetro

    // Obtener el tipo MIME del archivo
    final mimeType = lookupMimeType(imagen.path);
    final file = await http.MultipartFile.fromPath('file', imagen.path, contentType: mimeType != null ? MediaType.parse(mimeType) : null);
    request.files.add(file);

    final response = await request.send();

    // Esperar respuesta
    final responseString = await response.stream.bytesToString();
    final responseJson = jsonDecode(responseString);

    return responseJson;
  }
}
