import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

class DropboxService {
  final _dio = Dio();

  Future<String> obtenerAccessToken() async {
    try {
      final response = await _dio.post(
        'https://api.dropboxapi.com/oauth2/token',
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': dropboxRefreshToken,
          'client_id': 'eg2n5msy608v3kb',
          'client_secret': 'ee3ga615b3lulxg',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['access_token'];
        debugPrint('Nuevo access token: $accessToken');
        return accessToken;
      } else {
        throw Exception(
            'Error al obtener el access token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al obtener el token de acceso: $e');
      throw Exception('Error al obtener el access token');
    }
  }

  /// Sube una imagen a Dropbox y devuelve el enlace compartido.
  Future<String?> uploadImageToDropbox(String imagePath, String path) async {
    try {
      final String accessToken = await obtenerAccessToken();
      final file = File(imagePath);
      final fileBytes = await file.readAsBytes();
      final fileName = file.uri.pathSegments.last;
      final dropboxFolderPath = '/AGOO/$path/$fileName';

      final response = await _dio.post(
        apiDropbox,
        data: Stream.fromIterable([fileBytes]),
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/octet-stream',
            'Dropbox-API-Arg': {
              'path': dropboxFolderPath,
              'mode': 'add',
              'autorename': true,
              'mute': false,
            },
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('Imagen subida con éxito a Dropbox');
        final sharedLink =
            await _getSharedLink(accessToken, response.data['path_display']);
        debugPrint('Enlace compartido de la imagen: $sharedLink');
        return sharedLink;
      } else {
        debugPrint('Error al subir la imagen: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Excepción al subir a Dropbox: $e');
      return null;
    }
  }

  /// Obtiene un enlace compartido público de Dropbox.
  Future<String?> _getSharedLink(String accessToken, String filePath) async {
    try {
      final response = await _dio.post(
        apiDropboxEnlace,
        data: {
          'path': filePath,
          'settings': {
            'requested_visibility': 'public',
          },
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['url'];
      } else {
        debugPrint(
            'Error al obtener el enlace compartido: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Excepción al obtener enlace Dropbox: $e');
      return null;
    }
  }
}
