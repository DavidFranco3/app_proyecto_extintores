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
import 'package:dropdown_search/dropdown_search.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../utils/offline_sync_util.dart';

class EncuestaEditarPage extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  const EncuestaEditarPage(
      {super.key,
      required this.showModal,
      required this.onCompleted,
      required this.accion,
      required this.data});
  @override
  State<EncuestaEditarPage> createState() => _EncuestaEditarPageState();
}

final GlobalKey<DropdownSearchState<String>> clienteKey = GlobalKey();
final GlobalKey<DropdownSearchState<String>> ramaKey = GlobalKey();
final GlobalKey<DropdownSearchState<String>> clasificacionKey = GlobalKey();
final GlobalKey<DropdownSearchState<String>> frecuenciaKey = GlobalKey();
final GlobalKey<DropdownSearchState<String>> encuestaKey = GlobalKey();

class _EncuestaEditarPageState extends State<EncuestaEditarPage> {
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
    debugPrint("preguntas aca");
    debugPrint(widget.data["inspeccion_eficiencias"]?.toString() ?? "[]");
    selectedEncuestaId = widget.data["idEncuesta"];
    selectedRamaId = widget.data["idRama"];
    selectedClienteId = widget.data["idCliente"];
    selectedFrecuenciaId = widget.data["idFrecuencia"];
    selectedIdClasificacion = widget.data["idClasificacion"];
    descripcionController.text =
        widget.data["descripcion"] ?? "Sin descripción";
    uploadedEficiencias = (widget.data["inspeccion_eficiencias"] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    uploadedImageLinks =
        (widget.data["imagenes"] as List?)?.cast<Map<String, dynamic>>() ?? [];
    uploadedImageLinksCloudinary = (widget.data["imagenesCloudinary"] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    getEncuestas(widget.data["idRama"]!, widget.data["idFrecuencia"]!,
        widget.data["idClasificacion"]!, widget.data["idCliente"]!);
    setState(() {
      debugPrint("encuestas");
      debugPrint(dataEncuestas.toString());
    });
  }

  @override
  void dispose() {
    comentariosController.dispose();
    descripcionController.dispose();
    super.dispose();
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
    descripcionEficienciaController.clear();
    comentariosEficienciaController.clear();
    calificacionSeleccionada = null;
    imagenSeleccionada = null;

    setState(() {}); // Para que se actualice visualmente

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Registro agregado correctamente")),
    );
  }

  Future<Map<String, dynamic>> obtenerDatosComunes(String token) async {
    try {
      final authService = AuthService();

      // Obtener el id del usuario
      final idUsuario = authService.obtenerIdUsuarioLogueado(token);
      debugPrint('ID Usuario obtenido: $idUsuario');

      return {'idUsuario': idUsuario};
    } catch (e) {
      debugPrint('Error al obtener datos comunes: $e');
      rethrow; // Lanza el error para que lo maneje la función que lo llamó
    }
  }

