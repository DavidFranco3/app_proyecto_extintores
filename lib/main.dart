import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart'; // Generado por FlutterFire CLI
import 'components/Login/login.dart';
import 'components/Home/home.dart';
import 'components/Generales/flushbar_helper.dart';
import 'api/auth.dart';
import 'api/tokens.dart';
import 'utils/offline_sync_util.dart';
import 'providers/app_providers.dart';

// 🌎 Navigator global para diálogos y flushbar
import 'utils/globals.dart';

// 🔔 Plugin de notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 📌 Manejo de notificaciones en segundo plano
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  debugPrint(
      "📌 [BACKGROUND] Notificación recibida: ${message.notification?.title}");
}

// 📌 Configuración de notificaciones locales
Future<void> configurarNotificacionesLocales() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();

  const InitializationSettings settings =
      InitializationSettings(android: androidSettings, iOS: iosSettings);

  await flutterLocalNotificationsPlugin.initialize(settings: settings);
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

  await flutterLocalNotificationsPlugin.show(
      id: 0, title: title, body: body, notificationDetails: platformDetails);
}

// 📌 Mostrar alerta dentro de la app
void mostrarAlertaNotificacion(String title, String body) {
  if (navigatorKey.currentContext != null) {
    if (navigatorKey.currentContext!.mounted) {
      showCustomFlushbar(
        context: navigatorKey.currentContext!,
        title: title,
        message: body,
        backgroundColor: Colors.green,
      );
    }
  }
}

// 📌 Obtener datos comunes del usuario
Future<Map<String, dynamic>> obtenerDatosComunes(String token) async {
  try {
    final authService = AuthService();
    final idUsuario = authService.obtenerIdUsuarioLogueado(token);
    debugPrint('ID Usuario obtenido: $idUsuario');
    return {'idUsuario': idUsuario};
  } catch (e) {
    debugPrint('Error al obtener datos comunes: $e');
    rethrow;
  }
}

// 📌 Obtener y almacenar token FCM
Future<void> obtenerTokenFCM() async {
  try {
    final String? tokenn = await AuthService().getTokenApi();
    debugPrint('Token obtenido para logout: $tokenn');

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
      final box = Hive.box('settingsBox');
      await box.put('fcm_token', token);
      debugPrint("📌 Token FCM obtenido y guardado: $token");
      tokensService.registraTokens(formData);
    } else {
      debugPrint("❌ No se pudo obtener el token de FCM.");
    }
  } catch (e) {
    debugPrint("❌ Error al obtener el token de FCM: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📦 Inicializar Hive
  await Hive.initFlutter();
  final boxes = [
    'clientesBox',
    'reporteFinalBox',
    'clasificacionesBox',
    'encuestasBox',
    'extintoresBox',
    'frecuenciasBox',
    'inspeccionesBox',
    'inspeccionAnualBox',
    'inspeccionesProximasBox',
    'inspeccionesInspectorBox',
    'logsBox',
    'tokensBox',
    'ramasBox',
    'tiposExtintoresBox',
    'usuariosBox',
    'operacionesOfflineClasificaciones',
    'operacionesOfflineExtintores',
    'operacionesOfflineEncuestas',
    'operacionesOfflineFrecuencias',
    'operacionesOfflineRamas',
    'operacionesOfflineTiposExtintores',
    'operacionesOfflineInspecciones',
    'operacionesOfflineInspeccionAnual',
    'operacionesOfflineClientes',
    'operacionesOfflineUsuarios',
    'operacionesOfflineReportes',
    'encuestasPendientes',
    'operacionesOfflinePreguntas',
    'offline_queue',
    'settingsBox'
  ];

  for (var boxName in boxes) {
    await Hive.openBox(boxName);
  }

  // 🔥 Inicializar Firebase multiplataforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔄 Configurar notificaciones locales
  await configurarNotificacionesLocales();

  // 🔔 Configurar FCM background
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  // 📌 Inicializar Hive settings
  final box = Hive.box('settingsBox');
  if (!box.containsKey('isLoggedIn')) {
    await box.put('isLoggedIn', false);
  }
  final bool isLoggedIn = box.get('isLoggedIn') ?? false;

  // 📌 Inicializar FCM solo si hay sesión activa (No bloqueante para evitar cuelgues)
  if (isLoggedIn) {
    obtenerTokenFCM();
  }

  // 📌 Escuchar notificaciones en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint(
        "📩 [FOREGROUND] Notificación recibida: ${message.notification?.title}");
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
    debugPrint(
        "📩 [BACKGROUND] Notificación abierta por el usuario: ${message.notification?.title}");
  });

  // 🛠 Inicializar Util de Sincronización Offline
  OfflineSyncUtil().init();

  // 🚀 Ejecutar app
  runApp(
    ProviderScope(
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Sincronizar al iniciar si hay internet
    OfflineSyncUtil().sincronizarTodo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("📱 App resumida - Iniciando Sincronización Proactiva");
      OfflineSyncUtil().sincronizarTodo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Prueba Extintores',
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFE94742),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE94742),
          primary: const Color(0xFFE94742),
          secondary: const Color(0xFF2C3E50),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2C3E50),
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE94742),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE94742),
          brightness: Brightness.dark,
          primary: const Color(0xFFE94742),
          secondary: const Color(0xFF94A3B8),
          surface: const Color(0xFF1E293B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      supportedLocales: const [Locale('es', 'ES')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('es', 'ES'),
      home: widget.isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}
