import 'package:flutter/material.dart';
import '../../api/inspecciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Logs/logs_informativos.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../components/Generales/flushbar_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../InspeccionesPantalla1/inspecciones_pantalla_1.dart';
import '../../api/dropbox.dart';
import '../../api/cloudinary.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CargarImagenesFinalesScreen extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  @override
  const CargarImagenesFinalesScreen({super.key, 
    required this.showModal,
    required this.onCompleted,
    required this.accion,
    required this.data,
  });

  @override
  State<CargarImagenesFinalesScreen> createState() =>
      _CargarImagenesFinalesScreenState();
}

class _CargarImagenesFinalesScreenState
    extends State<CargarImagenesFinalesScreen> {
  final _formKey = GlobalKey<FormState>();
  bool loading = true;
  bool _isLoading = false;
  // Lista para almacenar imágenes y comentarios
  List<Map<String, dynamic>> imagePaths = [];
  List<Map<String, dynamic>> uploadedImageLinks =
      []; // Array para guardar objetos con enlaces y comentarios
  List<Map<String, dynamic>> uploadedImageLinksCloudinary =
      []; // Array para guardar objetos con enlaces y comentarios
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        loading = false;
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

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> sincronizarOperacionesPendientes() async {
    final conectado = await verificarConexion();
    if (!conectado) return;

    final box = Hive.box('operacionesOfflineInspecciones');
    final operacionesRaw = box.get('operaciones', defaultValue: []);

    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    if (operaciones.isEmpty) return;

    final inspeccionesService = InspeccionesService();
    final List<int> eliminarIndices = [];

    for (int i = 0; i < operaciones.length; i++) {
      final operacion = operaciones[i];

      // Inicializar / Incrementar intentos
      operacion['intentos'] = (operacion['intentos'] ?? 0) + 1;

      try {
        final response = await inspeccionesService
            .actualizarImagenesInspecciones(operacion['id'], operacion['data']);

        if (response['status'] == 200) {
          final inspeccionesBox = Hive.box('inspeccionesBox');
          final actualesRaw =
              inspeccionesBox.get('inspecciones', defaultValue: []);
          final actuales = (actualesRaw as List)
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item))
              .toList();

          final index = actuales
              .indexWhere((element) => element['id'] == operacion['id']);
          if (index != -1) {
            actuales[index] = {
              ...actuales[index],
              ...operacion['data'],
              'updatedAt': DateTime.now().toString()
            };
            await inspeccionesBox.put('inspecciones', actuales);
          }
          eliminarIndices.add(i);
        } else if (response['status'] >= 400 && response['status'] < 500) {
          debugPrint(
              "Error no reintentable (4xx) en sincronización de imágenes: ${response['status']}");
          eliminarIndices.add(i);
        } else {
          debugPrint(
              "Error de servidor (5xx) en sincronización de imágenes: ${response['status']}");
          if (operacion['intentos'] >= 5) {
            debugPrint(
                "Límite de reintentos alcanzado para sincronización de imágenes.");
            eliminarIndices.add(i);
          }
        }
      } catch (e) {
        debugPrint('Error de red sincronizando imágenes: $e');
        if (operacion['intentos'] >= 5) {
          debugPrint("Límite de reintentos alcanzado por red en imágenes.");
          eliminarIndices.add(i);
        }
      }
    }

    // Actualizar el box de Hive
    final nuevasOperaciones = operaciones
        .asMap()
        .entries
        .where((entry) => !eliminarIndices.contains(entry.key))
        .map((e) => e.value)
        .toList();

    await box.put('operaciones', nuevasOperaciones);

    if (eliminarIndices.isNotEmpty) {
      debugPrint("✔ Sincronización de imágenes finalizada.");
    }

    // ✅ Actualizar lista completa desde API
    try {
      final List<dynamic> dataAPI =
          await inspeccionesService.listarInspecciones();

      final formateadas = dataAPI
          .map<Map<String, dynamic>>((item) => {
                'id': item['_id'],
                'idUsuario': item['idUsuario'],
                'idCliente': item['idCliente'],
                'idEncuesta': item['idEncuesta'],
                'idRama': item['cuestionario']['idRama'],
                'idClasificacion': item['cuestionario']['idClasificacion'],
                'idFrecuencia': item['cuestionario']['idFrecuencia'],
                'idCuestionario': item['cuestionario']['_id'],
                'encuesta': item['encuesta'],
                'imagenes': item?['imagenes'] ?? [],
                'imagenesCloudinary': item?['imagenesCloudinary'] ?? [],
                'imagenes_finales': item?['imagenesFinales'] ?? [],
                'imagenes_finales_cloudinary':
                    item?['imagenesFinalesCloudinary'] ?? [],
                'comentarios': item['comentarios'],
                'preguntas': item['encuesta'],
                'descripcion': item['descripcion'],
                'usuario': item['usuario']['nombre'],
                'cliente': item['cliente']['nombre'],
                'puestoCliente': item['cliente']['puesto'],
                'responsableCliente': item['cliente']['responsable'],
                'estadoDom': item['cliente']['direccion']['estadoDom'],
                'municipio': item['cliente']['direccion']['municipio'],
                'imagen_cliente': item['cliente']['imagen'],
                'imagen_cliente_cloudinary': item['cliente']
                    ['imagenCloudinary'],
                'firma_usuario': item['usuario']['firma'],
                'firma_usuario_cloudinary': item['usuario']['firmaCloudinary'],
                'cuestionario': item['cuestionario']['nombre'],
                'usuarios': item['usuario'],
                'inspeccion_eficiencias': item['inspeccionEficiencias'],
                'estado': item['estado'],
                'createdAt': item['createdAt'],
                'updatedAt': item['updatedAt'],
              })
          .toList();

      final inspeccionesBox = Hive.box('inspeccionesBox');
      await inspeccionesBox.put('inspecciones', formateadas);
    } catch (e) {
      debugPrint('Error actualizando datos después de sincronización: $e');
    }
  }

  void _guardarEncuesta(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'imagenesFinales': data['imagenesFinales'],
      'imagenesFinalesCloudinary': data['imagenesFinalesCloudinary'],
    };

    if (!conectado) {
      final box = Hive.box('operacionesOfflineInspecciones');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'editar',
        'id': widget.data["id"],
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final inspeccionesBox = Hive.box('inspeccionesBox');
      final actualesRaw = inspeccionesBox.get('inspecciones', defaultValue: []);

      final actuales = (actualesRaw as List)
          .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final index =
          actuales.indexWhere((element) => element['id'] == widget.data["id"]);
      // Actualiza localmente el registro editado
      if (index != -1) {
        actuales[index] = {
          ...actuales[index],
          ...dataTemp,
          'updatedAt': DateTime.now().toString(),
        };
        await inspeccionesBox.put('inspecciones', actuales);
      }

      setState(() {
        _isLoading = false;
      });
      returnPrincipalPage();
      if (mounted) {
        showCustomFlushbar(
        context: context,
        title: "Sin conexión",
        message:
            "Encuesta actualizada localmente y se sincronizará cuando haya internet",
        backgroundColor: Colors.orange,
      );
      }
      return;
    }

    try {
      final inspeccionesService = InspeccionesService();
      var response = await inspeccionesService.actualizarImagenesInspecciones(
          widget.data["id"], dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        returnPrincipalPage();
        logsInformativos(
            "Se ha actualizado la encuesta ${data['nombre']} correctamente",
            {});
        if (mounted) {
          showCustomFlushbar(
          context: context,
          title: "Actualización exitosa",
          message: "Los datos de la encuesta fueron actualizados correctamente",
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

  Future<void> _onSubmit() async {
    // ✅ Agregar async a la función

    final dropboxService = DropboxService();
    final cloudinaryService = CloudinaryService();
    setState(() {
      _isLoading = true; // Activar la animación de carga al inicio
    });

// Subir imágenes adicionales si hay imágenes seleccionadas
    if (imagePaths.isNotEmpty) {
      for (var imagePath in imagePaths) {
        // Asegúrate de que imagePath sea un mapa con las claves correctas
        String? imagePathStr = imagePath["imagePath"];

        if (imagePathStr != null) {
          String? sharedLink = await dropboxService.uploadImageToDropbox(
              imagePathStr, "inspecciones");
          String? sharedLink2 = await cloudinaryService.subirArchivoCloudinary(
              imagePathStr, "inspecciones");
          if (sharedLink != null) {
            // Crear un mapa con el sharedLink y el comentario
            var imageInfo = {
              "sharedLink": sharedLink,
            };
            // Agregar el mapa a la lista
            uploadedImageLinks.add(imageInfo);
          }
          if (sharedLink2 != null) {
            // Crear un mapa con el sharedLink y el comentario
            var imageInfo = {
              "sharedLink": sharedLink2,
            };
            // Agregar el mapa a la lista
            uploadedImageLinksCloudinary.add(imageInfo);
          }
        }
      }
    }

// Desactivamos la animación de carga después de que todas las imágenes se hayan subido
    setState(() {
      _isLoading = false; // Desactivar la animación de carga
    });

    // Crear el formulario con los datos
    var formData = {
      "imagenesFinales":
          uploadedImageLinks, // Asegúrate de pasar los enlaces de las imágenes
      "imagenesFinalesCloudinary":
          uploadedImageLinksCloudinary, // Asegúrate de pasar los enlaces de las imágenes
    };

    // Llamar a la función para guardar la encuesta
    _guardarEncuesta(formData);
  }

  String get buttonLabel {
    if (widget.accion == 'registrar') {
      return 'Guardar';
    } else {
      return 'Actualizar';
    }
  }

  void returnPrincipalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InspeccionesPantalla1Page()),
    ).then((_) {
      // Actualizar encuestas al regresar de la página
    });
  }

  final ImagePicker _picker = ImagePicker();
  XFile? _image; // Imagen en vista previa

  // Método para seleccionar imagen
  Future<void> _pickImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _image = pickedImage; // Muestra la imagen en vista previa
      });
    }
  }

  // Método para agregar imagen con comentario y limpiar vista previa
  void _agregarImagen() {
    if (_image != null) {
      setState(() {
        // Agregar imagen y comentario a la lista
        imagePaths.add({
          "imagePath": _image!.path,
        });

        // Limpiar vista previa y comentario
        _image = null;
      });

      debugPrint("Imagen agregada: ${imagePaths.last}");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Selecciona una imagen y escribe un comentario")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _formKey,
      appBar: Header(), // Usa el header con menú de usuario
      drawer: MenuLateral(
          currentPage: "Cargar imagenes finales"), // Usa el menú lateral
      body: loading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          "Reporte",
                          style: TextStyle(
                            fontSize: 24, // Tamaño grande
                            fontWeight: FontWeight.bold, // Negrita
                          ),
                        ),
                      ),
                    ),
                    // Botones centrados con separación
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _onSubmit,
                          icon: Icon(FontAwesomeIcons.plus), // Ícono de +
                          label: _isLoading
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SpinKitFadingCircle(
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text("Cargando..."), // Texto de carga
                                  ],
                                )
                              : Text(
                                  buttonLabel), // Texto normal cuando no está cargando
                        ),
                        SizedBox(width: 10), // Separación entre botones
                        ElevatedButton.icon(
                          onPressed: returnPrincipalPage,
                          icon: Icon(FontAwesomeIcons
                              .arrowLeft), // Ícono de flecha hacia la izquierda
                          label: _isLoading
                              ? SpinKitFadingCircle(
                                  color: const Color.fromARGB(255, 241, 8, 8),
                                  size: 24,
                                )
                              : Text("Regresar"),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          // Permite desplazamiento cuando el contenido excede la pantalla
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  "Carga de Imágenes",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              SizedBox(height: 10),

                              // Centrar la parte de carga de imágenes
                              Center(
                                child: GestureDetector(
                                  onTap:
                                      _pickImage, // Asegúrate de implementar este método
                                  child: Container(
                                    width: double.infinity,
                                    height: 250,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: _image == null
                                        ? Center(
                                            child: Icon(
                                              Icons.cloud_upload,
                                              size: 50,
                                              color: Colors.blueAccent,
                                            ),
                                          )
                                        : ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.file(
                                              File(_image!.path),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              // Centrar el botón de agregar
                              Center(
                                child: ElevatedButton(
                                  onPressed:
                                      _agregarImagen, // Verifica que este método maneje la lógica correctamente
                                  child: Text("Agregar"),
                                ),
                              ),
                              SizedBox(height: 16),

                              // Lista de imágenes con comentarios
                              if (imagePaths
                                  .isNotEmpty) // Asegúrate de que la lista no esté vacía
                                ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: imagePaths.length,
                                  itemBuilder: (context, index) {
                                    return Card(
                                      margin: EdgeInsets.symmetric(vertical: 8),
                                      child: ListTile(
                                        leading: Image.file(
                                          File(imagePaths[index]["imagePath"]),
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}


