import '../../api/logs.dart';
import 'base_controller.dart';

class LogsController extends BaseController {
  List<Map<String, dynamic>> dataLogs = [];
  final _service = LogsService();

  Future<void> cargarLogs() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _service.listarLogs(),
      cacheBox: 'logsBox',
      cacheKey: 'logs',
      onDataReceived: (data) {
        dataLogs = _formatModel(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataLogs = List<Map<String, dynamic>>.from(
              cachedData.map((e) => Map<String, dynamic>.from(e)));
        }
      },
    );
  }

  List<Map<String, dynamic>> _formatModel(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'folio': item['folio'],
        'usuario': item['usuario'],
        'correo': item['correo'],
        'dispositivo': item['dispositivo'],
        'ip': item['ip'],
        'descripcion': item['descripcion'],
        'detalles': item['detalles']?['mensaje'] ?? '',
        'estado': "true", // Logs are generally always "true" or just historical
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }
}
