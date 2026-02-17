// flushbar_helper.dart
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class FlushbarHelper {
  static void _show({
    required BuildContext context,
    required String message,
    String? title,
    required List<Color> gradientColors,
    required IconData icon,
    FlushbarPosition position = FlushbarPosition.TOP,
    Duration duration = const Duration(seconds: 3),
  }) {
    Flushbar<void>(
      titleText: title != null
          ? Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      messageText: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: Icon(
        icon,
        size: 28,
        color: Colors.white,
      ),
      shouldIconPulse: true,
      backgroundGradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          offset: const Offset(0, 4),
          blurRadius: 10,
        ),
      ],
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      flushbarPosition: position,
      duration: duration,
      forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
      reverseAnimationCurve: Curves.easeOut,
      isDismissible: true,
    ).show(context);
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
    String? title = 'Éxito',
  }) {
    _show(
      context: context,
      message: message,
      title: title,
      icon: Icons.check_circle_outline,
      gradientColors: [Colors.green.shade800, Colors.green.shade500],
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    String? title = 'Error',
  }) {
    _show(
      context: context,
      message: message,
      title: title,
      icon: Icons.error_outline,
      gradientColors: [Colors.red.shade900, Colors.red.shade600],
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    String? title = 'Advertencia',
  }) {
    _show(
      context: context,
      message: message,
      title: title,
      icon: Icons.warning_amber_outlined,
      gradientColors: [Colors.orange.shade800, Colors.orange.shade500],
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    String? title = 'Información',
  }) {
    _show(
      context: context,
      message: message,
      title: title,
      icon: Icons.info_outline,
      gradientColors: [Colors.blue.shade800, Colors.blue.shade500],
    );
  }
}

// 🔄 Mantener compatibilidad con llamadas existentes
void showCustomFlushbar({
  required BuildContext context,
  required String title,
  required String message,
  required Color backgroundColor,
}) {
  // Intentar mapear el color a un tipo si es posible, de lo contrario usar el estilo genérico
  List<Color> gradient;
  IconData icon;

  if (backgroundColor == Colors.green ||
      backgroundColor.toARGB32() == Colors.green.toARGB32()) {
    gradient = [Colors.green.shade800, Colors.green.shade500];
    icon = Icons.check_circle_outline;
  } else if (backgroundColor == Colors.red ||
      backgroundColor.toARGB32() == Colors.red.toARGB32()) {
    gradient = [Colors.red.shade900, Colors.red.shade600];
    icon = Icons.error_outline;
  } else if (backgroundColor == Colors.orange ||
      backgroundColor.toARGB32() == Colors.orange.toARGB32()) {
    gradient = [Colors.orange.shade800, Colors.orange.shade500];
    icon = Icons.warning_amber_outlined;
  } else {
    gradient = [backgroundColor, backgroundColor.withValues(alpha: 0.8)];
    icon = Icons.notifications_none;
  }

  Flushbar<void>(
    titleText: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    messageText: Text(
      message,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
    ),
    icon: Icon(icon, color: Colors.white, size: 28),
    shouldIconPulse: true,
    backgroundGradient: LinearGradient(colors: gradient),
    boxShadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        offset: const Offset(0, 4),
        blurRadius: 10,
      ),
    ],
    margin: const EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(16),
    flushbarPosition: FlushbarPosition.TOP,
    duration: const Duration(seconds: 3),
    forwardAnimationCurve: Curves.fastLinearToSlowEaseIn,
  ).show(context);
}
