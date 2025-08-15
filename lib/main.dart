import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'components/Login/login.dart';
import 'components/Home/home.dart';
import 'api/auth.dart';
import 'api/tokens.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'components/Generales/flushbar_helper.dart';
import 'package:hive_flutter/hive_flutter.dart';

// 📌 Clave global para manejar el contexto en los diálogos
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 📌 Inicializar `flutter_local_notifications`
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 📌 Manejo de notificaciones en segundo plano o cerrada
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  print(
      "📌 [BACKGROUND] Notificación recibida: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // 🔥 Inicializar Firebase

  // 🔄 Configurar notificaciones locales
  await configurarNotificacionesLocales();

  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('isLoggedIn')) {
    await prefs.setBool('isLoggedIn', false);
  }
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // 📌 Obtener el token FCM
  await obtenerTokenFCM();

  // 📩 Escuchar notificaciones en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print(
        "📩 [FOREGROUND] Notificación recibida: ${message.notification?.title}");

    // 📌 Mostrar notificación en la barra de estado
    mostrarNotificacionLocal(message.notification?.title ?? "Sin título",
        message.notification?.body ?? "Sin mensaje");

    // 📌 Mostrar alerta en la app
    mostrarAlertaNotificacion(message.notification?.title ?? "Notificación",
        message.notification?.body ?? "Mensaje");
  });

  // 📩 Manejar notificación cuando la app se abre desde el segundo plano
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print(
        "📩 [BACKGROUND] Notificación abierta por el usuario: ${message.notification?.title}");
  });

  runApp(MyApp(isLoggedIn: isLoggedIn));
  await Hive.initFlutter();
  await Hive.openBox('clientesBox');
  await Hive.openBox('reporteFinalBox');
  await Hive.openBox('clasificacionesBox');
  await Hive.openBox('encuestasBox');
  await Hive.openBox('extintoresBox');
  await Hive.openBox('frecuenciasBox');
  await Hive.openBox('inspeccionesBox');
  await Hive.openBox('inspeccionAnualBox');
  await Hive.openBox('inspeccionesProximasBox');
  await Hive.openBox('inspeccionesInspectorBox');
  await Hive.openBox('logsBox');
  await Hive.openBox('tokensBox');
  await Hive.openBox('ramasBox');
  await Hive.openBox('tiposExtintoresBox');
  await Hive.openBox('usuariosBox');
  await Hive.openBox('operacionesOfflineClasificaciones');
  await Hive.openBox('operacionesOfflineExtintores');
  await Hive.openBox('operacionesOfflineEncuestas');
  await Hive.openBox('operacionesOfflineFrecuencias');
  await Hive.openBox('operacionesOfflineRamas');
  await Hive.openBox('operacionesOfflineTiposExtintores');
  await Hive.openBox('operacionesOfflineInspecciones');
  await Hive.openBox('operacionesOfflineInspeccionAnual');
  await Hive.openBox('operacionesOfflineClientes');
  await Hive.openBox('operacionesOfflineUsuarios');
  await Hive.openBox('operacionesOfflineReportes');
  await Hive.openBox('encuestasPendientes');
  await Hive.openBox('operacionesOfflinePreguntas');
}

Future<Map<String, dynamic>> obtenerDatosComunes(String token) async {
  try {
    final authService = AuthService();

    // Obtener el id del usuario
    final idUsuario = await authService.obtenerIdUsuarioLogueado(token);
    print('ID Usuario obtenido: $idUsuario');

    return {'idUsuario': idUsuario};
  } catch (e) {
    print('Error al obtener datos comunes: $e');
    rethrow; // Lanza el error para que lo maneje la función que lo llamó
  }
}

// 📌 Obtener y almacenar el token FCM
Future<void> obtenerTokenFCM() async {
  try {
    final String? tokenn = await AuthService().getTokenApi();
    print('Token obtenido para logout: $tokenn');

    // Forzar que el token no sea null
    if (tokenn == null) {
      throw Exception("Token de autenticación es nulo");
    }

    // Obtener los datos comunes utilizando el token
    final datosComunes = await obtenerDatosComunes(tokenn);
    print('Datos comunes obtenidos para logout: $datosComunes');

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    var formData = {
      "idUsuario": datosComunes["idUsuario"],
      "token": token,
      "estado": "true"
    };

    final tokensService = TokensService();

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print("📌 Token FCM obtenido y guardado: $token");
      tokensService.registraTokens(formData);
    } else {
      print("❌ No se pudo obtener el token de FCM.");
    }
  } catch (e) {
    print("❌ Error al obtener el token de FCM: $e");
  }
}

// 📌 Configurar notificaciones locales
Future<void> configurarNotificacionesLocales() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();

  const InitializationSettings settings =
      InitializationSettings(android: androidSettings, iOS: iosSettings);

  await flutterLocalNotificationsPlugin.initialize(settings);
}

// 📌 Mostrar una notificación en la barra de estado
void mostrarNotificacionLocal(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'canal_id',
    'canal_nombre',
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // ID de la notificación
    title,
    body,
    platformChannelSpecifics,
  );
}

// 📌 Mostrar alerta de notificación dentro de la app
void mostrarAlertaNotificacion(String title, String body) {
  if (navigatorKey.currentContext != null) {
    showCustomFlushbar(
      context: navigatorKey.currentContext!,
      title: title,
      message: body,
      backgroundColor: Colors.green,
    );
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Utilizando el navigator global
      debugShowCheckedModeBanner: false,
      supportedLocales: [
        Locale('es', 'ES'), // Español
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: Locale('es', 'ES'),
      home: isLoggedIn ? HomePage() : LoginPage(),
    );
  }
}
