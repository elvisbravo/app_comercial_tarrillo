class VentaData {
  final String fecha;
  final VendedorInfo? vendedor;
  final List<ProductoVenta> productos;
  final int movilesUbicacionId;
  final List<ClienteVenta> clientes;
  final List<Comprobante> comprobantes;
  final List<TipoDocumento> tipoDocumentos;
  final List<FormaPago> formaPagos;
  final List<Banco> bancos;
  final List<SectorOpcion> sectores;

  VentaData({
    required this.fecha,
    required this.vendedor,
    required this.productos,
    required this.movilesUbicacionId,
    required this.clientes,
    required this.comprobantes,
    required this.tipoDocumentos,
    required this.formaPagos,
    required this.bancos,
    required this.sectores,
  });

  factory VentaData.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) from) =>
        ((json[key] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(from)
            .toList();

    int _i(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

    return VentaData(
      fecha: (json['fecha'] ?? '').toString(),
      vendedor: json['vendedor'] is Map<String, dynamic>
          ? VendedorInfo.fromJson(json['vendedor'] as Map<String, dynamic>)
          : null,
      productos: parseList('productos', ProductoVenta.fromJson),
      movilesUbicacionId: _i(json['moviles_ubicacion_id']),
      clientes: parseList('clientes', ClienteVenta.fromJson),
      comprobantes: parseList('comprobantes', Comprobante.fromJson),
      tipoDocumentos: parseList('tipo_documentos', TipoDocumento.fromJson),
      formaPagos: parseList('forma_pagos', FormaPago.fromJson),
      bancos: parseList('bancos', Banco.fromJson),
      sectores: parseList('sectores', SectorOpcion.fromJson),
    );
  }
}

class VendedorInfo {
  final int id;
  final String nombre;

  VendedorInfo({required this.id, required this.nombre});

  factory VendedorInfo.fromJson(Map<String, dynamic> json) {
    return VendedorInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
    );
  }
}

class ProductoVenta {
  final int id;
  final String nombre;
  final String? codigoBarras;
  final int stock;
  final double precioContado;
  final double precioCredito;

  ProductoVenta({
    required this.id,
    required this.nombre,
    required this.codigoBarras,
    required this.stock,
    required this.precioContado,
    required this.precioCredito,
  });

  factory ProductoVenta.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int _i(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

    return ProductoVenta(
      id: _i(json['id']),
      nombre: (json['nombre'] ?? '').toString(),
      codigoBarras: json['codigo_barras']?.toString(),
      stock: _i(json['stock']),
      precioContado: _d(json['precio_contado']),
      precioCredito: _d(json['precio_credito']),
    );
  }
}

class ClienteVenta {
  final int id;
  final String? documento;
  final int? tipoDoc;
  final String nombre;
  final String? razonSocial;
  final String? direccion;
  final String? telefono;
  final int? sectorId;

  ClienteVenta({
    required this.id,
    required this.documento,
    required this.tipoDoc,
    required this.nombre,
    required this.razonSocial,
    required this.direccion,
    required this.telefono,
    required this.sectorId,
  });

  factory ClienteVenta.fromJson(Map<String, dynamic> json) {
    return ClienteVenta(
      id: (json['id'] as num?)?.toInt() ?? 0,
      documento: json['documento']?.toString(),
      tipoDoc: (json['tipo_doc'] as num?)?.toInt(),
      nombre: (json['nombre'] ?? '').toString(),
      razonSocial: json['razon_social']?.toString(),
      direccion: json['direccion']?.toString(),
      telefono: json['telefono']?.toString(),
      sectorId: (json['sector_id'] as num?)?.toInt(),
    );
  }
}

class Comprobante {
  final int id;
  final String nombre;

  Comprobante({required this.id, required this.nombre});

  factory Comprobante.fromJson(Map<String, dynamic> json) {
    return Comprobante(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
    );
  }
}

class TipoDocumento {
  final int id;
  final String nombre;

  TipoDocumento({required this.id, required this.nombre});

  factory TipoDocumento.fromJson(Map<String, dynamic> json) {
    return TipoDocumento(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
    );
  }
}

class FormaPago {
  final int id;
  final String nombre;

  FormaPago({required this.id, required this.nombre});

  factory FormaPago.fromJson(Map<String, dynamic> json) {
    return FormaPago(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
    );
  }
}

class Banco {
  final int id;
  final String banco;
  final String? numeroCuenta;
  final String? cci;

  Banco({required this.id, required this.banco, required this.numeroCuenta, required this.cci});

  factory Banco.fromJson(Map<String, dynamic> json) {
    return Banco(
      id: (json['id'] as num?)?.toInt() ?? 0,
      banco: (json['banco'] ?? '').toString(),
      numeroCuenta: json['numero_cuenta']?.toString(),
      cci: json['cci']?.toString(),
    );
  }
}

class SectorOpcion {
  final int id;
  final String nombre;

  SectorOpcion({required this.id, required this.nombre});

  factory SectorOpcion.fromJson(Map<String, dynamic> json) {
    return SectorOpcion(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
    );
  }
}
