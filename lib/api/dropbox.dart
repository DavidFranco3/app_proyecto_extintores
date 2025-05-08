import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../utils/constants.dart'; // Asegúrate de tener tu API_DROPBOX, API_DROPBOX_ENLACE, dropboxRefreshToken, etc.

class DropboxService {
  /// Obtener nuevo access token con refresh_token
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
      print('Nuevo access token: $accessToken');
      return accessToken;
    } else {
      print('Error al obtener el token de acceso: ${response.statusCode}');
      print('Respuesta: ${response.body}');
      throw Exception('Error al obtener el access token');
    }
  }

  /// Comprime la imagen localmente antes de subirla
  Future<File> comprimirImagen(String path, {int calidad = 40}) async {
    final originalFile = File(path);
    final bytes = await originalFile.readAsBytes();
    final imagen = img.decodeImage(bytes);
    if (imagen == null) throw Exception('No se pudo leer la imagen');

    final comprimido = img.encodeJpg(imagen, quality: calidad);
    final nuevoPath =
        '${originalFile.parent.path}/compressed_${originalFile.uri.pathSegments.last}';
    final nuevoArchivo = File(nuevoPath);
    await nuevoArchivo.writeAsBytes(comprimido);
    return nuevoArchivo;
  }

  /// Sube una imagen comprimida a Dropbox y devuelve el enlace compartido.
  Future<String?> uploadImageToDropbox(String imagePath, String path, {int calidad = 65}) async {
    final String accessToken = await obtenerAccessToken();
    final file = await comprimirImagen(imagePath, calidad: calidad); // imagen comprimida
    final fileBytes = await file.readAsBytes();
    final fileName = file.uri.pathSegments.last;
    final dropboxFolderPath = '/AGOO/$path/$fileName';

    final response = await http.post(
      Uri.parse(API_DROPBOX),
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
      print('Imagen subida con éxito a Dropbox');
      final responseData = json.decode(response.body);

      final sharedLink =
          await _getSharedLink(accessToken, responseData['path_display']);
      print('Enlace compartido de la imagen: $sharedLink');
      return sharedLink;
    } else {
      print('Error al subir la imagen: ${response.statusCode}');
      print('Respuesta: ${response.body}');
      return null;
    }
  }

  /// Obtiene un enlace compartido público de Dropbox.
  Future<String?> _getSharedLink(String accessToken, String filePath) async {
    final response = await http.post(
      Uri.parse(API_DROPBOX_ENLACE),
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
      print('Error al obtener el enlace compartido: ${response.statusCode}');
      print('Respuesta: ${response.body}');
      return null;
    }
  }
}
