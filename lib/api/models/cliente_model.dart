class ClienteModel {
  final String id;
  final String nombre;
  final String? imagen;
  final String? imagenCloudinary;
  final String correo;
  final String telefono;
  final String calle;
  final String nExterior;
  final String nInterior;
  final String colonia;
  final String estadoDom;
  final String municipio;
  final String cPostal;
  final String referencia;
  final String responsable;
  final String puesto;
  final String estado;
  final String createdAt;
  final String updatedAt;

  ClienteModel({
    required this.id,
    required this.nombre,
    this.imagen,
    this.imagenCloudinary,
    required this.correo,
    required this.telefono,
    required this.calle,
    required this.nExterior,
    required this.nInterior,
    required this.colonia,
    required this.estadoDom,
    required this.municipio,
    required this.cPostal,
    required this.referencia,
    required this.responsable,
    required this.puesto,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    final direccion = json['direccion'] ?? {};
    return ClienteModel(
      id: json['_id'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      imagen: json['imagen'],
      imagenCloudinary: json['imagenCloudinary'],
      correo: json['correo'] ?? '',
      telefono: json['telefono'] ?? '',
      calle: direccion['calle'] ?? json['calle'] ?? '',
      nExterior: (direccion['nExterior']?.isNotEmpty == true)
          ? direccion['nExterior']
          : (json['nExterior']?.isNotEmpty == true)
              ? json['nExterior']
              : 'S/N',
      nInterior: (direccion['nInterior']?.isNotEmpty == true)
          ? direccion['nInterior']
          : (json['nInterior']?.isNotEmpty == true)
              ? json['nInterior']
              : 'S/N',
      colonia: direccion['colonia'] ?? json['colonia'] ?? '',
      estadoDom: direccion['estadoDom'] ?? json['estadoDom'] ?? '',
      municipio: direccion['municipio'] ?? json['municipio'] ?? '',
      cPostal: direccion['cPostal'] ?? json['cPostal'] ?? '',
      referencia: direccion['referencia'] ?? json['referencia'] ?? '',
      responsable: json['responsable'] ?? '',
      puesto: json['puesto'] ?? '',
      estado: json['estado']?.toString() ?? 'true',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'imagen': imagen,
      'imagenCloudinary': imagenCloudinary,
      'correo': correo,
      'telefono': telefono,
      'direccion': {
        'calle': calle,
        'nExterior': nExterior,
        'nInterior': nInterior,
        'colonia': colonia,
        'estadoDom': estadoDom,
        'municipio': municipio,
        'cPostal': cPostal,
        'referencia': referencia,
      },
      'responsable': responsable,
      'puesto': puesto,
      'estado': estado,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
