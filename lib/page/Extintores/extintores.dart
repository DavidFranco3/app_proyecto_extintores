import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../api/extintores.dart';
import '../../components/Extintores/list_extintores.dart';
import '../../components/Extintores/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';

class ExtintoresPage extends StatefulWidget {
  const ExtintoresPage({super.key});

  @override
  State<ExtintoresPage> createState() => _ExtintoresPageState();
}

class _ExtintoresPageState extends State<ExtintoresPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataExtintores = [];
  bool showModal = false;

  @override
  void initState() {
    super.initState();
    getExtintores();
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> getExtintores() async {
    final conectado = await verificarConexion();

    if (conectado) {
      await getExtintoresDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando desde Hive...");
      await getExtintoresDesdeHive();
    }
  }

  Future<void> getExtintoresDesdeAPI() async {
    try {
      final extintoresService = ExtintoresService();
      final List<dynamic> response = await extintoresService.listarExtintores();

      if (response.isNotEmpty) {
        final formateados = formatModelExtintores(response);

        // Guardar en Hive
        final box = Hive.box('extintoresBox');
        await box.put('extintores', formateados);

        setState(() {
          dataExtintores = formateados;
          loading = false;
        });
      } else {
        setState(() {
          dataExtintores = [];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error al obtener los extintores: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getExtintoresDesdeHive() async {
    try {
      final box = Hive.box('extintoresBox');
      final List<dynamic>? guardados = box.get('extintores');

      if (guardados != null) {
        setState(() {
          dataExtintores = guardados
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item))
              .where((item) => item['estado'] == "true")
              .toList();
          loading = false;
        });
      } else {
        setState(() {
          dataExtintores = [];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error leyendo Hive: $e");
      setState(() {
        loading = false;
      });
    }
  }

  // Función para abrir el modal de registro
  void openRegistroModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Acciones(
            showModal: () {
              if (mounted) Navigator.pop(context);
            },
            onCompleted: getExtintores,
            accion: "registrar",
            data: null,
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

  List<Map<String, dynamic>> formatModelExtintores(List<dynamic> data) {
    return data
        .map((item) => {
              'id': item['_id'],
              'numeroSerie': item['numeroSerie'],
              'idTipoExtintor': item['idTipoExtintor'],
              'extintor': item['tipoExtintor']['nombre'],
              'capacidad': item['capacidad'],
              'ultimaRecarga': item['ultimaRecarga'],
              'estado': item['estado'],
              'createdAt': item['createdAt'],
              'updatedAt': item['updatedAt'],
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Extintores"),
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
                        "Extintores",
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
                  child: TblExtintores(
                    showModal: () {
                      if (mounted) Navigator.pop(context);
                    },
                    extintores: dataExtintores,
                    onCompleted: getExtintores,
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
