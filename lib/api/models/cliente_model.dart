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
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    final direccion = json['direccion'] ?? {};
    return ClienteModel(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      imagen: json['imagen'],
      imagenCloudinary: json['imagenCloudinary'],
      correo: json['correo'] ?? '',
      telefono: json['telefono'] ?? '',
      calle: direccion['calle'] ?? '',
      nExterior: (direccion['nExterior']?.isNotEmpty == true)
          ? direccion['nExterior']
          : 'S/N',
      nInterior: (direccion['nInterior']?.isNotEmpty == true)
          ? direccion['nInterior']
          : 'S/N',
      colonia: direccion['colonia'] ?? '',
      estadoDom: direccion['estadoDom'] ?? '',
      municipio: direccion['municipio'] ?? '',
      cPostal: direccion['cPostal'] ?? '',
      referencia: direccion['referencia'] ?? '',
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
      'estado': estado,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
