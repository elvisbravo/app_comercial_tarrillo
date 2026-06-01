class DashboardSummary {
  final double ventasTotal;
  final int ventasCantidad;
  final double cobranzasTotal;
  final int cobranzasCantidad;
  final double porCobrar;
  final int stockUnidades;
  final int stockItems;
  final int sectoresTotal;
  final List<SectorAsignado> sectores;

  DashboardSummary({
    required this.ventasTotal,
    required this.ventasCantidad,
    required this.cobranzasTotal,
    required this.cobranzasCantidad,
    required this.porCobrar,
    required this.stockUnidades,
    required this.stockItems,
    required this.sectoresTotal,
    required this.sectores,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    double _d(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);
    int _i(dynamic v) =>
        v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);

    final sectoresRaw = (json['sectores']?['lista'] as List?) ?? const [];

    return DashboardSummary(
      ventasTotal: _d(json['ventas']?['total']),
      ventasCantidad: _i(json['ventas']?['cantidad']),
      cobranzasTotal: _d(json['cobranzas']?['total']),
      cobranzasCantidad: _i(json['cobranzas']?['cantidad']),
      porCobrar: _d(json['por_cobrar']),
      stockUnidades: _i(json['stock']?['unidades']),
      stockItems: _i(json['stock']?['items']),
      sectoresTotal: _i(json['sectores']?['total']),
      sectores: sectoresRaw
          .whereType<Map<String, dynamic>>()
          .map(SectorAsignado.fromJson)
          .toList(),
    );
  }
}

class SectorAsignado {
  final int sectorId;
  final String nombre;

  SectorAsignado({required this.sectorId, required this.nombre});

  factory SectorAsignado.fromJson(Map<String, dynamic> json) {
    return SectorAsignado(
      sectorId: (json['sector_id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
    );
  }
}
