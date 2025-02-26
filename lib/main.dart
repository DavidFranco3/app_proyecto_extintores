import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'components/Login/login.dart';
import 'components/Home/home.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// 📌 Clave global para manejar el contexto en los diálogos
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 📌 Inicializar `flutter_local_notifications`
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 📌 Manejo de notificaciones en segundo plano o cerrada
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  print("📌 [BACKGROUND] Notificación recibida: ${message.notification?.title}");
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
    print("📩 [FOREGROUND] Notificación recibida: ${message.notification?.title}");

    // 📌 Mostrar notificación en la barra de estado
    mostrarNotificacionLocal(
      message.notification?.title ?? "Sin título",
      message.notification?.body ?? "Sin mensaje"
    );

    // 📌 Mostrar alerta en la app
    mostrarAlertaNotificacion(
      message.notification?.title ?? "Notificación",
      message.notification?.body ?? "Mensaje"
    );
  });

  // 📩 Manejar notificación cuando la app se abre desde el segundo plano
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📩 [BACKGROUND] Notificación abierta por el usuario: ${message.notification?.title}");
  });

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

// 📌 Obtener y almacenar el token FCM
Future<void> obtenerTokenFCM() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print("📌 Token FCM obtenido y guardado: $token");
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
    'canal_id', 'canal_nombre',
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
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Aceptar"),
            )
          ],
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,  // 📌 Necesario para mostrar alertas sin problemas
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
