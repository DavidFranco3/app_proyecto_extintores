import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BasicModal extends StatelessWidget {
  final bool show;
  final Function setShow;
  final String title;
  final Widget child;
  final String size;

  BasicModal({
    required this.show,
    required this.setShow,
    required this.title,
    required this.child,
    this.size = "xl",
  });

  @override
  Widget build(BuildContext context) {
    return show
        ? Dialog(
            insetPadding: EdgeInsets.all(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: Colors.blue, // Puedes personalizar el color
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          FontAwesomeIcons.timesCircle,
                          size: 30,
                          color: Colors.white,
                        ),
                        onPressed: () => setShow(false),
                        tooltip: 'Cerrar ventana',
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  child: child, // Aquí se pasa el formulario de Acciones
                ),
              ],
            ),
          )
        : SizedBox();
  }
}
