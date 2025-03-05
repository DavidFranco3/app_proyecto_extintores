import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'acciones.dart';
import '../Generales/list_view.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import '../../api/inspecciones.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class TblInspecciones extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> inspecciones;
  final Function onCompleted;

  TblInspecciones(
      {Key? key,
      required this.showModal,
      required this.inspecciones,
      required this.onCompleted})
      : super(key: key);

  @override
  _TblInspeccionesState createState() => _TblInspeccionesState();
}

class _TblInspeccionesState extends State<TblInspecciones> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;
  bool isLoading = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

Future<void> handleDownloadPDF(Map<String, dynamic> row) async {
  setState(() => isLoading = true);

  try {
    final inspeccionesService = InspeccionesService();
    String fileURL = inspeccionesService.urlDownloadPDF(row["id"]);

    if (fileURL.isEmpty) {
      throw Exception("La URL del archivo es inválida.");
    }

    var dio = Dio();

    // **Solicitar permisos de almacenamiento**
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception("Permiso de almacenamiento denegado.");
      }
    }

    // **Obtener la carpeta de descargas adecuada**
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    if (downloadsDir == null) {
      throw Exception("No se pudo obtener el directorio de descargas.");
    }

    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }

    String filePath = "${downloadsDir.path}/Encuesta_de_inspección_${row["id"]}.pdf";

    print("Descargando archivo en: $filePath");

    // **Descargar el archivo**
    await dio.download(fileURL, filePath);

    // **Verificar si el archivo se descargó**
    File file = File(filePath);
    if (await file.exists()) {
      OpenFile.open(filePath);
      print("Archivo guardado correctamente en: $filePath");
    } else {
      throw Exception("El archivo no se descargó correctamente.");
    }
  } catch (e) {
    print("Error al descargar el PDF: $e");
  } finally {
    setState(() => isLoading = false);
  }
}

  Future<void> handleSendEmail(Map<String, dynamic> row) async {
    try {
      final inspeccionesService = InspeccionesService();
      var response = await inspeccionesService.sendEmail(row["id"]);

      if (response['status'] == 200) {
        _showMessage("Correo enviado");
      } else {
        _showMessage("Error al enviar correo");
      }
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    } finally {
      isLoading = false;
    }
  }

  // Función para formatear fechas
  String formatDate(String date) {
    // Parseamos la fecha guardada en la base de datos
    final parsedDate = DateTime.parse(date);

    // Convertimos la fecha a la hora local
    final localDate = parsedDate.toLocal();

    // Ahora formateamos la fecha en formato de 12 horas (con AM/PM)
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm:ss a'); // Formato 12 horas
    return dateFormat.format(localDate);
  }

  void openEliminarModal(row) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Eliminar Inspeccion',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Aquí agregamos un widget GestureDetector para que cuando el usuario toque fuera del formulario, el teclado se cierre.
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context)
                          .unfocus(); // Cierra el teclado al tocar fuera
                    },
                    child: Acciones(
                      showModal: widget.showModal,
                      onCompleted: widget.onCompleted,
                      accion: "eliminar",
                      data: row,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Usuario'},
      {'name': 'Cliente'},
      {'name': 'Encuesta'},
      {'name': 'Comentarios'},
      {'name': 'Creado el'},
      {'name': 'Actualizado el'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Envolvemos el SizedBox dentro de Expanded
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
              datos: widget.inspecciones.map((row) {
                return {
                  'Usuario': row['usuario'],
                  'Cliente': row['cliente'],
                  'Encuesta': row['cuestionario'],
                  'Comentarios': row['comentarios'],
                  'Creado el': formatDate(row['createdAt'] ?? ''),
                  'Actualizado el': formatDate(row['updatedAt'] ?? ''),
                  '_originalRow': row,
                };
              }).toList(),
              columnas: columnas,
              accionesBuilder: (row) {
                return Row(
                  children: [
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                      onPressed: () => openEliminarModal(row['_originalRow']),
                    ),
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.filePdf,
                          color: Colors.blue), // Ícono más relacionado con PDF
                      onPressed: () => handleDownloadPDF(row['_originalRow']),
                    ),
                    IconButton(
                      icon: FaIcon(FontAwesomeIcons.envelope,
                          color: Colors
                              .orange), // Ícono más relacionado con el correo
                      onPressed: () => handleSendEmail(row['_originalRow']),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
