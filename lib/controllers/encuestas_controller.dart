import '../../api/encuesta_inspeccion.dart';
import '../../api/frecuencias.dart';
import '../../api/clasificaciones.dart';
import 'base_controller.dart';

class EncuestasController extends BaseController {
  List<Map<String, dynamic>> dataEncuestas = [];
  List<Map<String, dynamic>> filteredEncuestas = [];
  List<Map<String, dynamic>> dataFrecuencias = [];
  List<Map<String, dynamic>> dataClasificaciones = [];

  String? selectedFrecuencia;
  String? selectedClasificacion;

  final _encuestaService = EncuestaInspeccionService();
  final _frecuenciaService = FrecuenciasService();
  final _clasificacionService = ClasificacionesService();

  Future<void> cargarTodo() async {
    setLoading(true);
    await Future.wait([
      cargarFrecuencias(),
      cargarClasificaciones(),
      cargarEncuestas(),
    ]);
    setLoading(false);
  }

  Future<void> cargarEncuestas() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _encuestaService.listarEncuestaInspeccion(),
      cacheBox: 'encuestasBox',
      cacheKey: 'encuestas',
      onDataReceived: (data) {
        dataEncuestas = _formatModelEncuestas(data);
        filterEncuestas();
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataEncuestas = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
          filterEncuestas();
        }
      },
      formatToCache: (data) => _formatModelEncuestas(data),
    );
  }

  Future<void> cargarFrecuencias() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _frecuenciaService.listarFrecuencias(),
      cacheBox: 'frecuenciasBox',
      cacheKey: 'frecuencias',
      onDataReceived: (data) {
        dataFrecuencias = _formatModelFrecuencias(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataFrecuencias = List<Map<String, dynamic>>.from(
              cachedData.map((e) => Map<String, dynamic>.from(e)));
        }
      },
      formatToCache: (data) => _formatModelFrecuencias(data),
    );
  }

  Future<void> cargarClasificaciones() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _clasificacionService.listarClasificaciones(),
      cacheBox: 'clasificacionesBox',
      cacheKey: 'clasificaciones',
      onDataReceived: (data) {
        dataClasificaciones = _formatModelClasificaciones(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataClasificaciones = List<Map<String, dynamic>>.from(
              cachedData.map((e) => Map<String, dynamic>.from(e)));
        }
      },
      formatToCache: (data) => _formatModelClasificaciones(data),
    );
  }

  void filterEncuestas() {
    filteredEncuestas = dataEncuestas.where((encuesta) {
      final frecuenciaMatch = selectedFrecuencia == null ||
          encuesta['frecuencia'] == selectedFrecuencia;
      final clasificacionMatch = selectedClasificacion == null ||
          encuesta['clasificacion'] == selectedClasificacion;
      return frecuenciaMatch && clasificacionMatch;
    }).toList();
    notifyListeners();
  }

  void setFrecuencia(String? value) {
    selectedFrecuencia = value;
    filterEncuestas();
  }

  void setClasificacion(String? value) {
    selectedClasificacion = value;
    filterEncuestas();
  }

  void clearFilters() {
    selectedFrecuencia = null;
    selectedClasificacion = null;
    filteredEncuestas = dataEncuestas;
    notifyListeners();
  }

  List<Map<String, dynamic>> _formatModelEncuestas(List<dynamic> data) {
    return data.map((item) {
      return {
        'id': item['_id'],
        'nombre': item['nombre'],
        'idFrecuencia': item['idFrecuencia'],
        'idClasificacion': item['idClasificacion'],
        'idRama': item['idRama'],
        'frecuencia': item['frecuencia']['nombre'],
        'clasificacion': item['clasificacion']['nombre'],
        'rama': item['rama']['nombre'],
        'preguntas': item['preguntas'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
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

  List<Map<String, dynamic>> _formatModelClasificaciones(List<dynamic> data) {
    return data
        .map((item) => {
              'id': item['_id'],
              'nombre': item['nombre'],
              'descripcion': item['descripcion'],
              'estado': item['estado'],
              'createdAt': item['createdAt'],
              'updatedAt': item['updatedAt'],
            })
        .toList();
  }
}
