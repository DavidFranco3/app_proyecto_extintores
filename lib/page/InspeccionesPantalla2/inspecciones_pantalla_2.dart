import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/inspecciones.dart';
import '../../components/InspeccionesPantalla2/list_inspecciones_pantalla_2.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../InspeccionesPantalla1/inspecciones_pantalla_1.dart';

class InspeccionesPantalla2Page extends StatefulWidget {
  final VoidCallback showModal;
  final dynamic data;

  InspeccionesPantalla2Page({required this.showModal, required this.data});
  @override
  _InspeccionesPantalla2PageState createState() =>
      _InspeccionesPantalla2PageState();
}

class _InspeccionesPantalla2PageState extends State<InspeccionesPantalla2Page> {
  bool loading = true;
  bool isAscending = true; // Estado para controlar el orden de la lista
  List<Map<String, dynamic>> dataInspecciones = [];
  List<Map<String, dynamic>> filteredInspecciones = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getInspecciones();
  }

  Future<void> getInspecciones() async {
    try {
      final inspeccionesService = InspeccionesService();
      final List<dynamic> response = await inspeccionesService
          .listarInspeccionesPorCliente(widget.data["id"]);

      if (response.isNotEmpty) {
        setState(() {
          dataInspecciones = formatModelInspecciones(response);
          filteredInspecciones = List.from(dataInspecciones);
          loading = false;
        });
      } else {
        setState(() {
          dataInspecciones = [];
          filteredInspecciones = [];
          loading = false;
        });
      }
    } catch (e) {
      print("Error al obtener las inspecciones: $e");
      setState(() {
        loading = false;
      });
    }
  }

  void _filterInspecciones(String query) {
    setState(() {
      filteredInspecciones = dataInspecciones
          .where((inspeccion) => inspeccion['frecuencia']
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleOrder() {
    setState(() {
      isAscending = !isAscending;
      filteredInspecciones = List.from(filteredInspecciones.reversed);
    });
  }

  List<Map<String, dynamic>> formatModelInspecciones(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'idUsuario': item['idUsuario'],
        'idCliente': item['idCliente'],
        'idEncuesta': item['idEncuesta'],
        'encuesta': item['encuesta'],
        'imagenes': item['imagenes'],
        'comentarios': item['comentarios'],
        'usuario': item['usuario']['nombre'],
        'cliente': item['cliente']['nombre'],
        'imagen_cliente': item['cliente']['imagen'],
        'firma_usuario': item['usuario']['firma'],
        'cuestionario': item['cuestionario']['nombre'],
        'frecuencia': item['cuestionario']['frecuencia']['nombre'],
        'usuarios': item['usuario'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  // Función para abrir el modal de registro con el formulario de Acciones
  void returnPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InspeccionesPantalla1Page()),
    ).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Tabla Inspecciones"),
      body: loading
          ? Load()
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Inspecciones",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed:
                          returnPage, // Abre el modal con el formulario de acciones
                      icon: Icon(FontAwesomeIcons.arrowLeft),
                      label: Text("Volver"),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Cliente: ${widget.data["nombre"]}",
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: _filterInspecciones,
                          decoration: InputDecoration(
                            labelText: "Buscar periodo",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                        ),
                        onPressed: _toggleOrder,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TblInspeccionesPantalla2(
                    showModal: () {
                      Navigator.pop(context);
                    },
                    inspecciones: searchController.text.isEmpty
                        ? dataInspecciones
                        : filteredInspecciones,
                    onCompleted: getInspecciones,
                    data: widget.data
                  ),
                ),
              ],
            ),
    );
  }
}
