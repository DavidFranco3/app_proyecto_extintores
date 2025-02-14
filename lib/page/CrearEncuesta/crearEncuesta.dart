import 'package:flutter/material.dart';

class CrearEncuestaScreen extends StatefulWidget {
  @override
  _CrearEncuestaScreenState createState() => _CrearEncuestaScreenState();
}

class _CrearEncuestaScreenState extends State<CrearEncuestaScreen> {
  List<Pregunta> preguntas = [];
  TextEditingController preguntaController = TextEditingController();
  TextEditingController opcionController = TextEditingController();
  List<String> opcionesTemp = [];

  void _agregarPregunta() {
    if (preguntaController.text.isNotEmpty && opcionesTemp.isNotEmpty) {
      setState(() {
        preguntas.add(Pregunta(
          titulo: preguntaController.text,
          opciones: List.from(opcionesTemp),
        ));
        preguntaController.clear();
        opcionesTemp.clear();
      });
    }
  }

  void _agregarOpcion() {
    if (opcionController.text.isNotEmpty) {
      setState(() {
        opcionesTemp.add(opcionController.text);
        opcionController.clear();
      });
    }
  }

  void _eliminarOpcion(int index) {
    setState(() {
      opcionesTemp.removeAt(index);
    });
  }

  void _eliminarPregunta(int index) {
    setState(() {
      preguntas.removeAt(index);
    });
  }

  void _publicarEncuesta() {
    print("Encuesta creada con ${preguntas.length} preguntas.");
    for (var pregunta in preguntas) {
      print("Pregunta: ${pregunta.titulo}");
      for (var opcion in pregunta.opciones) {
        print("   - $opcion");
      }
    }
    // Aquí podrías enviar la encuesta a Firebase o guardarla localmente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Crear Encuesta")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: preguntaController,
              decoration: InputDecoration(labelText: "Pregunta"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: opcionController,
              decoration: InputDecoration(labelText: "Opción"),
              onSubmitted: (_) => _agregarOpcion(),
            ),
            ElevatedButton(
              onPressed: _agregarOpcion,
              child: Text("Agregar Opción"),
            ),
            Wrap(
              spacing: 8.0,
              children: opcionesTemp
                  .asMap()
                  .entries
                  .map(
                    (entry) => Chip(
                      label: Text(entry.value),
                      onDeleted: () => _eliminarOpcion(entry.key),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _agregarPregunta,
              child: Text("Agregar Pregunta"),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: preguntas.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      title: Text(preguntas[index].titulo),
                      subtitle: Text(preguntas[index].opciones.join(", ")),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarPregunta(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _publicarEncuesta,
              child: Text("Publicar Encuesta"),
            ),
          ],
        ),
      ),
    );
  }
}

class Pregunta {
  String titulo;
  List<String> opciones;

  Pregunta({required this.titulo, required this.opciones});
}
