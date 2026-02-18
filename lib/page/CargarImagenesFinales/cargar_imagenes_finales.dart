import 'package:flutter/material.dart';

import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Logs/logs_informativos.dart';
import '../../components/Generales/premium_button.dart';

import '../../components/Generales/flushbar_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../InspeccionesPantalla1/inspecciones_pantalla_1.dart';
import '../../api/dropbox.dart';
import '../../api/cloudinary.dart';
import 'package:provider/provider.dart';
import '../../controllers/inspecciones_controller.dart';

class CargarImagenesFinalesScreen extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  @override
  const CargarImagenesFinalesScreen({
    super.key,
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
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _guardarEncuesta(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final controller = context.read<InspeccionesController>();
    final isOnline = !controller.isOffline;

    final wasSent =
        await controller.actualizarImagenes(widget.data["id"], data);

    setState(() {
      _isLoading = false;
    });

    if (wasSent) {
      returnPrincipalPage();
      logsInformativos("Se ha actualizado la encuesta correctamente", {});
      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Actualización exitosa",
          message: "Los datos de la encuesta fueron actualizados correctamente",
          backgroundColor: Colors.green,
        );
      }
    } else if (!isOnline) {
      returnPrincipalPage();
      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Sin conexión",
          message:
              "Actualizada localmente. Se sincronizará al recuperar internet.",
          backgroundColor: Colors.orange,
        );
      }
    } else {
      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Error",
          message: "No se pudo actualizar la encuesta",
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
          currentPage: "Historial de actividades"), // Usa el menú lateral
      body: loading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Center(
                        child: Text(
                          "Reporte",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C3E50),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    // Botones centrados con separación
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: PremiumActionButton(
                            onPressed: _isLoading ? () {} : _onSubmit,
                            icon: FontAwesomeIcons.plus,
                            label: _isLoading ? "Cargando..." : buttonLabel,
                            isLoading: _isLoading,
                            style: PremiumButtonStyle.primary,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: PremiumActionButton(
                            onPressed: returnPrincipalPage,
                            icon: FontAwesomeIcons.arrowLeft,
                            label: "Regresar",
                            style: PremiumButtonStyle.secondary,
                          ),
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
                                child: PremiumActionButton(
                                  onPressed: _agregarImagen,
                                  label: "Agregar",
                                  icon: FontAwesomeIcons.plus,
                                  style: PremiumButtonStyle.primary,
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
