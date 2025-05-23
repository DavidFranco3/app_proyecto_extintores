// Login
const String ENDPOINT_LOGIN_ADMINISTRADOR = "/login";

// Usuarios
const String ENDPOINT_LISTAR_USUARIO = "/usuarios/listar";
const String ENDPOINT_REGISTRAR_USUARIO = "/usuarios/registro";
const String ENDPOINT_OBTENER_USUARIOS = "/usuarios/obtener";
const String ENDPOINT_OBTENER_USUARIOS_EMAIL = "/usuarios/obtenerPorEmail";
const String ENDPOINT_ACTUALIZAR_USUARIO = "/usuarios/actualizar";
const String ENDPOINT_ELIMINAR_USUARIO = "/usuarios/eliminar";
const String ENDPOINT_DESHABILITAR_USUARIO = "/usuarios/deshabilitar";

// Clasificaciones
const String ENDPOINT_LISTAR_CLASIFICACIONES = "/clasificaciones/listar";
const String ENDPOINT_REGISTRAR_CLASIFICACIONES = "/clasificaciones/registro";
const String ENDPOINT_OBTENER_CLASIFICACIONES = "/clasificaciones/obtener";
const String ENDPOINT_ACTUALIZAR_CLASIFICACIONES = "/clasificaciones/actualizar";
const String ENDPOINT_ELIMINAR_CLASIFICACIONES = "/clasificaciones/eliminar";
const String ENDPOINT_DESHABILITAR_CLASIFICACIONES = "/clasificaciones/deshabilitar";

// Clientes
const String ENDPOINT_LISTAR_CLIENTES = "/clientes/listar";
const String ENDPOINT_REGISTRAR_CLIENTES = "/clientes/registro";
const String ENDPOINT_OBTENER_CLIENTES = "/clientes/obtener";
const String ENDPOINT_ACTUALIZAR_CLIENTES = "/clientes/actualizar";
const String ENDPOINT_ELIMINAR_CLIENTES = "/clientes/eliminar";
const String ENDPOINT_DESHABILITAR_CLIENTES = "/clientes/deshabilitar";

// Ramas
const String ENDPOINT_LISTAR_RAMAS = "/ramas/listar";
const String ENDPOINT_REGISTRAR_RAMAS = "/ramas/registro";
const String ENDPOINT_OBTENER_RAMAS = "/ramas/obtener";
const String ENDPOINT_ACTUALIZAR_RAMAS = "/ramas/actualizar";
const String ENDPOINT_ELIMINAR_RAMAS = "/ramas/eliminar";
const String ENDPOINT_DESHABILITAR_RAMAS = "/ramas/deshabilitar";

// Reporte Final
const String ENDPOINT_LISTAR_REPORTE_FINAL = "/reporteFinal/listar";
const String ENDPOINT_REGISTRAR_REPORTE_FINAL = "/reporteFinal/registro";
const String ENDPOINT_OBTENER_REPORTE_FINAL = "/reporteFinal/obtener";
const String ENDPOINT_ACTUALIZAR_REPORTE_FINAL = "/reporteFinal/actualizar";
const String ENDPOINT_ELIMINAR_REPORTE_FINAL = "/reporteFinal/eliminar";
const String ENDPOINT_DESHABILITAR_REPORTE_FINAL = "/reporteFinal/deshabilitar";

// Inspeccion anual
const String ENDPOINT_LISTAR_INSPECCION_ANUAL = "/inspeccionAnual/listar";
const String ENDPOINT_LISTAR_INSPECCION_ANUAL_ID = "/inspeccionAnual/listarPorId";
const String ENDPOINT_REGISTRAR_INSPECCION_ANUAL = "/inspeccionAnual/registro";
const String ENDPOINT_OBTENER_INSPECCION_ANUAL = "/inspeccionAnual/obtener";
const String ENDPOINT_ACTUALIZAR_INSPECCION_ANUAL = "/inspeccionAnual/actualizar";
const String ENDPOINT_ELIMINAR_INSPECCION_ANUAL = "/inspeccionAnual/eliminar";
const String ENDPOINT_DESHABILITAR_INSPECCION_ANUAL = "/inspeccionAnual/deshabilitar";
const String ENDPOINT_ENVIAR_PDF_INSPECCION_ANUAL = "/inspeccionAnual/enviar-pdf";