  Future<void> getClientes() async {
    try {
      final clientesService = ClientesService();
      final List<dynamic> response = await clientesService.listarClientes();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          dataClientes = formatModelClientes(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataClientes = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      debugPrint("Error al obtener los clientes: $e");
      if (!mounted) return;
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
      });
    }
  }

  Future<void> getRamas() async {
    try {
      final ramasService = RamasService();
      final List<dynamic> response = await ramasService.listarRamas();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          dataRamas = formatModelRamas(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        if (!mounted) return;
        setState(() {
          dataRamas = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      debugPrint("Error al obtener las ramas: $e");
      if (!mounted) return;
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
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
    try {
      final frecuenciasService = FrecuenciasService();
      final List<dynamic> response =
          await frecuenciasService.listarFrecuencias();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          dataFrecuencias = formatModelFrecuencias(response);
          loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          loading = false;
          dataFrecuencias = [];
        });
      }
    } catch (e) {
      debugPrint("Error al obtener las frecuencias: $e");
      if (!mounted) return;
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
    try {
      final clasificacionesService = ClasificacionesService();
      final List<dynamic> response =
          await clasificacionesService.listarClasificaciones();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          dataClasificaciones = formatModelClasificaciones(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        if (!mounted) return;
        setState(() {
          dataClasificaciones = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      debugPrint("Error al obtener las clasificaciones: $e");
      if (!mounted) return;
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
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
        debugPrint('Imagen guardada en: $filePath');
      }

      // Retornar la ruta del archivo
      return filePath;
    } catch (e) {
      debugPrint('Error guardando la imagen: $e');
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
    try {
      final encuestaInspeccionClienteService =
          EncuestaInspeccionClienteService();
      final List<dynamic> response = await encuestaInspeccionClienteService
          .listarEncuestaInspeccionClientePorRamaPorCliente(
              idRama, idFrecuencia, idClasificacion, idCliente);
      debugPrint(response.toString());

      if (response.isNotEmpty) {
        setState(() {
          dataEncuestas = formatModelEncuestas(response);
          actualizarPreguntas(dataEncuestas[0]["id"]);
          loading = false;
        });
      } else {
        setState(() {
          dataEncuestas = [];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error al obtener las encuestas: $e");
      setState(() {
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> formatModelEncuestas(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    debugPrint("linea 472");
    debugPrint(selectedEncuestaId);
    for (var item in data) {
      if (item['_id'] == selectedEncuestaId) {
        dataTemp.add({
          'id': item['_id'],
          'nombre': item['nombre'],
          'idFrecuencia': item['idFrecuencia'],
          'preguntas': item['preguntas'],
        });
      }
    }

    return dataTemp;
  }

  // Actualiza las preguntas cuando se selecciona una encuesta
  void actualizarPreguntas(String encuestaId) {
    debugPrint(encuestaId);
    final encuesta =
        dataEncuestas.firstWhere((encuesta) => encuesta['id'] == encuestaId);

    final respuestasPrevias = widget.data["preguntas"] ?? [];

    setState(() {
      preguntas = (encuesta['preguntas'] as List<dynamic>).map((pregunta) {
        final tituloPregunta = pregunta['titulo'];

        // Buscar si hay una respuesta previa para esta pregunta
        final respuestaExistente = respuestasPrevias.firstWhere(
          (element) => element['pregunta'] == tituloPregunta,
          orElse: () => null,
        );

        return Pregunta(
          titulo: tituloPregunta,
          observaciones: respuestaExistente != null
              ? respuestaExistente['observaciones'] ?? ""
              : "",
          respuesta: respuestaExistente != null
              ? respuestaExistente['respuesta'] ?? ""
              : "",
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

      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Campos incompletos",
          message:
              "Por favor, completa todos los campos obligatorios antes de continuar.",
          backgroundColor: Colors.red,
        );
      }
      return;
    }

    var dataTemp = {
      'idUsuario': data['idUsuario'],
      'idCliente': data['idCliente'],
      'idEncuesta': data['idEncuesta'],
      'encuesta': data['preguntas'],
      'descripcion': data['descripcion'],
      'comentarios': data['comentarios'] ?? "",
      'imagenes': data['imagenes'],
      'imagenesCloudinary': data['imagenesCloudinary'],
      'firmaCliente': data['firmaCliente'] ?? "",
      'firmaClienteCloudinary': data['firmaClienteCloudinary'] ?? "",
      "inspeccionEficiencias": data['inspeccionEficiencias'],
    };

    final conectado = await OfflineSyncUtil().verificarConexion();

    if (!conectado) {
      final box = Hive.box('operacionesOfflineEncuestas');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'editar',
        'id': widget.data["id"],
        'operacionId': UniqueKey().toString(),
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Sin conexión",
            message:
                "Actualización guardada localmente y se sincronizará cuando haya internet",
            backgroundColor: Colors.orange,
          );
        }
      }
      return;
    }

    try {
      final inspeccionesService = InspeccionesService();
      var response = await inspeccionesService.actualizarInspecciones(
          widget.data["id"], dataTemp);

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

        logsInformativos(
          "Se ha registrado la inspección ${data['idCliente']} correctamente",
          dataFrecuencia,
        );

        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Registro exitoso",
            message: "Los datos de la encuesta fueron llenados correctamente",
            backgroundColor: Colors.green,
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Error",
            message:
                "Hubo un problema al registrar la encuesta. Inténtalo nuevamente.",
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Oops...",
          message: "Error inesperado: ${error.toString()}",
          backgroundColor: Colors.red,
        );
      }
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

    final conectado = await OfflineSyncUtil().verificarConexion();

    if (!conectado) {
      final box = Hive.box('operacionesOfflineEncuestas');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'registrar',
        'operacionId': UniqueKey().toString(),
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Sin conexión",
            message:
                "Avance guardado localmente y se sincronizará cuando haya internet",
            backgroundColor: Colors.orange,
          );
        }
      }
      return;
    }

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

        logsInformativos(
          "Se ha registrado la inspección ${data['idCliente']} correctamente",
          dataFrecuencia,
        );

        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Registro exitoso",
            message: "Los datos de la encuesta fueron llenados correctamente",
            backgroundColor: Colors.green,
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Error",
            message:
                "Hubo un problema al registrar la encuesta. Inténtalo nuevamente.",
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Oops...",
          message: "Error inesperado: ${error.toString()}",
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _onSubmit(accion) async {
    // ✅ Agregar async a la función

    final String? token = await AuthService().getTokenApi();
    debugPrint('Token obtenido para logout: $token');

    // Forzar que el token no sea null
    if (token == null) {
      throw Exception("Token de autenticación es nulo");
    }

    // Obtener los datos comunes utilizando el token
    final datosComunes = await obtenerDatosComunes(token);
    debugPrint('Datos comunes obtenidos para logout: $datosComunes');

    final dropboxService = DropboxService();
    final cloudinaryService = CloudinaryService();
    setState(() {
      _isLoading = true; // Activar la animación de carga al inicio
    });

    String imagenFile = "";

// Obtener la imagen de la firma
    final Uint8List? signatureImage = await _controller.toPngBytes();
    debugPrint(
        "Firma imagen generada con tamaño: ${signatureImage?.length} bytes");

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
        debugPrint('No se pudo guardar el logo del cliente de forma correcta');
      }
    } else {
      debugPrint('El logo del cliente es nulo');
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
          debugPrint("Enlace de la firma: $linkFirma");
        }
        if (sharedLink2 != null) {
          linkFirmaCloudinary = sharedLink2; // Guardar el enlace de la firma
          debugPrint("Enlace de la firma: $linkFirmaCloudinary");
        }
      } else {
        debugPrint('No se pudo guardar la imagen de la firma correctamente');
      }
    } else {
      debugPrint('La imagen de firma es nula');
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
        String? imagen = imagenes["imagen"];

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

  String _orientacion = 'horizontal';
  File? _imageHorizontal;
  File? _imageVertical1;
  File? _imageVertical2;

  final TextEditingController _comentarioController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  Future<void> _pickImage(Function(File) onImagePicked) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      onImagePicked(File(pickedFile.path));
    }
  }

  Widget _buildImageContainer(File? image, {String? label}) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: image == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 50, color: Colors.blueAccent),
                  if (label != null) Text(label),
                ],
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(image, fit: BoxFit.cover),
            ),
    );
  }

  void _agregarImagen() {
    if (_comentarioController.text.isEmpty || _valorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Completa comentario y valor")),
      );
      return;
    }

    if (_orientacion == 'horizontal') {
      if (_imageHorizontal != null) {
        setState(() {
          imagePaths.add({
            "imagePath": _imageHorizontal!.path,
            "comentario": _comentarioController.text,
            "valor": _valorController.text,
          });
          _imageHorizontal = null;
          _comentarioController.clear();
          _valorController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Selecciona una imagen")),
        );
      }
    } else {
      if (_imageVertical1 != null && _imageVertical2 != null) {
        setState(() {
          imagePaths.addAll([
            {
              "imagePath": _imageVertical1!.path,
              "comentario": _comentarioController.text,
              "valor": _valorController.text,
            },
            {
              "imagePath": _imageVertical2!.path,
              "comentario": _comentarioController.text,
              "valor": _valorController.text,
            },
          ]);
          _imageVertical1 = null;
          _imageVertical2 = null;
          _comentarioController.clear();
          _valorController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Selecciona ambas imágenes verticales")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Aplicar actividad"),
      body: loading
          ? Load()
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                      bottom: 80), // deja espacio para el botón fijo
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "Aplicar actividad",
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
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
                        SizedBox(height: 20),
                        Row(
                          children: [
                            // Dropdown para Cliente
                            Expanded(
                              child: DropdownSearch<String>(
                                key: clienteKey,
                                items: (filter, _) {
                                  return dataClientes
                                      .where((c) => c['nombre']
                                          .toString()
                                          .toLowerCase()
                                          .contains(filter.toLowerCase()))
                                      .map((c) => c['nombre'].toString())
                                      .toList();
                                },
                                selectedItem: selectedClienteId != null
                                    ? dataClientes.firstWhere((c) =>
                                        c['id'] ==
                                        selectedClienteId)['nombre'] as String
                                    : null,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    if (newValue != null) {
                                      selectedClienteId =
                                          dataClientes.firstWhere((c) =>
                                              c['nombre'] == newValue)['id'];
                                    } else {
                                      selectedClienteId = null;
                                    }
                                  });

                                  if (selectedClienteId != null &&
                                      selectedRamaId != null &&
                                      selectedFrecuenciaId != null &&
                                      selectedIdClasificacion != null) {
                                    getEncuestas(
                                      selectedRamaId!,
                                      selectedFrecuenciaId!,
                                      selectedIdClasificacion!,
                                      selectedClienteId!,
                                    );
                                  }
                                },
                                dropdownBuilder: (context, selectedItem) =>
                                    Text(
                                  selectedItem ?? "",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14),
                                ),
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: "Selecciona un Cliente",
                                    border: UnderlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                ),
                                popupProps:
                                    PopupProps.menu(showSearchBox: true),
                              ),
                            ),
                            SizedBox(width: 10),
                            // Dropdown para Tipo de Sistema
                            Expanded(
                              child: DropdownSearch<String>(
                                key: ramaKey,
                                items: (filter, _) {
                                  return dataRamas
                                      .where((r) => r['nombre']
                                          .toString()
                                          .toLowerCase()
                                          .contains(filter.toLowerCase()))
                                      .map((r) => r['nombre'].toString())
                                      .toList();
                                },
                                selectedItem: selectedRamaId != null
                                    ? dataRamas.firstWhere((r) =>
                                            r['id'] == selectedRamaId)['nombre']
                                        as String
                                    : null,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    if (newValue != null) {
                                      selectedRamaId = dataRamas.firstWhere(
                                          (r) => r['nombre'] == newValue)['id'];
                                    } else {
                                      selectedRamaId = null;
                                    }
                                  });

                                  if (selectedClienteId != null &&
                                      selectedRamaId != null &&
                                      selectedFrecuenciaId != null &&
                                      selectedIdClasificacion != null) {
                                    getEncuestas(
                                      selectedRamaId!,
                                      selectedFrecuenciaId!,
                                      selectedIdClasificacion!,
                                      selectedClienteId!,
                                    );
                                  }
                                },
                                dropdownBuilder: (context, selectedItem) =>
                                    Text(
                                  selectedItem ?? "",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14),
                                ),
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: "Selecciona un Tipo de Sistema",
                                    border: UnderlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                ),
                                popupProps:
                                    PopupProps.menu(showSearchBox: true),
                              ),
                            ),
                          ],
                        ),

