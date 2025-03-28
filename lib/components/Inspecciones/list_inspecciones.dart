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
import './pdf.dart';
import '../../page/GraficaDatosInspecciones/grafica_datos_inspecciones.dart';
import '../Generales/flushbar_helper.dart';

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

      String filePath =
          "${downloadsDir.path}/Encuesta_de_inspección_${row["id"]}.pdf";

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
        showCustomFlushbar(
          context: context,
          title: "Correo enviado",
          message: "El PDF fue enviado exitosamente al correo del cliente",
          backgroundColor: Colors.green,
        );
      } else {
        showCustomFlushbar(
          context: context,
          title: "Error al enviar el correo",
          message: "Hubo un problema al enviar el PDF por correo",
          backgroundColor: Colors.red,
        );
      }
    } catch (error) {
      showCustomFlushbar(
        context: context,
        title: "Oops...",
        message: error.toString(),
        backgroundColor: Colors.red,
      );
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
                  style: TextStyle(
                    fontSize: 20, // Tamaño más pequeño
                    fontWeight: FontWeight.bold, // Negrita
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
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

  void openRegistroPage(Map<String, dynamic> row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GraficaDatosInspeccionesPage(idInspeccion: row["id"]),
      ),
    ).then((_) {
      // Puedes agregar lógica aquí si necesitas hacer algo cuando regresas de la página
    });
  }

  String formatEncuesta(List<dynamic> encuesta) {
    return encuesta.map((item) {
      return '${item['pregunta']} ${item['respuesta']}';
    }).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Inspector'},
      {'name': 'Encuesta'},
      {'name': ''},
      {'name': 'Comentarios'},
      {'name': 'Creado el'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Envolvemos el SizedBox dentro de Expanded
        Expanded(
          child: SingleChildScrollView(
            child: DataTableCustom(
                datos: widget.inspecciones.asMap().entries.map((entry) {
                  Map<String, dynamic> row = entry.value;
                  return {
                    'Inspector': row['usuario'],
                    'Encuesta': row['cuestionario'],
                    '': formatEncuesta(row['encuesta']),
                    'Comentarios': row['comentarios'],
                    'Creado el': formatDate(row['createdAt'] ?? ''),
                    '_originalRow': row,
                  };
                }).toList(),
                columnas: columnas,
                accionesBuilder: (row) {
                  return PopupMenuButton<String>(
                    icon: FaIcon(
                      FontAwesomeIcons.bars,
                      color: Color.fromARGB(255, 27, 40, 223),
                    ), // Icono del menú
                    onSelected: (String value) {
                      if (value == 'eliminar') {
                        openEliminarModal(row['_originalRow']);
                      } else if (value == 'pdf') {
                        handleDownloadPDF(row['_originalRow']);
                      } else if (value == 'enviarCorreo') {
                        handleSendEmail(row['_originalRow']);
                      } else if (value == 'guardarPdf') {
                        PdfGenerator.guardarPDF(row['_originalRow']);
                      } else if (value == 'enviarPdfBackend') {
                        PdfGenerator.enviarPdfAlBackend(
                            context, row['_originalRow']);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.trash,
                              color: Colors.red,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Eliminar'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'pdf',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.filePdf,
                              color: Colors.blue,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Guardar PDF 1'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'enviarCorreo',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.envelope,
                              color: Color.fromRGBO(255, 152, 0, 1),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Enviar PDF 1'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'guardarPdf',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.filePdf,
                              color: Colors.blue,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Guardar PDF 2'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'enviarPdfBackend',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.envelope,
                              color: Color.fromRGBO(255, 152, 0, 1),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Enviar PDF 2'),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
          ),
        ),
      ],
    );
  }
}
