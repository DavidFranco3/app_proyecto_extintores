import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'acciones.dart';
import '../Generales/list_view.dart';
import '../Generales/formato_fecha.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import '../../api/inspecciones.dart';
import 'package:path_provider/path_provider.dart';
import './pdf.dart';
import './pdf2.dart';
import './pdf3.dart';
import '../../page/LlenarEncuestaEditar/llenar_encuesta_editar.dart';
import '../../page/GraficaDatosInspecciones/grafica_datos_inspecciones.dart';
import '../Generales/flushbar_helper.dart';
import '../../page/CargarImagenesFinales/cargar_imagenes_finales.dart';
import 'package:intl/intl.dart';

class TblInspecciones extends StatefulWidget {
  final VoidCallback showModal;
  final List<Map<String, dynamic>> inspecciones;
  final Function onCompleted;

  const TblInspecciones(
      {super.key,
      required this.showModal,
      required this.inspecciones,
      required this.onCompleted});

  @override
  State<TblInspecciones> createState() => _TblInspeccionesState();
}

class _TblInspeccionesState extends State<TblInspecciones> {
  bool showModal = false;
  Widget? contentModal;
  String? titulosModal;
  bool isLoading = false;

  static String fechaFormateada = DateFormat('dd-MM-yy').format(DateTime.now());

