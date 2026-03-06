import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/clientes_controller.dart';
import '../controllers/ramas_controller.dart';
import '../controllers/frecuencias_controller.dart';
import '../controllers/clasificaciones_controller.dart';
import '../controllers/extintores_controller.dart';
import '../controllers/tipos_extintores_controller.dart';
import '../controllers/inspecciones_proximas_controller.dart';
import '../controllers/logs_controller.dart';
import '../controllers/usuarios_controller.dart';
import '../controllers/encuestas_controller.dart';
import '../controllers/inspecciones_controller.dart';

export '../controllers/home_controller.dart';
export '../controllers/theme_controller.dart';

// Definición de todos los providers de la aplicación para Riverpod
// Estos reemplazan a los definidos en el MultiProvider de Provider

// NOTA: HomeController ya tiene homeProvider y ThemeController ya es NotifierProvider
// Por organización, los importamos aquí o los usamos directamente pero los otros controllers
// que extienden BaseController/ChangeNotifier los definimos acá

final clientesProvider =
    ChangeNotifierProvider<ClientesController>((ref) => ClientesController());
final ramasProvider =
    ChangeNotifierProvider<RamasController>((ref) => RamasController());
final frecuenciasProvider = ChangeNotifierProvider<FrecuenciasController>(
    (ref) => FrecuenciasController());
final clasificacionesProvider =
    ChangeNotifierProvider<ClasificacionesController>(
        (ref) => ClasificacionesController());
final extintoresProvider = ChangeNotifierProvider<ExtintoresController>(
    (ref) => ExtintoresController());
final tiposExtintoresProvider =
    ChangeNotifierProvider<TiposExtintoresController>(
        (ref) => TiposExtintoresController());
final inspeccionesProximasProvider =
    ChangeNotifierProvider<InspeccionesProximasController>(
        (ref) => InspeccionesProximasController());
final logsProvider =
    ChangeNotifierProvider<LogsController>((ref) => LogsController());
final usuariosProvider =
    ChangeNotifierProvider<UsuariosController>((ref) => UsuariosController());
final encuestasProvider =
    ChangeNotifierProvider<EncuestasController>((ref) => EncuestasController());
final inspeccionesProvider = ChangeNotifierProvider<InspeccionesController>(
    (ref) => InspeccionesController());
