import 'package:flutter/material.dart';
import '../../api/encuesta_inspeccion.dart';
import '../../api/inspecciones.dart';
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

class EncuestaPage extends StatefulWidget {
  @override
  _EncuestaPageState createState() => _EncuestaPageState();
}

class _EncuestaPageState extends State<EncuestaPage> {
  List<Pregunta> preguntas = [];
  List<Map<String, dynamic>> dataEncuestas = [];
  List<Map<String, dynamic>> dataRamas = [];
  String? selectedEncuestaId;
  String? selectedRamaId;
  String? selectedFrecuenciaId;
  bool loading = true;
  bool _isLoading = false;
  int currentPage = 0; // Para controlar la página actual
  final int preguntasPorPagina = 5; // Número de preguntas por página
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> dataClientes = [];
  String? selectedIdFrecuencia;

  List<Map<String, dynamic>> dataFrecuencias = [];

  // Lista para almacenar imágenes y comentarios
  List<Map<String, dynamic>> imagePaths = [];

  List<Map<String, dynamic>> uploadedImageLinks =
      []; // Array para guardar objetos con enlaces y comentarios

  List<Map<String, dynamic>> uploadedImageLinksCloudinary =
      []; // Array para guardar objetos con enlaces y comentarios

  String linkFirma = "";
  String linkFirmaCloudinary = "";

  late TextEditingController clienteController;
  late TextEditingController descripcionController;
  late TextEditingController comentariosController;
  late TextEditingController comentariosImagenController;

  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  void limpiarCampos() {
    preguntas = [];
    selectedEncuestaId = null;
    selectedRamaId = null;
    selectedFrecuenciaId = null;
    selectedIdFrecuencia = null;

    uploadedImageLinks = [];

    uploadedImageLinksCloudinary = [];

    imagePaths = [];

    linkFirma = "";
    linkFirmaCloudinary = "";

    dataEncuestas = [];

    clienteController.clear();
    comentariosController.clear();
    descripcionController.clear();

    _controller.clear();
  }

  @override
  void initState() {
    super.initState();
    getRamas();
    getClientes();
    getFrecuencias();

    _pageController.addListener(() {
      setState(() {
        currentPage = _pageController.page!.round();
      });
    });

    clienteController = TextEditingController();
    comentariosController = TextEditingController();
    descripcionController = TextEditingController();
  }

