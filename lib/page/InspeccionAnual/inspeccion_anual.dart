import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../api/clientes.dart';
import '../../api/inspeccion_anual.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Logs/logs_informativos.dart';
import '../InspeccionEspecial/inspeccion_especial.dart';
import 'package:flutter/services.dart';
import '../../components/Generales/flushbar_helper.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../components/Generales/premium_button.dart';
import '../../components/Generales/premium_inputs.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InspeccionAnualPage extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;
  const InspeccionAnualPage({
    super.key,
    required this.showModal,
    required this.onCompleted,
    required this.accion,
    required this.data,
  });

  @override
  State<InspeccionAnualPage> createState() => _InspeccionAnualPageState();
}

class _InspeccionAnualPageState extends State<InspeccionAnualPage> {
  final _formKey = GlobalKey<FormState>();
  List<Pregunta> preguntas = [];
  TextEditingController preguntaController = TextEditingController();
  TextEditingController observacionController = TextEditingController();
  TextEditingController nombreController = TextEditingController();
  TextEditingController clienteController = TextEditingController();
  List<Map<String, dynamic>> dataClientes = [];
  bool loading = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getClientes();
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> getClientes() async {
    final conectado = await verificarConexion();

    if (conectado) {
      await getClientesDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando clientes desde Hive...");
      await getClientesDesdeHive();
    }
  }

