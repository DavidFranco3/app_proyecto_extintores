import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/usuarios.dart';
import '../../api/dropbox.dart';
import '../../api/cloudinary.dart';
import '../Logs/logs_informativos.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../Generales/premium_button.dart';
import '../Generales/flushbar_helper.dart';
import 'package:prueba/components/Header/header.dart';
import 'package:prueba/components/Menu/menu_lateral.dart';
import '../Load/load.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dropdown_search/dropdown_search.dart';

class Acciones extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  const Acciones({
    super.key,
    required this.showModal,
    required this.onCompleted,
    required this.accion,
    required this.data,
  });

  @override
  State<Acciones> createState() => _AccionesState();
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
        debugPrint('Imagen guardada en: $filePath');
      }

      // Retornar la ruta del archivo
      return filePath;
    } catch (e) {
      debugPrint('Error guardando la imagen: $e');
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
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _rolController.dispose();
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

    final box = Hive.box('operacionesOfflineUsuarios');
    final operacionesRaw = box.get('operaciones', defaultValue: []);

    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    final usuariosService = UsuariosService();
    final dropboxService = DropboxService();
    final cloudinaryService = CloudinaryService();

    final List<String> operacionesExitosas = [];

    for (var operacion in List.from(operaciones)) {
      try {
        // Subir imagen firma si existe y no es null
        if (operacion['data'] != null &&
            operacion['data']['firma'] != null &&
            (operacion['accion'] == 'registrar' ||
                operacion['accion'] == 'editar')) {
          String localFilePath = operacion['data']['firma'];

          if (localFilePath.isNotEmpty) {
            // Subir a Dropbox
            String? sharedLink = await dropboxService.uploadImageToDropbox(
                localFilePath, "usuarios");
            // Subir a Cloudinary
            String? sharedLinkCloud = await cloudinaryService
                .subirArchivoCloudinary(localFilePath, "clientes");

            if (sharedLink != null) {
              operacion['data']['firma'] = sharedLink;
            }
            if (sharedLinkCloud != null) {
              operacion['data']['firmaCloudinary'] = sharedLinkCloud;
            }
          }
        }

        if (operacion['accion'] == 'registrar') {
          final response =
              await usuariosService.registraUsuarios(operacion['data']);

          if (response['status'] == 200 && response['data'] != null) {
            final usuariosBox = Hive.box('usuariosBox');
            final actualesRaw = usuariosBox.get('usuarios', defaultValue: []);

            final actuales = (actualesRaw as List)
                .map<Map<String, dynamic>>(
                    (item) => Map<String, dynamic>.from(item))
                .toList();

            actuales.removeWhere((element) => element['id'] == operacion['id']);

            actuales.add({
              'id': response['data']['_id'],
              'nombre': response['data']['nombre'],
              'email': response['data']['email'],
              'telefono': response['data']['telefono'],
              'password': response['data']['password'],
              'tipo': response['data']['tipo'],
              'firma': response['data']['firma'],
              'firmaCloudinary': response['data']['firmaCloudinary'],
              'estado': "true",
            });

            await usuariosBox.put('usuarios', actuales);
          }

          operacionesExitosas.add(operacion['operacionId']);
        } else if (operacion['accion'] == 'editar') {
          final response = await usuariosService.actualizarUsuario(
              operacion['id'], operacion['data']);

          if (response['status'] == 200) {
            final usuariosBox = Hive.box('usuariosBox');
            final actualesRaw = usuariosBox.get('usuarios', defaultValue: []);

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
                'updatedAt': DateTime.now().toString(),
              };
              await usuariosBox.put('usuarios', actuales);
            }
          }

          operacionesExitosas.add(operacion['operacionId']);
        } else if (operacion['accion'] == 'eliminar') {
          final response = await usuariosService.actualizaDeshabilitarUsuario(
              operacion['id'], {'estado': 'false'});

          if (response['status'] == 200) {
            final usuariosBox = Hive.box('usuariosBox');
            final actualesRaw = usuariosBox.get('usuarios', defaultValue: []);

            final actuales = (actualesRaw as List)
                .map<Map<String, dynamic>>(
                    (item) => Map<String, dynamic>.from(item))
                .toList();

            final index = actuales
                .indexWhere((element) => element['id'] == operacion['id']);
            if (index != -1) {
              actuales[index] = {
                ...actuales[index],
                'estado': 'false',
                'updatedAt': DateTime.now().toString(),
              };
              await usuariosBox.put('usuarios', actuales);
            }
          }

          operacionesExitosas.add(operacion['operacionId']);
        }
      } catch (e) {
        debugPrint('Error sincronizando operación: $e');
      }
    }

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
      final List<dynamic> dataAPI = await usuariosService.listarUsuarios();

      final formateadas = dataAPI
          .map<Map<String, dynamic>>((item) => {
                'id': item['_id'],
                'nombre': item['nombre'],
                'email': item['email'],
                'telefono': item['telefono'],
                'tipo': item['tipo'],
                'createdAt': item['createdAt'],
                'updatedAt': item['updatedAt'],
              })
          .toList();

      final usuariosBox = Hive.box('usuariosBox');
      await usuariosBox.put('usuarios', formateadas);
    } catch (e) {
      debugPrint('Error actualizando datos después de sincronización: $e');
    }
  }

  void _guardarUsuario(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

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

    if (!conectado) {
      final box = Hive.box('operacionesOfflineUsuarios');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'registrar',
        'id': null,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final usuariosBox = Hive.box('usuariosBox');
      final actualesRaw = usuariosBox.get('usuarios', defaultValue: []);

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
      await usuariosBox.put('usuarios', actuales);

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
              "Usuario guardado localmente y se sincronizará cuando haya internet",
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final usuariosService = UsuariosService();
      var response = await usuariosService.registraUsuarios(dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        logsInformativos(
            "Se ha registrado el usuario ${data['nombre']} correctamente", {});
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Registro exitoso",
            message: "El usuario fue agregado correctamente",
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
            message: "No se pudo guardar el usuario",
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

  void _editarUsuario(String id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'nombre': data['nombre'],
    };

    if (!conectado) {
      final box = Hive.box('operacionesOfflineUsuarios');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'editar',
        'id': id,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final usuariosBox = Hive.box('usuariosBox');
      final actualesRaw = usuariosBox.get('usuarios', defaultValue: []);

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
        await usuariosBox.put('usuarios', actuales);
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
              "Usuario actualizado localmente y se sincronizará cuando haya internet",
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final usuariosService = UsuariosService();
      var response = await usuariosService.actualizarUsuario(id, dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        logsInformativos(
            "Se ha actualizado el usuario ${data['nombre']} correctamente", {});
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Actualización exitosa",
            message: "Los datos del usuario fueron actualizados correctamente",
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

  void _eliminarUsuario(String id, data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {'estado': "false"};

    if (!conectado) {
      final box = Hive.box('operacionesOfflineUsuarios');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': 'eliminar',
        'id': id,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      final usuariosBox = Hive.box('usuariosBox');
      final actualesRaw = usuariosBox.get('usuarios', defaultValue: []);

      final actuales = (actualesRaw as List)
          .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final index = actuales.indexWhere((element) => element['id'] == id);
      if (index != -1) {
        actuales[index] = {
          ...actuales[index],
          'estado': 'false',
          'updatedAt': DateTime.now().toString(),
        };
        await usuariosBox.put('usuarios', actuales);
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
              "Usuario eliminado localmente y se sincronizará cuando haya internet",
          backgroundColor: Colors.orange,
        );
      }
      return;
    }

    try {
      final usuariosService = UsuariosService();
      var response =
          await usuariosService.actualizaDeshabilitarUsuario(id, dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
        });
        widget.onCompleted();
        widget.showModal();
        logsInformativos(
            "Se ha eliminado el usuario ${data['id']} correctamente", {});
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Eliminación exitosa",
            message: "Se han eliminado correctamente los datos del usuario",
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
          String? sharedLink2 = await cloudinaryService.subirArchivoCloudinary(
              imagenFile, "clientes");
          if (sharedLink != null) {
            linkFirma = sharedLink; // Guardar el enlace de la firma
          }
          if (sharedLink2 != null) {
            linkFirmaCloudinary = sharedLink2; // Guardar el enlace de la firma
          }
        } else {
          debugPrint('No se pudo guardar la imagen de la firma correctamente');
        }
      } else {
        debugPrint('La imagen de firma es nula');
      }

      // Desactivamos la animación de carga después de que todas las imágenes se hayan subido
      setState(() {
        _isLoading = false; // Desactivar la animación de carga
      });
    }

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
      appBar: const Header(),
      drawer: MenuLateral(currentPage: "Usuarios"), // Usa el menú lateral
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
                        style: const TextStyle(
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
                          decoration:
                              const InputDecoration(labelText: 'Nombre'),
                          enabled: !isEliminar && !_isLoading,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'El nombre es obligatorio'
                                  : null,
                        ),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
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
                          decoration:
                              const InputDecoration(labelText: 'Teléfono'),
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
                          decoration:
                              const InputDecoration(labelText: 'Contraseña'),
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
                        DropdownSearch<String>(
                          key: const Key('rolDropdown'),
                          enabled: !isEliminar &&
                              !_isLoading, // Deshabilitado si corresponde
                          items: (filter, _) {
                            // Lista de roles filtrada por búsqueda
                            final roles = [
                              {'value': '', 'label': 'Selecciona una opción'},
                              {
                                'value': 'administrador',
                                'label': 'Administrador'
                              },
                              {'value': 'inspector', 'label': 'Tecnico'},
                            ];

                            return roles
                                .where((r) => r['label']!
                                    .toLowerCase()
                                    .contains(filter.toLowerCase()))
                                .map((r) => r['value']!)
                                .toList();
                          },
                          selectedItem: _rolController.text.isEmpty
                              ? null
                              : _rolController.text,
                          onChanged: !isEliminar && !_isLoading
                              ? (String? newValue) {
                                  setState(() {
                                    _rolController.text = newValue ?? '';
                                  });
                                }
                              : null,
                          dropdownBuilder: (context, selectedItem) {
                            final roles = [
                              {'value': '', 'label': 'Selecciona una opción'},
                              {
                                'value': 'administrador',
                                'label': 'Administrador'
                              },
                              {'value': 'inspector', 'label': 'Tecnico'},
                            ];

                            final rol = roles.firstWhere(
                                (r) => r['value'] == selectedItem,
                                orElse: () => {'label': ''});
                            return Text(
                              rol['label'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: selectedItem == ''
                                      ? Colors.grey
                                      : Colors.black),
                            );
                          },
                          decoratorProps: DropDownDecoratorProps(
                            decoration: InputDecoration(
                              labelText: 'Rol',
                              border: UnderlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            fit: FlexFit.loose,
                            constraints: BoxConstraints(maxHeight: 300),
                          ),
                          validator: !isEliminar && !_isLoading
                              ? (value) => value == null || value.isEmpty
                                  ? 'Por favor selecciona un rol'
                                  : null
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
                              PremiumActionButton(
                                onPressed: _controller.clear,
                                label: "Limpiar",
                                icon: Icons.cleaning_services,
                                style: PremiumButtonStyle.secondary,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                        ],
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PremiumActionButton(
                              onPressed: closeRegistroModal,
                              label: 'Cancelar',
                              icon: Icons.close,
                              style: PremiumButtonStyle.secondary,
                            ),
                            const SizedBox(width: 20),
                            PremiumActionButton(
                              onPressed: _onSubmit,
                              label: buttonLabel,
                              icon: isEliminar
                                  ? FontAwesomeIcons.trash
                                  : (isEditar
                                      ? FontAwesomeIcons.penToSquare
                                      : FontAwesomeIcons.floppyDisk),
                              isLoading: _isLoading,
                              style: isEliminar
                                  ? PremiumButtonStyle.danger
                                  : PremiumButtonStyle.primary,
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
