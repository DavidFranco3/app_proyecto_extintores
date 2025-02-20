import 'package:flutter/material.dart';
import '../../api/encuesta_inspeccion.dart';
import '../../api/inspecciones.dart';
import '../../api/auth.dart';
import '../../api/clientes.dart';
import '../../components/Logs/logs_informativos.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../page/Inspecciones/inspecciones.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class EncuestaPage extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

EncuestaPage(
      {required this.showModal,
      required this.onCompleted,
      required this.accion,
      required this.data});

  @override
  _EncuestaPageState createState() => _EncuestaPageState();
}

class _EncuestaPageState extends State<EncuestaPage> {
  List<Pregunta> preguntas = [];
  List<Map<String, dynamic>> dataEncuestas = [];
  String? selectedEncuestaId;
  bool loading = true;
  bool _isLoading = false;
  int currentPage = 0; // Para controlar la página actual
  final int preguntasPorPagina = 5; // Número de preguntas por página
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> dataClientes = [];

  late TextEditingController usuarioController;
  late TextEditingController clienteController;
  late TextEditingController comentariosController;

  @override
  void initState() {
    super.initState();
    getEncuestas();
    getClientes();

    _pageController.addListener(() {
      setState(() {
        currentPage = _pageController.page!.round();
      });
    });

    usuarioController = TextEditingController();
    clienteController = TextEditingController();
    comentariosController = TextEditingController();
  }

  @override
  void dispose() {
    clienteController.dispose();
    comentariosController.dispose();
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

  Future<void> getEncuestas() async {
    try {
      final encuestaInspeccionService = EncuestaInspeccionService();
      final List<dynamic> response =
          await encuestaInspeccionService.listarEncuestaInspeccion();

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
          observaciones: pregunta['observaciones'],
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

    print(data);

    var dataTemp = {
      'idUsuario': data['idUsuario'],
      'idCliente': data['idCliente'],
      'idEncuesta': data['idEncuesta'],
      'encuesta': data['preguntas'],
      'comentarios': data['comentarios'],
      'estado': "true",
    };

    try {
      final inspeccionesService = InspeccionesService();
      var response = await inspeccionesService.registraInspecciones(dataTemp);
      // Verifica el statusCode correctamente, según cómo esté estructurada la respuesta
      if (response['status'] == 200) {
        // Asumiendo que 'response' es un Map que contiene el código de estado
        setState(() {
          _isLoading = false;
        });
        LogsInformativos(
            "Se ha registrado la inspeccion ${data['idCliente']} correctamente",
            dataTemp);
        _showDialog(
            "Inspeccion agregada correctamente", Icons.check, Colors.green);
      } else {
        // Maneja el caso en que el statusCode no sea 200
        setState(() {
          _isLoading = false;
        });
        _showDialog("Error al agregar la inspeccion", Icons.error, Colors.red);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showDialog("Oops...", Icons.error, Colors.red,
          error.toString()); // Muestra el error de manera más explícita
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
    List<Map<String, String>> respuestasAguardar =
        obtenerRespuestasParaGuardar();

    var formData = {
      "idUsuario": datosComunes["idUsuario"],
      "idCliente": clienteController.text,
      "idEncuesta": selectedEncuestaId,
      "preguntas": respuestasAguardar,
      "comentarios": comentariosController.text
    };

    _guardarEncuesta(formData);
  }

  void returnPrincipalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InspeccionesPage()),
    ).then((_) {
      // Actualizar encuestas al regresar de la página
    });
  }

  void _showDialog(String title, IconData icon, Color color,
      [String message = '']) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: 10),
              Text(message),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                returnPrincipalPage();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Inspeccion"),
      body: loading
          ? Load()
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Center(
                      child: Text(
                        "Inspeccion",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Botón centrado debajo del título
                    Center(
                      child: ElevatedButton(
                        onPressed: _onSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          minimumSize: Size(200, 50), // Tamaño fijo
                        ),
                        child: Text("Guardar Inspección"),
                      ),
                    ),
                    Center(
                      child: ElevatedButton(
                          onPressed: returnPrincipalPage,
                          child: _isLoading
                              ? SpinKitFadingCircle(
                                  color: const Color.fromARGB(255, 241, 8, 8),
                                  size: 24)
                              : Text("Cancelar"),
                        ),
                    ),
                    SizedBox(height: 20), // Espacio debajo del botón

                    // Dropdown de Encuesta
                    DropdownButtonFormField<String>(
                      value: selectedEncuestaId,
                      hint: Text('Selecciona una encuesta'),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedEncuestaId = newValue;
                          currentPage = 0;
                        });
                        if (newValue != null) {
                          actualizarPreguntas(newValue);
                        }
                      },
                      items: dataEncuestas.map((encuesta) {
                        return DropdownMenuItem<String>(
                          value: encuesta['id'],
                          child: Text(encuesta['nombre']!),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10),

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
                    SizedBox(height: 10),

                    // Si hay encuesta seleccionada y preguntas disponibles
                    if (selectedEncuestaId != null && preguntas.isNotEmpty)
                      SizedBox(
                        height:
                            300, // Si no quieres que sea fijo, quita el height aquí
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: dividirPreguntasEnPaginas().length + 1,
                          itemBuilder: (context, pageIndex) {
                            if (pageIndex <
                                dividirPreguntasEnPaginas().length) {
                              var preguntasPagina =
                                  dividirPreguntasEnPaginas()[pageIndex];
                              return ListView.builder(
                                itemCount: preguntasPagina.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    margin: EdgeInsets.all(10),
                                    child: Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            preguntasPagina[index].titulo,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          SizedBox(height: 10),
                                          Column(
                                            children: preguntasPagina[index]
                                                .opciones
                                                .map((opcion) {
                                              return ListTile(
                                                title: Text(opcion),
                                                leading: Radio<String>(
                                                  value: opcion,
                                                  groupValue:
                                                      preguntasPagina[index]
                                                          .respuesta,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      preguntasPagina[index]
                                                          .respuesta = value!;
                                                    });
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              return Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Comentarios finales",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10),
                                    TextField(
                                      controller: comentariosController,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        hintText:
                                            "Escribe aquí tus comentarios...",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),

                    // Paginación para las preguntas
                    if (preguntas.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back),
                              onPressed: currentPage > 0
                                  ? () {
                                      _pageController.previousPage(
                                          duration: Duration(milliseconds: 300),
                                          curve: Curves.easeIn);
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: Icon(Icons.arrow_forward),
                              onPressed: currentPage <
                                      dividirPreguntasEnPaginas().length
                                  ? () {
                                      _pageController.nextPage(
                                          duration: Duration(milliseconds: 300),
                                          curve: Curves.easeIn);
                                    }
                                  : null,
                            ),
                          ],
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