  Future<void> getClientesDesdeAPI() async {
    try {
      final clientesService = ClientesService();
      final List<dynamic> response = await clientesService.listarClientes();

      if (response.isNotEmpty) {
        final formateados = formatModelClientes(response);

        final box = Hive.box('clientesBox');
        await box.put('clientes', formateados);

        setState(() {
          dataClientes = formateados;
          loading = false;
        });
      } else {
        setState(() {
          dataClientes = [];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error al obtener los clientes: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getClientesDesdeHive() async {
    try {
      final box = Hive.box('clientesBox');
      final List<dynamic>? guardados = box.get('clientes');

      if (guardados != null) {
        setState(() {
          dataClientes = guardados
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item))
              .where((item) => item['estado'] == "true")
              .toList();
          loading = false;
        });
      } else {
        setState(() {
          dataClientes = [];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error leyendo clientes desde Hive: $e");
      setState(() {
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> formatModelClientes(List<dynamic> data) {
    return data
        .map((item) => {
              'id': item['_id'],
              'nombre': item['nombre'],
              'imagen': item['imagen'],
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
            })
        .toList();
  }

  void _agregarPregunta() {
    setState(() {
      preguntas.add(Pregunta(
          pregunta: preguntaController.text,
          valores: observacionController.text));
      preguntaController.clear();
      observacionController.clear();
    });
  }

  void _eliminarPregunta(int index) {
    setState(() {
      preguntas.removeAt(index);
    });
  }

  void _guardarEncuesta(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    var dataTemp = {
      'titulo': data['nombre'],
      'idCliente': data['cliente'],
      'datos': data['preguntas'],
      'estado': "true",
    };

    try {
      final inspeccionAnualService = InspeccionAnualService();
      var response =
          await inspeccionAnualService.registrarInspeccionAnual(dataTemp);

      if (response['status'] == 200) {
        setState(() {
          _isLoading = false;
          returnPrincipalPage();
        });
        logsInformativos(
            "Se ha registrado la inspección anual ${data['nombre']} correctamente",
            dataTemp);
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Registro exitoso",
            message: "La inspección anual fue agregada correctamente",
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
            message: "Hubo un error al agregar la inspección anual",
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
      "nombre": nombreController.text,
      "cliente": clienteController.text,
      "preguntas": preguntas.map((pregunta) => pregunta.toJson()).toList(),
    };
    _guardarEncuesta(formData);
  }

  void returnPrincipalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InspeccionEspecialPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _formKey,
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Actividad anual"),
      body: loading
          ? Load()
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Inspección anual",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C3E50),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: PremiumActionButton(
                          onPressed: _isLoading ? () {} : _publicarEncuesta,
                          label: "Guardar",
                          icon: FontAwesomeIcons.floppyDisk,
                          isLoading: _isLoading,
                          isFullWidth: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PremiumActionButton(
                          onPressed: returnPrincipalPage,
                          label: "Regresar",
                          icon: FontAwesomeIcons.arrowLeft,
                          style: PremiumButtonStyle.secondary,
                          isFullWidth: true,
                        ),
                      ),
                    ],
                  ),
                  const Divider(indent: 20, endIndent: 20, height: 32),
                  SizedBox(height: 20),
                  const PremiumSectionTitle(
                    title: "Información de la Inspección",
                    icon: FontAwesomeIcons.circleInfo,
                  ),
                  PremiumCardField(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: nombreController,
                          decoration: PremiumInputs.decoration(
                            labelText: "Nombre de la inspección",
                            prefixIcon: FontAwesomeIcons.tag,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownSearch<String>(
                          key: const Key('clienteDropdown'),
                          enabled: dataClientes.isNotEmpty,
                          items: (filter, _) {
                            return dataClientes
                                .where((c) => c['nombre']
                                    .toString()
                                    .toLowerCase()
                                    .contains(filter.toLowerCase()))
                                .map((c) => c['id'].toString())
                                .toList();
                          },
                          itemAsString: (String? id) {
                            if (id == null) return "";
                            final cliente = dataClientes.firstWhere(
                                (c) => c['id'].toString() == id,
                                orElse: () => {'nombre': ''});
                            return cliente['nombre']?.toString() ?? "";
                          },
                          selectedItem: clienteController.text.isEmpty
                              ? null
                              : clienteController.text,
                          onChanged: dataClientes.isEmpty
                              ? null
                              : (String? newValue) {
                                  setState(() {
                                    clienteController.text = newValue!;
                                  });
                                },
                          dropdownBuilder: (context, selectedItem) {
                            final cliente = dataClientes.firstWhere(
                                (c) => c['id'].toString() == selectedItem,
                                orElse: () => {'nombre': ''});
                            return Text(
                              cliente['nombre'] != '' ? cliente['nombre'] : "",
                              style: const TextStyle(fontSize: 14),
                            );
                          },
                          decoratorProps: DropDownDecoratorProps(
                            decoration: PremiumInputs.decoration(
                              labelText: 'Cliente',
                              prefixIcon: FontAwesomeIcons.buildingUser,
                            ),
                          ),
                          popupProps: const PopupProps.menu(
                            showSearchBox: true,
                            fit: FlexFit.loose,
                            constraints: BoxConstraints(maxHeight: 300),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const PremiumSectionTitle(
                    title: "Agregar Nuevo Campo",
                    icon: FontAwesomeIcons.plusCircle,
                  ),
                  PremiumCardField(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: preguntaController,
                          decoration: PremiumInputs.decoration(
                            labelText: "Pregunta / Concepto",
                            prefixIcon: FontAwesomeIcons.question,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: observacionController,
                          decoration: PremiumInputs.decoration(
                            labelText: "Valores (separados por coma)",
                            prefixIcon: FontAwesomeIcons.listOl,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^[0-9,]*$')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        PremiumActionButton(
                          onPressed: _agregarPregunta,
                          label: "Agregar Dato",
                          icon: FontAwesomeIcons.plus,
                          style: PremiumButtonStyle.secondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const PremiumSectionTitle(
                    title: "Conceptos Agregados",
                    icon: FontAwesomeIcons.listCheck,
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: preguntas.length,
                    itemBuilder: (context, index) {
                      return PremiumCardField(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            preguntas[index].pregunta,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50)),
                          ),
                          subtitle: Text(
                            "Valores: ${preguntas[index].valores}",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: IconButton(
                            icon: const FaIcon(FontAwesomeIcons.trashCan,
                                color: Color(0xFFE74C3C), size: 20),
                            onPressed: () => _eliminarPregunta(index),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class Pregunta {
  String pregunta;
  String valores;

  Pregunta({required this.pregunta, required this.valores});

  Map<String, dynamic> toJson() {
    return {"pregunta": pregunta, "valores": valores};
  }
}