  @override
  void dispose() {
    clienteController.dispose();
    comentariosController.dispose();
    descripcionController.dispose();
    super.dispose();
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
    try {
      final clientesService = ClientesService();
      final List<dynamic> response = await clientesService.listarClientes();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
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
      print("Error al obtener los clientes: $e");
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
        setState(() {
          dataRamas = formatModelRamas(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataRamas = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      print("Error al obtener las ramas: $e");
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
        setState(() {
          dataFrecuencias = formatModelFrecuencias(response);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          dataFrecuencias = [];
        });
      }
    } catch (e) {
      print("Error al obtener las frecuencias: $e");
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

  Future<void> getEncuestas(String idRama, String idFrecuencia) async {
    try {
      final encuestaInspeccionService = EncuestaInspeccionService();
      final List<dynamic> response = await encuestaInspeccionService
          .listarEncuestaInspeccionPorRama(idRama, idFrecuencia);

      if (response.isNotEmpty) {
        setState(() {
          dataEncuestas = formatModelEncuestas(response);
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

  // Función para formatear los datos de las encuestas
  List<Map<String, dynamic>> formatModelEncuestas(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'idFrecuencia': item['idFrecuencia'],
        'preguntas': item['preguntas'],
      });
    }
    return dataTemp;
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

  // Dividir las preguntas en páginas de 5
  List<List<Pregunta>> dividirPreguntasEnPaginas() {
    List<List<Pregunta>> paginas = [];
    for (int i = 0; i < preguntas.length; i += preguntasPorPagina) {
      paginas.add(preguntas.sublist(
          i,
          i + preguntasPorPagina > preguntas.length
              ? preguntas.length
              : i + preguntasPorPagina));
    }
    return paginas;
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
        clienteController.text.isEmpty ||
        data["imagenes"] == null ||
        data["imagenes"].length < 7) {
      setState(() {
        _isLoading = false;
      });

      String mensaje = data["imagenes"] == null || data["imagenes"].length < 7
          ? "Debes subir al menos 7 imágenes para continuar."
          : "Por favor, completa todos los campos obligatorios antes de continuar.";

      showCustomFlushbar(
        context: context,
        title: "Campos incompletos",
        message: mensaje,
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

  Future<void> _onSubmit() async {
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
      "idCliente": clienteController.text,
      "idEncuesta": selectedEncuestaId,
      "preguntas": respuestasAguardar,
      "imagenes":
          uploadedImageLinks, // Asegúrate de pasar los enlaces de las imágenes
      "imagenesCloudinary":
          uploadedImageLinksCloudinary, // Asegúrate de pasar los enlaces de las imágenes
      "comentarios": comentariosController.text,
      "descripcion": descripcionController.text,
      "firmaCliente": linkFirma,
      "firmaClienteCloudinary": linkFirmaCloudinary
    };

    // Llamar a la función para guardar la encuesta
    _guardarEncuesta(formData);
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
      drawer: MenuLateral(currentPage: "Aplicar inspección"),
      body: loading
          ? Load()
          : SingleChildScrollView(
              // Añadimos SingleChildScrollView
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Center(
                      child: Text(
                        "Aplicar inspección",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Botón centrado debajo del título
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : _onSubmit, // Deshabilitar botón mientras carga
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12), // Altura estándar
                              fixedSize:
                                  Size(150, 50), // Ancho fijo y altura flexible
                            ),
                            icon: Icon(FontAwesomeIcons.plus), // Ícono de +
                            label: _isLoading
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SpinKitFadingCircle(
                                        color: const Color.fromARGB(
                                            255, 241, 8, 8),
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text("Guardando..."), // Texto de carga
                                    ],
                                  )
                                : Text(
                                    "Guardar"), // Texto normal cuando no está cargando
                          ),
                          SizedBox(width: 10), // Espacio entre los botones
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Dropdown de Encuesta
                    DropdownButtonFormField<String>(
                      value: selectedRamaId,
                      hint: Text('Selecciona un Tipo de Sistema'),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRamaId = newValue;
                        });

                        if (newValue != null && selectedFrecuenciaId != null) {
                          getEncuestas(selectedRamaId!, selectedFrecuenciaId!);
                        }
                      },
                      isExpanded: true,
                      items: dataRamas.map((rama) {
                        return DropdownMenuItem<String>(
                          value: rama['id'],
                          child: Text(rama['nombre']!),
                        );
                      }).toList(),
                    ),
                    // Dropdown de Encuesta
                    DropdownButtonFormField<String>(
                      value: selectedFrecuenciaId,
                      hint: Text('Selecciona un periodo'),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedFrecuenciaId = newValue;
                        });

                        if (newValue != null && selectedRamaId != null) {
                          getEncuestas(selectedRamaId!, selectedFrecuenciaId!);
                        }
                      },
                      isExpanded: true,
                      items: dataFrecuencias.map((rama) {
                        return DropdownMenuItem<String>(
                          value: rama['id'],
                          child: Text(rama['nombre']!),
                        );
                      }).toList(),
                    ),
                    // Dropdown de Encuesta
                    DropdownButtonFormField<String>(
                      value: selectedEncuestaId,
                      hint: Text('Selecciona una encuesta'),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedEncuestaId = newValue;
                          currentPage = 0;

                          final encuestaSeleccionada = dataEncuestas.firstWhere(
                            (encuesta) => encuesta['id'] == newValue,
                          );

                          selectedIdFrecuencia =
                              encuestaSeleccionada['idFrecuencia'];
                        });

                        if (newValue != null) {
                          actualizarPreguntas(newValue);
                        }
                      },
                      isExpanded: true,
                      items: dataEncuestas.map((encuesta) {
                        return DropdownMenuItem<String>(
                          value: encuesta['id'],
                          child: Text(encuesta['nombre']!),
                        );
                      }).toList(),
                    ),
                    // Dropdown de Cliente
                    DropdownButtonFormField<String>(
                      value: clienteController.text.isEmpty
                          ? null
                          : clienteController.text,
                      decoration: InputDecoration(labelText: 'Cliente'),
                      isExpanded: true,
                      items: dataClientes.map((cliente) {
                        return DropdownMenuItem<String>(
                          value: cliente['id'],
                          child: Text(cliente['nombre']!),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          clienteController.text = newValue!;
                        });
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'El cliente es obligatorio'
                          : null,
                    ),
                    // Agregar más Dropdowns si es necesario
                    if (selectedEncuestaId != null && preguntas.isNotEmpty)
                      SizedBox(
                        height:
                            MediaQuery.of(context).size.width > 700 ? 700 : 300,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: 5, // ← Ahora son 5 páginas
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
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              physics: ClampingScrollPhysics(),
                                              itemCount:
                                                  pregunta.opciones.length,
                                              itemBuilder: (context, i) {
                                                final opcion =
                                                    pregunta.opciones[i];
                                                return ListTile(
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  title: Text(opcion),
                                                  leading: Radio<String>(
                                                    value: opcion,
                                                    groupValue:
                                                        pregunta.respuesta,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        pregunta.respuesta =
                                                            value!;
                                                      });
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          TextField(
                                            decoration: InputDecoration(
                                              labelText: "Observaciones",
                                              border: OutlineInputBorder(),
                                            ),
                                            maxLines: 2,
                                            onChanged: (value) {
                                              setState(() {
                                                pregunta.observaciones = value;
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Descripción",
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
                                            "Escribe aquí la descripción de la inspección...",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else if (pageIndex == 2) {
                              // Página de comentarios finales
                              return Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Comentarios Finales",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10),
                                    TextField(
                                      controller: comentariosController,
                                      maxLines: 5,
                                      decoration: InputDecoration(
                                        hintText:
                                            "Escribe aquí tus comentarios finales...",
                                        border: OutlineInputBorder(),
                                      ),
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
                                                fontWeight: FontWeight.bold),
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
                                                    child: Text('Horizontal')),
                                                DropdownMenuItem(
                                                    value: 'vertical',
                                                    child: Text('Vertical')),
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
                                              setState(
                                                  () => _imageHorizontal = img);
                                            }),
                                            child: _buildImageContainer(
                                                _imageHorizontal),
                                          )
                                        else ...[
                                          GestureDetector(
                                            onTap: () => _pickImage((img) {
                                              setState(
                                                  () => _imageVertical1 = img);
                                            }),
                                            child: _buildImageContainer(
                                                _imageVertical1,
                                                label: "Imagen 1"),
                                          ),
                                          SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () => _pickImage((img) {
                                              setState(
                                                  () => _imageVertical2 = img);
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
                                          keyboardType: TextInputType.number,
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
                                                margin: EdgeInsets.symmetric(
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
                                            backgroundColor: Colors.transparent,
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
                                              child:
                                                  const Text("Limpiar Firma"),
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

                    // Si hay encuesta seleccionada y preguntas disponibles
                    if (preguntas.isNotEmpty)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          height: 60,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
              ),
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
