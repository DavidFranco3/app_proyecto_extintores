// Login
const String endpointLoginAdministrador = "/login";

// Usuarios
const String endpointListarUsuario = "/usuarios/listar";
const String endpointRegistrarUsuario = "/usuarios/registro";
const String endpointObtenerUsuarios = "/usuarios/obtener";
const String endpointObtenerUsuariosEmail = "/usuarios/obtenerPorEmail";
const String endpointActualizarUsuario = "/usuarios/actualizar";
const String endpointEliminarUsuario = "/usuarios/eliminar";
const String endpointDeshabilitarUsuario = "/usuarios/deshabilitar";

// Clasificaciones
const String endpointListarClasificaciones = "/clasificaciones/listar";
const String endpointRegistrarClasificaciones = "/clasificaciones/registro";
const String endpointObtenerClasificaciones = "/clasificaciones/obtener";
const String endpointActualizarClasificaciones = "/clasificaciones/actualizar";
const String endpointEliminarClasificaciones = "/clasificaciones/eliminar";
const String endpointDeshabilitarClasificaciones = "/clasificaciones/deshabilitar";

// Clientes
const String endpointListarClientes = "/clientes/listar";
const String endpointRegistrarClientes = "/clientes/registro";
const String endpointObtenerClientes = "/clientes/obtener";
const String endpointActualizarClientes = "/clientes/actualizar";
const String endpointEliminarClientes = "/clientes/eliminar";
const String endpointDeshabilitarClientes = "/clientes/deshabilitar";

// Ramas
const String endpointListarRamas = "/ramas/listar";
const String endpointRegistrarRamas = "/ramas/registro";
const String endpointObtenerRamas = "/ramas/obtener";
const String endpointActualizarRamas = "/ramas/actualizar";
const String endpointEliminarRamas = "/ramas/eliminar";
const String endpointDeshabilitarRamas = "/ramas/deshabilitar";

// Reporte Final
const String endpointListarReporteFinal = "/reporteFinal/listar";
const String endpointRegistrarReporteFinal = "/reporteFinal/registro";
const String endpointObtenerReporteFinal = "/reporteFinal/obtener";
const String endpointActualizarReporteFinal = "/reporteFinal/actualizar";
const String endpointEliminarReporteFinal = "/reporteFinal/eliminar";
const String endpointDeshabilitarReporteFinal = "/reporteFinal/deshabilitar";

// Inspeccion anual
const String endpointListarInspeccionAnual = "/inspeccionAnual/listar";
const String endpointListarInspeccionAnualId = "/inspeccionAnual/listarPorId";
const String endpointRegistrarInspeccionAnual = "/inspeccionAnual/registro";
const String endpointObtenerInspeccionAnual = "/inspeccionAnual/obtener";
const String endpointActualizarInspeccionAnual = "/inspeccionAnual/actualizar";
const String endpointEliminarInspeccionAnual = "/inspeccionAnual/eliminar";
const String endpointDeshabilitarInspeccionAnual = "/inspeccionAnual/deshabilitar";
const String endpointEnviarPdfInspeccionAnual = "/inspeccionAnual/enviar-pdf";

// Encuestas de inspeccion
const String endpointListarEncuestaInspeccion = "/encuestaInspeccion/listar";
const String endpointListarEncuestaInspeccionRama = "/encuestaInspeccion/listarPorRama";
const String endpointRegistrarEncuestaInspeccion = "/encuestaInspeccion/registro";
const String endpointObtenerEncuestaInspeccion = "/encuestaInspeccion/obtener";
const String endpointActualizarEncuestaInspeccion = "/encuestaInspeccion/actualizar";
const String endpointEliminarEncuestaInspeccion = "/encuestaInspeccion/eliminar";
const String endpointDeshabilitarEncuestaInspeccion = "/encuestaInspeccion/deshabilitar";

// Encuestas de inspeccion cliente
const String endpointListarEncuestaInspeccionCliente = "/encuestaInspeccionCliente/listar";
const String endpointListarEncuestaInspeccionRamaCliente = "/encuestaInspeccionCliente/listarPorRama";
const String endpointListarEncuestaInspeccionRamaPorCliente = "/encuestaInspeccionCliente/listarPorRamaCliente";
const String endpointRegistrarEncuestaInspeccionCliente = "/encuestaInspeccionCliente/registro";
const String endpointObtenerEncuestaInspeccionCliente = "/encuestaInspeccionCliente/obtener";
const String endpointObtenerEncuestaInspeccionClienteEncuestas = "/encuestaInspeccionCliente/encuestasExistentes";
const String endpointActualizarEncuestaInspeccionCliente = "/encuestaInspeccionCliente/actualizar";
const String endpointEliminarEncuestaInspeccionCliente = "/encuestaInspeccionCliente/eliminar";
const String endpointDeshabilitarEncuestaInspeccionCliente = "/encuestaInspeccionCliente/deshabilitar";

