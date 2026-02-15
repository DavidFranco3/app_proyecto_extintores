import 'package:flutter/material.dart';
import '../../api/reporte_final.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../components/Generales/flushbar_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../ReporteFinal/reporte_final.dart';
import '../../api/dropbox.dart';
import '../../api/cloudinary.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../utils/offline_sync_util.dart';

class RegistrarReporteScreen extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  @override
  const RegistrarReporteScreen({super.key, 
    required this.showModal,
    required this.onCompleted,
    required this.accion,
    required this.data,
  });

  @override
  State<RegistrarReporteScreen> createState() => _RegistrarReporteScreenState();
}

class _RegistrarReporteScreenState extends State<RegistrarReporteScreen> {
  final _formKey = GlobalKey<FormState>();
  bool loading = true;
  bool _isLoading = false;
  // Lista para almacenar imágenes y comentarios
  List<Map<String, dynamic>> imagePaths = [];
  List<Map<String, dynamic>> uploadedImageLinks =
      []; // Array para guardar objetos con enlaces y comentarios
  List<Map<String, dynamic>> uploadedImageLinksCloudinary =
      []; // Array para guardar objetos con enlaces y comentarios
  late TextEditingController descripcionController;
  @override
  void initState() {
    super.initState();
    descripcionController = TextEditingController();
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
    descripcionController.dispose();
    super.dispose();
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> sincronizarOperacionesPendientes() async {
    final conectado = await OfflineSyncUtil().verificarConexion();
    if (!conectado) return;

    final box = Hive.box('operacionesOfflineReportes');
    final operacionesRaw = box.get('operaciones', defaultValue: []);

    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    if (operaciones.isEmpty) return;

    final reportesService = ReporteFinalService();
    final List<String> eliminarIds = [];

    for (var operacion in operaciones) {
      operacion['intentos'] = (operacion['intentos'] ?? 0) + 1;
      try {
        final response =
            await reportesService.registrarReporteFinal(operacion['data']);

        final status = response['status'];
        if (status == 200 ||
            (status >= 400 && status < 500) ||
            operacion['intentos'] >= 5) {
          eliminarIds.add(operacion['operacionId'] ?? '');

          if (status == 200 && response['data'] != null) {
            final reportesBox = Hive.box('reporteFinalBox');
            final actualesRaw = reportesBox.get('reportes', defaultValue: []);
            final actuales = (actualesRaw as List)
                .map<Map<String, dynamic>>(
                    (item) => Map<String, dynamic>.from(item))
                .toList();

            actuales.removeWhere((element) => element['id'] == operacion['id']);
            actuales.add({
              'id': response['data']['_id'],
              'descripcion': response['data']['descripcion'],
              'estado': response['data']['estado'],
              'createdAt': response['data']['createdAt'],
              'updatedAt': response['data']['updatedAt'],
            });
            await reportesBox.put('reportes', actuales);
          }
        }
      } catch (e) {
        debugPrint('Error sincronizando operación: $e');
        if (operacion['intentos'] >= 5) {
          eliminarIds.add(operacion['operacionId'] ?? '');
        }
      }
    }

    final nuevasOperaciones = operaciones
        .where((op) => !eliminarIds.contains(op['operacionId']))
        .toList();
    await box.put('operaciones', nuevasOperaciones);

    if (eliminarIds.isNotEmpty) {
      debugPrint("✔ Sincronización de reportes finalizada.");
    }

    // ✅ Actualizar lista completa desde API
    try {
      final List<dynamic> dataAPI = await reportesService.listarReporteFinal();
      final formateadas = dataAPI
          .map<Map<String, dynamic>>((item) => {
                'id': item['_id'],
                'descripcion': item['descripcion'],
                'imagenes': item['imagenes'],
                'estado': item['estado'],
                'createdAt': item['createdAt'],
                'updatedAt': item['updatedAt'],
              })
          .toList();
      await Hive.box('reporteFinalBox').put('reportes', formateadas);
    } catch (e) {
      debugPrint('Error actualizando datos de reportes: $e');
    }
  }

  void _guardarEncuesta(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await OfflineSyncUtil().verificarConexion();

    var dataTemp = {
      'descripcion': data['descripcion'],
      'imagenes': data['imagenes'],
      'imagenesCloudinary': data['imagenesCloudinary'],
      'estado': "true",
    };

    if (!conectado) {
      final box = Hive.box(
          'operacionesOfflineReportes'); // Corregido: RegistrarReporte usa reportes
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'registrar',
        'operacionId': UniqueKey().toString(),
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      // Actualización local anticipada
      final reportesBox = Hive.box('reporteFinalBox');
      final actualesRaw = reportesBox.get('reportes', defaultValue: []);
      final actuales = (actualesRaw as List)
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();

      actuales.add({
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        ...dataTemp,
        'createdAt': DateTime.now().toString(),
        'updatedAt': DateTime.now().toString(),
      });
      await reportesBox.put('reportes', actuales);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        returnPrincipalPage();
        if (mounted) {
          showCustomFlushbar(
          context: context,
          title: "Sin conexión",
          message:
              "Reporte guardado localmente y se sincronizará cuando haya internet",
          backgroundColor: Colors.orange,
        );
        }
      }
      return;
    }

    try {
      final reportesService = ReporteFinalService();
      var response = await reportesService.registrarReporteFinal(dataTemp);

      if (response['status'] == 200) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          returnPrincipalPage();
          if (mounted) {
            showCustomFlushbar(
            context: context,
            title: "Registro exitoso",
            message: "El reporte se ha guardado correctamente",
            backgroundColor: Colors.green,
          );
          }
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          showCustomFlushbar(
          context: context,
          title: "Error",
          message: error.toString(),
          backgroundColor: Colors.red,
        );
        }
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
        String? comentario = imagePath["comentario"];

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
            };
            // Agregar el mapa a la lista
            uploadedImageLinks.add(imageInfo);
          }
          if (sharedLink2 != null) {
            // Crear un mapa con el sharedLink y el comentario
            var imageInfo = {
              "sharedLink": sharedLink2,
              "comentario": comentario,
            };
            // Agregar el mapa a la lista
            uploadedImageLinks.add(imageInfo);
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
      "imagenes":
          uploadedImageLinks, // Asegúrate de pasar los enlaces de las imágenes
      "imagenesClodinary":
          uploadedImageLinksCloudinary, // Asegúrate de pasar los enlaces de las imágenes
      "descripcion": descripcionController.text,
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
      MaterialPageRoute(builder: (context) => ReporteFinalPage()),
    ).then((_) {
      // Actualizar encuestas al regresar de la página
    });
  }

  final ImagePicker _picker = ImagePicker();
  XFile? _image; // Imagen en vista previa
  final TextEditingController _comentarioController = TextEditingController();

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
    if (_image != null && _comentarioController.text.isNotEmpty) {
      setState(() {
        // Agregar imagen y comentario a la lista
        imagePaths.add({
          "imagePath": _image!.path,
          "comentario": _comentarioController.text,
        });

        // Limpiar vista previa y comentario
        _image = null;
        _comentarioController.clear();
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
          currentPage:
              "Reporte de inspecciones y pruebas"), // Usa el menú lateral
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
                    // Campo de texto para descripción (tipo textarea)
                    TextFormField(
                      controller: descripcionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Escribe aquí la descripción del reporte...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),

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

                              // Campo de texto para comentario
                              TextField(
                                controller: _comentarioController,
                                decoration:
                                    InputDecoration(labelText: "Comentario"),
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
                                        title: Text(
                                          '${imagePaths[index]["comentario"]}',
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


