// flushbar_helper.dart
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

void showCustomFlushbar({
  required BuildContext context,
  required String title,
  required String message,
  required Color backgroundColor,
}) {
  Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    backgroundColor: backgroundColor,
    duration: Duration(seconds: 3),
    titleText: Center(
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    ),
    messageText: Center(
      child: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  ).show(context);
}
