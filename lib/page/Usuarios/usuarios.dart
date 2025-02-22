import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/usuarios.dart';
import '../../components/Usuarios/list_usuarios.dart';
import '../../components/Usuarios/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class UsuariosPage extends StatefulWidget {
  @override
  _UsuariosPageState createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataUsuarios = [];

  @override
  void initState() {
    super.initState();
    getUsuarios();
  }

  Future<void> getUsuarios() async {
    try {
      final usuariosService = UsuariosService();
      final List<dynamic> response =
          await usuariosService.listarUsuarios();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataUsuarios = formatModelUsuarios(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataUsuarios = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      print("Error al obtener las usuarios: $e");
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
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
                  'Registrar Usuario',
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
              child: Column(
                children: [
                  // Aquí agregamos un widget GestureDetector para que cuando el usuario toque fuera del formulario, el teclado se cierre.
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context)
                          .unfocus(); // Cierra el teclado al tocar fuera
                    },
                    child: Acciones(
                      showModal: () {
                        Navigator.pop(context); // Esto cierra el modal
                      },
                      onCompleted: getUsuarios,
                      accion: "registrar",
                      data: null,
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  // Función para formatear los datos de las usuarios
  List<Map<String, dynamic>> formatModelUsuarios(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'email': item['email'],
        'telefono': item['telefono'],
        'tipo': item['tipo'],
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
      drawer:
          MenuLateral(currentPage: "Usuarios"), // Usa el menú lateral
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
                      "Usuarios",
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
                  child: TblUsuarios(
                    showModal: () {
                      Navigator.pop(context); // Esto cierra el modal
                    },
                    usuarios: dataUsuarios,
                    onCompleted: getUsuarios,
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