  Future<void> handleDownloadPDF(Map<String, dynamic> row) async {
    setState(() => isLoading = true);

    try {
      final inspeccionesService = InspeccionesService();
      String fileURL = inspeccionesService.urlDownloadPDF(row["id"]);

      if (fileURL.isEmpty) {
        throw Exception("La URL del archivo es inválida.");
      }

      var dio = Dio();

      // Obtener la ruta de la carpeta de documentos de la aplicación
      Directory appDocDir = await getApplicationDocumentsDirectory();

      String filePath =
          "${appDocDir.path}/${row["cliente"]}_$fechaFormateada-IPM.pdf";

      debugPrint("Descargando archivo en: $filePath");

      // Descargar el archivo PDF
      await dio.download(fileURL, filePath);

      // Verificar si el archivo fue descargado correctamente
      File file = File(filePath);
      if (await file.exists()) {
        OpenFile.open(filePath);
        debugPrint("Archivo guardado correctamente en: $filePath");
      } else {
        throw Exception("El archivo no se descargó correctamente.");
      }
    } catch (e) {
      debugPrint("Error al descargar el PDF: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> handleSendEmail(Map<String, dynamic> row) async {
    try {
      final inspeccionesService = InspeccionesService();
      var response = await inspeccionesService.sendEmail(row["id"]);

      if (response['status'] == 200) {
        if (mounted) {
          showCustomFlushbar(
          context: context,
          title: "Correo enviado",
          message: "El PDF fue enviado exitosamente al correo del cliente",
          backgroundColor: Colors.green,
        );
        }
      } else {
        if (mounted) {
          showCustomFlushbar(
          context: context,
          title: "Error al enviar el correo",
          message: "Hubo un problema al enviar el PDF por correo",
          backgroundColor: Colors.red,
        );
        }
      }
    } catch (error) {
      if (mounted) {
        showCustomFlushbar(
        context: context,
        title: "Oops...",
        message: error.toString(),
        backgroundColor: Colors.red,
      );
      }
    } finally {
      isLoading = false;
    }
  }

  void openEliminarModal(Map<String, dynamic> row) {
    // Navegar a la página de eliminación en lugar de mostrar un modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Acciones(
          showModal: widget.showModal,
          onCompleted: widget.onCompleted,
          accion: "eliminar",
          data: row,
        ),
      ),
    );
  }

  void openCargaImagenes(row) {
    // Navegar a la página de eliminación en lugar de mostrar un modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CargarImagenesFinalesScreen(
          showModal: widget.showModal,
          onCompleted: widget.onCompleted,
          accion: "editar",
          data: row,
        ),
      ),
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

  void openEditarEncuestaPage(Map<String, dynamic> row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EncuestaEditarPage(
            showModal: widget.showModal,
            onCompleted: widget.onCompleted,
            accion: "editar",
            data: row),
      ),
    ).then((_) {
      // Puedes agregar lógica aquí si necesitas hacer algo cuando regresas de la página
    });
  }

  String formatEncuesta(List<dynamic> encuesta) {
    return encuesta.map((item) {
      return '${item['pregunta']}\n${item['respuesta']}';
    }).join(
        '\n- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n');
  }

  Future<void> downloadAndOpenZip(
      Map<String, dynamic> row, String email) async {
    try {
      final inspeccionesService = InspeccionesService();
      var response = await inspeccionesService.urlDownloadZIP(row["id"], email);

      if (response['status'] == 200) {
        if (mounted) {
          showCustomFlushbar(
          context: context,
          title: "ZIP enviado",
          message: "Se ha enviado correctamente el zip al email $email",
          backgroundColor: Colors.green,
        );
        }
      } else {
        if (mounted) {
          showCustomFlushbar(
          context: context,
          title: "Error al enviar el ZIP",
          message: "Ha ocurrido un problema al enviar el ZIP al email $email",
          backgroundColor: Colors.red,
        );
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomFlushbar(
        context: context,
        title: "Error al enviar el ZIP",
        message: "Error: ${e.toString()}",
        backgroundColor: Colors.red,
      );
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> showEmailModal(Map<String, dynamic> row) async {
    TextEditingController emailController = TextEditingController();

    // 📌 Mostrar el modal
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Ingresar Correo"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Correo electrónico",
                  hintText: "Ingresa el correo",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el modal sin hacer nada
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                // 📌 Validar el correo
                String email = emailController.text.trim();
                if (email.isNotEmpty) {
                  // 📌 Ejecutar la función con el correo
                  downloadAndOpenZip(row, email);
                  Navigator.of(context).pop(); // Cerrar el modal
                } else {
                  debugPrint("❌ Por favor ingresa un correo válido.");
                }
              },
              child: Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> columnas = [
      {'name': 'Técnico'},
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
                    'Técnico': row['usuario'],
                    'Encuesta': row['cuestionario'],
                    '': formatEncuesta(row['encuesta']),
                    'Comentarios': row['comentarios'],
                    'Creado el': formatDate(row['createdAt'] ?? ''),
                    '_originalRow': row,
                  };
                }).toList(),
                columnas: columnas,
                accionesBuilder: (Map<String, dynamic> row) {
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
                      } else if (value == 'enviarPdfBackend') {
                        PdfGenerator.enviarPdfAlBackend(
                            context, row['_originalRow']);
                      } else if (value == 'guardarPdf3') {
                        GenerarPdfPage.generarPdf(row['_originalRow']);
                      } else if (value == 'guardarPdf4') {
                        GenerarPdfPage4.guardarPDF(row['_originalRow']);
                      } else if (value == 'enviarPdf4Backend') {
                        GenerarPdfPage4.enviarPdfAlBackend(
                            context, row['_originalRow']);
                      } else if (value == 'cargarImagenes') {
                        openCargaImagenes(row['_originalRow']);
                      } else if (value == 'enviarZip') {
                        showEmailModal(row['_originalRow']);
                      } else if (value == 'editarEncuesta') {
                        openEditarEncuestaPage(row['_originalRow']);
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
                            Text('Guardar PDF Reporte IPM'),
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
                            Text('Enviar PDF Reporte IPM'),
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
                            Text('Guardar PDF Certificado'),
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
                            Text('Enviar PDF Certificado'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'guardarPdf3',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.filePdf,
                              color: Colors.blue,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Guardar PDF Evidencia'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'guardarPdf4',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.filePdf,
                              color: Colors.blue,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Guardar PDF R. Problemas'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'enviarPdf4Backend',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.envelope,
                              color: Color.fromRGBO(255, 152, 0, 1),
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Enviar PDF R. Problemas'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'cargarImagenes',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.image,
                              color: Colors.blue,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Cargar imagenes'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'enviarZip',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.fileZipper,
                              color: Colors.yellow,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Enviar imagenes'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'editarEncuesta',
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.pencil,
                              color: Colors.lightBlue,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text('Editar encuesta'),
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



