import '../api/api_client.dart';
import 'endpoints.dart';

class NotificacionesService {
  final _api = ApiClient().dio;

  Future<Map<String, dynamic>> enviarNotificacion(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.post(endpointEnviarNotificacion, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      return {
        'body': e.toString(),
        'status': 500,
      };
    }
  }
}
