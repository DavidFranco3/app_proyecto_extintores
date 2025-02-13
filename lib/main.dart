import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/Login/login.dart';
import 'components/Home/home.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Para la localización

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Establecer un valor predeterminado si no existe
  if (!prefs.containsKey('isLoggedIn')) {
    await prefs.setBool('isLoggedIn', false);
  }

  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Agregar soporte para español en la aplicación
      supportedLocales: [
        Locale('es', 'ES'), // Español
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Establecer el idioma en español
      locale: Locale('es', 'ES'),
      home: isLoggedIn ? HomePage() : LoginPage(),
    );
  }
}
