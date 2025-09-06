import 'package:flutter/material.dart';
import '../../api/encuesta_inspeccion_cliente.dart';
import '../../api/inspecciones.dart';
import '../../api/clasificaciones.dart';
import '../../api/frecuencias.dart';
import '../../api/auth.dart';
import '../../api/ramas.dart';
import '../../api/clientes.dart';
import '../../api/dropbox.dart';
import '../../api/cloudinary.dart';
import '../../api/inspecciones_proximas.dart';
import '../../components/Logs/logs_informativos.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../../components/Generales/flushbar_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EncuestaPage extends StatefulWidget {
  const EncuestaPage({super.key}); // <-- super parameter
  @override
  EncuestaPageState createState() => EncuestaPageState();
}

class EncuestaPageState extends State<EncuestaPage> {
  List<Pregunta> preguntas = [];
  List<Map<String, dynamic>> dataEncuestas = [];
  List<Map<String, dynamic>> dataRamas = [];
  String? selectedEncuestaId;
  String? selectedRamaId;
  String? selectedClienteId;
  String? selectedFrecuenciaId;
  bool loading = true;
  bool _isLoading = false;
  int currentPage = 0; // Para controlar la página actual
  final int preguntasPorPagina = 5; // Número de preguntas por página
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> dataClientes = [];
  String? selectedIdFrecuencia;
  String? selectedIdClasificacion;

  List<Map<String, dynamic>> registrosEficiencia = [];

  List<Map<String, dynamic>> dataFrecuencias = [];

  List<Map<String, dynamic>> dataClasificaciones = [];

  // Lista para almacenar imágenes y comentarios
  List<Map<String, dynamic>> imagePaths = [];

  List<Map<String, dynamic>> uploadedImageLinks =
      []; // Array para guardar objetos con enlaces y comentarios

  List<Map<String, dynamic>> uploadedImageLinksCloudinary =
      []; // Array para guardar objetos con enlaces y comentarios

  String linkFirma = "";
  String linkFirmaCloudinary = "";

  late TextEditingController descripcionController;
  late TextEditingController comentariosController;
  late TextEditingController comentariosImagenController;

  late TextEditingController descripcionEficienciaController;
  late TextEditingController comentariosEficienciaController;
  String? calificacionSeleccionada;
  File? imagenSeleccionada;

  String imagenEficiencia = "";
  String imagenEficienciaCloudinary = "";

  List<Map<String, dynamic>> uploadedEficiencias =
      []; // Array para guardar objetos con enlaces y comentarios

