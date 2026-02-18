import '../api/frecuencias.dart';
import 'base_controller.dart';

class FrecuenciasController extends BaseController {
  List<Map<String, dynamic>> dataFrecuencias = [];
  final _frecuenciasService = FrecuenciasService();

  Future<void> cargarFrecuencias() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _frecuenciasService.listarFrecuencias(),
      cacheBox: 'frecuenciasBox',
      cacheKey: 'frecuencias',
      onDataReceived: (data) {
        dataFrecuencias = _formatModelFrecuencias(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataFrecuencias = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModelFrecuencias(data),
    );
  }

  List<Map<String, dynamic>> _formatModelFrecuencias(List<dynamic> data) {
    return data
        .map((item) => {
              'id': item['_id'],
              'nombre': item['nombre'],
              'cantidadDias': item['cantidadDias'],
              'estado': item['estado'],
              'createdAt': item['createdAt'],
              'updatedAt': item['updatedAt'],
            })
        .toList();
  }
}
