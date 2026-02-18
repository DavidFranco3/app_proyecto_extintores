import '../../api/inspecciones_proximas.dart';
import 'base_controller.dart';

class InspeccionesProximasController extends BaseController {
  List<Map<String, dynamic>> dataInspeccionesProximas = [];
  final _service = InspeccionesProximasService();

  Future<void> cargarInspeccionesProximas() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _service.listarInspeccionesProximas(),
      cacheBox: 'inspeccionesProximasBox',
      cacheKey: 'inspecciones_proximas',
      onDataReceived: (data) {
        dataInspeccionesProximas = _formatModel(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataInspeccionesProximas = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModel(data),
    );
  }

  List<Map<String, dynamic>> _formatModel(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'idFrecuencia': item['idFrecuencia'],
        'idEncuesta': item['idEncuesta'],
        'idCliente': item['idCliente'],
        'cuestionario': item['cuestionario']['nombre'],
        'frecuencia': item['frecuencia']['nombre'],
        'cliente': item['cliente']['nombre'],
        'proximaInspeccion': item['nuevaInspeccion'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }
}
