import 'package:flutter/material.dart';

class Load extends StatefulWidget {
  @override
  _LoadState createState() => _LoadState();
}

class _LoadState extends State<Load> {
  double _opacity = 0.0; // Inicialmente invisible

  @override
  void initState() {
    super.initState();
    // Inicia la animación de opacidad después de un pequeño retraso
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _opacity = 1.0; // Se hace completamente visible
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Fondo transparente
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: Duration(seconds: 1), // Duración de la animación
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5), // Fondo oscuro semi-transparente
              ),
            ),
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 6, // Grosor del círculo
              ),
            ),
          ],
        ),
      ),
    );
  }
}
