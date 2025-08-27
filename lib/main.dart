import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart'; // Generado por FlutterFire CLI
import 'components/Login/login.dart';
import 'components/Home/home.dart';
import 'components/Generales/flushbar_helper.dart';
import 'api/auth.dart';
import 'api/tokens.dart';

// 🌎 Navigator global para diálogos y flushbar
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔔 Plugin de notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 📌 Manejo de notificaciones en segundo plano
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  print("📌 [BACKGROUND] Notificación recibida: ${message.notification?.title}");
}

// 📌 Configuración de notificaciones locales
Future<void> configurarNotificacionesLocales() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

  const InitializationSettings settings =
      InitializationSettings(android: androidSettings, iOS: iosSettings);

  await flutterLocalNotificationsPlugin.initialize(settings);
}

// 📌 Mostrar notificación local
Future<void> mostrarNotificacionLocal(String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'canal_id',
    'canal_nombre',
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
}

// 📌 Mostrar alerta dentro de la app
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

// 📌 Obtener datos comunes del usuario
Future<Map<String, dynamic>> obtenerDatosComunes(String token) async {
  try {
    final authService = AuthService();
    final idUsuario = await authService.obtenerIdUsuarioLogueado(token);
    print('ID Usuario obtenido: $idUsuario');
    return {'idUsuario': idUsuario};
  } catch (e) {
    print('Error al obtener datos comunes: $e');
    rethrow;
  }
}

// 📌 Obtener y almacenar token FCM
Future<void> obtenerTokenFCM() async {
  try {
    final String? tokenn = await AuthService().getTokenApi();
    print('Token obtenido para logout: $tokenn');

    if (tokenn == null) throw Exception("Token de autenticación es nulo");

    final datosComunes = await obtenerDatosComunes(tokenn);

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Inicializar Firebase multiplataforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔄 Configurar notificaciones locales
  await configurarNotificacionesLocales();

  // 🔔 Configurar FCM background
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  // 📌 Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('isLoggedIn')) await prefs.setBool('isLoggedIn', false);
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // 📌 Inicializar FCM
  await obtenerTokenFCM();

  // 📌 Escuchar notificaciones en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 [FOREGROUND] Notificación recibida: ${message.notification?.title}");
    mostrarNotificacionLocal(
      message.notification?.title ?? "Sin título",
      message.notification?.body ?? "Sin mensaje",
    );
    mostrarAlertaNotificacion(
      message.notification?.title ?? "Notificación",
      message.notification?.body ?? "Mensaje",
    );
  });

  // 📌 Notificación al abrir la app desde segundo plano
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print(
        "📩 [BACKGROUND] Notificación abierta por el usuario: ${message.notification?.title}");
  });

  // 📦 Inicializar Hive
  await Hive.initFlutter();
  final boxes = [
    'clientesBox', 'reporteFinalBox', 'clasificacionesBox', 'encuestasBox',
    'extintoresBox', 'frecuenciasBox', 'inspeccionesBox', 'inspeccionAnualBox',
    'inspeccionesProximasBox', 'inspeccionesInspectorBox', 'logsBox', 'tokensBox',
    'ramasBox', 'tiposExtintoresBox', 'usuariosBox',
    'operacionesOfflineClasificaciones', 'operacionesOfflineExtintores',
    'operacionesOfflineEncuestas', 'operacionesOfflineFrecuencias',
    'operacionesOfflineRamas', 'operacionesOfflineTiposExtintores',
    'operacionesOfflineInspecciones', 'operacionesOfflineInspeccionAnual',
    'operacionesOfflineClientes', 'operacionesOfflineUsuarios',
    'operacionesOfflineReportes', 'encuestasPendientes', 'operacionesOfflinePreguntas'
  ];

  for (var box in boxes) {
    await Hive.openBox(box);
  }

  // 🚀 Ejecutar app
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      supportedLocales: const [Locale('es', 'ES')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('es', 'ES'),
      home: isLoggedIn ? HomePage() : LoginPage(),
    );
  }
}
