// =================== Historial de cargas ===================

class HistorialCargas {
  final List<CargaItem> items;
  final int total;

  HistorialCargas({required this.items, required this.total});

  factory HistorialCargas.fromJson(Map<String, dynamic> json) {
    return HistorialCargas(
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CargaItem.fromJson)
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class CargaItem {
  final int id;
  final String? fecha;
  final String? hora;
  final String? serie;
  final String? correlativo;
  final String? motivo;
  final int estado;
  final String estadoLegible;
  final double totalUnidades;
  final String? usuarioNombre;

  CargaItem({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.serie,
    required this.correlativo,
    required this.motivo,
    required this.estado,
    required this.estadoLegible,
    required this.totalUnidades,
    required this.usuarioNombre,
  });

  factory CargaItem.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int _i(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
    return CargaItem(
      id: _i(json['id']),
      fecha: json['fecha']?.toString(),
      hora: json['hora']?.toString(),
      serie: json['serie']?.toString(),
      correlativo: json['correlativo']?.toString(),
      motivo: json['motivo']?.toString(),
      estado: _i(json['estado']),
      estadoLegible: (json['estado_legible'] ?? 'ACTIVO').toString(),
      totalUnidades: _d(json['total_unidades']),
      usuarioNombre: json['usuario_nombre']?.toString(),
    );
  }
}

class CargaDetalle {
  final CargaItem traslado;
  final List<ProductoCarga> productos;
  final double totalUnidades;
  final double totalValor;

  CargaDetalle({
    required this.traslado,
    required this.productos,
    required this.totalUnidades,
    required this.totalValor,
  });

  factory CargaDetalle.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    return CargaDetalle(
      traslado: CargaItem.fromJson({
        ...Map<String, dynamic>.from(json['traslado'] as Map),
        'estado': json['traslado']?['estado'] ?? 0,
        'estado_legible': json['traslado']?['estado_legible'] ?? 'ACTIVO',
        'total_unidades': 0,
      }),
      productos: ((json['productos'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ProductoCarga.fromJson)
          .toList(),
      totalUnidades: _d(json['total_unidades']),
      totalValor: _d(json['total_valor']),
    );
  }
}

class ProductoCarga {
  final int id;
  final String nombre;
  final String? codigoBarras;
  final double cantidad;
  final double precioUnitario;
  final double subtotal;

  ProductoCarga({
    required this.id,
    required this.nombre,
    required this.codigoBarras,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory ProductoCarga.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int _i(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
    return ProductoCarga(
      id: _i(json['id']),
      nombre: (json['nombre'] ?? '').toString(),
      codigoBarras: json['codigo_barras']?.toString(),
      cantidad: _d(json['cantidad']),
      precioUnitario: _d(json['precio_unitario']),
      subtotal: _d(json['subtotal']),
    );
  }
}

// =================== Historial de ventas ===================

class HistorialVentas {
  final List<VentaItem> items;
  final int total;

  HistorialVentas({required this.items, required this.total});

  factory HistorialVentas.fromJson(Map<String, dynamic> json) {
    return HistorialVentas(
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(VentaItem.fromJson)
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class VentaItem {
  final int id;
  final String? fecha;
  final String? hora;
  final String? comprobante;
  final double monto;
  final int tipoPagoId;
  final String? tipoPago;
  final String? tipoComprobante;
  final String? clienteNombre;
  final String? clienteDocumento;
  final String estado;
  final String? estadoLiquidacion;
  final double totalUnidades;

  VentaItem({
    required this.id,
    required this.fecha,
    required this.hora,
    required this.comprobante,
    required this.monto,
    required this.tipoPagoId,
    required this.tipoPago,
    required this.tipoComprobante,
    required this.clienteNombre,
    required this.clienteDocumento,
    required this.estado,
    required this.estadoLiquidacion,
    required this.totalUnidades,
  });

  bool get esCredito => tipoPagoId == 2;
  bool get esContado => tipoPagoId == 1;

  factory VentaItem.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int _i(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
    return VentaItem(
      id: _i(json['id']),
      fecha: json['fecha']?.toString(),
      hora: json['hora']?.toString(),
      comprobante: json['comprobante']?.toString(),
      monto: _d(json['monto']),
      tipoPagoId: _i(json['tipo_pago_id']),
      tipoPago: json['tipo_pago']?.toString(),
      tipoComprobante: json['tipo_comprobante']?.toString(),
      clienteNombre: json['cliente_nombre']?.toString(),
      clienteDocumento: json['cliente_documento']?.toString(),
      estado: (json['estado'] ?? 'ACTIVA').toString(),
      estadoLiquidacion: json['estado_liquidacion']?.toString(),
      totalUnidades: _d(json['total_unidades']),
    );
  }
}

class VentaDetalle {
  final VentaItem venta;
  final List<ProductoCarga> productos;
  final double totalUnidades;

  VentaDetalle({
    required this.venta,
    required this.productos,
    required this.totalUnidades,
  });

  factory VentaDetalle.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    return VentaDetalle(
      venta: VentaItem.fromJson(Map<String, dynamic>.from(json['venta'] as Map)),
      productos: ((json['productos'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((p) => ProductoCarga(
                id: (p['id'] as num?)?.toInt() ?? 0,
                nombre: (p['nombre'] ?? '').toString(),
                codigoBarras: null,
                cantidad: _d(p['cantidad']),
                precioUnitario: _d(p['precio']),
                subtotal: _d(p['subtotal']),
              ))
          .toList(),
      totalUnidades: _d(json['total_unidades']),
    );
  }
}

// =================== Historial de cobros ===================

class HistorialCobrosList {
  final List<CobroHistItem> items;
  final int total;

  HistorialCobrosList({required this.items, required this.total});

  factory HistorialCobrosList.fromJson(Map<String, dynamic> json) {
    return HistorialCobrosList(
      items: ((json['items'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CobroHistItem.fromJson)
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class CobroHistItem {
  final int id;
  final String? fecha;
  final String? numRecibo;
  final double monto;
  final String? estado;
  final String estadoLegible;
  final String? estadoLiquidacion;
  final String? clienteNombre;
  final String? clienteDocumento;
  final String? formaPago;
  final String? createdAt;

  CobroHistItem({
    required this.id,
    required this.fecha,
    required this.numRecibo,
    required this.monto,
    required this.estado,
    required this.estadoLegible,
    required this.estadoLiquidacion,
    required this.clienteNombre,
    required this.clienteDocumento,
    required this.formaPago,
    required this.createdAt,
  });

  factory CobroHistItem.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int _i(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
    return CobroHistItem(
      id: _i(json['id']),
      fecha: json['fecha']?.toString(),
      numRecibo: json['num_recibo']?.toString(),
      monto: _d(json['monto']),
      estado: json['estado']?.toString(),
      estadoLegible: (json['estado_legible'] ?? 'EMITIDO').toString(),
      estadoLiquidacion: json['estado_liquidacion']?.toString(),
      clienteNombre: json['cliente_nombre']?.toString(),
      clienteDocumento: json['cliente_documento']?.toString(),
      formaPago: json['forma_pago']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class CobroHistDetalle {
  final CobroHistItem recibo;
  final List<AmortizacionHistItem> amortizaciones;
  final double totalAmortizado;

  CobroHistDetalle({
    required this.recibo,
    required this.amortizaciones,
    required this.totalAmortizado,
  });

  factory CobroHistDetalle.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    return CobroHistDetalle(
      recibo: CobroHistItem.fromJson({
        ...Map<String, dynamic>.from(json['recibo'] as Map),
        'cliente_nombre': json['recibo']?['cliente_nombre'],
        'cliente_documento': json['recibo']?['cliente_documento'],
        'forma_pago': json['recibo']?['forma_pago'],
        'estado_liquidacion': json['recibo']?['estado_liquidacion'],
      }),
      amortizaciones: ((json['amortizaciones'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AmortizacionHistItem.fromJson)
          .toList(),
      totalAmortizado: _d(json['total_amortizado']),
    );
  }
}

class AmortizacionHistItem {
  final int id;
  final double montoAmortizado;
  final double capital;
  final double interes;
  final double saldoRestanteCuota;
  final int numeroCuota;
  final double montoCuota;
  final String? vencimientoCuota;
  final int creditoId;
  final double totalCredito;
  final String? comprobante;
  final String? tipoComprobante;

  AmortizacionHistItem({
    required this.id,
    required this.montoAmortizado,
    required this.capital,
    required this.interes,
    required this.saldoRestanteCuota,
    required this.numeroCuota,
    required this.montoCuota,
    required this.vencimientoCuota,
    required this.creditoId,
    required this.totalCredito,
    required this.comprobante,
    required this.tipoComprobante,
  });

  factory AmortizacionHistItem.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int _i(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
    return AmortizacionHistItem(
      id: _i(json['id']),
      montoAmortizado: _d(json['monto_amortizado']),
      capital: _d(json['capital']),
      interes: _d(json['interes']),
      saldoRestanteCuota: _d(json['saldo_restante_cuota']),
      numeroCuota: _i(json['numero_cuota']),
      montoCuota: _d(json['monto_cuota']),
      vencimientoCuota: json['vencimiento_cuota']?.toString(),
      creditoId: _i(json['credito_id']),
      totalCredito: _d(json['total_credito']),
      comprobante: json['comprobante']?.toString(),
      tipoComprobante: json['tipo_comprobante']?.toString(),
    );
  }
}
