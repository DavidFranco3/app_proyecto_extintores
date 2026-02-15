import 'package:flutter/material.dart';
import '../../api/frecuencias.dart';
import '../../api/clasificaciones.dart';
import '../../api/ramas.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../Encuestas/encuestas.dart';
import '../CrearEncuesta/crear_encuesta.dart';
import '../../components/Generales/pregunta.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CrearEncuestaPantalla1Screen extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;
  final TextEditingController nombreController;
  final TextEditingController clasificacionController;
  final TextEditingController ramaController;

  @override
  const CrearEncuestaPantalla1Screen(
      {super.key, required this.showModal,
      required this.onCompleted,
      required this.accion,
      required this.data,
      required this.nombreController,
      required this.clasificacionController,
      required this.ramaController});

  @override
  State<CrearEncuestaPantalla1Screen> createState() =>
      _CrearEncuestaPantalla1ScreenState();
}

class _CrearEncuestaPantalla1ScreenState
    extends State<CrearEncuestaPantalla1Screen> {
  final _formKey = GlobalKey<FormState>();
  List<Pregunta> preguntas = [];
  TextEditingController frecuenciaController = TextEditingController();
  List<String> opcionesTemp = ["Si", "No"];
  List<Map<String, dynamic>> dataFrecuencias = [];
  List<Map<String, dynamic>> dataClasificaciones = [];
  List<Map<String, dynamic>> dataRamas = [];
  bool loading = true;
  final bool _isLoading = false;
  final List<Map<String, String>> secciones = [];

  @override
  void initState() {
    super.initState();
    getFrecuencias();
    cargarClasificaciones();
    cargarRamas();

    if (widget.accion == 'editar') {
      widget.nombreController.text = widget.data['nombre'] ?? '';
      widget.clasificacionController.text =
          widget.data['idClasificacion'] ?? '';
      widget.ramaController.text = widget.data['idRama'] ?? '';
      frecuenciaController.text = widget.data['idFrecuencia'] ?? '';
      debugPrint(widget.data['preguntas']);
      preguntas = (widget.data["preguntas"] as List<dynamic>?)?.map((item) {
            final map = item as Map<String, dynamic>;
            return Pregunta(
              titulo: map['titulo'] ?? '',
              categoria: map['categoria'] ?? '',
              opciones: List<String>.from(map['opciones'] ?? []),
            );
          }).toList() ??
          [];
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

  void returnPrincipalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EncuestasPage()),
    ).then((_) {
      // Actualizar encuestas al regresar de la página
    });
  }

  // Función para abrir el modal de registro con el formulario de Acciones
  void openPantalla2Page(Map<String, dynamic> row) {
    // Primero validamos el formulario
    if (_formKey.currentState?.validate() ?? false) {
      // Si la validación es exitosa, navegamos a la siguiente pantalla
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CrearEncuestaScreen(
              showModal: () {
                if (mounted) Navigator.pop(context); // Esto cierra el modal
              },
              accion: widget.accion,
              data: widget.data,
              nombreController: widget.nombreController,
              ramaController: widget.ramaController,
              clasificacionController: widget.clasificacionController,
              preguntas: preguntas,
              onCompleted: widget.onCompleted,
              frecuencia: row),
        ),
      ).then((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //key: _formKey,
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Crear actividad"),
      body: loading
          ? Load()
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: returnPrincipalPage,
                          icon: Icon(FontAwesomeIcons.arrowLeft),
                          label: _isLoading
                              ? SpinKitFadingCircle(
                                  color: const Color.fromARGB(255, 241, 8, 8),
                                  size: 24,
                                )
                              : Text("Regresar"),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey, // Asigna el GlobalKey<FormState> aquí
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: widget.nombreController,
                                decoration:
                                    InputDecoration(labelText: "Nombre"),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El nombre es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                              // Dropdown de Tipo de Sistema (Rama)
                              // Dropdown de Rama
                              DropdownSearch<String>(
                                key: Key('ramaDropdown'),
                                enabled: dataRamas.isNotEmpty,
                                items: (filter, _) {
                                  return dataRamas
                                      .where((tipo) => tipo['nombre']
                                          .toString()
                                          .toLowerCase()
                                          .contains(filter.toLowerCase()))
                                      .map((tipo) => tipo['nombre']
                                          .toString()) // ✅ valor = nombre
                                      .toList();
                                },
                                selectedItem: widget.ramaController.text.isEmpty
                                    ? null
                                    : widget.ramaController.text,
                                onChanged: dataRamas.isEmpty
                                    ? null
                                    : (String? newValue) {
                                        setState(() {
                                          widget.ramaController.text =
                                              newValue!;
                                        });
                                      },
                                dropdownBuilder: (context, selectedItem) =>
                                    Text(
                                  selectedItem ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: selectedItem == null
                                          ? Colors.grey
                                          : Colors.black),
                                ),
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: 'Tipo de Sistema',
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
                                validator: dataRamas.isEmpty
                                    ? null
                                    : (value) => value == null || value.isEmpty
                                        ? 'La rama es obligatoria'
                                        : null,
                              ),

// Dropdown de Clasificación
                              DropdownSearch<String>(
                                key: Key('clasificacionDropdown'),
                                enabled: dataClasificaciones.isNotEmpty,
                                items: (filter, _) {
                                  return dataClasificaciones
                                      .where((tipo) => tipo['nombre']
                                          .toString()
                                          .toLowerCase()
                                          .contains(filter.toLowerCase()))
                                      .map((tipo) => tipo['nombre']
                                          .toString()) // ✅ valor = nombre
                                      .toList();
                                },
                                selectedItem:
                                    widget.clasificacionController.text.isEmpty
                                        ? null
                                        : widget.clasificacionController.text,
                                onChanged: dataClasificaciones.isEmpty
                                    ? null
                                    : (String? newValue) {
                                        setState(() {
                                          widget.clasificacionController.text =
                                              newValue!;
                                        });
                                      },
                                dropdownBuilder: (context, selectedItem) =>
                                    Text(
                                  selectedItem ??
                                      '',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: selectedItem == null
                                          ? Colors.grey
                                          : Colors.black),
                                ),
                                decoratorProps: DropDownDecoratorProps(
                                  decoration: InputDecoration(
                                    labelText: 'Clasificación',
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
                                validator: dataClasificaciones.isEmpty
                                    ? null
                                    : (value) => value == null || value.isEmpty
                                        ? 'La clasificación es obligatoria'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Column(
                      children: dataFrecuencias.map((frecuencia) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () => {
                                openPantalla2Page(frecuencia),
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      frecuencia['nombre'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}


