import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../api/clientes.dart';
import '../../components/Clientes/list_clientes.dart';
import '../../components/Clientes/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataClientes = [];
  bool showModal = false;

  @override
  void initState() {
    super.initState();
    cargarClientes();
  }

  Future<void> cargarClientes() async {
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

  void openRegistroModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: Acciones(
              showModal: () {
                if (mounted) Navigator.pop(context);
              },
              onCompleted: cargarClientes,
              accion: "registrar",
              data: null,
            ),
          );
        },
      ),
    );
  }

  void closeModal() {
    setState(() {
      showModal = false;
    });
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Clientes"),
      body: loading
          ? Load()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Clientes",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PremiumActionButton(
                        onPressed: openRegistroModal,
                        label: "Registrar",
                        icon: FontAwesomeIcons.plus,
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 20, endIndent: 20, height: 32),
                Expanded(
                  child: dataClientes.isEmpty
                      ? const Center(
                          child: Text("No hay clientes disponibles."))
                      : TblClientes(
                          showModal: () {
                            if (mounted) Navigator.pop(context);
                          },
                          clientes: dataClientes,
                          onCompleted: cargarClientes,
                        ),
                ),
              ],
            ),
      floatingActionButton: showModal
          ? FloatingActionButton(
              onPressed: closeModal,
              child: Icon(Icons.close),
            )
          : null,
    );
  }
}