// segunda fila: Clasificación y Frecuencia
                        Row(
                          children: [
                            // Dropdown para Clasificación
                            Expanded(
                              child: DropdownSearch<String>(
                                key: clasificacionKey,
                                items: (filter, _) {
                                  return dataClasificaciones
                                      .where((c) => c['nombre']
                                          .toString()
                                          .toLowerCase()
                                          .contains(filter.toLowerCase()))
                                      .map((c) => c['nombre'].toString())
                                      .toList();
                                },
                                selectedItem: selectedIdClasificacion != null
                                    ? dataClasificaciones.firstWhere((c) =>
                                            c['id'] ==
                                            selectedIdClasificacion)['nombre']
                                        as String
                                    : null,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    if (newValue != null) {
                                      selectedIdClasificacion =
                                          dataClasificaciones.firstWhere((c) =>
                                              c['nombre'] == newValue)['id'];
                                    } else {
                                      selectedIdClasificacion = null;
                                    }
                                  });

                                  if (selectedRamaId != null &&
                                      selectedFrecuenciaId != null &&
                                      selectedIdClasificacion != null &&
                                      selectedClienteId != null) {
                                    getEncuestas(
                                      selectedRamaId!,
                                      selectedFrecuenciaId!,
                                      selectedIdClasificacion!,
                                      selectedClienteId!,
                                    );
                                  }
                                },
                                dropdownBuilder: (context, selectedItem) =>
                                    Text(
                                  selectedItem ?? "",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14),
                                ),
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: "Selecciona una clasificación",
                                    border: UnderlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                ),
                                popupProps:
                                    PopupProps.menu(showSearchBox: true),
                              ),
                            ),
                            SizedBox(width: 10),
                            // Dropdown para Frecuencia
                            Expanded(
                              child: DropdownSearch<String>(
                                key: frecuenciaKey,
                                items: (filter, _) {
                                  return dataFrecuencias
                                      .where((f) => f['nombre']
                                          .toString()
                                          .toLowerCase()
                                          .contains(filter.toLowerCase()))
                                      .map((f) => f['nombre'].toString())
                                      .toList();
                                },
                                selectedItem: selectedFrecuenciaId != null
                                    ? dataFrecuencias.firstWhere((f) =>
                                            f['id'] ==
                                            selectedFrecuenciaId)['nombre']
                                        as String
                                    : null,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    if (newValue != null) {
                                      selectedFrecuenciaId =
                                          dataFrecuencias.firstWhere((f) =>
                                              f['nombre'] == newValue)['id'];
                                    } else {
                                      selectedFrecuenciaId = null;
                                    }
                                  });

                                  if (selectedRamaId != null &&
                                      selectedFrecuenciaId != null &&
                                      selectedIdClasificacion != null &&
                                      selectedClienteId != null) {
                                    getEncuestas(
                                      selectedRamaId!,
                                      selectedFrecuenciaId!,
                                      selectedIdClasificacion!,
                                      selectedClienteId!,
                                    );
                                  }
                                },
                                dropdownBuilder: (context, selectedItem) =>
                                    Text(
                                  selectedItem ?? "",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14),
                                ),
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: "Selecciona un periodo",
                                    border: UnderlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                ),
                                popupProps:
                                    PopupProps.menu(showSearchBox: true),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),

