import 'package:flutter/material.dart';
import '../../api/clientes.dart';
import '../../components/InspeccionesPantalla1/list_inspecciones_pantalla_1.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class InspeccionesPantalla1Page extends StatefulWidget {
  const InspeccionesPantalla1Page({super.key});

  @override
  State<InspeccionesPantalla1Page> createState() =>
      _InspeccionesPantalla1PageState();
}

class _InspeccionesPantalla1PageState extends State<InspeccionesPantalla1Page> {
  bool loading = true;
  List<Map<String, dynamic>> dataClientes = [];
  List<Map<String, dynamic>> filteredClientes = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getClientes();
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

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
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
              .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item as Map))
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

  void filterClientes(String query) {
    setState(() {
      filteredClientes = dataClientes
          .where((cliente) =>
              cliente['nombre'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  bool showModal = false; // Estado que maneja la visibilidad del modal

  // Función para formatear los datos de las clientes
  List<Map<String, dynamic>> formatModelClientes(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    int total = data.length; // Obtener el total de elementos
    for (var i = 0; i < total; i++) {
      var item = data[i];
      dataTemp.add({
        'index': total - i,
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
      });
    }
    return dataTemp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(), // Usa el header con menú de usuario
      drawer: MenuLateral(
          currentPage: "Historial de actividades"), // Usa el menú lateral
      body: loading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Centra el encabezado
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Actividades",
                      style: TextStyle(
                        fontSize: 24, // Tamaño grande
                        fontWeight: FontWeight.bold, // Negrita
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterClientes,
                    decoration: InputDecoration(
                      labelText: "Buscar cliente",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: TblInspeccionesPantalla1(
                    showModal: () {
                      Navigator.pop(
                          context); // Cierra el modal después de registrar
                    },
                    clientes: searchController.text.isEmpty
                        ? dataClientes
                        : filteredClientes,
                    onCompleted:
                        getClientes, // Pasa la función para que se pueda llamar desde el componente
                  ),
                ),
              ],
            ),
      // Modal: Se muestra solo si `showModal` es true
    );
  }
}

