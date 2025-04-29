import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/constants.dart';

class CloudinaryService {
  Future<String?> subirArchivoCloudinary(String imagePath, String carpeta, {int calidad = 65}) async {
    final uri = Uri.parse(API_CLOUDINARY);
    final file = File(imagePath);

    if (!await file.exists()) {
      print('El archivo no existe en la ruta proporcionada.');
      return null;
    }

    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    request.fields['upload_preset'] = 'cancun';
    request.fields['public_id'] =
        '$carpeta/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    request.fields['folder'] = carpeta;
    request.fields['cloud_name'] = 'omarlestrella';
    request.fields['quality'] = calidad.toString();

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['secure_url']; // Aquí ya devuelves el URL directamente
    } else {
      print('Error al subir imagen a Cloudinary: ${response.statusCode}');
      print('Respuesta: ${response.body}');
      return null;
    }
  }
}