// Dropdown para Encuesta
                        DropdownSearch<String>(
                          key: encuestaKey,
                          enabled: dataEncuestas.isNotEmpty,
                          items: (filter, _) {
                            return dataEncuestas
                                .where((e) => e['nombre']
                                    .toString()
                                    .toLowerCase()
                                    .contains(filter.toLowerCase()))
                                .map((e) => e['nombre'].toString())
                                .toList();
                          },
                          selectedItem: selectedEncuestaId != null
                              ? dataEncuestas.firstWhere((e) =>
                                      e['id'] == selectedEncuestaId)['nombre']
                                  as String
                              : null,
                          onChanged: (String? newValue) {
                            if (newValue == null) return;
                            setState(() {
                              selectedEncuestaId = dataEncuestas.firstWhere(
                                  (e) => e['nombre'] == newValue)['id'];
                              currentPage = 0;
                              selectedIdFrecuencia = dataEncuestas.firstWhere(
                                  (e) =>
                                      e['nombre'] == newValue)['idFrecuencia'];
                            });
                            actualizarPreguntas(selectedEncuestaId!);
                          },
                          dropdownBuilder: (context, selectedItem) => Text(
                            selectedItem ?? "",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
                          ),
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              labelText: "Selecciona una actividad",
                              border: UnderlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                          ),
                          popupProps: PopupProps.menu(showSearchBox: true),
                        ),
                        if (selectedEncuestaId != null && preguntas.isNotEmpty)
                          SizedBox(
                            height: MediaQuery.of(context).size.width > 700
                                ? 700
                                : 300,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: 5,
                              itemBuilder: (context, pageIndex) {
                                if (pageIndex == 0) {
                                  // Página con TODAS las preguntas
                                  return ListView.builder(
                                    itemCount: preguntas.length,
                                    itemBuilder: (context, index) {
                                      final pregunta = preguntas[index];
                                      return Card(
                                        margin: EdgeInsets.all(10),
                                        child: Padding(
                                          padding: EdgeInsets.all(10.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pregunta.titulo,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                              SizedBox(
                                                height: 120,
                                                child: RadioGroup<String>(
                                                  groupValue:
                                                      pregunta.respuesta,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      pregunta.respuesta =
                                                          value!;
                                                    });
                                                  },
                                                  child: ListView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        ClampingScrollPhysics(),
                                                    itemCount: pregunta
                                                        .opciones.length,
                                                    itemBuilder: (context, i) {
                                                      final opcion =
                                                          pregunta.opciones[i];
                                                      final esNoAplica = opcion
                                                              .toLowerCase() ==
                                                          "no aplica";

                                                      return ListTile(
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        title: Text(opcion),
                                                        leading: esNoAplica
                                                            ? null // No se muestra ningún widget a la izquierda
                                                            : Radio<String>(
                                                                value: opcion,
                                                              ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              TextFormField(
                                                initialValue:
                                                    pregunta.observaciones,
                                                decoration: InputDecoration(
                                                  labelText: "Observaciones",
                                                  border: OutlineInputBorder(),
                                                ),
                                                maxLines: 2,
                                                onChanged: (value) {
                                                  setState(() {
                                                    pregunta.observaciones =
                                                        value;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                } else if (pageIndex == 1) {
                                  // Página de descripción
                                  return Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Descripción General",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
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
                                  );
                                } else if (pageIndex == 2) {
                                  // Página de comentarios finales
                                  return SingleChildScrollView(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text("Descripción del problema",
                                            style: TextStyle(
                                                fontSize: 16,
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
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        DropdownSearch<String>(
                                          key: Key('calificacionDropdown'),
                                          enabled:
                                              true, // Siempre habilitado, ya que siempre hay opciones
                                          items: (filter, _) {
                                            final opciones = [
                                              "Crítico",
                                              "No crítico",
                                              "Desactivación",
                                              "Solucionado"
                                            ];
                                            return opciones
                                                .where((o) => o
                                                    .toLowerCase()
                                                    .contains(
                                                        filter.toLowerCase()))
                                                .toList();
                                          },
                                          selectedItem:
                                              calificacionSeleccionada,
                                          onChanged: (String? valor) {
                                            setState(() {
                                              calificacionSeleccionada = valor;
                                            });
                                          },
                                          dropdownBuilder:
                                              (context, selectedItem) => Text(
                                            selectedItem ?? "",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: selectedItem == null
                                                    ? Colors.grey
                                                    : Colors.black),
                                          ),
                                          decoratorProps:
                                              DropDownDecoratorProps(
                                            decoration: InputDecoration(
                                              labelText: "Calificación",
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                            ),
                                          ),
                                          popupProps: PopupProps.menu(
                                            showSearchBox: true,
                                            fit: FlexFit.loose,
                                            constraints:
                                                BoxConstraints(maxHeight: 300),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text("Comentarios",
                                            style: TextStyle(
                                                fontSize: 16,
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
                                              fontSize: 18,
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
                                                fontSize: 16),
                                          ),
                                        if (imagenSeleccionada == null)
                                          const Text(
                                            "Selecciona una imagen",
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 16),
                                          ),
                                        const SizedBox(height: 20),
                                        Center(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              agregarRegistro();
                                            },
                                            child:
                                                const Text("Agregar registro"),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        if (registrosEficiencia.isNotEmpty)
                                          const Text(
                                            "Registros agregados",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        if (registrosEficiencia.isNotEmpty)
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            itemCount:
                                                registrosEficiencia.length,
                                            itemBuilder: (context, index) {
                                              final registro =
                                                  registrosEficiencia[index];
                                              return Card(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                                child: ListTile(
                                                  leading: Image.file(
                                                    File(registro["imagen"]
                                                        .path),
                                                    width: 50,
                                                    height: 50,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  title: Text(
                                                    '${registro["comentarios"]} - ${registro["calificacion"]}',
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                  subtitle: Text(
                                                      registro["descripcion"]),
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                } else if (pageIndex == 3) {
                                  // Página de imágenes
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Text(
                                                "Carga de Imágenes",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            SizedBox(height: 10),

                                            // Selector de orientación
                                            Row(
                                              children: [
                                                Text("Orientación: "),
                                                SizedBox(width: 10),
                                                DropdownButton<String>(
                                                  value: _orientacion,
                                                  items: [
                                                    DropdownMenuItem(
                                                        value: 'horizontal',
                                                        child:
                                                            Text('Horizontal')),
                                                    DropdownMenuItem(
                                                        value: 'vertical',
                                                        child:
                                                            Text('Vertical')),
                                                  ],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _orientacion = value!;
                                                      _imageHorizontal = null;
                                                      _imageVertical1 = null;
                                                      _imageVertical2 = null;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 16),

                                            // Carga visual de imagen
                                            if (_orientacion == 'horizontal')
                                              GestureDetector(
                                                onTap: () => _pickImage((img) {
                                                  setState(() =>
                                                      _imageHorizontal = img);
                                                }),
                                                child: _buildImageContainer(
                                                    _imageHorizontal),
                                              )
                                            else ...[
                                              GestureDetector(
                                                onTap: () => _pickImage((img) {
                                                  setState(() =>
                                                      _imageVertical1 = img);
                                                }),
                                                child: _buildImageContainer(
                                                    _imageVertical1,
                                                    label: "Imagen 1"),
                                              ),
                                              SizedBox(height: 8),
                                              GestureDetector(
                                                onTap: () => _pickImage((img) {
                                                  setState(() =>
                                                      _imageVertical2 = img);
                                                }),
                                                child: _buildImageContainer(
                                                    _imageVertical2,
                                                    label: "Imagen 2"),
                                              ),
                                            ],

                                            SizedBox(height: 16),

                                            TextField(
                                              controller: _comentarioController,
                                              decoration: InputDecoration(
                                                  labelText: "Comentario"),
                                            ),
                                            SizedBox(height: 16),

                                            TextField(
                                              controller: _valorController,
                                              decoration: InputDecoration(
                                                  labelText: "Valor"),
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly
                                              ],
                                            ),
                                            SizedBox(height: 16),

                                            Center(
                                              child: ElevatedButton(
                                                onPressed: _agregarImagen,
                                                child: Text("Agregar"),
                                              ),
                                            ),
                                            SizedBox(height: 16),

                                            // Vista de imágenes agregadas
                                            if (imagePaths.isNotEmpty)
                                              ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                itemCount: imagePaths.length,
                                                itemBuilder: (context, index) {
                                                  return Card(
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                            vertical: 8),
                                                    child: ListTile(
                                                      leading: Image.file(
                                                        File(imagePaths[index]
                                                            ["imagePath"]),
                                                        width: 50,
                                                        height: 50,
                                                        fit: BoxFit.cover,
                                                      ),
                                                      title: Text(
                                                        '${imagePaths[index]["comentario"]} - ${imagePaths[index]["valor"]}',
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
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
                                                fontSize: 18,
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
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
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
                            onPressed: currentPage < 4
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

  Pregunta({
    required this.titulo,
    required this.observaciones,
    required this.opciones,
    this.respuesta = '',
  });
}
