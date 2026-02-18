import '../../api/extintores.dart';
import 'base_controller.dart';

class ExtintoresController extends BaseController {
  List<Map<String, dynamic>> dataExtintores = [];
  final _extintoresService = ExtintoresService();

  Future<void> cargarExtintores() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _extintoresService.listarExtintores(),
      cacheBox: 'extintoresBox',
      cacheKey: 'extintores',
      onDataReceived: (data) {
        dataExtintores = _formatModelExtintores(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataExtintores = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModelExtintores(data),
    );
  }

  List<Map<String, dynamic>> _formatModelExtintores(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'numeroSerie': item['numeroSerie'],
        'idTipoExtintor': item['idTipoExtintor'],
        'extintor': item['tipoExtintor']['nombre'],
        'capacidad': item['capacidad'],
        'ultimaRecarga': item['ultimaRecarga'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }
}
