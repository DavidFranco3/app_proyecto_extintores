import 'package:flutter/material.dart';
import '../../api/encuesta_inspeccion.dart';
import '../../api/encuesta_inspeccion_cliente.dart';
import '../../api/clientes.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/flushbar_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../utils/offline_sync_util.dart';

class EncuestasJerarquicasWidget extends StatefulWidget {
  const EncuestasJerarquicasWidget({super.key});

  @override
  State<EncuestasJerarquicasWidget> createState() =>
      _EncuestasJerarquicasPageState();
}

class _EncuestasJerarquicasPageState extends State<EncuestasJerarquicasWidget> {
  final Set<String> seleccionados = {};
  bool loading = true;
  bool _guardando = false;

  List<Map<String, dynamic>> dataEncuestas = [];
  List<Map<String, dynamic>> dataClientes = [];
  late TextEditingController clienteController;

  @override
  void initState() {
    super.initState();
    getEncuestas();
    getClientes();

    clienteController = TextEditingController();

    sincronizarOperacionesPendientesInspecciones();

    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> event) {
      if (event.any((result) => result != ConnectivityResult.none)) {
        sincronizarOperacionesPendientesInspecciones();
      }
    });
  }

  Future<void> precargarEncuestasCliente(String idCliente) async {
    try {
      final encuestaInspeccionClienteService =
          EncuestaInspeccionClienteService();

      final List<dynamic> encuestasCliente =
          await encuestaInspeccionClienteService
              .obtenerEncuestaInspeccionClienteEncuestas(idCliente);

      final Set<String> seleccionPrevia = {};

      for (var encCliente in encuestasCliente) {
        final encontrada = dataEncuestas.firstWhere(
          (e) =>
              e['nombre'] == encCliente['nombre'] &&
              e['idFrecuencia'] == encCliente['idFrecuencia'] &&
              e['idClasificacion'] == encCliente['idClasificacion'] &&
              e['idRama'] == encCliente['idRama'],
          orElse: () => {},
        );

        if (encontrada.isNotEmpty) {
          final encuestaId = encontrada['id'];
          final frecuenciaId = encontrada['idFrecuencia'];
          final clasificacionId = encontrada['idClasificacion'];
          final ramaId = encontrada['idRama'];

          // Marcar encuesta + preguntas
          seleccionPrevia.add(encuestaId);
          (encontrada['preguntas'] as List).asMap().forEach((i, _) {
            seleccionPrevia.add('${encuestaId}_$i');
          });

          // Marcar jerarquía superior
          seleccionPrevia.add(frecuenciaId);
          seleccionPrevia.add(clasificacionId);
          seleccionPrevia.add(ramaId);
        }
      }

      setState(() {
        seleccionados
          ..clear()
          ..addAll(seleccionPrevia);
      });
    } catch (e) {
      debugPrint("Error al precargar encuestas del cliente: $e");
    }
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  // --- ENCUESTAS ---

  Future<void> getEncuestas() async {
    final conectado = await verificarConexion();

    if (conectado) {
      await getEncuestasDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando encuestas desde Hive...");
      await getEncuestasDesdeHive();
    }
  }

  Future<void> getEncuestasDesdeAPI() async {
    try {
      final encuestaInspeccionService = EncuestaInspeccionService();
      final List<dynamic> response =
          await encuestaInspeccionService.listarEncuestaInspeccion();

      if (response.isNotEmpty) {
        final encuestasFormateadas = formatModelEncuestas(response);

        // Guardar en Hive
        final box = Hive.box('encuestasBox');
        await box.put('encuestas', encuestasFormateadas);

        setState(() {
          dataEncuestas = encuestasFormateadas;
          loading = false;
        });
      } else {
        setState(() {
          dataEncuestas = [];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error al obtener encuestas desde API: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getEncuestasDesdeHive() async {
    try {
      final box = Hive.box('encuestasBox');
      final List<dynamic>? guardadas = box.get('encuestas');

      if (guardadas != null) {
        setState(() {
          dataEncuestas = guardadas
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item))
              .where((item) => item['estado'] == "true")
              .toList();
          loading = false;
        });
      } else {
        setState(() {
          dataEncuestas = [];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error leyendo encuestas desde Hive: $e");
      setState(() {
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> formatModelEncuestas(List<dynamic> data) {
    return data.map((item) {
      return {
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
      };
    }).toList();
  }

  Future<void> getClientes() async {
    final conectado = await verificarConexion();
    if (conectado) {
      debugPrint("Conectado a internet");
      await getClientesDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando desde Hive...");
      await getClientesDesdeHive();
    }
  }

  Future<void> getClientesDesdeAPI() async {
    try {
      final clientesService = ClientesService();
      final List<dynamic> response = await clientesService.listarClientes();

      if (response.isNotEmpty) {
        final formateadas = formatModelClientes(response);

        final box = Hive.box('clientesBox');
        await box.put('clientes', formateadas);

        if (mounted) {
          setState(() {
            dataClientes = formateadas;
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            dataClientes = [];
            loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al obtener los clientes: $e");
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getClientesDesdeHive() async {
    final box = Hive.box('clientesBox');
    final List<dynamic>? guardados = box.get('clientes');

    if (guardados != null) {
      if (mounted) {
        setState(() {
          dataClientes = guardados
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item as Map))
              .where((item) => item['estado'] == "true")
              .toList();
          loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          dataClientes = [];
          loading = false;
        });
      }
    }
  }

  Future<void> sincronizarOperacionesPendientesInspecciones() async {
    final conectado = await OfflineSyncUtil().verificarConexion();
    if (!conectado) return;

    final box = Hive.box('operacionesOfflinePreguntas');
    final operacionesRaw = box.get('operaciones', defaultValue: []);

    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    if (operaciones.isEmpty) return;

    final encuestaService = EncuestaInspeccionClienteService();
    final List<String> operacionesEliminar = [];

    for (var operacion in operaciones) {
      operacion['intentos'] = (operacion['intentos'] ?? 0) + 1;
      try {
        final response = await encuestaService
            .registraEncuestaInspeccionCliente(operacion['data']);

        final status = response['status'];
        if (status == 200 ||
            (status >= 400 && status < 500) ||
            operacion['intentos'] >= 5) {
          operacionesEliminar.add(operacion['idTemporal'] ?? '');
        }
      } catch (e) {
        debugPrint('Error sincronizando encuesta: $e');
        if (operacion['intentos'] >= 5) {
          operacionesEliminar.add(operacion['idTemporal'] ?? '');
        }
      }
    }

    final nuevasOperaciones = operaciones
        .where((op) => !operacionesEliminar.contains(op['idTemporal']))
        .toList();
    await box.put('operaciones', nuevasOperaciones);

    if (operacionesEliminar.isNotEmpty) {
      debugPrint("✔ Sincronización de encuestas finalizada.");
    }
  }

  // Función para formatear los datos de las clientes
  List<Map<String, dynamic>> formatModelClientes(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'imagen': item['imagen'],
        'imagenCloudinary': item['imagenCloudinary'],
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

  @override
  void dispose() {
    clienteController.dispose();
    super.dispose();
  }

  Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>
      agruparJerarquia() {
    final Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>>
        jerarquia = {};
    for (var encuesta in dataEncuestas) {
      final rama = encuesta['idRama'] + "-" + encuesta['rama'];
      final clasificacion =
          encuesta['idClasificacion'] + "-" + encuesta['clasificacion'];
      final frecuencia =
          encuesta['idFrecuencia'] + "-" + encuesta['frecuencia'];
      jerarquia.putIfAbsent(rama, () => {});
      jerarquia[rama]!.putIfAbsent(clasificacion, () => {});
      jerarquia[rama]![clasificacion]!.putIfAbsent(frecuencia, () => []);
      jerarquia[rama]![clasificacion]![frecuencia]!.add(encuesta);
    }
    return jerarquia;
  }

  void actualizarSeleccionJerarquica({
    required List<String> hijos,
    required bool seleccionar,
  }) {
    setState(() {
      debugPrint("hijos");
      debugPrint(hijos.toString());
      if (seleccionar) {
        seleccionados.addAll(hijos);
      } else {
        seleccionados.removeAll(hijos);
      }
    });
  }

  bool estanTodosSeleccionados(List<String> ids) {
    return ids.every((id) => seleccionados.contains(id));
  }

  Future<List<Map<String, dynamic>>> generarEstructuraGuardar(
    BuildContext context,
    Map<String, Map<String, Map<String, List<Map<String, dynamic>>>>> jerarquia,
    List<String> seleccionados,
    TextEditingController clienteController,
  ) async {
    setState(() {
      _guardando = true;
    });

    final conectado = await verificarConexion();

    final box = Hive.box('operacionesOfflinePreguntas');

    final List<Map<String, dynamic>> resultado = [];
    final List<Future> tareas = [];

    jerarquia.forEach((idRama, clasificaciones) {
      clasificaciones.forEach((idClasificacion, frecuencias) {
        frecuencias.forEach((idFrecuencia, encuestas) {
          for (var encuesta in encuestas) {
            final encuestaId = encuesta['id'];

            final preguntasSeleccionadas = <Map<String, dynamic>>[];

            final preguntas = (encuesta['preguntas'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            for (int i = 0; i < preguntas.length; i++) {
              final preguntaId = '${encuestaId}_$i';
              if (seleccionados.contains(preguntaId)) {
                preguntasSeleccionadas.add({
                  'titulo': preguntas[i]['titulo'],
                  'categoria': preguntas[i]['categoria'],
                  'opciones': preguntas[i]['opciones'],
                });
              }
            }

            if (preguntasSeleccionadas.isNotEmpty) {
              final estructura = {
                'nombre': encuesta['nombre'],
                'idFrecuencia': idFrecuencia.split("-")[0],
                'idClasificacion': idClasificacion.split("-")[0],
                'idRama': idRama.split("-")[0],
                'idCliente': clienteController.text,
                'preguntas': preguntasSeleccionadas,
                'estado': "true",
              };

              resultado.add(estructura);

              if (conectado) {
                final encuestaInspeccionClienteService =
                    EncuestaInspeccionClienteService();
                tareas.add(encuestaInspeccionClienteService
                    .registraEncuestaInspeccionCliente(estructura));
              } else {
                final operaciones = box.get('operaciones', defaultValue: []);
                operaciones.add({
                  'accion': 'guardarEncuesta',
                  'data': estructura,
                  'idTemporal': UniqueKey().toString(),
                });
                box.put('operaciones', operaciones);
              }
            }
          }
        });
      });
    });

    if (conectado) {
      try {
        await Future.wait(tareas);
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Registro exitoso",
            message: "Todas las encuestas se han guardado correctamente.",
            backgroundColor: Colors.green,
          );
        }
      } catch (e) {
        if (mounted) {
          showCustomFlushbar(
            context: context,
            title: "Error",
            message: "Ocurrió un error guardando las encuestas: $e",
            backgroundColor: Colors.red,
          );
        }
      }
    } else {
      if (mounted) {
        showCustomFlushbar(
          context: context,
          title: "Sin conexión",
          message:
              "Las encuestas se guardaron localmente y se sincronizarán cuando haya internet.",
          backgroundColor: Colors.orange,
        );
      }
    }

    setState(() {
      _guardando = false;
      clienteController.clear();
      seleccionados.clear();
    });

    if (conectado) {
      await sincronizarOperacionesPendientesInspecciones();
    }

    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    final jerarquia = agruparJerarquia();

    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(
        currentPage: "Configuración de Cliente",
      ),
      body: loading
          ? Load()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Configuración de Cliente",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _guardando
                      ? null
                      : () async {
                          setState(() {
                            _guardando = true;
                          });

                          final dataAGuardar = await generarEstructuraGuardar(
                            context,
                            jerarquia,
                            seleccionados.toList(),
                            clienteController,
                          );

                          debugPrint("data a guardar");
                          debugPrint(dataAGuardar.toString());

                          setState(() {
                            _guardando = false;
                            seleccionados.clear(); // Limpiar checkboxes
                            clienteController.text = ''; // Limpiar dropdown
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: _guardando
                        ? SizedBox(
                            key: ValueKey('cargando'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Guardar selección',
                            key: ValueKey('texto'),
                          ),
                  ),
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                      clienteController.text), // 👈 esto obliga a reconstruir
                  initialValue: clienteController.text.isEmpty
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
                  onChanged: (newValue) async {
                    setState(() {
                      clienteController.text = newValue!;
                      seleccionados.clear(); // 👉 limpia visualmente primero
                    });

                    await precargarEncuestasCliente(
                        newValue!); // 👉 vuelve a llenar 'seleccionados'
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'El cliente es obligatorio'
                      : null,
                ),
                ...jerarquia.entries.map((ramaEntry) {
                  final ramaId = ramaEntry.key;
                  final ramaContiene = [ramaId];
                  final todosHijosRama = <String>[];
                  ramaEntry.value.forEach((clasificacion, freqs) {
                    todosHijosRama.add(clasificacion);
                    freqs.forEach((frecuencia, encuestasList) {
                      todosHijosRama.add(frecuencia);
                      for (var encuesta in encuestasList) {
                        todosHijosRama.add(encuesta['id']);
                        encuesta['preguntas'].asMap().forEach((i, pregunta) {
                          todosHijosRama.add('${encuesta['id']}_$i');
                        });
                      }
                    });
                  });

                  return ExpansionTile(
                    title: CheckboxListTile(
                      value: estanTodosSeleccionados(todosHijosRama),
                      onChanged: (val) {
                        actualizarSeleccionJerarquica(
                          hijos: [...todosHijosRama, ...ramaContiene],
                          seleccionar: val!,
                        );
                      },
                      title: Text('🧬 Tipo de sistema: ${ramaId.split("-")[1]}',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    children: ramaEntry.value.entries.map((clasificacionEntry) {
                      final clasificacionId = clasificacionEntry.key;
                      final hijosClasificacion = <String>[];

                      clasificacionEntry.value
                          .forEach((frecuencia, encuestasList) {
                        hijosClasificacion.add(frecuencia);
                        for (var encuesta in encuestasList) {
                          hijosClasificacion.add(encuesta['id']);
                          encuesta['preguntas'].asMap().forEach((i, pregunta) {
                            hijosClasificacion.add('${encuesta['id']}_$i');
                          });
                        }
                      });

                      return ExpansionTile(
                        title: CheckboxListTile(
                          value: estanTodosSeleccionados(hijosClasificacion),
                          onChanged: (val) {
                            actualizarSeleccionJerarquica(
                              hijos: hijosClasificacion + [clasificacionId],
                              seleccionar: val!,
                            );
                          },
                          title: Text(
                              '📁 Clasificación: ${clasificacionId.split("-")[1]}'),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.only(left: 12),
                        ),
                        children: clasificacionEntry.value.entries
                            .map((frecuenciaEntry) {
                          final frecuenciaId = frecuenciaEntry.key;
                          final encuestasLista = frecuenciaEntry.value;
                          final hijosFrecuencia = <String>[];

                          for (var encuesta in encuestasLista) {
                            hijosFrecuencia.add(encuesta['id']);
                            encuesta['preguntas']
                                .asMap()
                                .forEach((i, pregunta) {
                              hijosFrecuencia.add('${encuesta['id']}_$i');
                            });
                          }

                          return ExpansionTile(
                            title: CheckboxListTile(
                              value: estanTodosSeleccionados(hijosFrecuencia),
                              onChanged: (val) {
                                actualizarSeleccionJerarquica(
                                  hijos: hijosFrecuencia + [frecuenciaId],
                                  seleccionar: val!,
                                );
                              },
                              title: Text(
                                  '⏱ Periodo: ${frecuenciaId.split("-")[1]}'),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.only(left: 24),
                            ),
                            children: encuestasLista.map((encuesta) {
                              final encuestaId = encuesta['id'];
                              final preguntasIds =
                                  (encuesta['preguntas'] as List)
                                      .asMap()
                                      .keys
                                      .map((i) => '${encuestaId}_$i')
                                      .toList();

                              return ExpansionTile(
                                title: CheckboxListTile(
                                  value: seleccionados.contains(encuestaId) &&
                                      estanTodosSeleccionados(preguntasIds),
                                  onChanged: (val) {
                                    actualizarSeleccionJerarquica(
                                      hijos: [encuestaId, ...preguntasIds],
                                      seleccionar: val!,
                                    );
                                  },
                                  title: Text(
                                      '📋 Encuesta: ${encuesta['nombre']}'),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.only(left: 36),
                                ),
                                children: [
                                  ...List<Widget>.from(
                                    (encuesta['preguntas'] as List)
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final i = entry.key;
                                      final pregunta = entry.value;
                                      final preguntaId = '${encuestaId}_$i';
                                      return CheckboxListTile(
                                        value:
                                            seleccionados.contains(preguntaId),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val!) {
                                              seleccionados.add(preguntaId);
                                            } else {
                                              seleccionados.remove(preguntaId);
                                            }
                                          });
                                        },
                                        title: Text(
                                            '❓ ${pregunta['titulo']} (${pregunta['categoria']})'),
                                        subtitle: Text(
                                            'Opciones: ${(pregunta['opciones'] as List).join(', ')}'),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding:
                                            EdgeInsets.only(left: 48),
                                      );
                                    }),
                                  )
                                ],
                              );
                            }).toList(),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
    );
  }
}
