import '../api/clientes.dart';
import '../api/models/cliente_model.dart';
import 'base_controller.dart';

class ClientesController extends BaseController {
  List<ClienteModel> dataClientes = [];
  final _clientesService = ClientesService();

  Future<void> cargarClientes() async {
    await fetchData<List<ClienteModel>>(
      fetchFromApi: () => _clientesService.listarClientes(),
      cacheBox: 'clientesBox',
      cacheKey: 'clientes',
      onDataReceived: (data) {
        dataClientes = data;
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataClientes = cachedData
              .map((item) =>
                  ClienteModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .where((item) => item.estado == "true")
              .toList();
        }
      },
      formatToCache: (data) => data.map((e) => e.toJson()).toList(),
    );
  }
}
