import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/sync_service.dart';
import '../models/cobros_data.dart';
import '../services/api_client.dart';
import '../services/cobros_service.dart';
import '../widgets/offline_banner.dart';

class CollectionRegistrationScreen extends StatefulWidget {
  const CollectionRegistrationScreen({super.key});

  @override
  State<CollectionRegistrationScreen> createState() => _CollectionRegistrationScreenState();
}

class _CollectionRegistrationScreenState extends State<CollectionRegistrationScreen> {
  static const Color primary = Color(0xFF00236F);
  static const Color primaryContainer = Color(0xFF1E3A8A);
  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color onSecondaryContainer = Color(0xFF00714D);
  static const Color danger = Color(0xFFBA1A1A);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color surfaceContainerLow = Color(0xFFF0F3FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFE7EEFE);
  static const Color outlineVariant = Color(0xFFC5C5D3);
  static const Color onSurface = Color(0xFF151C27);
  static const Color onSurfaceVariant = Color(0xFF444651);
  static const Color warning = Color(0xFFB45309);

  CobrosData? _data;
  bool _isLoading = true;
  String? _error;

  final _searchController = TextEditingController();
  String _filter = 'TODOS';
  String _search = '';

  double get _saldoTotal {
    return _data?.creditos.fold<double>(0, (s, c) => s + c.saldoPendiente) ?? 0;
  }

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

  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await CobrosService.getCobros();
      if (!mounted) return;
      if (result.data == null) {
        setState(() {
          _error = result.error ?? 'No se pudieron cargar los datos.';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _data = result.data;
        _isLoading = false;
      });
      if (result.vinoDeCache) {
        _toast('Mostrando datos sin conexión (caché)');
      }
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

  List<CreditoCobro> get _creditosFiltrados {
    final all = _data?.creditos ?? const [];
    return all.where((c) {
      final matchEstado = _filter == 'TODOS' || c.estado == _filter;
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          c.cliente.nombre.toLowerCase().contains(q) ||
          (c.cliente.documento ?? '').toLowerCase().contains(q);
      return matchEstado && matchSearch;
    }).toList();
  }

  // =================== Acciones ===================

  Future<void> _abrirCobro(CreditoCobro credito) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CobroSheet(credito: credito),
    );
    if (ok == true && mounted) {
      await _cargar();
    }
  }

  Future<void> _abrirDetalle(int creditoId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalleSheet(creditoId: creditoId),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // =================== Build ===================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Registrar Cobranza',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _cargar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null ? _buildError() : _buildContent()),
          ),
        ],
      ),
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
    final creditos = _creditosFiltrados;
    return Column(
      children: [
        _buildFiltros(),
        _buildResumen(),
        Expanded(
          child: creditos.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: creditos.length,
                    itemBuilder: (_, i) => _buildCreditoCard(creditos[i]),
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
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o DNI...',
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
                _chip('TODOS'),
                const SizedBox(width: 8),
                _chip('AL_DIA', label: 'Al día', color: secondary),
                const SizedBox(width: 8),
                _chip('MOROSO', label: 'Moroso', color: danger),
                const SizedBox(width: 8),
                _chip('PAGADO', label: 'Pagado', color: const Color(0xFF7C3AED)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, {String? label, Color? color}) {
    final selected = _filter == value;
    final c = color ?? primary;
    final bg = selected ? c : surfaceContainerLow;
    final fg = selected ? Colors.white : c;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: Text(
          label ?? value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
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
                Text('Total por cobrar',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text('S/ ${_saldoTotal.toStringAsFixed(2)}',
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
              Text('Créditos activos',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text('${_data?.creditos.length ?? 0}',
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
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Sin créditos',
                style: GoogleFonts.manrope(
                    color: onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              _filter == 'TODOS'
                  ? 'No tienes créditos activos en tus sectores de hoy.'
                  : 'No hay créditos que coincidan con el filtro.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditoCard(CreditoCobro c) {
    final progress = c.montoTotal > 0
        ? ((c.montoTotal - c.saldoPendiente) / c.montoTotal).clamp(0.0, 1.0)
        : 0.0;

    Color statusColor;
    String statusLabel;
    switch (c.estado) {
      case 'PAGADO':
        statusColor = const Color(0xFF7C3AED);
        statusLabel = 'Pagado';
        break;
      case 'MOROSO':
        statusColor = danger;
        statusLabel = 'Moroso';
        break;
      default:
        statusColor = secondary;
        statusLabel = 'Al día';
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.cliente.nombre,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 15, color: onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text('${c.cliente.documento ?? '-'}',
                          style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(statusLabel,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _row('Deuda total', 'S/ ${c.montoTotal.toStringAsFixed(2)}'),
                const SizedBox(height: 4),
                _row('Pagado',
                    'S/ ${(c.montoTotal - c.saldoPendiente).toStringAsFixed(2)}',
                    color: secondary),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 8),
                _row('Por cobrar', 'S/ ${c.saldoPendiente.toStringAsFixed(2)}',
                    big: true, color: primary),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cuotas: ${c.cuotasPagadas}/${c.cuotasTotales}',
                        style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 12)),
                    if (c.proximaCuota != null)
                      Text(
                        'Próx: ${_formatDate(c.proximaCuota!.vencimiento)} · S/ ${c.proximaCuota!.monto.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 12),
                      ),
                  ],
                ),
                if (c.cuotasVencidas > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: danger, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${c.cuotasVencidas} cuota${c.cuotasVencidas == 1 ? '' : 's'} vencida${c.cuotasVencidas == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                              color: danger, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _abrirDetalle(c.id),
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: Text('Ver detalle', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    foregroundColor: onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              Container(width: 1, height: 36, color: outlineVariant),
              Expanded(
                child: TextButton.icon(
                  onPressed: c.estado == 'PAGADO' ? null : () => _abrirCobro(c),
                  icon: const Icon(Icons.payments, size: 18),
                  label: Text('COBRAR', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  style: TextButton.styleFrom(
                    foregroundColor: c.estado == 'PAGADO' ? Colors.grey : primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool big = false, Color? color}) {
    final c = color ?? onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: big ? 14 : 13)),
        Text(value,
            style: GoogleFonts.manrope(
                fontSize: big ? 20 : 14,
                fontWeight: big ? FontWeight.w700 : FontWeight.w600,
                color: c)),
      ],
    );
  }

  String _formatDate(String iso) {
    if (iso.length >= 10) return iso.substring(8, 10) + '/' + iso.substring(5, 7);
    return iso;
  }
}

// =================== Sheet de cobro ===================

class _CobroSheet extends StatefulWidget {
  final CreditoCobro credito;
  const _CobroSheet({required this.credito});

  @override
  State<_CobroSheet> createState() => _CobroSheetState();
}

class _CobroSheetState extends State<_CobroSheet> {
  bool _isSaving = false;
  final _amountController = TextEditingController();
  final _observacionController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.credito;
    final mq = MediaQuery.of(context);
    final saldo = c.saldoPendiente;
    final quickAmounts = [50.0, 100.0, 200.0, 500.0, saldo >= 100 ? 1000.0 : saldo];

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
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
            _header(c),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _seccion('Monto rápido'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final a in quickAmounts) _amountChip(a),
                        _amountChip(saldo, label: 'SALDO', highlight: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _seccion('Monto a cobrar'),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                      ],
                      decoration: InputDecoration(
                        labelText: 'Ingrese el monto',
                        prefixText: 'S/ ',
                        prefixStyle: const TextStyle(
                            color: Color(0xFF00236F), fontWeight: FontWeight.w600),
                        filled: true,
                        fillColor: const Color(0xFFF0F3FF),
                        border: _border(),
                        enabledBorder: _border(),
                        focusedBorder: _border(focused: true),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _seccion('Observación'),
                    TextField(
                      controller: _observacionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notas (opcional)',
                        filled: true,
                        fillColor: const Color(0xFFF0F3FF),
                        border: _border(),
                        enabledBorder: _border(),
                        focusedBorder: _border(focused: true),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _resumen(c),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : () => _confirmar(c),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.payments),
                        label: Text('CONFIRMAR COBRANZA',
                            style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00236F),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(CreditoCobro c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registrar cobranza',
                    style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00236F))),
                Text('${c.cliente.nombre} · ${c.cliente.documento ?? '-'}',
                    style: GoogleFonts.inter(color: const Color(0xFF444651), fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _seccion(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: const Color(0xFF444651))),
      );

  Widget _amountChip(double amount, {String? label, bool highlight = false}) {
    final color = highlight ? const Color(0xFF006C49) : const Color(0xFF00236F);
    return InkWell(
      onTap: () {
        _amountController.text =
            amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFF6CF8BB) : const Color(0xFFF0F3FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label != null ? label : 'S/ ${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: color, fontSize: 13),
        ),
      ),
    );
  }

  Widget _resumen(CreditoCobro c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _resRow('Saldo pendiente', 'S/ ${c.saldoPendiente.toStringAsFixed(2)}',
              color: const Color(0xFF00236F)),
          if (c.proximaCuota != null) ...[
            const SizedBox(height: 4),
            _resRow('Próx. cuota',
                'N° ${c.proximaCuota!.numero} · ${c.proximaCuota!.vencimiento}'),
          ],
          if (c.cuotasVencidas > 0) ...[
            const SizedBox(height: 4),
            _resRow('Cuotas vencidas', '${c.cuotasVencidas}', color: const Color(0xFFBA1A1A)),
          ],
        ],
      ),
    );
  }

  Widget _resRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: const Color(0xFF444651), fontSize: 13)),
        Text(value,
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700, fontSize: 14, color: color ?? const Color(0xFF00236F))),
      ],
    );
  }

  OutlineInputBorder _border({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: focused ? const Color(0xFF00236F) : const Color(0xFFC5C5D3),
        width: focused ? 2 : 1,
      ),
    );
  }

  Future<void> _confirmar(CreditoCobro c) async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      _toast('Ingrese un monto válido');
      return;
    }
    if (amount > c.saldoPendiente) {
      _toast('El monto no puede ser mayor al saldo pendiente');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final result = await CobrosService.guardarCobro(
        creditoId: c.id,
        clienteId: c.clienteId,
        monto: amount,
        fechaRecibo: DateTime.now().toIso8601String().substring(0, 10),
        fechaPago: DateTime.now().toIso8601String().substring(0, 10),
        observacion: _observacionController.text.trim(),
      );

      if (!mounted) return;
      if (result.exito) {
        Navigator.of(context).pop(true);
        if (result.pendienteOffline) {
          await _mostrarExitoOffline(c, amount, result.idLocal ?? '');
        } else {
          await _mostrarExito(c, amount, result.saldoRestante);
        }
      } else {
        _toast(result.mensaje ?? 'No se pudo registrar la cobranza');
      }
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Error de conexión al guardar la cobranza');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _mostrarExitoOffline(
      CreditoCobro c, double amount, String idLocal) async {
    final ticket = idLocal.length > 8
        ? idLocal.substring(0, 4).toUpperCase() +
            '…' +
            idLocal.substring(idLocal.length - 4).toUpperCase()
        : idLocal.toUpperCase();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE0B2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off, color: Color(0xFFB45309), size: 48),
              ),
              const SizedBox(height: 20),
              Text('Cobranza guardada sin conexión',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Se enviará automáticamente al reconectar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: const Color(0xFF444651), fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('S/ ${amount.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00236F))),
                    const SizedBox(height: 4),
                    Text('Recibo #$ticket',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF444651),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(c.cliente.nombre,
                  style: GoogleFonts.inter(color: const Color(0xFF444651))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC5C5D3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('VOLVER',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await SyncService.instance.flushNow();
                      },
                      icon: const Icon(Icons.cloud_upload, size: 18),
                      label: Text('NUEVA COBRANZA',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00236F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarExito(CreditoCobro c, double amount, double? saldoRestante) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF6CF8BB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF00236F), size: 48),
              ),
              const SizedBox(height: 20),
              Text('¡Cobranza Registrada!',
                  style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('S/ ${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00236F))),
              ),
              const SizedBox(height: 12),
              Text(c.cliente.nombre,
                  style: GoogleFonts.inter(color: const Color(0xFF444651))),
              if (saldoRestante != null && saldoRestante > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFB45309), size: 18),
                      const SizedBox(width: 6),
                      Text('Saldo restante: S/ ${saldoRestante.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // volver home
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC5C5D3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('VOLVER',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00236F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('NUEVA COBRANZA',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}

// =================== Sheet de detalle ===================

class _DetalleSheet extends StatefulWidget {
  final int creditoId;
  const _DetalleSheet({required this.creditoId});

  @override
  State<_DetalleSheet> createState() => _DetalleSheetState();
}

class _DetalleSheetState extends State<_DetalleSheet> {
  CreditoDetalle? _detalle;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final d = await CobrosService.getDetalle(widget.creditoId);
      if (!mounted) return;
      if (d == null) {
        setState(() {
          _error = 'Detalle no disponible sin conexión';
          _loading = false;
        });
        return;
      }
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
                  Text('Detalle del crédito',
                      style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00236F))),
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
                          child: Text(_error!,
                              style: GoogleFonts.inter(color: const Color(0xFFBA1A1A))))
                      : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final d = _detalle!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card([
            _kv('Cliente', d.cliente.nombre),
            _kv('Documento', d.cliente.documento ?? '-'),
            _kv('Dirección', d.cliente.direccion ?? '-'),
            _kv('Teléfono', d.cliente.telefono ?? '-'),
            _kv('F. crédito', d.fechaCredito ?? '-'),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniStat('Total', 'S/ ${d.montoTotal.toStringAsFixed(2)}', const Color(0xFF00236F))),
              const SizedBox(width: 8),
              Expanded(child: _miniStat('Saldo', 'S/ ${d.saldoPendiente.toStringAsFixed(2)}', const Color(0xFF006C49))),
            ],
          ),
          const SizedBox(height: 16),
          Text('Productos', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _tablaProductos(d.productos),
          const SizedBox(height: 16),
          Text('Cuotas', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _tablaCuotas(d.cuotas),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC5C5D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 90,
                child: Text('$k:',
                    style: GoogleFonts.inter(color: const Color(0xFF444651), fontSize: 12))),
            Expanded(
                child: Text(v,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF151C27)))),
          ],
        ),
      );

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(color: const Color(0xFF444651), fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.manrope(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _tablaProductos(List<ProductoDetalle> list) {
    if (list.isEmpty) return Text('Sin productos.', style: GoogleFonts.inter(color: const Color(0xFF444651)));
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC5C5D3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: i.isEven ? const Color(0xFFFFFFFF) : const Color(0xFFF0F3FF),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: Text(list[i].nombre,
                          style: GoogleFonts.inter(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  Text('x${list[i].cantidad.toStringAsFixed(list[i].cantidad % 1 == 0 ? 0 : 2)}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF444651))),
                  const SizedBox(width: 12),
                  Text('S/ ${list[i].importe.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                          fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF00236F))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tablaCuotas(List<CuotaDetalle> list) {
    if (list.isEmpty) return Text('Sin cuotas.', style: GoogleFonts.inter(color: const Color(0xFF444651)));
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFC5C5D3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: i.isEven ? const Color(0xFFFFFFFF) : const Color(0xFFF0F3FF),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${list[i].numero}',
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF00236F))),
                  ),
                  Expanded(
                    child: Text(list[i].vencimiento,
                        style: GoogleFonts.inter(fontSize: 12)),
                  ),
                  Text('S/ ${list[i].saldo.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                          fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF00236F))),
                  const SizedBox(width: 8),
                  _estadoChip(list[i].estado),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _estadoChip(String estado) {
    Color c;
    String label;
    switch (estado) {
      case 'COBRADA':
        c = const Color(0xFF006C49);
        label = 'OK';
        break;
      case 'REPROGRAMADA':
        c = const Color(0xFFB45309);
        label = 'REPRO';
        break;
      default:
        c = const Color(0xFF7C3AED);
        label = 'PEND';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }
}
