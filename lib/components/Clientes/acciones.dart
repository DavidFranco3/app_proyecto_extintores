import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/clientes.dart';
import '../../api/models/cliente_model.dart';
import '../Logs/logs_informativos.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../api/dropbox.dart';
import '../../api/cloudinary.dart';
import 'dart:io';
import '../Generales/flushbar_helper.dart';
import 'package:prueba/components/Header/header.dart';
import 'package:prueba/components/Menu/menu_lateral.dart';
import '../Generales/premium_button.dart';
import '../Load/load.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../Generales/premium_inputs.dart';

class Acciones extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  const Acciones(
      {super.key,
      required this.showModal,
      required this.onCompleted,
      required this.accion,
      required this.data});

  @override
  State<Acciones> createState() => _AccionesState();
}

class _AccionesState extends State<Acciones> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  late TextEditingController _nombreController;
  late TextEditingController _imagenController;
  late TextEditingController _imagenCloudinaryController;
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;
  late TextEditingController _calleController;
  late TextEditingController _nExteriorController;
  late TextEditingController _nInteriorController;
  late TextEditingController _coloniaController;
  late TextEditingController _estadoDomController;
  late TextEditingController _municipioController;
  late TextEditingController _cpostalController;
  late TextEditingController _referenciaController;
  late TextEditingController _puestoController;
  late TextEditingController _responsableController;

  final ImagePicker _picker = ImagePicker();
  XFile? _image; // Variable para almacenar la imagen seleccionada
  String? imageUrl; // Para la URL de la imagen desde Dropbox

  // Método para seleccionar una imagen desde la galería
  Future<void> _pickImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage; // Asignar la imagen seleccionada a la variable
      imageUrl = null;
    });
  }

  late List<Map<String, dynamic>> _estadosFuture = [];
  Map<String, List<String>> _municipiosMap = {};

  @override
  void initState() {
    super.initState();
    cargarEstados();
    cargarMunicipios();

    _nombreController = TextEditingController();
    _imagenController = TextEditingController();
    _imagenCloudinaryController = TextEditingController();
    _correoController = TextEditingController();
    _telefonoController = TextEditingController();
    _calleController = TextEditingController();
    _nExteriorController = TextEditingController();
    _nInteriorController = TextEditingController();
    _coloniaController = TextEditingController();
    _estadoDomController = TextEditingController();
    _municipioController = TextEditingController();
    _cpostalController = TextEditingController();
    _referenciaController = TextEditingController();
    _puestoController = TextEditingController();
    _responsableController = TextEditingController();

    if (widget.accion == 'editar') {
      final direccion = widget.data['direccion'] ?? {};
      _nombreController.text = (widget.data['nombre'] ?? '').toString();
      _imagenController.text = (widget.data['imagen'] ?? '').toString();
      _imagenCloudinaryController.text =
          (widget.data['imagenCloudinary'] ?? '').toString();
      _correoController.text = (widget.data['correo'] ?? '').toString();
      _telefonoController.text = (widget.data['telefono'] ?? '').toString();

      _calleController.text =
          (direccion['calle'] ?? widget.data['calle'] ?? '').toString();
      _nExteriorController.text =
          (direccion['nExterior'] ?? widget.data['nExterior'] ?? '').toString();
      _nInteriorController.text =
          (direccion['nInterior'] ?? widget.data['nInterior'] ?? '').toString();
      _coloniaController.text =
          (direccion['colonia'] ?? widget.data['colonia'] ?? '').toString();
      _estadoDomController.text =
          (direccion['estadoDom'] ?? widget.data['estadoDom'] ?? '').toString();
      _municipioController.text =
          (direccion['municipio'] ?? widget.data['municipio'] ?? '').toString();
      _cpostalController.text =
          (direccion['cPostal'] ?? widget.data['cPostal'] ?? '').toString();
      _referenciaController.text =
          (direccion['referencia'] ?? widget.data['referencia'] ?? '')
              .toString();

      _responsableController.text =
          (widget.data['responsable'] ?? '').toString();
      _puestoController.text = (widget.data['puesto'] ?? '').toString();

      final String? rawImagen = widget.data['imagen'];
      if (rawImagen != null && rawImagen.isNotEmpty) {
        imageUrl = rawImagen.replaceAll('dl=0', 'raw=1');
      }
    }
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });

    sincronizarOperacionesPendientes();

    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> event) {
      if (event.any((result) => result != ConnectivityResult.none)) {
        sincronizarOperacionesPendientes();
      }
    });
  }

  Future<void> cargarEstados() async {
    // Cargar el contenido del archivo JSON
    String data = await rootBundle
        .loadString('lib/assets/catalogosJSON/estadosPais.json');

    // Decodificar el JSON a una lista de mapas
    List<dynamic> decodedList = json.decode(data);

    // Convertirlo a List<Map<String, dynamic>>
    _estadosFuture =
        decodedList.map((e) => Map<String, dynamic>.from(e)).toList();

    setState(
        () {}); // Para actualizar el estado si estás dentro de un StatefulWidget
  }

  Future<void> cargarMunicipios() async {
    // Cargar el contenido del archivo JSON
    String data = await rootBundle
        .loadString('lib/assets/catalogosJSON/municipiosEstadosPais.json');

    // Decodificar el JSON a un mapa
    Map<String, dynamic> decodedMap = json.decode(data);

    // Convertir cada valor en una lista de strings
    _municipiosMap =
        decodedMap.map((key, value) => MapEntry(key, List<String>.from(value)));

    setState(
        () {}); // Para actualizar el estado si estás dentro de un StatefulWidget
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _imagenController.dispose();
    _imagenCloudinaryController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _calleController.dispose();
    _nExteriorController.dispose();
    _nInteriorController.dispose();
    _coloniaController.dispose();
    _estadoDomController.dispose();
    _municipioController.dispose();
    _cpostalController.dispose();
    _referenciaController.dispose();
    _responsableController.dispose();
    _puestoController.dispose();
    super.dispose();
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  // Corregimos la función para que acepte un parámetro bool
  void closeRegistroModal() {
    widget.showModal(); // Llama a setShow con el valor booleano
    widget.onCompleted();
  }

  Future<void> sincronizarOperacionesPendientes() async {
    final conectado = await verificarConexion();
    if (!conectado) return;

    final box = Hive.box('operacionesOfflineClientes');
    final operacionesRaw = box.get('operaciones', defaultValue: []);

    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    final clientesService = ClientesService();
    final dropboxService = DropboxService();
    final cloudinaryService = CloudinaryService();

    final clientesBox = Hive.box('clientesBox');
    final List<String> operacionesExitosas = [];

    for (var operacion in List.from(operaciones)) {
      try {
        // Si hay imagen local en data, subirla primero a Dropbox y Cloudinary
        if (operacion['data'] != null) {
          var data = Map<String, dynamic>.from(operacion['data']);

          // Asumo que la imagen local se encuentra en data['imagenLocal'] o similar, ajusta según tu estructura
          if (data.containsKey('imagenLocal') &&
              data['imagenLocal'] != null &&
              data['imagenLocal'].toString().isNotEmpty) {
            String rutaImagenLocal = data['imagenLocal'];

            // Subir a Dropbox
            String? linkDropbox = await dropboxService.uploadImageToDropbox(
                rutaImagenLocal, "clientes");
            // Subir a Cloudinary
            String? linkCloudinary = await cloudinaryService
                .subirArchivoCloudinary(rutaImagenLocal, "clientes");

            if (linkDropbox != null) {
              data['imagen'] = linkDropbox;
            }
            if (linkCloudinary != null) {
              data['imagenCloudinary'] = linkCloudinary;
            }

            // Remover el campo temporal de la ruta local para no enviarlo al backend
            data.remove('imagenLocal');

            // Actualizar el data de la operación con los links nuevos
            operacion['data'] = data;
          }
        }

        if (operacion['accion'] == 'registrar') {
          final response =
              await clientesService.registrarClientes(operacion['data']);

          if (response['status'] == 200 && response['body']['data'] != null) {
            final actualesRaw = clientesBox.get('clientes', defaultValue: []);
            final actuales =
                (actualesRaw as List).map<Map<String, dynamic>>((item) {
              if (item is Map) return Map<String, dynamic>.from(item);
              if (item is ClienteModel) return item.toJson();
              return {};
            }).toList();

            actuales.removeWhere((element) => element['id'] == operacion['id']);

            actuales.add({
              'id': response['body']['data']['_id'],
              'nombre': response['body']['data']['nombre'],
              'imagen': response['body']['data']['imagen'],
              'imagenCloudinary': response['body']['data']['imagenCloudinary'],
              'correo': response['body']['data']['correo'],
              'telefono': response['body']['data']['telefono'],
              'calle': response['body']['data']['direccion']['calle'],
              'nExterior': (response['body']['data']['direccion']['nExterior']
                          ?.isNotEmpty ??
                      false)
                  ? response['body']['data']['direccion']['nExterior']
                  : 'S/N',
              'nInterior': (response['body']['data']['direccion']['nInterior']
                          ?.isNotEmpty ??
                      false)
                  ? response['body']['data']['direccion']['nInterior']
                  : 'S/N',
              'colonia': response['body']['data']['direccion']['colonia'],
              'estadoDom': response['body']['data']['direccion']['estadoDom'],
              'municipio': response['body']['data']['direccion']['municipio'],
              'cPostal': response['body']['data']['direccion']['cPostal'],
              'referencia': response['body']['data']['direccion']['referencia'],
              'responsable': response['body']['data']['responsable'] ?? '',
              'puesto': response['body']['data']['puesto'] ?? '',
              'estado': "true",
              'createdAt': response['body']['data']['createdAt'],
              'updatedAt': response['body']['data']['updatedAt'],
            });

            await clientesBox.put('clientes', actuales);
          }

          operacionesExitosas.add(operacion['operacionId']);
        } else if (operacion['accion'] == 'editar') {
          final response = await clientesService.actualizarClientes(
              operacion['id'], operacion['data']);

          if (response['status'] == 200) {
            final actualesRaw = clientesBox.get('clientes', defaultValue: []);
            final actuales =
                (actualesRaw as List).map<Map<String, dynamic>>((item) {
              if (item is Map) return Map<String, dynamic>.from(item);
              if (item is ClienteModel) return item.toJson();
              return {};
            }).toList();

            final index = actuales.indexWhere((element) =>
                (element['id'] ?? element['_id']) == operacion['id']);
            if (index != -1) {
              actuales[index] = {
                ...actuales[index],
                ...operacion['data'],
                'updatedAt': DateTime.now().toString(),
              };
              await clientesBox.put('clientes', actuales);
            }
          }

          operacionesExitosas.add(operacion['operacionId']);
        } else if (operacion['accion'] == 'eliminar') {
          final response = await clientesService
              .deshabilitarClientes(operacion['id'], {'estado': 'false'});

          if (response['status'] == 200) {
            final clientesBox = Hive.box('clientesBox');
            final actualesRaw = clientesBox.get('clientes', defaultValue: []);
            final actuales =
                (actualesRaw as List).map<Map<String, dynamic>>((item) {
              if (item is Map) return Map<String, dynamic>.from(item);
              if (item is ClienteModel) return item.toJson();
              return {};
            }).toList();

            final index = actuales.indexWhere((element) =>
                (element['id'] ?? element['_id']) == operacion['id']);
            if (index != -1) {
              actuales[index] = {
                ...actuales[index],
                'estado': 'false',
                'updatedAt': DateTime.now().toString(),
              };
              await clientesBox.put('clientes', actuales);
            }
          }

          operacionesExitosas.add(operacion['operacionId']);
        }
      } catch (e) {
        debugPrint('Error sincronizando operación: $e');
      }
    }

    // Limpieza y actualización final igual que antes...
    if (operacionesExitosas.length == operaciones.length) {
      await box.put('operaciones', []);
      debugPrint("✔ Todas las operaciones sincronizadas. Limpieza completa.");
    } else {
      final nuevasOperaciones = operaciones
          .where((op) => !operacionesExitosas.contains(op['operacionId']))
          .toList();
      await box.put('operaciones', nuevasOperaciones);
      debugPrint(
          "❗ Algunas operaciones no se sincronizaron, se conservarán localmente.");
    }

    try {
      final List<ClienteModel> dataAPI = await clientesService.listarClientes();

      final formateadas = dataAPI
          .map<Map<String, dynamic>>((item) => {
                'id': item.id,
                'nombre': item.nombre,
                'imagen': item.imagen,
                'imagenCloudinary': item.imagenCloudinary,
                'correo': item.correo,
                'telefono': item.telefono,
                'calle': item.calle,
                'nExterior': item.nExterior,
                'nInterior': item.nInterior,
                'colonia': item.colonia,
                'estadoDom': item.estadoDom,
                'municipio': item.municipio,
                'cPostal': item.cPostal,
                'referencia': item.referencia,
                'responsable': item.responsable,
                'puesto': item.puesto,
                'estado': item.estado,
                'createdAt': item.createdAt,
                'updatedAt': item.updatedAt,
              })
          .toList();

      final clientesBox = Hive.box('clientesBox');
      await clientesBox.put('clientes', formateadas);
    } catch (e) {
      debugPrint('Error actualizando datos después de sincronización: $e');
    }
  }

  void _guardarCliente(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'nombre': data['nombre'],
      'imagen': data['imagen'],
      'imagenCloudinary': data['imagenCloudinary'],
      'correo': data['correo'],
      'telefono': data['telefono'],
      'responsable': data['responsable'],
      'puesto': data['puesto'],
      'direccion': {
        'calle': data['calle'] ?? '',
        'nExterior': data['nExterior'] ?? 'S/N',
        'nInterior': data['nInterior'] ?? 'S/N',
        'colonia': data['colonia'] ?? '',
        'estadoDom': data['estadoDom'] ?? '',
        'municipio': data['municipio'] ?? '',
        'cPostal': data['cPostal'] ?? '',
        'referencia': data['referencia'] ?? '',
      },
      'estado': "true",
    };

    if (!conectado) {
      final box = Hive.box('operacionesOfflineClientes');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'registrar',
        'id': null,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final clientesBox = Hive.box('clientesBox');
      final actualesRaw = clientesBox.get('clientes', defaultValue: []);

      final actuales = (actualesRaw as List)
          .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map))
          .toList();
      actuales.add({
        'id': DateTime.now().toIso8601String(),
        ...dataTemp,
        'createdAt': DateTime.now().toString(),
        'updatedAt': DateTime.now().toString(),
      });
      await clientesBox.put('clientes', actuales);

      setState(() {
        _isLoading = false;
      });
      widget.onCompleted();
      widget.showModal();
      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Sin conexión",
          message:
              "Clasificación guardada localmente y se sincronizará cuando haya internet",
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final clientesService = ClientesService();
      var response = await clientesService.registrarClientes(dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        logsInformativos(
            "Se ha registrado el cliente ${data['nombre']} correctamente", {});
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Registro exitoso",
            message: "La clasificación fue agregada correctamente",
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
            message: "No se pudo guardar la clasificación",
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
          message: error.toString(),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _editarCliente(String id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'nombre': data['nombre'],
      'imagen': data['imagen'],
      'imagenCloudinary': data['imagenCloudinary'],
      'correo': data['correo'],
      'telefono': data['telefono'],
      'responsable': data['responsable'],
      'puesto': data['puesto'],
      'direccion': {
        'calle': data['calle'] ?? '',
        'nExterior': data['nExterior'] ?? 'S/N',
        'nInterior': data['nInterior'] ?? 'S/N',
        'colonia': data['colonia'] ?? '',
        'estadoDom': data['estadoDom'] ?? '',
        'municipio': data['municipio'] ?? '',
        'cPostal': data['cPostal'] ?? '',
        'referencia': data['referencia'] ?? '',
      },
    };

    if (!conectado) {
      final box = Hive.box('operacionesOfflineClientes');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'editar',
        'id': id,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final clientesBox = Hive.box('clientesBox');
      final actualesRaw = clientesBox.get('clientes', defaultValue: []);

      final actuales = (actualesRaw as List)
          .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final index = actuales.indexWhere((element) => element['id'] == id);
      // Actualiza localmente el registro editado
      if (index != -1) {
        actuales[index] = {
          ...actuales[index],
          ...dataTemp,
          'updatedAt': DateTime.now().toString(),
        };
        await clientesBox.put('clientes', actuales);
      }

      setState(() {
        _isLoading = false;
      });
      widget.onCompleted();
      widget.showModal();
      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Sin conexión",
          message:
              "Clasificación actualizada localmente y se sincronizará cuando haya internet",
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final clientesService = ClientesService();
      var response = await clientesService.actualizarClientes(id, dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        logsInformativos(
            "Se ha actualizado el cliente ${data['nombre']} correctamente", {});
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Actualización exitosa",
            message:
                "Los datos de la clasificación fueron actualizados correctamente",
            backgroundColor: Colors.green,
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
          message: error.toString(),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _onSubmit() async {
    setState(() {
      _isLoading = true;
    });
    if (_formKey.currentState?.validate() ?? false) {
      final dropboxService = DropboxService();
      final cloudinaryService = CloudinaryService();
      String imagenFile = "";
      if (_image != null) {
        // Llamas a la función que espera un Uint8List y obtienes la ruta
        String filePath = _image!.path;
        if (filePath.isNotEmpty) {
          imagenFile = filePath;
          String? sharedLink =
              await dropboxService.uploadImageToDropbox(imagenFile, "clientes");
          String? sharedLink2 = await cloudinaryService.subirArchivoCloudinary(
              imagenFile, "clientes");

          if (sharedLink != null) {
            _imagenController.text =
                sharedLink; // Guardar el enlace de la firma
          }
          if (sharedLink2 != null) {
            _imagenCloudinaryController.text =
                sharedLink2; // Guardar el enlace de la firma
          }
        } else {
          debugPrint(
              'No se pudo guardar el logo del cliente de forma correcta');
        }
      } else {
        debugPrint('El logo del cliente es nulo');
      }

      var formData = {
        'nombre': _nombreController.text,
        'imagen': _imagenController.text,
        'imagenCloudinary': _imagenCloudinaryController.text,
        'correo': _correoController.text,
        'telefono': _telefonoController.text,
        'responsable': _responsableController.text,
        'puesto': _puestoController.text,
        'calle': _calleController.text,
        'nExterior': _nExteriorController.text,
        'nInterior': _nInteriorController.text,
        'colonia': _coloniaController.text,
        'estadoDom': _estadoDomController.text,
        'municipio': _municipioController.text,
        'cPostal': _cpostalController.text,
        'referencia': _referenciaController.text,
      };

      if (widget.accion == 'registrar') {
        _guardarCliente(formData);
      } else if (widget.accion == 'editar') {
        _editarCliente(widget.data['id'] ?? widget.data['_id'], formData);
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String get buttonLabel {
    if (widget.accion == 'registrar') {
      return 'Guardar';
    } else {
      return 'Actualizar';
    }
  }

  bool get isEliminar => widget.accion == 'eliminar';

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Clientes"), // Usa el menú lateral
      body: _isLoading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '${capitalize(widget.accion)} cliente',
                        style: TextStyle(
                          fontSize: 24, // Tamaño grande
                          fontWeight: FontWeight.bold, // Negrita
                        ),
                      ),
                    ),
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!isEliminar) ...[
                          const PremiumSectionTitle(
                            title: "Identidad Corporativa",
                            icon: FontAwesomeIcons.image,
                          ),
                          PremiumCardField(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: double.infinity,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      border: Border.all(
                                          color: Colors.grey
                                              .withValues(alpha: 0.2)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _image == null && imageUrl == null
                                        ? const Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                    FontAwesomeIcons
                                                        .cloudArrowUp,
                                                    size: 40,
                                                    color: Color(0xFFE94742)),
                                                SizedBox(height: 12),
                                                Text("Subir Logo",
                                                    style: TextStyle(
                                                        color: Colors.grey,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: _image != null
                                                ? Image.file(File(_image!.path),
                                                    fit: BoxFit.contain)
                                                : Image.network(imageUrl!,
                                                    fit: BoxFit.contain),
                                          ),
                                  ),
                                ),
                                if (_image != null || imageUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.green, size: 16),
                                        const SizedBox(width: 4),
                                        const Text(
                                            "Imagen cargada correctamente",
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const PremiumSectionTitle(
                          title: "Información General",
                          icon: FontAwesomeIcons.building,
                        ),
                        PremiumCardField(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nombreController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Razón Social / Nombre',
                                  prefixIcon: FontAwesomeIcons.idCard,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'El nombre es obligatorio'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _correoController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Correo Electrónico',
                                  prefixIcon: FontAwesomeIcons.envelope,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El email es obligatorio';
                                        }
                                        final emailRegex = RegExp(
                                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                        if (!emailRegex.hasMatch(value)) {
                                          return 'Ingrese un email válido';
                                        }
                                        return null;
                                      },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _telefonoController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Teléfono',
                                  prefixIcon: FontAwesomeIcons.phone,
                                  hintText: '10 dígitos',
                                ),
                                enabled: !isEliminar,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                validator: isEliminar
                                    ? null
                                    : (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El teléfono es obligatorio';
                                        }
                                        if (!RegExp(r'^\d{10}$')
                                            .hasMatch(value)) {
                                          return 'Debe contener exactamente 10 dígitos';
                                        }
                                        return null;
                                      },
                              ),
                            ],
                          ),
                        ),
                        const PremiumSectionTitle(
                          title: "Ubicación y Domicilio",
                          icon: FontAwesomeIcons.locationDot,
                        ),
                        PremiumCardField(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _calleController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Calle / Avenida',
                                  prefixIcon: FontAwesomeIcons.road,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'La calle es obligatoria'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nExteriorController,
                                      decoration: PremiumInputs.decoration(
                                        labelText: 'Núm. Ext.',
                                        prefixIcon: FontAwesomeIcons.hashtag,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      enabled: !isEliminar,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nInteriorController,
                                      decoration: PremiumInputs.decoration(
                                        labelText: 'Núm. Int.',
                                        prefixIcon: FontAwesomeIcons.doorOpen,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      enabled: !isEliminar,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _coloniaController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Colonia / Fraccionamiento',
                                  prefixIcon: FontAwesomeIcons.mapLocationDot,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'La colonia es obligatoria'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownSearch<String>(
                                key: const Key('estadoDropdown'),
                                enabled: !isEliminar,
                                items: (filter, _) {
                                  return _estadosFuture
                                      .where((e) => e['nombre']
                                          .toString()
                                          .toLowerCase()
                                          .contains(filter.toLowerCase()))
                                      .map((e) => e['nombre'].toString())
                                      .toList();
                                },
                                selectedItem: _estadoDomController.text.isEmpty
                                    ? null
                                    : _estadoDomController.text,
                                onChanged: isEliminar
                                    ? null
                                    : (String? newValue) {
                                        setState(() {
                                          _estadoDomController.text = newValue!;
                                          _municipioController.text = '';
                                        });
                                      },
                                dropdownBuilder: (context, selectedItem) =>
                                    Text(
                                  selectedItem ?? "",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedItem == null
                                        ? Colors.grey
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                  ),
                                ),
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: PremiumInputs.decoration(
                                    labelText: "Estado",
                                    prefixIcon: FontAwesomeIcons.map,
                                  ),
                                ),
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  fit: FlexFit.loose,
                                  itemBuilder: (context, item, isSelected,
                                      isItemDisabled) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                validator: isEliminar
                                    ? null
                                    : (value) => value == null || value.isEmpty
                                        ? 'El estado es obligatorio'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownSearch<String>(
                                key: const Key('municipioDropdown'),
                                enabled: _estadoDomController.text.isNotEmpty &&
                                    !isEliminar,
                                items: (filter, _) {
                                  if (_estadoDomController.text.isEmpty ||
                                      !_municipiosMap.containsKey(
                                          _estadoDomController.text)) {
                                    return [];
                                  }
                                  final municipios = _municipiosMap[
                                      _estadoDomController.text]!;
                                  return municipios
                                      .where((m) => m
                                          .toLowerCase()
                                          .contains(filter.toLowerCase()))
                                      .toList();
                                },
                                selectedItem:
                                    _municipioController.text.isNotEmpty
                                        ? _municipioController.text
                                        : null,
                                onChanged: isEliminar
                                    ? null
                                    : (String? newValue) {
                                        setState(() {
                                          _municipioController.text = newValue!;
                                        });
                                      },
                                dropdownBuilder: (context, selectedItem) =>
                                    Text(
                                  selectedItem ?? "",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedItem == null
                                        ? Colors.grey
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color,
                                  ),
                                ),
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: PremiumInputs.decoration(
                                    labelText: 'Municipio',
                                    prefixIcon: FontAwesomeIcons.city,
                                  ),
                                ),
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  fit: FlexFit.loose,
                                  itemBuilder: (context, item, isSelected,
                                      isItemDisabled) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                validator: isEliminar
                                    ? null
                                    : (value) => value == null || value.isEmpty
                                        ? 'El municipio es obligatorio'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _cpostalController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Código Postal',
                                  prefixIcon: FontAwesomeIcons.envelopesBulk,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(5),
                                ],
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'El código postal es obligatorio';
                                        } else if (value.length != 5) {
                                          return 'Debe tener 5 dígitos';
                                        }
                                        return null;
                                      },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _referenciaController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Referencia / Entre Calles',
                                  prefixIcon: FontAwesomeIcons.mapPin,
                                ),
                                enabled: !isEliminar,
                                validator: isEliminar
                                    ? null
                                    : (value) => value?.isEmpty ?? true
                                        ? 'La referencia es obligatoria'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        const PremiumSectionTitle(
                          title: "Información Adicional",
                          icon: FontAwesomeIcons.circleInfo,
                        ),
                        PremiumCardField(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _responsableController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Persona Responsable',
                                  prefixIcon: FontAwesomeIcons.userTie,
                                ),
                                enabled: !isEliminar,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _puestoController,
                                decoration: PremiumInputs.decoration(
                                  labelText: 'Puesto / Cargo',
                                  prefixIcon: FontAwesomeIcons.briefcase,
                                ),
                                enabled: !isEliminar,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: PremiumActionButton(
                                onPressed: closeRegistroModal,
                                label: 'Cancelar',
                                icon: Icons.close,
                                style: PremiumButtonStyle.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PremiumActionButton(
                                onPressed: _onSubmit,
                                label: buttonLabel,
                                icon: isEliminar
                                    ? FontAwesomeIcons.trash
                                    : (widget.accion == 'editar'
                                        ? FontAwesomeIcons.penToSquare
                                        : FontAwesomeIcons.floppyDisk),
                                isLoading: _isLoading,
                                style: isEliminar
                                    ? PremiumButtonStyle.danger
                                    : PremiumButtonStyle.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
