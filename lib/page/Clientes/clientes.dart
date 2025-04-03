import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/clientes.dart';
import '../../components/Clientes/list_clientes.dart';
import '../../components/Clientes/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class ClientesPage extends StatefulWidget {
  @override
  _ClientesPageState createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataClientes = [];

  @override
  void initState() {
    super.initState();
    getClientes();
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

  bool showModal = false; // Estado que maneja la visibilidad del modal

  void openRegistroModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return Scaffold(
            body: Acciones(
              showModal: () {
                Navigator.pop(context); // Esto cerrará la página
              },
              onCompleted: getClientes,
              accion: "registrar",
              data: null,
            ),
          );
        },
      ),
    );
  }

// Cierra el modal
  void closeModal() {
    setState(() {
      showModal = false; // Cierra el modal
    });
  }

  // Función para formatear los datos de las clientes
  List<Map<String, dynamic>> formatModelClientes(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
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
      drawer: MenuLateral(currentPage: "Clientes"), // Usa el menú lateral
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
                      "Clientes",
                      style: TextStyle(
                        fontSize: 24, // Tamaño grande
                        fontWeight: FontWeight.bold, // Negrita
                      ),
                    ),
                  ),
                ),
                // Centra el botón de registrar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed:
                          openRegistroModal, // Abre el modal con el formulario de acciones
                      icon: Icon(FontAwesomeIcons.plus),
                      label: Text("Registrar"),
                    ),
                  ),
                ),
                Expanded(
                  child: TblClientes(
                    showModal: () {
                      Navigator.pop(
                          context); // Cierra el modal después de registrar
                    },
                    clientes: dataClientes,
                    onCompleted:
                        getClientes, // Pasa la función para que se pueda llamar desde el componente
                  ),
                ),
              ],
            ),
      // Modal: Se muestra solo si `showModal` es true
      floatingActionButton: showModal
          ? FloatingActionButton(
              onPressed: closeModal, // Cierra el modal
              child: Icon(Icons.close),
            )
          : null,
    );
  }
}
