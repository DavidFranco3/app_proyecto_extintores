import '../../api/inspecciones.dart';
import 'base_controller.dart';

class InspeccionesController extends BaseController {
  List<Map<String, dynamic>> dataInspecciones = [];
  final _service = InspeccionesService();

  Future<void> cargarInspecciones(String clientId,
      {String cacheBox = 'inspeccionesBox'}) async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _service.listarInspeccionesDatos(clientId),
      cacheBox: cacheBox,
      cacheKey: 'inspecciones_$clientId',
      onDataReceived: (data) {
        dataInspecciones = _formatModel(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataInspecciones = List<Map<String, dynamic>>.from(cachedData
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
        'idUsuario': item['idUsuario'],
        'idCliente': item['idCliente'],
        'idEncuesta': item['idEncuesta'],
        'idRama': item['cuestionario']?['idRama'],
        'idClasificacion': item['cuestionario']?['idClasificacion'],
        'idFrecuencia': item['cuestionario']?['idFrecuencia'],
        'idCuestionario': item['cuestionario']?['_id'],
        'encuesta': item['encuesta'],
        'imagenes': item?['imagenes'] ?? [],
        'imagenesCloudinary': item?['imagenesCloudinary'] ?? [],
        'imagenes_finales': item?['imagenesFinales'] ?? [],
        'imagenes_finales_cloudinary': item?['imagenesFinalesCloudinary'] ?? [],
        'comentarios': item['comentarios'],
        'preguntas': item['encuesta'],
        'descripcion': item['descripcion'],
        'usuario': item['usuario']?['nombre'] ?? 'Sin usuario',
        'cliente': item['cliente']?['nombre'] ?? 'Sin cliente',
        'puestoCliente': item['cliente']?['puesto'] ?? 'Sin puesto',
        'responsableCliente':
            item['cliente']?['responsable'] ?? 'Sin responsable',
        'estadoDom':
            item['cliente']?['direccion']?['estadoDom'] ?? 'Sin estado',
        'municipio':
            item['cliente']?['direccion']?['municipio'] ?? 'Sin municipio',
        'imagen_cliente': item['cliente']?['imagen'],
        'imagen_cliente_cloudinary': item['cliente']?['imagenCloudinary'],
        'firma_usuario': item['usuario']?['firma'],
        'firma_usuario_cloudinary': item['usuario']?['firmaCloudinary'],
        'cuestionario': item['cuestionario']?['nombre'] ?? 'Sin cuestionario',
        'usuarios': item['usuario'],
        'inspeccion_eficiencias': item['inspeccionEficiencias'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }
}
