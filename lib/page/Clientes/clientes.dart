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

      if (response.isNotEmpty) {
        setState(() {
          dataClientes = formatModelClientes(response);
          loading = false;
        });
      } else {
        print('Error: La respuesta está vacía o no es válida.');
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      print("Error al obtener las clientes: $e");
      setState(() {
        loading = false;
      });
    }
  }

  bool showModal = false; // Estado que maneja la visibilidad del modal

  // Función para abrir el modal de registro con el formulario de Acciones
  void openRegistroModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Registrar cliente',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: IntrinsicHeight(
              child: GestureDetector(
                onTap: () {
                  // Cierra el teclado si se toca fuera de un campo de texto
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Acciones(
                  showModal: () {
                    Navigator.pop(
                        context); // Cierra el modal después de registrar
                  },
                  onCompleted: getClientes,
                  accion: "registrar",
                  data: null,
                ),
              ),
            ),
          ),
          // Permite que el teclado ajuste el contenido en la pantalla
          scrollable: true,
        );
      },
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
