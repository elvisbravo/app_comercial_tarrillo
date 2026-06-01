import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/historial_data.dart';
import '../services/api_client.dart';
import '../services/historial_service.dart';

class HistoryCollectionsScreen extends StatefulWidget {
  const HistoryCollectionsScreen({super.key});

  @override
  State<HistoryCollectionsScreen> createState() => _HistoryCollectionsScreenState();
}

class _HistoryCollectionsScreenState extends State<HistoryCollectionsScreen> {
  static const Color primary = Color(0xFF00236F);
  static const Color primaryContainer = Color(0xFF1E3A8A);
  static const Color secondary = Color(0xFF006C49);
  static const Color danger = Color(0xFFBA1A1A);
  static const Color warning = Color(0xFFB45309);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color surfaceContainerLow = Color(0xFFF0F3FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFE7EEFE);
  static const Color outlineVariant = Color(0xFFC5C5D3);
  static const Color onSurface = Color(0xFF151C27);
  static const Color onSurfaceVariant = Color(0xFF444651);

  HistorialCobrosList? _data;
  bool _isLoading = true;
  String? _error;
  String _rango = '7d';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  ({String? desde, String? hasta}) _rangoFechas() {
    final hoy = DateTime.now();
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    switch (_rango) {
      case 'hoy':
        return (desde: fmt(hoy), hasta: fmt(hoy));
      case '30d':
        return (desde: fmt(hoy.subtract(const Duration(days: 30))), hasta: fmt(hoy));
      case 'todo':
        return (desde: null, hasta: null);
      case '7d':
      default:
        return (desde: fmt(hoy.subtract(const Duration(days: 7))), hasta: fmt(hoy));
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final r = _rangoFechas();
      final data = await HistorialService.getCobros(
        fechaDesde: r.desde,
        fechaHasta: r.hasta,
        buscar: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Error de conexión. Verifica tu conexión a internet.';
        _isLoading = false;
      });
    }
  }

  double get _totalCobrado {
    return _data?.items.fold<double>(0, (s, c) => s + c.monto) ?? 0;
  }

  Future<void> _abrirDetalle(int id) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalleCobroSheet(cobroId: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Historial de Cobranzas',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _cargar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null ? _buildError() : _buildContent()),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: danger),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 15)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final cobros = _data?.items ?? const [];
    return Column(
      children: [
        _buildFiltros(),
        _buildResumen(),
        Expanded(
          child: cobros.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: cobros.length,
                    itemBuilder: (_, i) => _buildCobroCard(cobros[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outlineVariant),
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _cargar(),
              decoration: InputDecoration(
                hintText: 'Buscar por cliente o N° recibo...',
                hintStyle: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: onSurfaceVariant),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _rangoChip('hoy', 'Hoy'),
                const SizedBox(width: 6),
                _rangoChip('7d', '7 días'),
                const SizedBox(width: 6),
                _rangoChip('30d', '30 días'),
                const SizedBox(width: 6),
                _rangoChip('todo', 'Todo'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangoChip(String value, String label) {
    final selected = _rango == value;
    return InkWell(
      onTap: () {
        setState(() => _rango = value);
        _cargar();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primary : surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : primary,
          ),
        ),
      ),
    );
  }

  Widget _buildResumen() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total cobrado',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text('S/ ${_totalCobrado.toStringAsFixed(2)}',
                    style: GoogleFonts.manrope(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Recibos',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text('${_data?.items.length ?? 0}',
                  style: GoogleFonts.manrope(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Sin cobranzas',
                style: GoogleFonts.manrope(
                    color: onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('No hay recibos en el rango seleccionado.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildCobroCard(CobroHistItem c) {
    return InkWell(
      onTap: () => _abrirDetalle(c.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: outlineVariant),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments, color: secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.clienteNombre ?? 'Sin cliente',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 15, color: onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Recibo: ${c.numRecibo ?? '-'}',
                        style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 11, color: onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(c.fecha ?? '-',
                            style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 11)),
                        const SizedBox(width: 10),
                        Icon(Icons.account_balance_wallet, size: 11, color: onSurfaceVariant),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(c.formaPago ?? '-',
                              style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('S/ ${c.monto.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                          fontSize: 16, fontWeight: FontWeight.w700, color: primary)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: secondary.withOpacity(0.3)),
                    ),
                    child: Text(c.estadoLegible,
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700, color: secondary)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== Detalle de cobro ===================

class _DetalleCobroSheet extends StatefulWidget {
  final int cobroId;
  const _DetalleCobroSheet({required this.cobroId});

  @override
  State<_DetalleCobroSheet> createState() => _DetalleCobroSheetState();
}

class _DetalleCobroSheetState extends State<_DetalleCobroSheet> {
  CobroHistDetalle? _detalle;
  bool _loading = true;
  String? _error;

  static const Color primary = Color(0xFF00236F);
  static const Color secondary = Color(0xFF006C49);
  static const Color onSurface = Color(0xFF151C27);
  static const Color onSurfaceVariant = Color(0xFF444651);
  static const Color surfaceContainerLow = Color(0xFFF0F3FF);
  static const Color outlineVariant = Color(0xFFC5C5D3);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final d = await HistorialService.getCobroDetalle(widget.cobroId);
      if (!mounted) return;
      setState(() {
        _detalle = d;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar el detalle';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Text('Detalle de cobranza',
                      style: GoogleFonts.manrope(
                          fontSize: 20, fontWeight: FontWeight.w700, color: primary)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(_error!,
                                style: GoogleFonts.inter(color: const Color(0xFFBA1A1A))),
                          ),
                        )
                      : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final d = _detalle!;
    final r = d.recibo;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: secondary.withOpacity(0.3)),
                      ),
                      child: Text(r.estadoLegible,
                          style: GoogleFonts.inter(
                              fontSize: 11, fontWeight: FontWeight.w700, color: secondary)),
                    ),
                    const Spacer(),
                    Text('S/ ${r.monto.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                            fontSize: 22, fontWeight: FontWeight.w700, color: primary)),
                  ],
                ),
                const SizedBox(height: 10),
                _kv('Cliente', r.clienteNombre ?? '-'),
                _kv('Documento', r.clienteDocumento ?? '-'),
                _kv('N° recibo', r.numRecibo ?? '-'),
                _kv('Fecha', r.fecha ?? '-'),
                _kv('Forma de pago', r.formaPago ?? '-'),
                if (r.estadoLiquidacion != null) _kv('Liquidación', r.estadoLiquidacion!),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Amortizaciones',
              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _tablaAmortizaciones(d.amortizaciones, d.totalAmortizado),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 110,
                child: Text('$k:',
                    style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 12))),
            Expanded(
              child: Text(v,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 13, color: onSurface)),
            ),
          ],
        ),
      );

  Widget _tablaAmortizaciones(List<AmortizacionHistItem> list, double total) {
    if (list.isEmpty) {
      return Text('Sin amortizaciones.', style: GoogleFonts.inter(color: onSurfaceVariant));
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: i.isEven ? const Color(0xFFFFFFFF) : surfaceContainerLow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Cuota ${list[i].numeroCuota}',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: primary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(list[i].comprobante ?? '-',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w600, color: onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('S/ ${list[i].montoAmortizado.toStringAsFixed(2)}',
                          style: GoogleFonts.manrope(
                              fontSize: 13, fontWeight: FontWeight.w700, color: primary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _mini('Capital', 'S/ ${list[i].capital.toStringAsFixed(2)}'),
                      const SizedBox(width: 10),
                      _mini('Interés', 'S/ ${list[i].interes.toStringAsFixed(2)}'),
                      const SizedBox(width: 10),
                      _mini('Saldo', 'S/ ${list[i].saldoRestanteCuota.toStringAsFixed(2)}'),
                    ],
                  ),
                  if (list[i].vencimientoCuota != null) ...[
                    const SizedBox(height: 4),
                    Text('Vencimiento: ${list[i].vencimientoCuota}',
                        style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 11)),
                  ],
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: const BoxDecoration(
              color: surfaceContainerLow,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Text('Total amortizado',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant)),
                const Spacer(),
                Text('S/ ${total.toStringAsFixed(2)}',
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w700, color: primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mini(String k, String v) {
    return Expanded(
      child: Text('$k: $v',
          style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}
