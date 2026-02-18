import '../../api/tipos_extintores.dart';
import 'base_controller.dart';

class TiposExtintoresController extends BaseController {
  List<Map<String, dynamic>> dataTiposExtintores = [];
  final _tiposExtintoresService = TiposExtintoresService();

  Future<void> cargarTiposExtintores() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _tiposExtintoresService.listarTiposExtintores(),
      cacheBox: 'tiposExtintoresBox',
      cacheKey: 'tiposExtintores',
      onDataReceived: (data) {
        dataTiposExtintores = _formatModelTiposExtintores(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataTiposExtintores = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModelTiposExtintores(data),
    );
  }

  List<Map<String, dynamic>> _formatModelTiposExtintores(List<dynamic> data) {
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
