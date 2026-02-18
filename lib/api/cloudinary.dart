import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../utils/constants.dart';

class CloudinaryService {
  final _dio =
      Dio(); // Specific dio for cloudinary if needed, or use the global one

  Future<String?> subirArchivoCloudinary(String imagePath, String carpeta,
      {int calidad = 65}) async {
    final file = File(imagePath);

    if (!await file.exists()) {
      debugPrint('El archivo no existe en la ruta proporcionada.');
      return null;
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath,
            contentType: DioMediaType('image', 'jpeg')),
        'upload_preset': 'cancun',
        'public_id':
            '$carpeta/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}',
        'folder': carpeta,
        'cloud_name': 'omarlestrella',
        'quality': calidad.toString(),
      });

      final response = await _dio.post(apiCloudinary, data: formData);

      if (response.statusCode == 200) {
        return response.data['secure_url'];
      } else {
        debugPrint(
            'Error al subir imagen a Cloudinary: ${response.statusCode}');
        debugPrint('Respuesta: ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('Excepción al subir a Cloudinary: $e');
      return null;
    }
  }
}
