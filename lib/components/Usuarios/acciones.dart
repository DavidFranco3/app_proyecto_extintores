import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../api/usuarios.dart';
import '../../api/dropbox.dart';
import '../../api/cloudinary.dart';
import '../Logs/logs_informativos.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../Generales/flushbar_helper.dart';
import 'package:prueba/components/Header/header.dart';
import 'package:prueba/components/Menu/menu_lateral.dart';
import '../Load/load.dart';

class Acciones extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  Acciones(
      {required this.showModal,
      required this.onCompleted,
      required this.accion,
      required this.data});

  @override
  _AccionesState createState() => _AccionesState();
}

class _AccionesState extends State<Acciones> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _passwordController;
  late TextEditingController _rolController;

  String linkFirma = "";
  String linkFirmaCloudinary = "";

  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

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

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _emailController = TextEditingController();
    _telefonoController = TextEditingController();
    _passwordController = TextEditingController();
    _rolController = TextEditingController();

    if (widget.accion == 'editar' || widget.accion == 'eliminar') {
      _nombreController.text = widget.data['nombre'] ?? '';
      _emailController.text = widget.data['email'] ?? '';
      _telefonoController.text = widget.data['telefono'] ?? '';
      _passwordController.text = widget.data['password'] ?? '';
      _rolController.text = widget.data['tipo'] ?? '';
    }

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _rolController.dispose();
    super.dispose();
  }

  // Corregimos la función para que acepte un parámetro bool
  void closeRegistroModal() {
    widget.showModal(); // Llama a setShow con el valor booleano
    widget.onCompleted();
  }

  void _guardarUsuario(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {
      'nombre': data['nombre'],
      'email': data['email'],
      'telefono': data['telefono'],
      'password': data['password'],
      'tipo': data['tipo'],
      'firma': data['firma'],
      'firmaCloudinary': data['firmaCloudinary'],
      'estado': "true",
    };

    try {
      final usuariosService = UsuariosService();
      var response = await usuariosService.registraUsuarios(dataTemp);
      // Verifica el statusCode correctamente, según cómo esté estructurada la respuesta
      if (response['status'] == 200) {
        // Asumiendo que 'response' es un Map que contiene el código de estado
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha registrado el usuario ${data['nombre']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "El usuario fue agregado correctamente",
          backgroundColor: Colors.green,
        );
      } else {
        // Maneja el caso en que el statusCode no sea 200
        setState(() {
          _isLoading = false;
        });
        showCustomFlushbar(
          context: context,
          title: "Hubo un problema",
          message: "Hubo un error al agregar el usuario",
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
        message: error.toString(),
        backgroundColor: Colors.red,
      );
    }
  }

  void _editarUsuario(String id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {
      'nombre': data['nombre'],
      'email': data['email'],
      'telefono': data['telefono'],
      'password': data['password'],
      'tipo': data['tipo'],
    };

    try {
      final usuariosService = UsuariosService();
      var response = await usuariosService.actualizarUsuario(id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha modificado el usuario ${data['nombre']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Actualizacion exitosa",
          message: "Los datos del usuario fueron actualizados correctamente",
          backgroundColor: Colors.green,
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      showCustomFlushbar(
        context: context,
        title: "Oops...",
        message: error.toString(),
        backgroundColor: Colors.red,
      );
    }
  }

  void _eliminarUsuario(String id, data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {'estado': "false"};

    try {
      final usuariosService = UsuariosService();
      var response =
          await usuariosService.actualizaDeshabilitarUsuario(id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha eliminado el usuario ${data['nombre']} correctamente", {});
        showCustomFlushbar(
          context: context,
          title: "Eliminacion exitosa",
          message: "Se han eliminado correctamente los datos del usuario",
          backgroundColor: Colors.green,
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      showCustomFlushbar(
        context: context,
        title: "Oops...",
        message: error.toString(),
        backgroundColor: Colors.red,
      );
    }
  }

  void _onSubmit() async {
    if (!isEditar && !isEliminar) {
      final dropboxService = DropboxService();
      final cloudinaryService = CloudinaryService();
      setState(() {
        _isLoading = true; // Activar la animación de carga al inicio
      });

      String imagenFile = "";

      // Obtener la imagen de la firma
      final Uint8List? signatureImage = await _controller.toPngBytes();

      if (signatureImage != null) {
        // Llamas a la función que espera un Uint8List y obtienes la ruta
        String filePath = await saveImage(signatureImage);

        if (filePath.isNotEmpty) {
          imagenFile = filePath;
          String? sharedLink =
              await dropboxService.uploadImageToDropbox(imagenFile, "usuarios");
          String? sharedLink2 =
              await cloudinaryService.subirArchivoCloudinary(imagenFile, "clientes");
          if (sharedLink != null) {
            linkFirma = sharedLink; // Guardar el enlace de la firma
          }
          if (sharedLink2 != null) {
            linkFirmaCloudinary =
                sharedLink2; // Guardar el enlace de la firma
          }
        } else {
          print('No se pudo guardar la imagen de la firma correctamente');
        }
      } else {
        print('La imagen de firma es nula');
      }

      // Desactivamos la animación de carga después de que todas las imágenes se hayan subido
      setState(() {
        _isLoading = false; // Desactivar la animación de carga
      });
    }

    if (_formKey.currentState?.validate() ?? false) {
      var formData = {
        'nombre': _nombreController.text,
        'email': _emailController.text,
        'telefono': _telefonoController.text,
        'password': _passwordController.text,
        'tipo': _rolController.text,
        'firma': linkFirma,
        'firmaCloudinary': linkFirmaCloudinary,
      };

      if (widget.accion == 'registrar') {
        _guardarUsuario(formData);
      } else if (widget.accion == 'editar') {
        _editarUsuario(widget.data['id'], formData);
      } else if (widget.accion == 'eliminar') {
        _eliminarUsuario(widget.data['id'], formData);
      }
    }
  }

  String get buttonLabel {
    if (widget.accion == 'registrar') {
      return 'Guardar';
    } else if (widget.accion == 'editar') {
      return 'Actualizar';
    } else {
      return 'Eliminar';
    }
  }

  bool get isEliminar => widget.accion == 'eliminar';
  bool get isEditar => widget.accion == 'editar';

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Periodos"), // Usa el menú lateral
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
                        '${capitalize(widget.accion)} usuario',
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
                      mainAxisSize:
                          MainAxisSize.min, // Evita que ocupe todo el modal
                      children: [
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(labelText: 'Nombre'),
                          enabled: !isEliminar && !_isLoading,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'El nombre es obligatorio'
                                  : null,
                        ),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: 'Email'),
                          enabled: !isEliminar && !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          validator: isEliminar
                              ? null
                              : (value) => value != null &&
                                      !RegExp(r"^[^@]+@[^@]+\.[^@]+")
                                          .hasMatch(value)
                                  ? 'Por favor ingresa un email válido'
                                  : null,
                        ),
                        TextFormField(
                          controller: _telefonoController,
                          decoration: InputDecoration(labelText: 'Teléfono'),
                          enabled: !isEliminar && !_isLoading,
                          keyboardType: TextInputType.number,
                          validator: isEliminar
                              ? null
                              : (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El teléfono es obligatorio';
                                  } else if (!RegExp(r'^\d{10}$')
                                      .hasMatch(value)) {
                                    return 'El teléfono debe tener 10 dígitos';
                                  }
                                  return null;
                                },
                        ),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(labelText: 'Contraseña'),
                          enabled: !isEliminar && !_isLoading,
                          obscureText: true,
                          validator: (value) {
                            if (!isEliminar && !isEditar) {
                              return value?.isEmpty ?? true
                                  ? 'La contraseña es obligatoria'
                                  : null;
                            }
                            return null;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          value: _rolController.text.isEmpty
                              ? null
                              : _rolController.text, // Permitir valor nulo
                          onChanged: (isEliminar || _isLoading)
                              ? null
                              : (String? newValue) {
                                  setState(() {
                                    _rolController.text = newValue ??
                                        ''; // Asegurar que no sea nulo
                                  });
                                },
                          decoration: InputDecoration(labelText: 'Rol'),
                          items: [
                            DropdownMenuItem<String>(
                              value: "",
                              child: Text("Selecciona una opción",
                                  style: TextStyle(color: Colors.grey)),
                            ),
                            DropdownMenuItem<String>(
                              value: "administrador",
                              child: Text("Administrador"),
                            ),
                            DropdownMenuItem<String>(
                              value: "inspector",
                              child: Text("Inspector"),
                            ),
                          ],
                          validator: isEliminar
                              ? null
                              : (value) => (value == null || value.isEmpty)
                                  ? 'Por favor selecciona un rol'
                                  : null,
                        ),
                        SizedBox(height: 16),

                        /// **Sección de Firma**
                        if (!isEditar && !isEliminar) ...[
                          Text(
                            "Firma del cliente",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Container(
                            width:
                                double.infinity, // Se ajusta al ancho del modal
                            height: 250, // Altura fija para evitar problemas
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey), // Agrega borde
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Signature(
                                controller: _controller,
                                height: 300,
                                backgroundColor:
                                    Colors.transparent, // Fondo transparente
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _controller.clear(),
                                child: Text("Limpiar Firma"),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                        ],
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : closeRegistroModal,
                              child: Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _onSubmit,
                              child: _isLoading
                                  ? SpinKitFadingCircle(
                                      color: Colors.white, size: 24)
                                  : Text(buttonLabel),
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
