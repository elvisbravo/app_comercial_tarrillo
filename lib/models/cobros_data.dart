import 'venta_data.dart' show Banco, FormaPago, SectorOpcion;

class CobrosData {
  final String fecha;
  final VendedorCobro? vendedor;
  final List<CreditoCobro> creditos;
  final List<FormaPago> formaPagos;
  final List<Banco> bancos;
  final List<SectorOpcion> sectores;

  CobrosData({
    required this.fecha,
    required this.vendedor,
    required this.creditos,
    required this.formaPagos,
    required this.bancos,
    required this.sectores,
  });

  factory CobrosData.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) from) =>
        ((json[key] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(from)
            .toList();

    return CobrosData(
      fecha: (json['fecha'] ?? '').toString(),
      vendedor: json['vendedor'] is Map<String, dynamic>
          ? VendedorCobro.fromJson(json['vendedor'] as Map<String, dynamic>)
          : null,
      creditos: parseList('creditos', CreditoCobro.fromJson),
      formaPagos: parseList('forma_pagos', FormaPago.fromJson),
      bancos: parseList('bancos', Banco.fromJson),
      sectores: parseList('sectores', SectorOpcion.fromJson),
    );
  }
}

class VendedorCobro {
  final int id;
  final String nombre;

  VendedorCobro({required this.id, required this.nombre});

  factory VendedorCobro.fromJson(Map<String, dynamic> json) {
    return VendedorCobro(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
    );
  }
}

class ClienteCobro {
  final int id;
  final String nombre;
  final String? documento;
  final String? direccion;
  final String? telefono;
  final int? sectorId;

  ClienteCobro({
    required this.id,
    required this.nombre,
    required this.documento,
    required this.direccion,
    required this.telefono,
    required this.sectorId,
  });

  factory ClienteCobro.fromJson(Map<String, dynamic> json) {
    return ClienteCobro(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      documento: json['documento']?.toString(),
      direccion: json['direccion']?.toString(),
      telefono: json['telefono']?.toString(),
      sectorId: (json['sector_id'] as num?)?.toInt(),
    );
  }
}

class ProximaCuota {
  final int numero;
  final String vencimiento;
  final double monto;
  final double saldo;

  ProximaCuota({
    required this.numero,
    required this.vencimiento,
    required this.monto,
    required this.saldo,
  });

  factory ProximaCuota.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    return ProximaCuota(
      numero: (json['numero'] as num?)?.toInt() ?? 0,
      vencimiento: (json['vencimiento'] ?? '').toString(),
      monto: _d(json['monto']),
      saldo: _d(json['saldo']),
    );
  }
}

class CreditoCobro {
  final int id;
  final int clienteId;
  final double montoTotal;
  final double saldoPendiente;
  final String? fechaCredito;
  final String? fechaPago;
  final String? periodo;
  final int cuotasTotales;
  final int cuotasPagadas;
  final int cuotasVencidas;
  final ProximaCuota? proximaCuota;
  final String estado; // AL_DIA | MOROSO | PAGADO
  final ClienteCobro cliente;

  CreditoCobro({
    required this.id,
    required this.clienteId,
    required this.montoTotal,
    required this.saldoPendiente,
    required this.fechaCredito,
    required this.fechaPago,
    required this.periodo,
    required this.cuotasTotales,
    required this.cuotasPagadas,
    required this.cuotasVencidas,
    required this.proximaCuota,
    required this.estado,
    required this.cliente,
  });

  factory CreditoCobro.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int _i(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

    return CreditoCobro(
      id: _i(json['id']),
      clienteId: _i(json['cliente_id']),
      montoTotal: _d(json['monto_total']),
      saldoPendiente: _d(json['saldo_pendiente']),
      fechaCredito: json['fecha_credito']?.toString(),
      fechaPago: json['fecha_pago']?.toString(),
      periodo: json['periodo']?.toString(),
      cuotasTotales: _i(json['cuotas_totales']),
      cuotasPagadas: _i(json['cuotas_pagadas']),
      cuotasVencidas: _i(json['cuotas_vencidas']),
      proximaCuota: json['proxima_cuota'] is Map<String, dynamic>
          ? ProximaCuota.fromJson(json['proxima_cuota'] as Map<String, dynamic>)
          : null,
      estado: (json['estado'] ?? 'AL_DIA').toString(),
      cliente: json['cliente'] is Map<String, dynamic>
          ? ClienteCobro.fromJson(json['cliente'] as Map<String, dynamic>)
          : ClienteCobro(
              id: _i(json['cliente_id']),
              nombre: '',
              documento: null,
              direccion: null,
              telefono: null,
              sectorId: null,
            ),
    );
  }
}

class CreditoDetalle {
  final int id;
  final int clienteId;
  final double montoTotal;
  final double saldoPendiente;
  final String? fechaCredito;
  final String? fechaPago;
  final String? periodo;
  final String? observacion;
  final String estado;
  final ClienteCobro cliente;
  final List<ProductoDetalle> productos;
  final List<CuotaDetalle> cuotas;

  CreditoDetalle({
    required this.id,
    required this.clienteId,
    required this.montoTotal,
    required this.saldoPendiente,
    required this.fechaCredito,
    required this.fechaPago,
    required this.periodo,
    required this.observacion,
    required this.estado,
    required this.cliente,
    required this.productos,
    required this.cuotas,
  });

  factory CreditoDetalle.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int _i(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

    return CreditoDetalle(
      id: _i(json['id']),
      clienteId: _i(json['cliente_id']),
      montoTotal: _d(json['monto_total']),
      saldoPendiente: _d(json['saldo_pendiente']),
      fechaCredito: json['fecha_credito']?.toString(),
      fechaPago: json['fecha_pago']?.toString(),
      periodo: json['periodo']?.toString(),
      observacion: json['observacion']?.toString(),
      estado: (json['estado'] ?? '').toString(),
      cliente: json['cliente'] is Map<String, dynamic>
          ? ClienteCobro.fromJson(json['cliente'] as Map<String, dynamic>)
          : ClienteCobro(id: 0, nombre: '', documento: null, direccion: null, telefono: null, sectorId: null),
      productos: ((json['productos'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ProductoDetalle.fromJson)
          .toList(),
      cuotas: ((json['cuotas'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CuotaDetalle.fromJson)
          .toList(),
    );
  }
}

class ProductoDetalle {
  final int id;
  final String nombre;
  final double cantidad;
  final double precio;
  final double importe;

  ProductoDetalle({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.precio,
    required this.importe,
  });

  factory ProductoDetalle.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int _i(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
    return ProductoDetalle(
      id: _i(json['id']),
      nombre: (json['nombre'] ?? '').toString(),
      cantidad: _d(json['cantidad']),
      precio: _d(json['precio']),
      importe: _d(json['importe']),
    );
  }
}

class CuotaDetalle {
  final int id;
  final int numero;
  final String vencimiento;
  final double monto;
  final double capital;
  final double saldo;
  final String estado; // PENDIENTE | COBRADA | REPROGRAMADA

  CuotaDetalle({
    required this.id,
    required this.numero,
    required this.vencimiento,
    required this.monto,
    required this.capital,
    required this.saldo,
    required this.estado,
  });

  factory CuotaDetalle.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int _i(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
    return CuotaDetalle(
      id: _i(json['id']),
      numero: _i(json['numero']),
      vencimiento: (json['vencimiento'] ?? '').toString(),
      monto: _d(json['monto']),
      capital: _d(json['capital']),
      saldo: _d(json['saldo']),
      estado: (json['estado'] ?? '').toString(),
    );
  }
}
