import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart'; // Importa el archivo donde definiste los endpoints

class DropboxService {
  Future<String> obtenerAccessToken() async {
    final url = Uri.parse('https://api.dropboxapi.com/oauth2/token');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': dropboxRefreshToken,
        'client_id': 'eg2n5msy608v3kb',
        'client_secret': 'ee3ga615b3lulxg',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final accessToken = data['access_token'];
      debugPrint('Nuevo access token: $accessToken');
      return accessToken;
    } else {
      debugPrint('Error al obtener el token de acceso: ${response.statusCode}');
      debugPrint('Respuesta: ${response.body}');
      throw Exception('Error al obtener el access token');
    }
  }

  /// Sube una imagen a Dropbox y devuelve el enlace compartido.
  Future<String?> uploadImageToDropbox(String imagePath, String path) async {
    final String accessToken =
        await obtenerAccessToken(); // Obtiene el token actualizado
    final file = File(imagePath);
    final fileBytes = await file.readAsBytes();
    final fileName = file.uri.pathSegments.last;
    final dropboxFolderPath = '/AGOO/$path/$fileName';
    final response = await http.post(
      Uri.parse(apiDropbox),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/octet-stream',
        'Dropbox-API-Arg': json.encode({
          'path': dropboxFolderPath,
          'mode': 'add',
          'autorename': true,
          'mute': false,
        }),
      },
      body: fileBytes,
    );

    if (response.statusCode == 200) {
      debugPrint('Imagen subida con éxito a Dropbox');
      final responseData = json.decode(response.body);

      // Obtener el enlace compartido de la imagen
      final sharedLink =
          await _getSharedLink(accessToken, responseData['path_display']);
      debugPrint('Enlace compartido de la imagen: $sharedLink');
      return sharedLink;
    } else {
      debugPrint('Error al subir la imagen: ${response.statusCode}');
      debugPrint('Respuesta: ${response.body}');
      return null;
    }
  }

  /// Obtiene un enlace compartido público de Dropbox.
  Future<String?> _getSharedLink(String accessToken, String filePath) async {
    final response = await http.post(
      Uri.parse(apiDropboxEnlace),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'path': filePath,
        'settings': {
          'requested_visibility': 'public',
        },
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['url'];
    } else {
      debugPrint('Error al obtener el enlace compartido: ${response.statusCode}');
      debugPrint('Respuesta: ${response.body}');
      return null;
    }
  }
}


