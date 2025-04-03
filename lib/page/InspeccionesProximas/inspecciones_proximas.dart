import 'package:flutter/material.dart';
import '../../api/inspecciones_proximas.dart';
import '../../components/InspeccionesProximas/list_inspecciones_proximas.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class InspeccionesProximasPage extends StatefulWidget {
  @override
  _InspeccionesProximasPageState createState() =>
      _InspeccionesProximasPageState();
}

class _InspeccionesProximasPageState extends State<InspeccionesProximasPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspeccionesProximas = [];

  @override
  void initState() {
    super.initState();
    getInspeccionesProximas();
  }

  Future<void> getInspeccionesProximas() async {
    try {
      final inspeccionesProximasService = InspeccionesProximasService();
      final List<dynamic> response =
          await inspeccionesProximasService.listarInspeccionesProximas();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataInspeccionesProximas = formatModelInspeccionesProximas(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataInspeccionesProximas = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      print("Error al obtener las inspeccionesProximas: $e");
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
      });
    }
  }

  bool showModal = false; // Estado que maneja la visibilidad del modal

  // Función para formatear los datos de las inspeccionesProximas
  List<Map<String, dynamic>> formatModelInspeccionesProximas(
      List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'idFrecuencia': item['idFrecuencia'],
        'idEncuesta': item['idEncuesta'],
        'idCliente': item['idCliente'],
        'cuestionario': item['cuestionario']['nombre'],
        'frecuencia': item['frecuencia']['nombre'],
        'cliente': item['cliente']['nombre'],
        'proximaInspeccion': item['nuevaInspeccion'],
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
          currentPage: "Inspecciones próximas"), // Usa el menú lateral
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
                      "Inspecciones próximas",
                      style: TextStyle(
                        fontSize: 24, // Tamaño grande
                        fontWeight: FontWeight.bold, // Negrita
                      ),
                    ),
                  ),
                ),
                // Centra el botón de registrar
                Expanded(
                  child: TblInspeccionesProximas(
                    showModal: () {
                      Navigator.pop(context); // Esto cierra el modal
                    },
                    inspeccionesProximas: dataInspeccionesProximas,
                    onCompleted: getInspeccionesProximas,
                  ),
                ),
              ],
            ),
    );
  }
}
