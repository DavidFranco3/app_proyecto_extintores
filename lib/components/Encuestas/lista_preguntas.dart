import 'package:flutter/material.dart';
import 'package:prueba/components/Header/header.dart';
import 'package:prueba/components/Menu/menu_lateral.dart';
import '../Load/load.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class PreguntasVisualPage extends StatefulWidget {
  final VoidCallback showModal;
  final Function onCompleted;
  final String accion;
  final dynamic data;

  PreguntasVisualPage({
    required this.showModal,
    required this.onCompleted,
    required this.accion,
    required this.data,
  });

  @override
  _PreguntasVisualPageState createState() => _PreguntasVisualPageState();
}

class _PreguntasVisualPageState extends State<PreguntasVisualPage> {
  bool _isLoading = true;
  late Map<String, List<dynamic>> preguntasPorCategoria;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 300), () {
      final List<dynamic> preguntas = widget.data['preguntas'] ?? [];

      // Agrupar dinámicamente por categoría
      preguntasPorCategoria = {};
      for (var pregunta in preguntas) {
        final categoria = pregunta["categoria"] ?? "Sin categoría";
        preguntasPorCategoria[categoria] =
            preguntasPorCategoria[categoria] ?? [];
        preguntasPorCategoria[categoria]!.add(pregunta);
      }

      setState(() {
        _isLoading = false;
      });
    });
  }

  void closeRegistroModal() {
    widget.showModal(); // Llama a setShow con el valor booleano
    widget.onCompleted();
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Crear inspección"),
      body: _isLoading
          ? Load()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'Lista de preguntas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: closeRegistroModal,
                          icon: Icon(FontAwesomeIcons.arrowLeft),
                          label: _isLoading
                              ? SpinKitFadingCircle(
                                  color: const Color.fromARGB(255, 241, 8, 8),
                                  size: 24,
                                )
                              : Text("Regresar"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...preguntasPorCategoria.entries.map((entry) {
                    final categoria = entry.key;
                    final preguntas = entry.value;

                    return ExpansionTile(
                      title: Text(
                        categoria,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: preguntas.map<Widget>((pregunta) {
                        final opciones = pregunta['opciones'] ?? [];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pregunta['titulo'] ?? 'Sin título',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: 4),
                              Wrap(
                                spacing: 10,
                                children: opciones
                                    .map<Widget>((opcion) => Chip(
                                          label: Text(opcion.toString()),
                                        ))
                                    .toList(),
                              ),
                              Divider(),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}
