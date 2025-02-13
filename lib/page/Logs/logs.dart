import 'package:flutter/material.dart';
import '../../api/logs.dart';
import '../../components/Logs/list_logs.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class LogsPage extends StatefulWidget {
  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataLogs = [];

  @override
  void initState() {
    super.initState();
    getLogs();
  }

  Future<void> getLogs() async {
    try {
      final logsService = LogsService();
      final List<dynamic> response =
          await logsService.listarLogs();

      if (response.isNotEmpty) {
        setState(() {
          dataLogs = formatModelLogs(response);
          loading = false;
        });
      } else {
        print('Error: La respuesta está vacía o no es válida.');
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      print("Error al obtener los logs: $e");
      setState(() {
        loading = false;
      });
    }
  }

  bool showModal = false; // Estado que maneja la visibilidad del modal

  // Función para formatear los datos de las logs
  List<Map<String, dynamic>> formatModelLogs(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'folio': item['folio'],
        'usuario': item['usuario'],
        'correo': item['correo'],
        'dispositivo': item['dispositivo'],
        'ip': item['ip'],
        'descripcion': item['descripcion'],
        'detalles': item['detalles']['mensaje'],
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
      drawer: MenuLateral(), // Usa el menú lateral
      body: loading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Logs",
                    style: TextStyle(
                      fontSize: 24, // Tamaño grande
                      fontWeight: FontWeight.bold, // Negrita
                    ),
                  ),
                ),
                Expanded(
                  child: TblLogs(
                    showModal: () {
                      Navigator.pop(
                          context); // Cierra el modal después de registrar
                    },
                    logs: dataLogs,
                    onCompleted:
                        getLogs, // Pasa la función para que se pueda llamar desde el componente
                  ),
                ),
              ],
            ),
    );
  }
}
