import '../api/ramas.dart';
import 'base_controller.dart';

class RamasController extends BaseController {
  List<Map<String, dynamic>> dataRamas = [];
  final _ramasService = RamasService();

  Future<void> cargarRamas() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _ramasService.listarRamas(),
      cacheBox: 'ramasBox',
      cacheKey: 'ramas',
      onDataReceived: (data) {
        dataRamas = _formatModelRamas(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataRamas = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModelRamas(data),
    );
  }

  List<Map<String, dynamic>> _formatModelRamas(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'nombre': item['nombre'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }
}
