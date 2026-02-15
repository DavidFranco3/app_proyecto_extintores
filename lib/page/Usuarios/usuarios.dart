import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../api/usuarios.dart';
import '../../components/Usuarios/list_usuarios.dart';
import '../../components/Usuarios/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataUsuarios = [];
  bool showModal = false;

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    final conectado = await verificarConexion();
    if (conectado) {
      debugPrint("Conectado a internet");
      await getUsuariosDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando usuarios desde Hive...");
      await getUsuariosDesdeHive();
    }
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> getUsuariosDesdeAPI() async {
    try {
      final usuariosService = UsuariosService();
      final List<dynamic> response = await usuariosService.listarUsuarios();

      if (response.isNotEmpty) {
        final formateadas = formatModelUsuarios(response);

        final box = Hive.box('usuariosBox');
        await box.put('usuarios', formateadas);

        if (mounted) {
          setState(() {
            dataUsuarios = formateadas;
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            dataUsuarios = [];
            loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al obtener los usuarios: $e");
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getUsuariosDesdeHive() async {
    final box = Hive.box('usuariosBox');
    final List<dynamic>? guardados = box.get('usuarios');

    if (guardados != null) {
      if (mounted) {
        setState(() {
          dataUsuarios = guardados
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
          dataUsuarios = [];
          loading = false;
        });
      }
    }
  }

  void openRegistroModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Acciones(
          showModal: () {
            if (mounted) Navigator.pop(context);
          },
          onCompleted: cargarUsuarios,
          accion: "registrar",
          data: null,
        ),
      ),
    );
  }

  void closeModal() {
    setState(() {
      showModal = false;
    });
  }

  List<Map<String, dynamic>> formatModelUsuarios(List<dynamic> data) {
    return data.map((item) {
      return {
        'id': item['_id'],
        'nombre': item['nombre'],
        'email': item['email'],
        'telefono': item['telefono'],
        'tipo': item['tipo'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Usuarios"),
      body: loading
          ? Load()
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Usuarios",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: openRegistroModal,
                      icon: Icon(FontAwesomeIcons.plus),
                      label: Text("Registrar"),
                    ),
                  ),
                ),
                Expanded(
                  child: dataUsuarios.isEmpty
                      ? Center(child: Text("No hay usuarios disponibles."))
                      : TblUsuarios(
                          showModal: () { if (mounted) Navigator.pop(context); },
                          usuarios: dataUsuarios,
                          onCompleted: cargarUsuarios,
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




