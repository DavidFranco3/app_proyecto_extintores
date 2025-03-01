import 'package:flutter/material.dart';
import '../../api/inspecciones_proximas.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/calendario.dart'; // Importa el componente Calendario
import '../../components/Generales/event.dart';

class ProgramaInspeccionesPage extends StatefulWidget {
  @override
  _ProgramaInspeccionesPageState createState() =>
      _ProgramaInspeccionesPageState();
}

class _ProgramaInspeccionesPageState extends State<ProgramaInspeccionesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspeccionesProximas = [];
  late List<Event> eventosCalendario = [];

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

      if (response.isNotEmpty) {
        setState(() {
          dataInspeccionesProximas = formatModelInspeccionesProximas(response);
          eventosCalendario = _convertirAEventosCalendario(dataInspeccionesProximas);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataInspeccionesProximas = [];
          loading = false;
        });
      }
    } catch (e) {
      print("Error al obtener las inspeccionesProximas: $e");
      setState(() {
        loading = false;
      });
    }
  }

  // Convierte los datos de inspecciones próximas en una lista de eventos
  List<Event> _convertirAEventosCalendario(List<Map<String, dynamic>> data) {
    List<Event> eventos = [];

    for (var item in data) {
      DateTime fechaInspeccion = DateTime.parse(item['proximaInspeccion']);
      String evento = "Cliente: ${item['cliente']} - Inspeccion: ${item['cuestionario']}";

      // Crear un nuevo objeto Event
      eventos.add(Event(title: evento, date: fechaInspeccion));
    }

    return eventos;
  }

  List<Map<String, dynamic>> formatModelInspeccionesProximas(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'idFrecuencia': item['idFrecuencia'],
        'idCliente': item['idCliente'],
        'idEncuesta': item['idEncuesta'],
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
      drawer: MenuLateral(currentPage: "Programa de Inspección"), // Menú lateral
      body: loading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : Column(
              children: [
                // Título de la página
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Programa de inspecciones",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Aquí usamos el componente Calendario
                Expanded(
                  child: Calendario(
                    eventosIniciales: eventosCalendario, // Pasamos los eventos al calendario
                  ),
                ),
              ],
            ),
    );
  }
}
