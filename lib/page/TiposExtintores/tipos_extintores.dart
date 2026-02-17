import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../api/tipos_extintores.dart';
import '../../components/TiposExtintores/list_tipos_extintores.dart';
import '../../components/TiposExtintores/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';

class TiposExtintoresPage extends StatefulWidget {
  const TiposExtintoresPage({super.key});

  @override
  State<TiposExtintoresPage> createState() => _TiposExtintoresPageState();
}

class _TiposExtintoresPageState extends State<TiposExtintoresPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataTiposExtintores = [];
  bool showModal = false;

  @override
  void initState() {
    super.initState();
    cargarTiposExtintores();
  }

  Future<void> cargarTiposExtintores() async {
    final conectado = await verificarConexion();
    if (conectado) {
      debugPrint("Conectado a internet");
      await getTiposExtintoresDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando desde Hive...");
      await getTiposExtintoresDesdeHive();
    }
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> getTiposExtintoresDesdeAPI() async {
    try {
      final tiposExtintoresService = TiposExtintoresService();
      final List<dynamic> response =
          await tiposExtintoresService.listarTiposExtintores();

      if (response.isNotEmpty) {
        final formateadas = formatModelTiposExtintores(response);

        final box = Hive.box('tiposExtintoresBox');
        await box.put('tiposExtintores', formateadas);

        if (mounted) {
          setState(() {
            dataTiposExtintores = formateadas;
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            dataTiposExtintores = [];
            loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error al obtener los tipos de extintores: $e");
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> getTiposExtintoresDesdeHive() async {
    final box = Hive.box('tiposExtintoresBox');
    final List<dynamic>? guardados = box.get('tiposExtintores');

    if (guardados != null) {
      if (mounted) {
        setState(() {
          dataTiposExtintores = guardados
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
          dataTiposExtintores = [];
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
          onCompleted: cargarTiposExtintores,
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

  List<Map<String, dynamic>> formatModelTiposExtintores(List<dynamic> data) {
    return data.map((item) {
      return {
        'id': item['_id'],
        'nombre': item['nombre'],
        'descripcion': item['descripcion'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Tipos de extintores"),
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
                        "Tipos de extintores",
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
                  child: dataTiposExtintores.isEmpty
                      ? const Center(
                          child:
                              Text("No hay tipos de extintores disponibles."))
                      : TblTiposExtintores(
                          showModal: () {
                            if (mounted) Navigator.pop(context);
                          },
                          tiposExtintores: dataTiposExtintores,
                          onCompleted: cargarTiposExtintores,
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
