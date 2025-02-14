import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/tipos_extintores.dart';
import '../../components/TiposExtintores/list_tipos_extintores.dart';
import '../../components/TiposExtintores/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class TiposExtintoresPage extends StatefulWidget {
  @override
  _TiposExtintoresPageState createState() => _TiposExtintoresPageState();
}

class _TiposExtintoresPageState extends State<TiposExtintoresPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataTiposExtintores = [];

  @override
  void initState() {
    super.initState();
    getTiposExtintores();
  }

  Future<void> getTiposExtintores() async {
    try {
      final tiposExtintoresService = TiposExtintoresService();
      final List<dynamic> response = await tiposExtintoresService.listarTiposExtintores();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataTiposExtintores = formatModelTiposExtintores(response);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          dataTiposExtintores = [];
        });
      }
    } catch (e) {
      print("Error al obtener las tiposExtintores: $e");
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
                  'Registrar tipo de extintor',
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
              // Ajusta la altura según el contenido
              child: Acciones(
                showModal: () {
                  Navigator.pop(context); // Esto cierra el modal
                },
                onCompleted: getTiposExtintores,
                accion: "registrar",
                data: null,
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

  // Función para formatear los datos de las tiposExtintores
  List<Map<String, dynamic>> formatModelTiposExtintores(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'descripcion': item['descripcion'],
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
        currentPage: "Tipos de extintores",
      ), // Usa el menú lateral
      body: loading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Tipos de extintores",
                      style: TextStyle(
                        fontSize: 24, // Tamaño grande
                        fontWeight: FontWeight.bold, // Negrita
                      ),
                    ),
                  ),
                ),
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
                  child: TblTiposExtintores(
                    showModal: () {
                      Navigator.pop(context); // Esto cierra el modal
                    },
                    tiposExtintores: dataTiposExtintores,
                    onCompleted: getTiposExtintores,
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
