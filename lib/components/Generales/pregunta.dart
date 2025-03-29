class Pregunta {
  String titulo;
  String categoria;
  List<String> opciones;

  Pregunta(
      {required this.titulo, required this.categoria, required this.opciones});

  Map<String, dynamic> toJson() {
    return {
      "titulo": titulo,
      "categoria": categoria,
      "opciones": opciones,
    };
  }
}