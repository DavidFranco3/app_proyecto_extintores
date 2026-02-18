import '../../api/usuarios.dart';
import 'base_controller.dart';

class UsuariosController extends BaseController {
  List<Map<String, dynamic>> dataUsuarios = [];
  final _service = UsuariosService();

  Future<void> cargarUsuarios() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _service.listarUsuarios(),
      cacheBox: 'usuariosBox',
      cacheKey: 'usuarios',
      onDataReceived: (data) {
        dataUsuarios = _formatModel(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataUsuarios = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) =>
                  item['estado'] == "true" || item['estado'] == null));
        }
      },
      formatToCache: (data) => _formatModel(data),
    );
  }

  List<Map<String, dynamic>> _formatModel(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'nombre': item['nombre'],
        'email': item['email'],
        'telefono': item['telefono'],
        'tipo': item['tipo'],
        'estado': item['estado'] ?? "true",
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }
}
