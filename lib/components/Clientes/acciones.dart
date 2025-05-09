import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../api/clientes.dart';
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

    if (widget.accion == 'editar' || widget.accion == 'eliminar') {
      _nombreController.text = widget.data['nombre'] ?? '';
      _imagenController.text = widget.data['imagen'] ?? '';
      _imagenCloudinaryController.text = widget.data['imagenCloudinary'] ?? '';
      _correoController.text = widget.data['correo'] ?? '';
      _telefonoController.text = widget.data['telefono'] ?? '';
      _calleController.text = widget.data['calle'] ?? '';
      _nExteriorController.text = widget.data['nExterior'] ?? '';
      _nInteriorController.text = widget.data['nInterior'] ?? '';
      _coloniaController.text = widget.data['colonia'] ?? '';
      _estadoDomController.text = widget.data['estadoDom'] ?? '';
      _municipioController.text = widget.data['municipio'] ?? '';
      _cpostalController.text = widget.data['cPostal'] ?? '';
      _referenciaController.text = widget.data['referencia'] ?? '';
      _responsableController.text = widget.data['responsable'] ?? '';
      _puestoController.text = widget.data['puesto'] ?? '';
      imageUrl = widget.data['imagen'].replaceAll('dl=0', 'raw=1');
    }
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
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

  // Corregimos la función para que acepte un parámetro bool
  void closeRegistroModal() {
    widget.showModal(); // Llama a setShow con el valor booleano
    widget.onCompleted();
  }

  void _guardarCliente(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

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

    try {
      final clientesService = ClientesService();
      var response = await clientesService.registrarClientes(dataTemp);
      // Verifica el statusCode correctamente, según cómo esté estructurada la respuesta
      if (response['status'] == 200) {
        // Asumiendo que 'response' es un Map que contiene el código de estado
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha registrado eñ cliente ${data['nombre']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "El cliente fue agregado correctamente",
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
          message: "Hubo un error al agregar la clasificacion",
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

  void _editarCliente(String id, Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

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

    try {
      final clientesService = ClientesService();
      var response = await clientesService.actualizarClientes(id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha modificado la cliente ${data['nombre']} correctamente",
            dataTemp);
        showCustomFlushbar(
          context: context,
          title: "Actualizacion exitosa",
          message: "Los datos del cliente fueron actualizados correctamente",
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

  void _eliminarCliente(String id, data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {'estado': "false"};

    try {
      final clientesService = ClientesService();
      var response = await clientesService.deshabilitarClientes(id, dataTemp);
      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          closeRegistroModal();
        });
        LogsInformativos(
            "Se ha eliminado la cliente ${data['nombre']} correctamente", {});
        showCustomFlushbar(
          context: context,
          title: "Eliminacion exitosa",
          message: "Se han eliminado correctamente los datos del cliente",
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
          print('No se pudo guardar el logo del cliente de forma correcta');
        }
      } else {
        print('El logo del cliente es nulo');
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
        _editarCliente(widget.data['id'], formData);
      } else if (widget.accion == 'eliminar') {
        _eliminarCliente(widget.data['id'], formData);
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
    } else if (widget.accion == 'editar') {
      return 'Actualizar';
    } else {
      return 'Eliminar';
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
                          Text(
                            "Logo de la empresa",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap:
                                _pickImage, // Al hacer tap, se activa el selector de imágenes
                            child: Container(
                              width: double.infinity,
                              height: 250,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _image == null && imageUrl == null
                                  ? Center(
                                      child: Icon(
                                        Icons.cloud_upload,
                                        size: 50,
                                        color: Colors.blueAccent,
                                      ),
                                    )
                                  : (_image != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.file(
                                            File(_image!.path),
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.network(
                                            imageUrl!,
                                            fit: BoxFit.cover,
                                          ),
                                        )),
                            ),
                          ),
                          SizedBox(height: 10),
                          if (_image != null || imageUrl != null)
                            Text(
                              "Imagen seleccionada",
                              style:
                                  TextStyle(color: Colors.green, fontSize: 16),
                            ),
                          if (_image == null || imageUrl == null)
                            Text(
                              "Selecciona una imagen",
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                        ],
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(labelText: 'Nombre'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'El nombre es obligatorio'
                                  : null,
                        ),
                        TextFormField(
                          controller: _correoController,
                          decoration: InputDecoration(labelText: 'Email'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El email es obligatorio';
                                  }
                                  // Expresión regular para validar email
                                  final emailRegex = RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Ingrese un email válido';
                                  }
                                  return null;
                                },
                        ),
                        TextFormField(
                          controller: _telefonoController,
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            hintText: 'Ingresa solo números (máx. 10)',
                          ),
                          enabled: !isEliminar,
                          keyboardType: TextInputType
                              .phone, // Para mostrar el teclado numérico
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly, // Permite solo números
                            LengthLimitingTextInputFormatter(
                                10), // Limita a 10 caracteres
                          ],
                          validator: isEliminar
                              ? null
                              : (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El teléfono es obligatorio';
                                  }
                                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                                    return 'Debe contener exactamente 10 dígitos';
                                  }
                                  return null;
                                },
                        ),
                        TextFormField(
                          controller: _calleController,
                          decoration: InputDecoration(labelText: 'Calle'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'La calle es obligatoria'
                                  : null,
                        ),
                        TextFormField(
                          controller: _nExteriorController,
                          decoration: InputDecoration(
                            labelText: 'Número exterior',
                          ),
                          keyboardType: TextInputType
                              .number, // Solo permite números en el teclado
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly, // Solo números
                          ],
                          enabled: !isEliminar,
                        ),
                        TextFormField(
                          controller: _nInteriorController,
                          decoration: InputDecoration(
                            labelText: 'Número interior',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          enabled: !isEliminar,
                        ),
                        TextFormField(
                          controller: _coloniaController,
                          decoration: InputDecoration(labelText: 'Colonia'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'La colonia es obligatoria'
                                  : null,
                        ),
                        DropdownButtonFormField<String>(
                          value: _estadoDomController.text.isEmpty
                              ? null
                              : _estadoDomController.text,
                          decoration: InputDecoration(labelText: 'Estado'),
                          isExpanded: true,
                          items: _estadosFuture.map((estado) {
                            return DropdownMenuItem<String>(
                              value: estado['nombre'],
                              child: Text(estado[
                                  'nombre']), // Muestra el nombre en el select
                            );
                          }).toList(),
                          onChanged: isEliminar
                              ? null
                              : (newValue) {
                                  setState(() {
                                    _estadoDomController.text =
                                        newValue!; // Actualiza el estado
                                    _municipioController.text =
                                        ''; // Limpia el municipio cuando cambia el estado
                                  });
                                },
                          validator: isEliminar
                              ? null
                              : (value) => value == null || value.isEmpty
                                  ? 'El estado es obligatorio'
                                  : null,
                        ),
                        // Dropdown para seleccionar Municipio
                        DropdownButtonFormField<String>(
                          isExpanded: true, // Expande el menú
                          value: _municipioController.text.isNotEmpty
                              ? _municipioController.text
                              : null,
                          decoration: InputDecoration(labelText: 'Municipio'),
                          items: (_estadoDomController.text.isNotEmpty &&
                                  _municipiosMap
                                      .containsKey(_estadoDomController.text))
                              ? _municipiosMap[_estadoDomController.text]!
                                  .map((municipio) {
                                  return DropdownMenuItem<String>(
                                    value: municipio,
                                    child: Text(municipio),
                                  );
                                }).toList()
                              : [],
                          onChanged: isEliminar
                              ? null
                              : (newValue) {
                                  setState(() {
                                    _municipioController.text =
                                        newValue!; // Actualiza el municipio seleccionado
                                  });
                                },
                          validator: isEliminar
                              ? null
                              : (value) => value == null || value.isEmpty
                                  ? 'El municipio es obligatorio'
                                  : null,
                        ),
                        TextFormField(
                          controller: _cpostalController,
                          decoration: InputDecoration(
                            labelText: 'Código postal',
                          ),
                          keyboardType: TextInputType
                              .number, // Solo permite números en el teclado
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly, // Solo números
                            LengthLimitingTextInputFormatter(
                                5), // Máximo 5 caracteres
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
                        TextFormField(
                          controller: _referenciaController,
                          decoration: InputDecoration(labelText: 'Referencia'),
                          enabled: !isEliminar,
                          validator: isEliminar
                              ? null
                              : (value) => value?.isEmpty ?? true
                                  ? 'La referencia es obligatoria'
                                  : null,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed:
                                  closeRegistroModal, // Cierra el modal pasando false
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