  Future<void> seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.camera);

    if (imagen != null) {
      setState(() {
        imagenSeleccionada = File(imagen.path);
      });
    }
  }

  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  void limpiarCampos() {
    preguntas = [];
    selectedEncuestaId = null;
    selectedRamaId = null;
    selectedClienteId = null;
    selectedFrecuenciaId = null;
    selectedIdFrecuencia = null;
    selectedIdClasificacion = null;

    uploadedImageLinks = [];

    uploadedImageLinksCloudinary = [];

    imagePaths = [];

    linkFirma = "";
    linkFirmaCloudinary = "";

    dataEncuestas = [];

    comentariosController.clear();
    descripcionController.clear();

    comentariosEficienciaController.clear();
    descripcionEficienciaController.clear();
    calificacionSeleccionada = null;
    imagenSeleccionada = null;

    _controller.clear();
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion == ConnectivityResult.none) return false;
    return await InternetConnection().hasInternetAccess;
  }

  @override
  void initState() {
    super.initState();
    getRamas();
    getClientes();
    getFrecuencias();
    getClasificaciones();

    _pageController.addListener(() {
      setState(() {
        currentPage = _pageController.page!.round();
      });
    });

    comentariosController = TextEditingController();
    descripcionController = TextEditingController();

    descripcionEficienciaController = TextEditingController();
    comentariosEficienciaController = TextEditingController();

    sincronizarEncuestasPendientes();

    Connectivity().onConnectivityChanged.listen((event) {
      if (event != ConnectivityResult.none) {
        sincronizarEncuestasPendientes();
      }
    });
  }

  @override
  void dispose() {
    comentariosController.dispose();
    descripcionController.dispose();
    super.dispose();
  }

  Future<void> sincronizarEncuestasPendientes() async {
    final conectado = await verificarConexion();
    if (!conectado) return;

    final box = Hive.box('encuestasPendientes');
    final pendientesRaw = box.get('encuestas', defaultValue: []);
    final List<Map<String, dynamic>> pendientes = (pendientesRaw as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final inspeccionesService = InspeccionesService();
    final List<int> exitosas = [];

    for (int i = 0; i < pendientes.length; i++) {
      final operacion = pendientes[i];
      try {
        if (operacion['accion'] == 'registrar') {
          final response =
              await inspeccionesService.registraInspecciones(operacion['data']);
          if (response['status'] == 200) {
            exitosas.add(i); // índice de la operación exitosa
          }
        }
      } catch (e) {
        print("Error sincronizando encuesta: $e");
      }
    }

    // 🔄 Limpiar las encuestas que se sincronizaron
    final nuevasPendientes = pendientes
        .asMap()
        .entries
        .where((entry) => !exitosas.contains(entry.key))
        .map((e) => e.value)
        .toList();
    await box.put('encuestas', nuevasPendientes);
  }

  void agregarRegistro() {
    if (descripcionEficienciaController.text.isEmpty ||
        calificacionSeleccionada == null ||
        comentariosEficienciaController.text.isEmpty ||
        imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor, completa todos los campos")),
      );
      return;
    }

    registrosEficiencia.add({
      'descripcion': descripcionEficienciaController.text,
      'calificacion': calificacionSeleccionada,
      'comentarios': comentariosEficienciaController.text,
      'imagen': imagenSeleccionada, // puedes guardar solo la ruta si quieres
    });

    // Limpiar los campos
    imagenSeleccionada = null;

    setState(() {}); // Para que se actualice visualmente
    print(registrosEficiencia);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Registro agregado correctamente")),
    );
  }

  Future<Map<String, dynamic>> obtenerDatosComunes(String token) async {
    try {
      final authService = AuthService();

      // Obtener el id del usuario
      final idUsuario = await authService.obtenerIdUsuarioLogueado(token);
      print('ID Usuario obtenido: $idUsuario');

      return {'idUsuario': idUsuario};
    } catch (e) {
      print('Error al obtener datos comunes: $e');
      rethrow; // Lanza el error para que lo maneje la función que lo llamó
    }
  }

  Future<void> getClientes() async {
    final conectado = await verificarConexion();
    if (conectado) {
      print("Conectado a internet");
      await getClientesDesdeAPI();
    } else {
      print("Sin conexión, cargando desde Hive...");
      await getClientesDesdeHive();
    }
  }

  Future<void> getClientesDesdeAPI() async {
    try {
      final clientesService = ClientesService();
      final List<dynamic> response = await clientesService.listarClientes();

      if (response.isNotEmpty) {
        final formateadas = formatModelClientes(response);

        final box = Hive.box('clientesBox');
        await box.put('clientes', formateadas);

        if (mounted) {
          setState(() {
            dataClientes = formateadas;
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            dataClientes = [];
            loading = false;
          });
        }
      }
    } catch (e) {
      print("Error al obtener los clientes: $e");
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getClientesDesdeHive() async {
    final box = Hive.box('clientesBox');
    final List<dynamic>? guardados = box.get('clientes');

    if (guardados != null) {
      if (mounted) {
        setState(() {
          dataClientes = guardados
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item as Map))
              .where((item) => item['estado'] == "true")
              .toList();
          loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          dataClientes = [];
          loading = false;
        });
      }
    }
  }

  Future<void> getRamas() async {
    try {
      final conectado = await verificarConexion();
      if (conectado) {
        await getRamasDesdeAPI();
      } else {
        await getRamasDesdeHive();
      }
    } catch (e) {
      print("Error general al cargar ramas: $e");
      setState(() {
        dataRamas = [];
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getRamasDesdeAPI() async {
    final ramasService = RamasService();
    final List<dynamic> response = await ramasService.listarRamas();

    if (response.isNotEmpty) {
      final formateadas = formatModelRamas(response);

      final box = Hive.box('ramasBox');
      await box.put('ramas', formateadas);

      setState(() {
        dataRamas = formateadas;
      });
    }
  }

  Future<void> getRamasDesdeHive() async {
    final box = Hive.box('ramasBox');
    final List<dynamic>? guardadas = box.get('ramas');

    if (guardadas != null) {
      final locales = List<Map<String, dynamic>>.from(guardadas
          .map((e) => Map<String, dynamic>.from(e))
          .where((item) => item['estado'] == "true"));

      setState(() {
        dataRamas = locales;
      });
    }
  }

  // Función para formatear los datos de las clasificaciones
  List<Map<String, dynamic>> formatModelRamas(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  Future<void> getFrecuencias() async {
    final conectado = await verificarConexion();

    if (conectado) {
      await getFrecuenciasDesdeAPI();
    } else {
      print("Sin conexión, cargando desde Hive...");
      await getFrecuenciasDesdeHive();
    }
  }

  Future<void> getFrecuenciasDesdeAPI() async {
    try {
      final frecuenciasService = FrecuenciasService();
      final List<dynamic> response =
          await frecuenciasService.listarFrecuencias();

      if (response.isNotEmpty) {
        final formateados = formatModelFrecuencias(response);

        // Guardar en Hive
        final box = Hive.box('frecuenciasBox');
        await box.put('frecuencias', formateados);

        setState(() {
          dataFrecuencias = formateados;
          loading = false;
        });
      } else {
        setState(() {
          dataFrecuencias = [];
          loading = false;
        });
      }
    } catch (e) {
      print("Error al obtener las frecuencias: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getFrecuenciasDesdeHive() async {
    try {
      final box = Hive.box('frecuenciasBox');
      final List<dynamic>? guardados = box.get('frecuencias');

      if (guardados != null) {
        setState(() {
          dataFrecuencias = guardados
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item))
              .where((item) => item['estado'] == "true")
              .toList();
          loading = false;
        });
      } else {
        setState(() {
          dataFrecuencias = [];
          loading = false;
        });
      }
    } catch (e) {
      print("Error leyendo desde Hive: $e");
      setState(() {
        loading = false;
      });
    }
  }

  // Función para formatear los datos de las frecuencias
  List<Map<String, dynamic>> formatModelFrecuencias(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'cantidadDias': item['cantidadDias'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  Future<void> getClasificaciones() async {
    final conectado = await verificarConexion();
    if (conectado) {
      print("Conectado a internet");
      await getClasificacionesDesdeAPI();
    } else {
      print("Sin conexión, cargando desde Hive...");
      await getClasificacionesDesdeHive();
    }
  }

  Future<void> getClasificacionesDesdeAPI() async {
    try {
      final clasificacionesService = ClasificacionesService();
      final List<dynamic> response =
          await clasificacionesService.listarClasificaciones();

      if (response.isNotEmpty) {
        final formateadas = formatModelClasificaciones(response);

        // Guardar en Hive
        final box = Hive.box('clasificacionesBox');
        await box.put('clasificaciones', formateadas);

        setState(() {
          dataClasificaciones = formateadas;
          loading = false;
        });
      } else {
        setState(() {
          dataClasificaciones = [];
          loading = false;
        });
      }
    } catch (e) {
      print("Error al obtener las clasificaciones: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getClasificacionesDesdeHive() async {
    final box = Hive.box('clasificacionesBox');
    final List<dynamic>? guardadas = box.get('clasificaciones');

    if (guardadas != null) {
      final filtradas = guardadas
          .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map))
          .where((item) => item['estado'] == "true")
          .toList();

      setState(() {
        dataClasificaciones = filtradas;
        loading = false;
      });
    } else {
      setState(() {
        dataClasificaciones = [];
        loading = false;
      });
    }
  }

  // Función para formatear los datos de las clasificaciones
  List<Map<String, dynamic>> formatModelClasificaciones(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'descripcion': item['descripcion'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  Future<String> saveImage(Uint8List imageBytes) async {
    try {
      // Obtener el directorio de caché de la aplicación
      final directory = await getTemporaryDirectory();

      // Construir la ruta del archivo (formato PNG)
      final filePath =
          '${directory.path}/8808c45a-a5f8-4fa1-9007-b95295c174a1/1002317481.png';

      // Crear el directorio si no existe
      final fileDirectory =
          Directory('${directory.path}/8808c45a-a5f8-4fa1-9007-b95295c174a1');
      if (!await fileDirectory.exists()) {
        await fileDirectory.create(recursive: true);
      }

      // Convertir los bytes a imagen (no usar librería 'image' si no es necesario)
      final image = await decodeImageFromList(imageBytes);

      // Crear un archivo para guardar la imagen
      final file = File(filePath);

      // Convertir la imagen a PNG y guardarla, asegurándose de que sea transparente
      final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);

      if (pngBytes != null) {
        await file.writeAsBytes(pngBytes.buffer.asUint8List());
        print('Imagen guardada en: $filePath');
      }

      // Retornar la ruta del archivo
      return filePath;
    } catch (e) {
      print('Error guardando la imagen: $e');
      return ''; // Valor vacío en caso de error
    }
  }

  // Función para formatear los datos de las clientes
  List<Map<String, dynamic>> formatModelClientes(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'correo': item['correo'],
        'telefono': item['telefono'],
        'calle': item['direccion']['calle'],
        'nExterior': item['direccion']['nExterior']?.isNotEmpty ?? false
            ? item['direccion']['nExterior']
            : 'S/N',
        'nInterior': item['direccion']['nInterior']?.isNotEmpty ?? false
            ? item['direccion']['nInterior']
            : 'S/N',
        'colonia': item['direccion']['colonia'],
        'estadoDom': item['direccion']['estadoDom'],
        'municipio': item['direccion']['municipio'],
        'cPostal': item['direccion']['cPostal'],
        'referencia': item['direccion']['referencia'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  Future<void> getEncuestas(String idRama, String idFrecuencia,
      String idClasificacion, String idCliente) async {
    final conectado = await verificarConexion();
    if (conectado) {
      print("Conectado a internet, obteniendo encuestas desde API...");
      await getEncuestasDesdeAPI(
          idRama, idFrecuencia, idClasificacion, idCliente);
    } else {
      print("Sin conexión, cargando encuestas desde Hive...");
      await getEncuestasDesdeHive(
          idRama, idFrecuencia, idClasificacion, idCliente);
    }
  }

  Future<void> getEncuestasDesdeAPI(String idRama, String idFrecuencia,
      String idClasificacion, String idCliente) async {
    try {
      final encuestaService = EncuestaInspeccionClienteService();
      final List<dynamic> response = await encuestaService
          .listarEncuestaInspeccionClientePorRamaPorCliente(
              idRama, idFrecuencia, idClasificacion, idCliente);

      if (response.isNotEmpty) {
        final formateadas = formatModelEncuestas(response);

        // Guardar en Hive
        final box = Hive.box('encuestasBox');
        await box.put('encuestas', formateadas);

        setState(() {
          dataEncuestas = formateadas;
          loading = false;
        });
      } else {
        setState(() {
          dataEncuestas = [];
          loading = false;
        });
      }
    } catch (e) {
      print("Error al obtener las encuestas: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getEncuestasDesdeHive(String idRama, String idFrecuencia,
      String idClasificacion, String idCliente) async {
    final box = Hive.box('encuestasBox');
    final List<dynamic>? guardadas = box.get('encuestas');

    if (guardadas != null) {
      // Filtrar encuestas según los parámetros recibidos
      final filtradas = guardadas
          .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map))
          .where((item) =>
              item['idRama'] == idRama &&
              item['idFrecuencia'] == idFrecuencia &&
              item['idClasificacion'] == idClasificacion &&
              item['idCliente'] == idCliente)
          .toList();

      setState(() {
        dataEncuestas = filtradas;
        loading = false;
      });
    } else {
      setState(() {
        dataEncuestas = [];
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> formatModelEncuestas(List<dynamic> data) {
    final Map<String, Map<String, dynamic>> uniqueByName = {};

    for (var item in data) {
      // Sobrescribe cualquier entrada previa con el mismo nombre
      uniqueByName[item['nombre']] = {
        'id': item['_id'],
        'nombre': item['nombre'],
        'idFrecuencia': item['idFrecuencia'],
        'preguntas': item['preguntas'],
      };
    }

    // Devuelve solo los valores (últimos registros por nombre)
    return uniqueByName.values.toList();
  }

  // Actualiza las preguntas cuando se selecciona una encuesta
  void actualizarPreguntas(String encuestaId) {
    final encuesta =
        dataEncuestas.firstWhere((encuesta) => encuesta['id'] == encuestaId);
    setState(() {
      preguntas = (encuesta['preguntas'] as List<dynamic>).map((pregunta) {
        return Pregunta(
          titulo: pregunta['titulo'],
          observaciones: "",
          opciones: List<String>.from(pregunta['opciones']),
        );
      }).toList();
    });
  }

  List<Map<String, String>> obtenerRespuestasParaGuardar() {
    return preguntas.map((pregunta) {
      return {
        "pregunta": pregunta.titulo,
        "observaciones": pregunta.observaciones,
        "respuesta": pregunta.respuesta.isNotEmpty
            ? pregunta.respuesta
            : "No respondida",
      };
    }).toList();
  }

  void _guardarEncuesta(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    // Validación de campos obligatorios
    if (selectedEncuestaId == null ||
        selectedRamaId == null ||
        selectedFrecuenciaId == null ||
        selectedClienteId == null) {
      setState(() {
        _isLoading = false;
      });
      showCustomFlushbar(
        context: context,
        title: "Campos incompletos",
        message:
            "Por favor, completa todos los campos obligatorios antes de continuar.",
        backgroundColor: Colors.red,
      );
      return;
    }

    var dataTemp = {
      'idUsuario': data['idUsuario'],
      'idCliente': data['idCliente'],
      'idEncuesta': data['idEncuesta'],
      'encuesta': data['preguntas'],
      'comentarios': data['comentarios'] ?? "",
      'imagenes': data['imagenes'],
      'imagenesCloudinary': data['imagenesCloudinary'],
      'firmaCliente': data['firmaCliente'] ?? "",
      'firmaClienteCloudinary': data['firmaClienteCloudinary'] ?? "",
      "inspeccionEficiencias": data['inspeccionEficiencias'],
      'cerrado': "true",
      'estado': "true",
    };

    try {
      final inspeccionesService = InspeccionesService();
      var response = await inspeccionesService.registraInspecciones(dataTemp);

      if (response['status'] == 200) {
        var dataFrecuencia = {
          'idFrecuencia': selectedIdFrecuencia,
          'idCliente': data['idCliente'],
          'idEncuesta': data['idEncuesta'],
          'estado': "true",
        };

        final inspeccionesProximasService = InspeccionesProximasService();
        await inspeccionesProximasService
            .registraInspeccionesProximas(dataFrecuencia);

        setState(() {
          _isLoading = false;
          limpiarCampos();
        });

        LogsInformativos(
          "Se ha registrado la inspección ${data['idCliente']} correctamente",
          dataFrecuencia,
        );

        showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "Los datos de la encuesta fueron llenados correctamente",
          backgroundColor: Colors.green,
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        showCustomFlushbar(
          context: context,
          title: "Error",
          message:
              "Hubo un problema al registrar la encuesta. Inténtalo nuevamente.",
          backgroundColor: Colors.red,
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      // ❌ Si falla, guardar localmente
      final box = Hive.box('encuestasPendientes');
      List pendientes = box.get('encuestas', defaultValue: []);
      pendientes.add({
        'accion': 'registrar',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await box.put('encuestas', pendientes);

      setState(() => _isLoading = false);
      showCustomFlushbar(
        context: context,
        title: "Sin conexión",
        message:
            "La encuesta se guardó localmente y se enviará cuando haya internet",
        backgroundColor: Colors.orange,
      );
    }
  }

  void _guardarAvanceEncuesta(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {
      'idUsuario': data['idUsuario'],
      'idCliente': data['idCliente'],
      'idEncuesta': data['idEncuesta'],
      'encuesta': data['preguntas'],
      'comentarios': data['comentarios'] ?? "",
      'imagenes': data['imagenes'],
      'imagenesCloudinary': data['imagenesCloudinary'],
      'firmaCliente': data['firmaCliente'] ?? "",
      'firmaClienteCloudinary': data['firmaClienteCloudinary'] ?? "",
      "inspeccionEficiencias": {
        "descripcionProblema": data["descripcionProblemaEficiencia"],
        "calificacion": data["calificacionEficiencia"],
        "comentarios": data["comentariosEficiencia"],
        "imagen": data["imagenEficiencia"],
        "imagenCloudinary": data["imagenCloudinaryEficiencia"]
      },
      'cerrado': "false",
      'estado': "true",
    };

    try {
      final inspeccionesService = InspeccionesService();
      var response = await inspeccionesService.registraInspecciones(dataTemp);

      if (response['status'] == 200) {
        var dataFrecuencia = {
          'idFrecuencia': selectedIdFrecuencia,
          'idCliente': data['idCliente'],
          'idEncuesta': data['idEncuesta'],
          'estado': "true",
        };

        final inspeccionesProximasService = InspeccionesProximasService();
        await inspeccionesProximasService
            .registraInspeccionesProximas(dataFrecuencia);

        setState(() {
          _isLoading = false;
          limpiarCampos();
        });

        LogsInformativos(
          "Se ha registrado la inspección ${data['idCliente']} correctamente",
          dataFrecuencia,
        );

        showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "Los datos de la encuesta fueron llenados correctamente",
          backgroundColor: Colors.green,
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        showCustomFlushbar(
          context: context,
          title: "Error",
          message:
              "Hubo un problema al registrar la encuesta. Inténtalo nuevamente.",
          backgroundColor: Colors.red,
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      showCustomFlushbar(
        context: context,
        title: "Oops...",
        message: "Error inesperado: ${error.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _onSubmit(accion) async {
    // ✅ Agregar async a la función

    final String? token = await AuthService().getTokenApi();
    print('Token obtenido para logout: $token');

    // Forzar que el token no sea null
    if (token == null) {
      throw Exception("Token de autenticación es nulo");
    }

    // Obtener los datos comunes utilizando el token
    final datosComunes = await obtenerDatosComunes(token);
    print('Datos comunes obtenidos para logout: $datosComunes');

    final dropboxService = DropboxService();
    final cloudinaryService = CloudinaryService();
    setState(() {
      _isLoading = true; // Activar la animación de carga al inicio
    });

    String imagenFile = "";

// Obtener la imagen de la firma
    final Uint8List? signatureImage = await _controller.toPngBytes();
    print("Firma imagen generada con tamaño: ${signatureImage?.length} bytes");

    String imagenFile2 = "";
    if (imagenSeleccionada != null) {
      // Llamas a la función que espera un Uint8List y obtienes la ruta
      String filePath = imagenSeleccionada!.path;
      if (filePath.isNotEmpty) {
        imagenFile2 = filePath;
        String? sharedLink = await dropboxService.uploadImageToDropbox(
            imagenFile2, "inspecciones");
        String? sharedLink2 = await cloudinaryService.subirArchivoCloudinary(
            imagenFile2, "inspecciones");

        if (sharedLink != null) {
          imagenEficiencia = sharedLink; // Guardar el enlace de la firma
        }
        if (sharedLink2 != null) {
          imagenEficienciaCloudinary =
              sharedLink2; // Guardar el enlace de la firma
        }
      } else {
        print('No se pudo guardar el logo del cliente de forma correcta');
      }
    } else {
      print('El logo del cliente es nulo');
    }

    if (signatureImage != null) {
      // Llamas a la función que espera un Uint8List y obtienes la ruta
      String filePath = await saveImage(signatureImage);

      if (filePath.isNotEmpty) {
        imagenFile = filePath;
        String? sharedLink = await dropboxService.uploadImageToDropbox(
            imagenFile, "inspecciones");
        String? sharedLink2 = await cloudinaryService.subirArchivoCloudinary(
            imagenFile, "inspecciones");
        if (sharedLink != null) {
          linkFirma = sharedLink; // Guardar el enlace de la firma
          print("Enlace de la firma: $linkFirma");
        }
        if (sharedLink2 != null) {
          linkFirmaCloudinary = sharedLink2; // Guardar el enlace de la firma
          print("Enlace de la firma: $linkFirmaCloudinary");
        }
      } else {
        print('No se pudo guardar la imagen de la firma correctamente');
      }
    } else {
      print('La imagen de firma es nula');
    }

// Subir imágenes adicionales si hay imágenes seleccionadas
    if (imagePaths.isNotEmpty) {
      for (var imagePath in imagePaths) {
        // Asegúrate de que imagePath sea un mapa con las claves correctas
        String? imagePathStr = imagePath["imagePath"];
        String? comentario = imagePath["comentario"];
        double? valor = double.tryParse(imagePath["valor"]);

        if (imagePathStr != null) {
          String? sharedLink = await dropboxService.uploadImageToDropbox(
              imagePathStr, "inspecciones");
          String? sharedLink2 = await cloudinaryService.subirArchivoCloudinary(
              imagePathStr, "inspecciones");
          if (sharedLink != null) {
            // Crear un mapa con el sharedLink y el comentario
            var imageInfo = {
              "sharedLink": sharedLink,
              "comentario": comentario,
              "valor": valor
            };
            // Agregar el mapa a la lista
            uploadedImageLinks.add(imageInfo);
          }
          if (sharedLink2 != null) {
            // Crear un mapa con el sharedLink y el comentario
            var imageInfo = {
              "sharedLink": sharedLink2,
              "comentario": comentario,
              "valor": valor
            };
            // Agregar el mapa a la lista
            uploadedImageLinksCloudinary.add(imageInfo);
          }
        }
      }
    }

    // Subir imágenes adicionales si hay imágenes seleccionadas
    if (registrosEficiencia.isNotEmpty) {
      for (var imagenes in registrosEficiencia) {
        // Asegúrate de que imagePath sea un mapa con las claves correctas

        String? descripcion = imagenes["descripcion"];
        String? calificacion = imagenes["calificacion"];
        String? comentarios = imagenes["comentarios"];
        String? imagen = imagenes["imagen"]!.path;

        if (imagen != null) {
          String? sharedLink =
              await dropboxService.uploadImageToDropbox(imagen, "inspecciones");
          String? sharedLink2 = await cloudinaryService.subirArchivoCloudinary(
              imagen, "inspecciones");
          if (sharedLink != null) {
            // Crear un mapa con el sharedLink y el comentario
            var imageInfo = {
              "descripcion": descripcion,
              "calificacion": calificacion,
              "comentarios": comentarios,
              "imagen": sharedLink,
              "imagenCloudinary": sharedLink2
            };
            // Agregar el mapa a la lista
            uploadedEficiencias.add(imageInfo);
          }
        }
      }
    }

// Desactivamos la animación de carga después de que todas las imágenes se hayan subido
    setState(() {
      _isLoading = false; // Desactivar la animación de carga
    });

    // Obtener las respuestas para guardar
    List<Map<String, String>> respuestasAguardar =
        obtenerRespuestasParaGuardar();

    // Crear el formulario con los datos
    var formData = {
      "idUsuario": datosComunes["idUsuario"],
      "idCliente": selectedClienteId,
      "idEncuesta": selectedEncuestaId,
      "preguntas": respuestasAguardar,
      "imagenes":
          uploadedImageLinks, // Asegúrate de pasar los enlaces de las imágenes
      "imagenesCloudinary":
          uploadedImageLinksCloudinary, // Asegúrate de pasar los enlaces de las imágenes
      "comentarios": comentariosController.text,
      "descripcion": descripcionController.text,
      "firmaCliente": linkFirma,
      "firmaClienteCloudinary": linkFirmaCloudinary,
      "inspeccionEficiencias": uploadedEficiencias,
    };

    // Llamar a la función para guardar la encuesta
    if (accion == "guardar") {
      _guardarEncuesta(formData);
    } else if (accion == "editar") {
      _guardarAvanceEncuesta(formData);
    }
  }

  Future<File?> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  void agregarImagenEncuesta(File? imagen,
      {String? comentario, String? valor}) {
    if (imagen == null) return;

    setState(() {
      imagePaths.add({
        "imagePath": imagen.path,
        "comentario": comentario ?? "",
        "valor": valor ?? "",
      });
    });
    print(imagePaths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Aplicar actividad"),
      body: loading
          ? Load()
          : Stack(
              fit: StackFit.expand,
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                      bottom:
                          60), // igual a la altura del botón/ deja espacio para el botón fijo
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "Aplicar actividad",
                            style: TextStyle(
                                fontSize: 23, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () => _onSubmit("guardar"),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  fixedSize: Size(150, 50),
                                ),
                                icon: Icon(FontAwesomeIcons.plus),
                                label: _isLoading
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SpinKitFadingCircle(
                                            color: Colors.red,
                                            size: 24,
                                          ),
                                          SizedBox(width: 8),
                                          Text("Guardando..."),
                                        ],
                                      )
                                    : Text("Guardar"),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            // Primera fila: 2 dropdowns
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: selectedClienteId,
                                    hint: const Text('Selecciona un Cliente'),
                                    isExpanded: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedClienteId = newValue;
                                      });
                                      if (newValue != null) {
                                        getEncuestas(
                                          selectedRamaId!,
                                          selectedFrecuenciaId!,
                                          selectedIdClasificacion!,
                                          selectedClienteId!,
                                        );
                                      }
                                    },
                                    items: dataClientes.map((rama) {
                                      return DropdownMenuItem<String>(
                                        value: rama['id'],
                                        child: Text(rama['nombre']!),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: selectedRamaId,
                                    hint: const Text(
                                        'Selecciona un Tipo de Sistema'),
                                    isExpanded: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedRamaId = newValue;
                                      });
                                      if (newValue != null) {
                                        getEncuestas(
                                          selectedRamaId!,
                                          selectedFrecuenciaId!,
                                          selectedIdClasificacion!,
                                          selectedClienteId!,
                                        );
                                      }
                                    },
                                    items: dataRamas.map((rama) {
                                      return DropdownMenuItem<String>(
                                        value: rama['id'],
                                        child: Text(rama['nombre']!),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            // Segunda fila: 2 dropdowns
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: selectedIdClasificacion,
                                    hint: const Text(
                                        'Selecciona una clasificación'),
                                    isExpanded: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedIdClasificacion = newValue;
                                      });
                                      if (newValue != null) {
                                        getEncuestas(
                                          selectedRamaId!,
                                          selectedFrecuenciaId!,
                                          selectedIdClasificacion!,
                                          selectedClienteId!,
                                        );
                                      }
                                    },
                                    items: dataClasificaciones.map((rama) {
                                      return DropdownMenuItem<String>(
                                        value: rama['id'],
                                        child: Text(rama['nombre']!),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: selectedFrecuenciaId,
                                    hint: const Text('Selecciona un periodo'),
                                    isExpanded: true,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedFrecuenciaId = newValue;
                                      });
                                      if (newValue != null) {
                                        getEncuestas(
                                          selectedRamaId!,
                                          selectedFrecuenciaId!,
                                          selectedIdClasificacion!,
                                          selectedClienteId!,
                                        );
                                      }
                                    },
                                    items: dataFrecuencias.map((rama) {
                                      return DropdownMenuItem<String>(
                                        value: rama['id'],
                                        child: Text(rama['nombre']!),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            // Última fila: 1 dropdown
                            DropdownButtonFormField<String>(
                              initialValue: selectedEncuestaId,
                              hint: const Text('Selecciona una actividad'),
                              isExpanded: true,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedEncuestaId = newValue;
                                  currentPage = 0;
                                  final encuestaSeleccionada =
                                      dataEncuestas.firstWhere(
                                    (encuesta) => encuesta['id'] == newValue,
                                  );
                                  selectedIdFrecuencia =
                                      encuestaSeleccionada['idFrecuencia'];
                                });
                                if (newValue != null) {
                                  actualizarPreguntas(newValue);
                                }
                              },
                              items: dataEncuestas.map((encuesta) {
                                return DropdownMenuItem<String>(
                                  value: encuesta['id'],
                                  child: Text(encuesta['nombre']!),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        if (selectedEncuestaId != null && preguntas.isNotEmpty)
                          SizedBox(
                            height: MediaQuery.of(context).size.width > 700
                                ? 700
                                : 450,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: 3,
                              itemBuilder: (context, pageIndex) {
                                if (pageIndex == 0) {
                                  // Página con TODAS las preguntas
                                  return ListView(
                                    children: [
                                      // Listado de preguntas
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: preguntas.length,
                                        itemBuilder: (context, index) {
                                          final pregunta = preguntas[index];
                                          return Card(
                                            margin: EdgeInsets.all(4),
                                            child: Padding(
                                              padding: EdgeInsets.all(4.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Título de la pregunta
                                                  Text(
                                                    pregunta.titulo,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  // Opciones
                                                  SizedBox(
                                                    height: 100,
                                                    child: RadioGroup<String>(
                                                      groupValue:
                                                          pregunta.respuesta,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          pregunta.respuesta =
                                                              value ?? '';
                                                        });
                                                      },
                                                      child: ListView.builder(
                                                        shrinkWrap: true,
                                                        physics:
                                                            const ClampingScrollPhysics(),
                                                        itemCount: pregunta
                                                            .opciones.length,
                                                        itemBuilder:
                                                            (context, i) {
                                                          final opcion =
                                                              pregunta
                                                                  .opciones[i];
                                                          final esNoAplica =
                                                              opcion.toLowerCase() ==
                                                                  "no aplica";

                                                          return ListTile(
                                                            contentPadding:
                                                                EdgeInsets.zero,
                                                            title: Text(opcion),
                                                            leading: esNoAplica
                                                                ? null
                                                                : Radio<String>(
                                                                    value:
                                                                        opcion),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),

                                                  // Observaciones
                                                  TextField(
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          "Observaciones",
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                    maxLines: 2,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        pregunta.observaciones =
                                                            value;
                                                      });
                                                    },
                                                  ),
                                                  SizedBox(height: 10),
                                                  // Selector de imagen
                                                  GestureDetector(
                                                    onTap: () async {
                                                      final img =
                                                          await _pickImage(); // devuelve File?
                                                      if (img != null) {
                                                        setState(() {
                                                          pregunta.imagen =
                                                              img; // Imagen temporal
                                                        });
                                                      }
                                                    },
                                                    child: Container(
                                                      width: double.infinity,
                                                      height: 200,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[200],
                                                        border: Border.all(
                                                            color: Colors.grey),
                                                      ),
                                                      child: pregunta.imagen ==
                                                              null
                                                          ? const Center(
                                                              child: Icon(
                                                                Icons
                                                                    .cloud_upload,
                                                                size: 50,
                                                                color: Colors
                                                                    .blueAccent,
                                                              ),
                                                            )
                                                          : ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              child: Image.file(
                                                                pregunta
                                                                    .imagen!,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  // Campo para valor
                                                  TextField(
                                                    controller: pregunta
                                                        .controllerValor,
                                                    decoration: InputDecoration(
                                                      labelText: "Valor",
                                                      border:
                                                          OutlineInputBorder(),
                                                    ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        pregunta.controllerValor
                                                            .text = value;
                                                      });
                                                    },
                                                  ),
                                                  SizedBox(height: 10),
                                                  // Botón "Guardar imagen"
                                                  ElevatedButton.icon(
                                                    onPressed:
                                                        pregunta.imagen == null
                                                            ? null
                                                            : () {
                                                                // Guarda la imagen en el arreglo global
                                                                agregarImagenEncuesta(
                                                                  pregunta
                                                                      .imagen,
                                                                  comentario:
                                                                      pregunta
                                                                          .titulo,
                                                                  valor: pregunta
                                                                      .controllerValor
                                                                      .text,
                                                                );

                                                                setState(() {
                                                                  // Limpia solo la imagen y el valor
                                                                  pregunta.imagen =
                                                                      null;
                                                                  pregunta
                                                                      .controllerValor
                                                                      .clear();
                                                                });
                                                              },
                                                    icon: Icon(Icons.save),
                                                    label:
                                                        Text("Guardar imagen"),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      // Descripción General al final
                                      Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Descripción General",
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            TextField(
                                              controller: descripcionController,
                                              maxLines: 4,
                                              decoration: InputDecoration(
                                                hintText:
                                                    "Escribe aquí la descripción de la actividad...",
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                } else if (pageIndex == 1) {
                                  // Página de comentarios finales
                                  return SingleChildScrollView(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text("Descripción del problema",
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller:
                                              descripcionEficienciaController,
                                          maxLines: 4,
                                          decoration: InputDecoration(
                                            hintText: "Describe el problema...",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text("Calificación",
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        DropdownButtonFormField<String>(
                                          initialValue: calificacionSeleccionada,
                                          items: [
                                            "Crítico",
                                            "No crítico",
                                            "Desactivación",
                                            "Solucionado"
                                          ]
                                              .map((opcion) => DropdownMenuItem(
                                                    value: opcion,
                                                    child: Text(opcion),
                                                  ))
                                              .toList(),
                                          onChanged: (valor) {
                                            setState(() {
                                              calificacionSeleccionada = valor;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(),
                                            hintText: "Selecciona una opción",
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text("Comentarios",
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller:
                                              comentariosEficienciaController,
                                          maxLines: 4,
                                          decoration: InputDecoration(
                                            hintText:
                                                "Comentarios adicionales...",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Foto",
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        GestureDetector(
                                          onTap: seleccionarImagen,
                                          child: Container(
                                            width: double.infinity,
                                            height: 250,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              border: Border.all(
                                                  color: Colors.grey),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: imagenSeleccionada == null
                                                ? const Center(
                                                    child: Icon(
                                                      Icons.cloud_upload,
                                                      size: 50,
                                                      color: Colors.blueAccent,
                                                    ),
                                                  )
                                                : ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    child: Image.file(
                                                      File(imagenSeleccionada!
                                                          .path),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        if (imagenSeleccionada != null)
                                          const Text(
                                            "Imagen seleccionada",
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 15),
                                          ),
                                        if (imagenSeleccionada == null)
                                          const Text(
                                            "Selecciona una imagen",
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 15),
                                          ),
                                        const SizedBox(height: 20),
                                        Center(
                                          child: Column(
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  agregarRegistro();
                                                  // 👉 Limpia solo la imagen seleccionada
                                                  setState(() {
                                                    imagenSeleccionada = null;
                                                  });
                                                },
                                                child: const Text(
                                                    "Agregar registro"),
                                              ),
                                              const SizedBox(height: 10),
                                              ElevatedButton(
                                                onPressed: () {
                                                  // 👉 Limpia todo el formulario
                                                  setState(() {
                                                    descripcionEficienciaController
                                                        .clear();
                                                    comentariosEficienciaController
                                                        .clear();
                                                    calificacionSeleccionada =
                                                        null;
                                                    imagenSeleccionada = null;
                                                  });
                                                },
                                                child: const Text(
                                                    "Limpiar formulario"),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  // Página de firma
                                  return SafeArea(
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              "Firma del cliente",
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Signature(
                                                controller: _controller,
                                                height: 300,
                                                backgroundColor:
                                                    Colors.transparent,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: _isLoading
                                                      ? null
                                                      : _controller.clear,
                                                  child: const Text(
                                                      "Limpiar Firma"),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (preguntas.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      color: Colors
                          .transparent, // quita border y borderRadius para que quede al ras
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: currentPage > 0
                                ? () => _pageController.previousPage(
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    )
                                : null,
                            child: Text('Anterior'),
                          ),
                          TextButton(
                            onPressed: currentPage < 2
                                ? () => _pageController.nextPage(
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeIn,
                                    )
                                : null,
                            child: Text('Siguiente'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class Pregunta {
  String titulo;
  String observaciones;
  List<String> opciones;
  String respuesta;
  String descripcion;
  TextEditingController controllerValor;
  File? imagen;

  Pregunta({
    required this.titulo,
    required this.observaciones,
    required this.opciones,
    this.respuesta = '',
    this.descripcion = '',
    TextEditingController? controllerValor,
    this.imagen,
  }) : controllerValor = controllerValor ?? TextEditingController();
}
