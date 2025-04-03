import 'package:intl/intl.dart';

// Función para formatear fechas
String formatDate(String date) {
  // Parseamos la fecha guardada en la base de datos
  final parsedDate = DateTime.parse(date);

  // Convertimos la fecha a la hora local
  final localDate = parsedDate.toLocal();

  // Ahora formateamos la fecha en formato de 12 horas (con AM/PM)
  final dateFormat = DateFormat('dd/MM/yyyy hh:mm:ss a'); // Formato 12 horas
  return dateFormat.format(localDate);
}
