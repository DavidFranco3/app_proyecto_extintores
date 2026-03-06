import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class FlushbarHelper {
  static void _show({
    required BuildContext context,
    required String message,
    String? title,
    required ToastificationType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flat,
      applyBlurEffect: true,
      title: title != null
          ? Text(title, style: const TextStyle(fontWeight: FontWeight.bold))
          : null,
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: duration,
      showProgressBar: false,
      borderRadius: BorderRadius.circular(12),
    );
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
        type: ToastificationType.success);
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
        type: ToastificationType.error);
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
        type: ToastificationType.warning);
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
        type: ToastificationType.info);
  }
}

// 🔄 Mantener compatibilidad con llamadas existentes
void showCustomFlushbar({
  required BuildContext context,
  required String title,
  required String message,
  required Color backgroundColor,
}) {
  ToastificationType type = ToastificationType.info;

  if (backgroundColor == Colors.green ||
      backgroundColor.value == Colors.green.value) {
    type = ToastificationType.success;
  } else if (backgroundColor == Colors.red ||
      backgroundColor.value == Colors.red.value) {
    type = ToastificationType.error;
  } else if (backgroundColor == Colors.orange ||
      backgroundColor.value == Colors.orange.value) {
    type = ToastificationType.warning;
  }

  toastification.show(
    context: context,
    type: type,
    style: ToastificationStyle.flat,
    applyBlurEffect: true,
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    description: Text(message),
    alignment: Alignment.topCenter,
    autoCloseDuration: const Duration(seconds: 3),
    showProgressBar: false,
    borderRadius: BorderRadius.circular(12),
    primaryColor: type == ToastificationType.info ? backgroundColor : null,
  );
}