// Encuestas de inspeccion
const String ENDPOINT_LISTAR_ENCUESTA_INSPECCION = "/encuestaInspeccion/listar";
const String ENDPOINT_LISTAR_ENCUESTA_INSPECCION_RAMA = "/encuestaInspeccion/listarPorRama";
const String ENDPOINT_REGISTRAR_ENCUESTA_INSPECCION = "/encuestaInspeccion/registro";
const String ENDPOINT_OBTENER_ENCUESTA_INSPECCION = "/encuestaInspeccion/obtener";
const String ENDPOINT_ACTUALIZAR_ENCUESTA_INSPECCION = "/encuestaInspeccion/actualizar";
const String ENDPOINT_ELIMINAR_ENCUESTA_INSPECCION = "/encuestaInspeccion/eliminar";
const String ENDPOINT_DESHABILITAR_ENCUESTA_INSPECCION = "/encuestaInspeccion/deshabilitar";

// Encuestas de inspeccion cliente
const String ENDPOINT_LISTAR_ENCUESTA_INSPECCION_CLIENTE = "/encuestaInspeccionCliente/listar";
const String ENDPOINT_LISTAR_ENCUESTA_INSPECCION_RAMA_CLIENTE = "/encuestaInspeccionCliente/listarPorRama";
const String ENDPOINT_LISTAR_ENCUESTA_INSPECCION_RAMA_POR_CLIENTE = "/encuestaInspeccionCliente/listarPorRamaCliente";
const String ENDPOINT_REGISTRAR_ENCUESTA_INSPECCION_CLIENTE = "/encuestaInspeccionCliente/registro";
const String ENDPOINT_OBTENER_ENCUESTA_INSPECCION_CLIENTE = "/encuestaInspeccionCliente/obtener";
const String ENDPOINT_ACTUALIZAR_ENCUESTA_INSPECCION_CLIENTE = "/encuestaInspeccionCliente/actualizar";
const String ENDPOINT_ELIMINAR_ENCUESTA_INSPECCION_CLIENTE = "/encuestaInspeccionCliente/eliminar";
const String ENDPOINT_DESHABILITAR_ENCUESTA_INSPECCION_CLIENTE = "/encuestaInspeccionCliente/deshabilitar";

// Extintores
const String ENDPOINT_LISTAR_EXTINTORES = "/extintores/listar";
const String ENDPOINT_REGISTRAR_EXTINTORES = "/extintores/registro";
const String ENDPOINT_OBTENER_EXTINTORES = "/extintores/obtener";
const String ENDPOINT_ACTUALIZAR_EXTINTORES = "/extintores/actualizar";
const String ENDPOINT_ELIMINAR_EXTINTORES = "/extintores/eliminar";
const String ENDPOINT_DESHABILITAR_EXTINTORES = "/extintores/deshabilitar";

// Frecuencias
const String ENDPOINT_LISTAR_FRECUENCIAS = "/frecuencias/listar";
const String ENDPOINT_REGISTRAR_FRECUENCIAS = "/frecuencias/registro";
const String ENDPOINT_OBTENER_FRECUENCIAS = "/frecuencias/obtener";
const String ENDPOINT_ACTUALIZAR_FRECUENCIAS = "/frecuencias/actualizar";
const String ENDPOINT_ELIMINAR_FRECUENCIAS = "/frecuencias/eliminar";
const String ENDPOINT_DESHABILITAR_FRECUENCIAS = "/frecuencias/deshabilitar";

