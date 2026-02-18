import '../../api/clasificaciones.dart';
import 'base_controller.dart';

class ClasificacionesController extends BaseController {
  List<Map<String, dynamic>> dataClasificaciones = [];
  final _clasificacionesService = ClasificacionesService();

  Future<void> cargarClasificaciones() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _clasificacionesService.listarClasificaciones(),
      cacheBox: 'clasificacionesBox',
      cacheKey: 'clasificaciones',
      onDataReceived: (data) {
        dataClasificaciones = _formatModelClasificaciones(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataClasificaciones = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModelClasificaciones(data),
    );
  }

  List<Map<String, dynamic>> _formatModelClasificaciones(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'nombre': item['nombre'],
        'descripcion': item['descripcion'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }
}