// Extintores
const String endpointListarExtintores = "/extintores/listar";
const String endpointRegistrarExtintores = "/extintores/registro";
const String endpointObtenerExtintores = "/extintores/obtener";
const String endpointActualizarExtintores = "/extintores/actualizar";
const String endpointEliminarExtintores = "/extintores/eliminar";
const String endpointDeshabilitarExtintores = "/extintores/deshabilitar";

// Frecuencias
const String endpointListarFrecuencias = "/frecuencias/listar";
const String endpointRegistrarFrecuencias = "/frecuencias/registro";
const String endpointObtenerFrecuencias = "/frecuencias/obtener";
const String endpointActualizarFrecuencias = "/frecuencias/actualizar";
const String endpointEliminarFrecuencias = "/frecuencias/eliminar";
const String endpointDeshabilitarFrecuencias = "/frecuencias/deshabilitar";

// Inspecciones
const String endpointListarInspecciones = "/inspecciones/listar";
const String endpointListarInspeccionesCerradas = "/inspecciones/listarCerrados";
const String endpointListarInspeccionesAbiertas = "/inspecciones/listarAbiertas";
const String endpointListarInspeccionesResultadosEncuestas = "/inspecciones/listarDatosEncuesta";
const String endpointListarInspeccionesCliente = "/inspecciones/listarPorCliente";
const String endpointListarInspeccionesDatosEncuestas = "/inspecciones/listarDatosInspeccion";
const String endpointRegistrarInspecciones = "/inspecciones/registro";
const String endpointObtenerInspecciones = "/inspecciones/obtener";
const String endpointActualizarInspecciones = "/inspecciones/actualizar";
const String endpointActualizarImagenesFinales = "/inspecciones/actualizarImagenes";
const String endpointEliminarInspecciones = "/inspecciones/eliminar";
const String endpointDeshabilitarInspecciones = "/inspecciones/deshabilitar";
const String endpointDescargarPdf = "/inspecciones/generar-pdf";
const String endpointEnviarPdf = "/inspecciones/enviar-pdf";
const String endpointEnviarPdf2 = "/inspecciones/enviar-pdf2";
const String endpointEnviarZip = "/inspecciones/enviar-imagenes";

// Inspecciones proximas
const String endpointListarInspeccionesProximas = "/inspeccionesProximas/listar";
const String endpointRegistrarInspeccionesProximas = "/inspeccionesProximas/registro";
const String endpointObtenerInspeccionesProximas = "/inspeccionesProximas/obtener";
const String endpointActualizarInspeccionesProximas = "/inspeccionesProximas/actualizar";
const String endpointEliminarInspeccionesProximas = "/inspeccionesProximas/eliminar";
const String endpointDeshabilitarInspeccionesProximas = "/inspeccionesProximas/deshabilitar";

// Tipos de Extintores
const String endpointListarTiposExtintores = "/tiposExtintores/listar";
const String endpointRegistrarTiposExtintores = "/tiposExtintores/registro";
const String endpointObtenerTiposExtintores = "/tiposExtintores/obtener";
const String endpointActualizarTiposExtintores = "/tiposExtintores/actualizar";
const String endpointEliminarTiposExtintores = "/tiposExtintores/eliminar";
const String endpointDeshabilitarTiposExtintores = "/tiposExtintores/deshabilitar";

// Tokens
const String endpointListarTokens = "/tokens/listar";
const String endpointRegistrarTokens = "/tokens/registro";
const String endpointObtenerTokens = "/tokens/obtener";
const String endpointActualizarTokens = "/tokens/actualizar";
const String endpointEliminarTokens = "/tokens/eliminar";
const String endpointDeshabilitarTokens = "/tokens/deshabilitar";

// Logs Generales
const String endpointRegistroLogs = "/logs/registro";
const String endpointListarLogs = "/logs/listar";
const String endpointObtenerNoLogs = "/logs/obtenerNoLog";
const String endpointObtenerLogs = "/logs/obtener";
const String endpointEliminarLogs = "/logs/eliminar";
const String endpointActualizarLogs = "/logs/actualizar";

// Enviar notificaciones
const String endpointEnviarNotificacion = "/notificaciones/enviar";

