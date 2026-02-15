import 'package:flutter/material.dart';
import '../../api/frecuencias.dart';
import '../../api/clasificaciones.dart';
import '../../api/ramas.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../CrearEncuestaPantalla1/crear_encuesta_pantalla_1.dart';
import '../../components/Generales/pregunta.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../components/Generales/flushbar_helper.dart';
import '../../components/Logs/logs_informativos.dart';
import '../../api/encuesta_inspeccion.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CrearEncuestaScreen extends StatefulWidget {
  final VoidCallback showModal;
  final String accion;
  final dynamic data;
  final TextEditingController nombreController;
  final TextEditingController clasificacionController;
  final TextEditingController ramaController;
  final Function onCompleted;
  final List<Pregunta> preguntas;
  final dynamic frecuencia;

  @override
  const CrearEncuestaScreen({
    super.key,
    required this.showModal,
    required this.accion,
    required this.data,
    required this.nombreController,
    required this.clasificacionController,
    required this.ramaController,
    required this.onCompleted,
    required this.preguntas,
    required this.frecuencia,
  });

  @override
  State<CrearEncuestaScreen> createState() => _CrearEncuestaScreenState();
}

class _CrearEncuestaScreenState extends State<CrearEncuestaScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController preguntaController = TextEditingController();
  TextEditingController categoriaController = TextEditingController();
  TextEditingController nombreController = TextEditingController();
  TextEditingController frecuenciaController = TextEditingController();
  TextEditingController ramaController = TextEditingController();
  TextEditingController clasificacionController = TextEditingController();
  List<String> opcionesTemp = ["Si", "No"];
  List<String> opcionesTemp2 = ["No aplica"];
  String? opcionSeleccionada; // Esta es la opción seleccionada temporalmente

  List<Map<String, dynamic>> dataFrecuencias = [];
  List<Map<String, dynamic>> dataClasificaciones = [];
  List<Map<String, dynamic>> dataRamas = [];
  bool loading = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getFrecuencias();
    cargarClasificaciones();
    cargarRamas();

    sincronizarOperacionesPendientes();

    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> event) {
      if (event.any((result) => result != ConnectivityResult.none)) {
        sincronizarOperacionesPendientes();
      }
    });
  }

  Future<void> sincronizarOperacionesPendientes() async {
    final conectado = await verificarConexion();
    if (!conectado) return;

    final box = Hive.box('operacionesOfflineEncuestas');
    final operacionesRaw = box.get('operaciones', defaultValue: []);

    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    if (operaciones.isEmpty) return;

    final encuestasService = EncuestaInspeccionService();
    final List<String> operacionesEliminar = [];

    for (var operacion in operaciones) {
      // Inicializar / Incrementar intentos
      operacion['intentos'] = (operacion['intentos'] ?? 0) + 1;

      try {
        Map<String, dynamic>? response;
        if (operacion['accion'] == 'registrar') {
          response = await encuestasService
              .registraEncuestaInspeccion(operacion['data']);
        } else if (operacion['accion'] == 'editar') {
          response = await encuestasService.actualizarEncuestaInspeccion(
              operacion['id'], operacion['data']);
        } else if (operacion['accion'] == 'eliminar') {
          response = await encuestasService.deshabilitarEncuestaInspeccion(
              operacion['id'], {'estado': 'false'});
        }

        if (response != null) {
          final status = response['status'];
          if (status == 200) {
            // Éxito: Actualizar Hive local si es necesario (ya tiene lógica para registrar/editar/eliminar)
            if (operacion['accion'] == 'registrar' &&
                response['data'] != null) {
              final encuestasBox = Hive.box('encuestasBox');
              final actualesRaw =
                  encuestasBox.get('encuestas', defaultValue: []);
              final actuales = (actualesRaw as List)
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();

              actuales
                  .removeWhere((element) => element['id'] == operacion['id']);
              actuales.add({
                'id': response['data']['_id'],
                'nombre': response['data']['nombre'],
                'descripcion': response['data']['descripcion'],
                'estado': response['data']['estado'],
                'createdAt': response['data']['createdAt'],
                'updatedAt': response['data']['updatedAt'],
              });
              await encuestasBox.put('encuestas', actuales);
            } else if (operacion['accion'] == 'editar' ||
                operacion['accion'] == 'eliminar') {
              // Lógica similar para actualizar cache local si es necesario
              // Pero la lógica actual ya lo hacía... simplificando:
              final encuestasBox = Hive.box('encuestasBox');
              final actualesRaw =
                  encuestasBox.get('encuestas', defaultValue: []);
              final actuales = (actualesRaw as List)
                  .map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item))
                  .toList();
              final index = actuales
                  .indexWhere((element) => element['id'] == operacion['id']);
              if (index != -1) {
                if (operacion['accion'] == 'editar') {
                  actuales[index] = {
                    ...actuales[index],
                    ...operacion['data'],
                    'updatedAt': DateTime.now().toString()
                  };
                } else {
                  actuales[index] = {
                    ...actuales[index],
                    'estado': 'false',
                    'updatedAt': DateTime.now().toString()
                  };
                }
                await encuestasBox.put('encuestas', actuales);
              }
            }
            operacionesEliminar.add(operacion['operacionId'] ?? "");
          } else if (status >= 400 && status < 500) {
            debugPrint(
                "Error no reintentable (4xx) en sincronización: $status");
            operacionesEliminar.add(operacion['operacionId'] ?? "");
          } else {
            debugPrint("Error de servidor (5xx) en sincronización: $status");
            if (operacion['intentos'] >= 5) {
              debugPrint("Límite de reintentos alcanzado para operación");
              operacionesEliminar.add(operacion['operacionId'] ?? "");
            }
          }
        }
      } catch (e) {
        debugPrint('Error de red sincronizando operación: $e');
        if (operacion['intentos'] >= 5) {
          debugPrint("Límite de reintentos alcanzado por red");
          operacionesEliminar.add(operacion['operacionId'] ?? "");
        }
      }
    }

    // Actualizar el box de Hive eliminando las exitosas o fallidas permanentes
    final nuevasOperaciones = operaciones
        .where((op) => !operacionesEliminar.contains(op['operacionId']))
        .toList();
    await box.put('operaciones', nuevasOperaciones);

    if (operacionesEliminar.length == operaciones.length) {
      debugPrint("✔ Sincronización finalizada.");
    } else {
      debugPrint(
          "❗ Quedan ${operaciones.length - operacionesEliminar.length} operaciones pendientes.");
    }

    // ✅ Actualizar lista completa desde API
    try {
      final List<dynamic> dataAPI =
          await encuestasService.listarEncuestaInspeccion();

      final formateadas = dataAPI
          .map<Map<String, dynamic>>((item) => {
                'id': item['_id'],
                'nombre': item['nombre'],
                'idFrecuencia': item['idFrecuencia'],
                'idClasificacion': item['idClasificacion'],
                'idRama': item['idRama'],
                'frecuencia': item['frecuencia']['nombre'],
                'clasificacion': item['clasificacion']['nombre'],
                'rama': item['rama']['nombre'],
                'preguntas': item['preguntas'],
                'estado': item['estado'],
                'createdAt': item['createdAt'],
                'updatedAt': item['updatedAt'],
              })
          .toList();

      final encuestasBox = Hive.box('encuestasBox');
      await encuestasBox.put('encuestas', formateadas);
    } catch (e) {
      debugPrint('Error actualizando datos después de sincronización: $e');
    }
  }

  Future<void> cargarClasificaciones() async {
    final conectado = await verificarConexion();
    if (conectado) {
      debugPrint("Conectado a internet");
      await getClasificacionesDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando desde Hive...");
      await getClasificacionesDesdeHive();
    }
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
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
      debugPrint("Error al obtener las clasificaciones: $e");
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

  Future<void> getFrecuencias() async {
    final conectado = await verificarConexion();

    if (conectado) {
      await getFrecuenciasDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando desde Hive...");
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
      debugPrint("Error al obtener las frecuencias: $e");
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
      debugPrint("Error leyendo desde Hive: $e");
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

  Future<void> cargarRamas() async {
    try {
      final conectado = await verificarConexion();
      if (conectado) {
        await getRamasDesdeAPI();
      } else {
        await getRamasDesdeHive();
      }
    } catch (e) {
      debugPrint("Error general al cargar ramas: $e");
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

  void _agregarPregunta() {
    if (preguntaController.text.isNotEmpty && opcionSeleccionada != null) {
      setState(() {
        widget.preguntas.add(Pregunta(
          titulo: preguntaController.text,
          categoria: "Default",
          opciones:
              opcionSeleccionada == "Sí/No" ? opcionesTemp : opcionesTemp2,
        ));
        preguntaController.clear();
        opcionSeleccionada = null;
      });
    }
  }

  void _eliminarPregunta(int index) {
    setState(() {
      widget.preguntas.removeAt(index);
    });
  }

  void _guardarEncuesta(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final conectado = await verificarConexion();

    var dataTemp = {
      'nombre': data['nombre'],
      'idFrecuencia': data['idFrecuencia'],
      'idRama': data['idRama'],
      'idClasificacion': data['idClasificacion'],
      'preguntas': data['preguntas'],
      'estado': "true",
    };

    if (!conectado) {
      // Guardar localmente la operación pendiente
      final box = Hive.box('operacionesOfflineEncuestas');
      final operaciones = box.get('operaciones', defaultValue: []);
      operaciones.add({
        'accion': widget.accion, // "registrar" o "editar"
        'id': widget.accion == "editar" ? widget.data["id"] : null,
        'data': dataTemp,
      });
      await box.put('operaciones', operaciones);

      // Guardar la encuesta localmente
      final encuestasBox = Hive.box('encuestasBox');
      final actualesRaw = encuestasBox.get('encuestas', defaultValue: []);
      final actuales = (actualesRaw as List)
          .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map))
          .toList();

      if (widget.accion == "editar") {
        // Actualizar localmente la encuesta con id que se tiene
        final index = actuales
            .indexWhere((element) => element['id'] == widget.data["id"]);
        if (index != -1) {
          actuales[index] = {
            'id': widget.data["id"],
            ...dataTemp,
            'updatedAt': DateTime.now().toIso8601String(),
          };
        } else {
          // Si no la encuentra, la agrega como nueva con id temporal
          actuales.add({
            'id': widget.data["id"] ?? DateTime.now().toIso8601String(),
            ...dataTemp,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      } else {
        // Si es registrar, agregar con id temporal
        actuales.add({
          'id': DateTime.now().toIso8601String(),
          ...dataTemp,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      await encuestasBox.put('encuestas', actuales);

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
            "Encuesta guardada localmente y se sincronizará cuando haya internet",
        backgroundColor: Colors.orange,
      );
      }

      return;
    }

    // Si hay conexión, hacer llamada al servicio normalmente
    try {
      final encuestaInspeccionService = EncuestaInspeccionService();
      Map<String, dynamic> response = {};
      if (widget.accion == "registrar") {
        response = await encuestaInspeccionService
            .registraEncuestaInspeccion(dataTemp);
      } else if (widget.accion == "editar") {
        response = await encuestaInspeccionService.actualizarEncuestaInspeccion(
            widget.data["id"], dataTemp);
      }

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          returnPrincipalPage();
        });
        logsInformativos(
            "Se ha registrado la encuesta ${data['nombre']} correctamente",
            dataTemp);
        if (mounted) {
          showCustomFlushbar(
          context: context,
          title: "Registro exitoso",
          message: "La encuesta fue agregada correctamente",
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
          title: "Hubo un problema",
          message: "Hubo un error al agregar la encuesta",
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

  void _publicarEncuesta() {
    var formData = {
      "nombre": widget.nombreController.text,
      "idFrecuencia": widget.frecuencia["id"],
      "idClasificacion": widget.clasificacionController.text,
      "idRama": widget.ramaController.text,
      "preguntas":
          widget.preguntas.map((pregunta) => pregunta.toJson()).toList(),
    };
    if (widget.accion == "registrar") {
      _guardarEncuesta(formData);
    } else if (widget.accion == "editar") {
      _guardarEncuesta(formData);
    }
    // Aquí podrías enviar la encuesta a Firebase o una API
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
      MaterialPageRoute(
          builder: (context) => CrearEncuestaPantalla1Screen(
              showModal: widget.showModal,
              //final Function onCompleted;
              accion: widget.accion,
              data: widget.data,
              nombreController: widget.nombreController,
              ramaController: widget.ramaController,
              clasificacionController: widget.clasificacionController,
              onCompleted: widget.onCompleted)),
    ).then((_) {
      // Actualizar encuestas al regresar de la página
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _formKey,
      appBar: Header(), // Usa el header con menú de usuario
      drawer:
          MenuLateral(currentPage: "Crear actividad"), // Usa el menú lateral
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
                          "Crear actividad",
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _publicarEncuesta,
                          icon: Icon(FontAwesomeIcons.plus),
                          label: _isLoading
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SpinKitFadingCircle(
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text("Cargando..."),
                                  ],
                                )
                              : Text(buttonLabel),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Sección de Preguntas
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Botón de "Agregar Pregunta" centrado en la parte superior de la Card
                            Center(
                              child: ElevatedButton(
                                onPressed: _agregarPregunta,
                                child: Text("Agregar Pregunta"),
                              ),
                            ),
                            SizedBox(height: 20), // Espacio debajo del botón
                            Text("Preguntas",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            TextField(
                              controller: preguntaController,
                              decoration:
                                  InputDecoration(labelText: "Pregunta"),
                            ),
                            SizedBox(height: 10),
// Combo para seleccionar entre Sí, No, No aplica
                            DropdownSearch<String>(
                              key: Key('opcionDropdown'),
                              items: (filter, _) {
                                final opciones = ["Sí/No", "No aplica"];
                                return opciones
                                    .where((o) => o
                                        .toLowerCase()
                                        .contains(filter.toLowerCase()))
                                    .toList();
                              },
                              selectedItem: opcionSeleccionada,
                              onChanged: (String? newValue) {
                                setState(() {
                                  opcionSeleccionada = newValue;
                                });
                              },
                              dropdownBuilder: (context, selectedItem) => Text(
                                selectedItem ?? "",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: selectedItem == null
                                        ? Colors.grey
                                        : Colors.black),
                              ),
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: 'Opción',
                                  border: UnderlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                ),
                              ),
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'La opcion es obligatoria'
                                      : null,
                            ),

                            SizedBox(height: 10),

                            SizedBox(height: 10),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: widget.preguntas.length,
                              itemBuilder: (context, index) {
                                // Verificar si la categoría coincide antes de crear el widget
                                if (widget.preguntas[index].categoria !=
                                    "Default") {
                                  return SizedBox.shrink();
                                }
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 5),
                                  child: ListTile(
                                    title: Text(widget.preguntas[index].titulo),
                                    subtitle: Text(
                                      "Categoría: ${widget.preguntas[index].categoria}\n"
                                      "Opciones: ${widget.preguntas[index].opciones.join(", ")}",
                                    ),
                                    trailing: IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminarPregunta(index),
                                    ),
                                  ),
                                );
                              },
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