// Inspecciones
const String ENDPOINT_LISTAR_INSPECCIONES = "/inspecciones/listar";
const String ENDPOINT_LISTAR_INSPECCIONES_CERRADAS = "/inspecciones/listarCerrados";
const String ENDPOINT_LISTAR_INSPECCIONES_ABIERTAS = "/inspecciones/listarAbiertas";
const String ENDPOINT_LISTAR_INSPECCIONES_RESULTADOS_ENCUESTAS = "/inspecciones/listarDatosEncuesta";
const String ENDPOINT_LISTAR_INSPECCIONES_CLIENTE = "/inspecciones/listarPorCliente";
const String ENDPOINT_LISTAR_INSPECCIONES_DATOS_ENCUESTAS = "/inspecciones/listarDatosInspeccion";
const String ENDPOINT_REGISTRAR_INSPECCIONES = "/inspecciones/registro";
const String ENDPOINT_OBTENER_INSPECCIONES = "/inspecciones/obtener";
const String ENDPOINT_ACTUALIZAR_INSPECCIONES = "/inspecciones/actualizar";
const String ENDPOINT_ACTUALIZAR_IMAGENES_FINALES = "/inspecciones/actualizarImagenes";
const String ENDPOINT_ELIMINAR_INSPECCIONES = "/inspecciones/eliminar";
const String ENDPOINT_DESHABILITAR_INSPECCIONES = "/inspecciones/deshabilitar";
const String ENDPOINT_DESCARGAR_PDF = "/inspecciones/generar-pdf";
const String ENDPOINT_ENVIAR_PDF = "/inspecciones/enviar-pdf";
const String ENDPOINT_ENVIAR_PDF2 = "/inspecciones/enviar-pdf2";
const String ENDPOINT_ENVIAR_ZIP = "/inspecciones/enviar-imagenes";

// Inspecciones proximas
const String ENDPOINT_LISTAR_INSPECCIONES_PROXIMAS = "/inspeccionesProximas/listar";
const String ENDPOINT_REGISTRAR_INSPECCIONES_PROXIMAS = "/inspeccionesProximas/registro";
const String ENDPOINT_OBTENER_INSPECCIONES_PROXIMAS = "/inspeccionesProximas/obtener";
const String ENDPOINT_ACTUALIZAR_INSPECCIONES_PROXIMAS = "/inspeccionesProximas/actualizar";
const String ENDPOINT_ELIMINAR_INSPECCIONES_PROXIMAS = "/inspeccionesProximas/eliminar";
const String ENDPOINT_DESHABILITAR_INSPECCIONES_PROXIMAS = "/inspeccionesProximas/deshabilitar";

// Tipos de Extintores
const String ENDPOINT_LISTAR_TIPOS_EXTINTORES = "/tiposExtintores/listar";
const String ENDPOINT_REGISTRAR_TIPOS_EXTINTORES = "/tiposExtintores/registro";
const String ENDPOINT_OBTENER_TIPOS_EXTINTORES = "/tiposExtintores/obtener";
const String ENDPOINT_ACTUALIZAR_TIPOS_EXTINTORES = "/tiposExtintores/actualizar";
const String ENDPOINT_ELIMINAR_TIPOS_EXTINTORES = "/tiposExtintores/eliminar";
const String ENDPOINT_DESHABILITAR_TIPOS_EXTINTORES = "/tiposExtintores/deshabilitar";

// Tokens
const String ENDPOINT_LISTAR_TOKENS = "/tokens/listar";
const String ENDPOINT_REGISTRAR_TOKENS = "/tokens/registro";
const String ENDPOINT_OBTENER_TOKENS = "/tokens/obtener";
const String ENDPOINT_ACTUALIZAR_TOKENS = "/tokens/actualizar";
const String ENDPOINT_ELIMINAR_TOKENS = "/tokens/eliminar";
const String ENDPOINT_DESHABILITAR_TOKENS = "/tokens/deshabilitar";

// Logs Generales
const String ENDPOINT_REGISTRO_LOGS = "/logs/registro";
const String ENDPOINT_LISTAR_LOGS = "/logs/listar";
const String ENDPOINT_OBTENER_NO_LOGS = "/logs/obtenerNoLog";
const String ENDPOINT_OBTENER_LOGS = "/logs/obtener";
const String ENDPOINT_ELIMINAR_LOGS = "/logs/eliminar";
const String ENDPOINT_ACTUALIZAR_LOGS = "/logs/actualizar";

// Enviar notificaciones
const String ENDPOINT_ENVIAR_NOTIFICACION = "/notificaciones/enviar";
