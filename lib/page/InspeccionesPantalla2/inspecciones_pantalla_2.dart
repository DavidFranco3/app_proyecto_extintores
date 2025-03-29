import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/inspecciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../InspeccionesPantalla1/inspecciones_pantalla_1.dart';
import 'package:intl/intl.dart';
import '../Inspecciones/inspecciones.dart';

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

  // Función para formatear fechas
  String formatDate(String date) {
    // Establecer el idioma a español
    Intl.defaultLocale = 'es_ES'; // Configuramos la localización a español

    // Parseamos la fecha guardada en la base de datos
    final parsedDate = DateTime.parse(date);

    // Convertimos la fecha a la hora local
    final localDate = parsedDate.toLocal();

    // Ahora formateamos la fecha en formato Día de Mes del Año
    final dateFormat = DateFormat('d MMMM yyyy'); // Formato Día de Mes del Año
    return dateFormat.format(localDate); // Ejemplo: 17 de Marzo del 2025
  }

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

  // Función para abrir el modal de registro con el formulario de Acciones
  void openPantalla2Page(Map<String, dynamic> row) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => InspeccionesPage(
              showModal: () {
                Navigator.pop(context); // Esto cierra el modal
              },
              data: row,
              data2: widget.data)),
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
                      label: Text("Regresar"),
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
                  child: ListView.builder(
                    itemCount: searchController.text.isEmpty
                        ? dataInspecciones.length
                        : filteredInspecciones.length,
                    itemBuilder: (context, index) {
                      var inspeccion = searchController.text.isEmpty
                          ? dataInspecciones[index]
                          : filteredInspecciones[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        child: SizedBox(
                          width: double
                              .infinity, // Hace que el botón ocupe todo el ancho disponible
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Bordes redondeados
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical:
                                      16), // Aumenta el tamaño vertical del botón
                            ),
                            onPressed: () =>
                                {openPantalla2Page(inspeccion)},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceBetween, // Espacio entre texto y el ícono
                              children: [
                                Expanded(
                                  child: Text(
                                    "${inspeccion['frecuencia']}: ${formatDate(inspeccion['createdAt'])}",
                                    textAlign:
                                        TextAlign.center, // Centra el texto
                                    style: TextStyle(
                                      fontSize: 16, // Tamaño de texto
                                      color: Colors
                                          .black, // Color de las letras (negro)
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons
                                      .chevron_right, // Icono que aparece a la derecha
                                  size: 24, // Tamaño del ícono
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
