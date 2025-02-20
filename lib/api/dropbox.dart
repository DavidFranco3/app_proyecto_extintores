import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart'; // Importa el archivo donde definiste los endpoints

class DropboxService {
  Future<String?> uploadImageToDropbox(String imagePath) async {
    final file = File(imagePath);
    final fileBytes = await file.readAsBytes();
    final fileName = file.uri.pathSegments.last;
    final dropboxFolderPath = '/extintores/inspecciones';

    // URL de la API de Dropbox para subir archivos
    final url = Uri.parse(API_DROPBOX);

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $dropboxAccessToken', // Autenticación con el Access Token
        'Content-Type': 'application/octet-stream', // El tipo de contenido es binary
        'Dropbox-API-Arg': json.encode({
          'path': '$dropboxFolderPath/$fileName', // Ruta del archivo con la carpeta
          'mode': 'add', // Añadir el archivo si no existe
          'autorename': true, // Renombrar si el archivo ya existe
          'mute': false, // Evitar notificaciones por subida
        }),
      },
      body: fileBytes, // Enviar los bytes del archivo
    );

    if (response.statusCode == 200) {
      print('Imagen subida con éxito a Dropbox');
      final responseData = json.decode(response.body);

      // Una vez subida la imagen, obtener el enlace compartido
      final sharedLink = await _getSharedLink(responseData['path_display']);
      print('Enlace compartido de la imagen: $sharedLink');
      
      return sharedLink; // Retornar el enlace
    } else {
      print('Error al subir la imagen: ${response.statusCode}');
      print('Respuesta: ${response.body}');
      return null;
    }
  }

  Future<String?> _getSharedLink(String filePath) async {
    final url = Uri.parse(API_DROPBOX_ENLACE);

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $dropboxAccessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'path': filePath, // El path de Dropbox del archivo
        'settings': {
          'requested_visibility': 'public',
        },
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['url']; // Retorna el enlace
    } else {
      print('Error al obtener el enlace compartido: ${response.statusCode}');
      print('Respuesta: ${response.body}');
      return null;
    }
  }
}
