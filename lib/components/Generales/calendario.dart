import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import './event.dart'; // Asegúrate de que este archivo exista y contenga la clase Event
import 'package:intl/intl.dart';

class Calendario extends StatefulWidget {
  final List<Event> eventosIniciales;

  Calendario({required this.eventosIniciales});

  @override
  _CalendarioState createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat =
      CalendarFormat.month; // Inicialmente mostramos el mes

  String formatDate(DateTime date) {
    // Formateamos la fecha en formato 'dd/MM/yyyy'
    final dateFormat = DateFormat('dd/MM/yyyy');
    return dateFormat.format(date);
  }

  // Cambiar el formato de la vista (día, mes, año)
  void _changeCalendarFormat(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calcular el primer y último día según el año actual
    DateTime now = DateTime.now();
    DateTime firstDay =
        DateTime(now.year - 10, now.month, now.day); // 10 años antes
    DateTime lastDay =
        DateTime(now.year + 10, now.month, now.day); // 10 años después

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TableCalendar<Event>(
              locale: 'ES_ES', // Configura el idioma a español
              firstDay: firstDay, // 10 años antes
              lastDay: lastDay, // 10 años después
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(day, _selectedDay);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; // Actualiza el día enfocado
                });
              },
              eventLoader: (day) {
                // Devuelve los eventos para un día específico
                return widget.eventosIniciales
                    .where((event) => isSameDay(event.date, day))
                    .toList();
              },
              headerStyle: HeaderStyle(
                formatButtonVisible:
                    false, // Ocultar el botón de formato de vista
                titleTextStyle: TextStyle(fontSize: 20),
                leftChevronIcon: Icon(Icons.chevron_left),
                rightChevronIcon: Icon(Icons.chevron_right),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue, // Color del día actual
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.green, // Color del día seleccionado
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1, // Limitar a 1 marcador por día
                markerDecoration: BoxDecoration(
                  color: Colors.transparent, // Sin marcador extra
                  shape: BoxShape.circle,
                ),
              ),
              calendarFormat:
                  _calendarFormat, // Controla la vista actual (mes, semana, 2 semanas)
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final eventsForDay = widget.eventosIniciales
                      .where((event) => isSameDay(event.date, day))
                      .toList();
                  if (eventsForDay.isNotEmpty) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors
                            .orange, // Fondo naranja para días con eventos
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: Colors.white, // Color del texto
                          ),
                        ),
                      ),
                    );
                  } else {
                    return null; // Si no hay eventos, mostramos el día normal
                  }
                },
              ),
            ),
            // Mostrar eventos solo del día seleccionado
            Expanded(
              child: ListView(
                children: widget.eventosIniciales
                    .where((event) => isSameDay(event.date, _selectedDay))
                    .map((event) => ListTile(
                          title: Text(event.title),
                          subtitle: Text(formatDate(event.date)),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
