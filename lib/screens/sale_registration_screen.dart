import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/sync_service.dart';
import '../models/venta_data.dart';
import '../services/api_client.dart';
import '../services/venta_service.dart';
import '../widgets/offline_banner.dart';

class SaleRegistrationScreen extends StatefulWidget {
  const SaleRegistrationScreen({super.key});

  @override
  State<SaleRegistrationScreen> createState() => _SaleRegistrationScreenState();
}

class _SaleRegistrationScreenState extends State<SaleRegistrationScreen> {
  // Theme
  static const Color primary = Color(0xFF00236F);
  static const Color primaryContainer = Color(0xFF1E3A8A);
  static const Color onPrimaryContainer = Color(0xFF90A8FF);
  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color onSecondaryContainer = Color(0xFF00714D);
  static const Color danger = Color(0xFFBA1A1A);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFE7EEFE);
  static const Color surfaceContainerLow = Color(0xFFF0F3FF);
  static const Color outlineVariant = Color(0xFFC5C5D3);
  static const Color onSurface = Color(0xFF151C27);
  static const Color onSurfaceVariant = Color(0xFF444651);

  // Estado de carga
  VentaData? _data;
  bool _isLoading = true;
  String? _error;

  // POS state
  String _tipoVenta = 'CONTADO'; // CONTADO | CREDITO
  String _search = '';
  final List<_CartLine> _cart = [];

  // Form de cobro
  final _numDocController = TextEditingController();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _celularController = TextEditingController();
  final _correoController = TextEditingController();
  final _totalRecibidoController = TextEditingController();
  final _numOperacionController = TextEditingController();
  final _observacionController = TextEditingController();
  final _searchClienteController = TextEditingController();

  Comprobante? _comprobante;
  TipoDocumento? _tipoDocIdentidad;
  FormaPago? _formaPago;
  Banco? _banco;
  SectorOpcion? _sector;
  ClienteVenta? _cliente;
  List<ClienteVenta> _clienteSugeridos = [];
  Timer? _clienteDebounce;

  bool _isSaving = false;
  bool _isConsulting = false;

  // Campos de crédito
  String _conceptoCreditoId = '';
  int _numCuotas = 1;
  DateTime _fechaPrimeraCuota = DateTime.now().add(const Duration(days: 30));
  double _cuotaInicial = 0;
  FormaPago? _inicialFormaPago;
  String _inicialNumeroOperacion = '';

  // Resultados
  String? _savedComprobante;

  @override
  void initState() {
    super.initState();
    _totalRecibidoController.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _clienteDebounce?.cancel();
    _numDocController.dispose();
    _nombreController.dispose();
    _direccionController.dispose();
    _celularController.dispose();
    _correoController.dispose();
    _totalRecibidoController.dispose();
    _numOperacionController.dispose();
    _observacionController.dispose();
    _searchClienteController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await VentaService.getVentaData();
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
        _comprobante = _data!.comprobantes.isNotEmpty
            ? _data!.comprobantes.firstWhere(
                (c) => c.nombre.toUpperCase().contains('NOTA DE VENTA'),
                orElse: () => _data!.comprobantes.first,
              )
            : null;
        _tipoDocIdentidad = _data!.tipoDocumentos.isNotEmpty
            ? _data!.tipoDocumentos.firstWhere(
                (t) => t.nombre.toUpperCase().contains('DNI'),
                orElse: () => _data!.tipoDocumentos.first)
            : null;
        _formaPago = _data!.formaPagos.isNotEmpty ? _data!.formaPagos.first : null;
        _banco = _data!.bancos.isNotEmpty ? _data!.bancos.first : null;
        _sector = _data!.sectores.isNotEmpty ? _data!.sectores.first : null;
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

  // =================== Helpers ===================

  bool get _esEfectivo {
    final n = _formaPago?.nombre.toLowerCase() ?? '';
    return n.contains('efectivo');
  }

  bool get _esOperativo {
    final n = _formaPago?.nombre.toLowerCase() ?? '';
    return n.contains('yape') || n.contains('plin') ||
        n.contains('transfer') || n.contains('operaci');
  }

  double get _total {
    return _cart.fold<double>(0, (s, l) => s + l.subtotal);
  }

  int get _itemsCount => _cart.fold<int>(0, (s, l) => s + l.cantidad.toInt());

  double get _cambio {
    final recibido = double.tryParse(_totalRecibidoController.text) ?? 0;
    return recibido > _total ? recibido - _total : 0;
  }

  // =================== Carrito ===================

  void _agregarProducto(ProductoVenta p) {
    setState(() {
      final idx = _cart.indexWhere((l) => l.idProducto == p.id);
      final precio = _tipoVenta == 'CREDITO' ? p.precioCredito : p.precioContado;
      if (idx >= 0) {
        if (_cart[idx].cantidad < p.stock) {
          _cart[idx].cantidad += 1;
          _cart[idx].precio = precio;
        } else {
          _toast('No hay más stock disponible para ${p.nombre}');
        }
      } else {
        if (p.stock > 0) {
          _cart.add(_CartLine(
            idProducto: p.id,
            nombre: p.nombre,
            precio: precio,
            cantidad: 1,
            maxStock: p.stock,
            ubicacion: p.ubicacionId > 0 ? p.ubicacionId : (_data?.movilesUbicacionId ?? 0),
          ));
        } else {
          _toast('Sin stock: ${p.nombre}');
        }
      }
    });
  }

  void _quitarCantidad(int index) {
    setState(() {
      final item = _cart[index];
      if (item.cantidad > 1) {
        item.cantidad -= 1;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  void _aumentarCantidad(int index) {
    setState(() {
      _cart[index].cantidad += 1;
    });
  }

  void _eliminarLinea(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _vaciarCarrito() {
    if (_cart.isEmpty) return;
    setState(() {
      _cart.clear();
      _cliente = null;
      _numDocController.clear();
      _nombreController.clear();
      _direccionController.clear();
      _celularController.clear();
      _correoController.clear();
      _totalRecibidoController.clear();
      _numOperacionController.clear();
      _observacionController.clear();
      _searchClienteController.clear();
      _clienteSugeridos = [];
    });
  }

  void _cambiarTipoVenta(String nuevo) {
    if (nuevo == _tipoVenta) return;
    setState(() {
      _tipoVenta = nuevo;
      // Re-precio con la lista correspondiente
      for (final line in _cart) {
        final prod = _data?.productos.firstWhere(
          (p) => p.id == line.idProducto,
          orElse: () => ProductoVenta(
              id: line.idProducto,
              nombre: line.nombre,
              codigoBarras: null,
              stock: line.maxStock,
              precioContado: line.precio,
              precioCredito: line.precio,
              ubicacionId: line.ubicacion,
          ),
        );
        if (prod != null) {
          line.precio = nuevo == 'CREDITO' ? prod.precioCredito : prod.precioContado;
        }
      }
    });
  }

  // =================== Cliente ===================

  void _onSearchCliente(String q) {
    _clienteDebounce?.cancel();
    _clienteDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (q.trim().isEmpty) {
        setState(() => _clienteSugeridos = []);
        return;
      }
      try {
        final lista = await VentaService.buscarClientes(q);
        if (!mounted) return;
        setState(() => _clienteSugeridos = lista);
      } catch (_) {}
    });
  }

  void _seleccionarCliente(ClienteVenta c) {
    setState(() {
      _cliente = c;
      _searchClienteController.text = c.nombre;
      _clienteSugeridos = [];
      _numDocController.text = c.documento ?? '';
      _nombreController.text = c.nombre;
      _direccionController.text = c.direccion ?? '';
      _celularController.text = c.telefono ?? '';
      if (c.tipoDoc != null) {
        final td = _data?.tipoDocumentos.firstWhere(
          (t) => t.id == c.tipoDoc,
          orElse: () => _data!.tipoDocumentos.first,
        );
        if (td != null) _tipoDocIdentidad = td;
      }
      if (c.sectorId != null) {
        final sec = _data?.sectores.firstWhere(
          (s) => s.id == c.sectorId,
          orElse: () => _data!.sectores.first,
        );
        if (sec != null) _sector = sec;
      }
    });
  }

  Future<void> _consultarDniRuc() async {
    final num = _numDocController.text.trim();
    if (num.isEmpty) {
      _toast('Ingrese un número de documento');
      return;
    }
    final tipo = _tipoDocIdentidad?.id ?? 1;
    setState(() => _isConsulting = true);
    try {
      final resp = await VentaService.consultarDniRuc(
        tipoDocumento: tipo,
        numDoc: num,
      );

      String? nombre;
      String? direccion;
      String? telefono;

      if (resp['origen'] == 'base_datos' && resp['cliente'] is Map) {
        final cli = resp['cliente'] as Map<String, dynamic>;
        nombre = (cli['nombres']?.toString().isNotEmpty == true)
            ? '${cli['nombres']} ${cli['apellidos'] ?? ''}'.trim()
            : cli['razon_social']?.toString();
        direccion = cli['direccion']?.toString();
        telefono = cli['telefono']?.toString();
      } else if (resp['data'] is Map) {
        final data = resp['data'] as Map<String, dynamic>;
        if (tipo == 1) {
          final n = data['nombres']?.toString() ?? '';
          final aP = data['apellido_paterno']?.toString() ?? '';
          final aM = data['apellido_materno']?.toString() ?? '';
          nombre = '$n $aP $aM'.trim();
        } else {
          nombre = data['razon_social']?.toString() ?? data['nombre_comercial']?.toString();
        }
        direccion = data['direccion']?.toString() ?? data['only_direccion']?.toString();
      }

      if (!mounted) return;
      if (nombre != null && nombre.isNotEmpty) {
        setState(() {
          _nombreController.text = nombre!;
          if (direccion != null && direccion.isNotEmpty) _direccionController.text = direccion;
          if (telefono != null && telefono.isNotEmpty) _celularController.text = telefono;
        });
        _toast('Datos cargados');
      } else {
        _toast('No se encontraron datos para ese documento');
      }
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('No se pudo consultar el documento');
    } finally {
      if (mounted) setState(() => _isConsulting = false);
    }
  }

  // =================== Cobro ===================

  void _abrirCobro() {
    if (_cart.isEmpty) {
      _toast('El carrito está vacío');
      return;
    }
    if (_tipoVenta == 'CREDITO' && _numDocController.text.trim().isEmpty) {
      _toast('Para venta a crédito debe seleccionar un cliente');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CobroSheet(state: this),
    );
  }

  // =================== Helpers Crédito ===================

  String _generarCuotasData() {
    final cuotas = <Map<String, dynamic>>[];
    final numCuotas = _numCuotas;
    final totalVenta = _total;
    final inicial = _cuotaInicial;
    final capital = (totalVenta - inicial).clamp(0, double.infinity);
    final montoCuota = numCuotas > 0 ? (capital / numCuotas) : 0.0;

    // Si hay inicial, agregarla como cuota 0
    if (inicial > 0) {
      cuotas.add({
        'numero': 0,
        'monto': inicial.toStringAsFixed(2),
        'fecha_vencimiento': DateTime.now().toIso8601String().split('T').first,
      });
    }

    // Agregar las cuotas
    var currentDate = _fechaPrimeraCuota;
    for (var i = 1; i <= numCuotas; i++) {
      cuotas.add({
        'numero': i,
        'monto': montoCuota.toStringAsFixed(2),
        'fecha_vencimiento': currentDate.toIso8601String().split('T').first,
      });
      currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
    }

    return jsonEncode(cuotas);
  }

  Future<void> _guardarVenta({bool confirmarCredito = false}) async {
    if (_isSaving) return;
    if (_formaPago == null) {
      _toast('Seleccione una forma de pago');
      return;
    }
    if (_esOperativo && _numOperacionController.text.trim().isEmpty) {
      _toast('Ingrese el número de operación');
      return;
    }
    if (_esOperativo && _banco == null) {
      _toast('Seleccione un banco');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await VentaService.guardarVenta(
        tipoComprobante: _comprobante?.id ?? 1,
        numeroDocumento: _numDocController.text.trim(),
        tipoDocumentoIdentidad: _tipoDocIdentidad?.id ?? 1,
        nombreCliente: _nombreController.text.trim().isNotEmpty
            ? _nombreController.text.trim()
            : 'CLIENTE VARIOS',
        celularCliente: _celularController.text.trim(),
        direccionCliente: _direccionController.text.trim(),
        correoCliente: _correoController.text.trim(),
        sectores: _sector?.id,
        tipoVenta: _tipoVenta == 'CREDITO' ? 2 : 1,
        formaPago: _formaPago!.id,
        totalVenta: _total,
        montosParticionados: const <num>[],
        items: _cart
            .map((l) => ItemVenta(
                  idProducto: l.idProducto,
                  nombre: l.nombre,
                  cantidad: l.cantidad,
                  precio: l.precio,
                  ubicacion: l.ubicacion,
                ))
            .toList(),
        confirmarCredito: confirmarCredito,
        conceptoCreditoId: _conceptoCreditoId,
        cuotasData: _generarCuotasData(),
        cuotaInicial: _cuotaInicial,
        inicialFormaPago: _inicialFormaPago?.id.toString() ?? '',
        inicialNumeroOperacion: _inicialNumeroOperacion,
      );

      if (!mounted) return;

      if (result.creditoActivo) {
        Navigator.of(context).pop(); // cierra el sheet
        _mostrarModalCredito(result.credito!);
        return;
      }

      if (result.exito) {
        Navigator.of(context).pop(); // cierra el sheet
        _savedComprobante = 'VENTA REGISTRADA';
        if (result.pendienteOffline) {
          _mostrarExitoOffline(result.idLocal ?? '');
        } else {
          _mostrarExito();
        }
        return;
      }

      _toast(result.mensaje ?? 'No se pudo registrar la venta');
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (e, st) {
      _toast('Error de conexión al guardar la venta: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // =================== Modales & mensajes ===================

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _mostrarExito() {
    showDialog(
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
                  color: secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: primary, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                '¡Venta Registrada!',
                style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _tipoVenta == 'CREDITO' ? 'Venta a crédito' : 'Venta al contado',
                style: GoogleFonts.inter(color: onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total: S/ ${_total.toStringAsFixed(2)}',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // volver a home
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: outlineVariant),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('VOLVER', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        _vaciarCarrito();
                        await _cargar();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('NUEVA VENTA',
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

  void _mostrarExitoOffline(String idLocal) {
    final ticket = idLocal.length > 8
        ? idLocal.substring(0, 4).toUpperCase() + '…' + idLocal.substring(idLocal.length - 4).toUpperCase()
        : idLocal.toUpperCase();
    showDialog(
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
              Text(
                'Venta guardada sin conexión',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Se enviará automáticamente al reconectar',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Total: S/ ${_total.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                            fontSize: 22, fontWeight: FontWeight.w700, color: primary)),
                    const SizedBox(height: 4),
                    Text('Ticket #$ticket',
                        style: GoogleFonts.inter(
                            color: onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(); // volver a home
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: outlineVariant),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('VOLVER', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await SyncService.instance.flushNow();
                        _vaciarCarrito();
                        await _cargar();
                      },
                      icon: const Icon(Icons.cloud_upload, size: 18),
                      label: Text('NUEVA VENTA', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _mostrarModalCredito(Map<String, dynamic> cred) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: danger,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cliente con crédito activo',
                        style: GoogleFonts.manrope(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cred['mensaje']?.toString() ?? 'El cliente ya tiene un crédito activo.',
                        style: GoogleFonts.inter(color: onSurface)),
                    const SizedBox(height: 16),
                    _kv('Sede', cred['sede']?.toString() ?? '-'),
                    _kv('Comprobante', cred['comprobante']?.toString() ?? '-'),
                    _kv('Fecha venta', cred['fecha_venta']?.toString() ?? '-'),
                    _kv('Fecha crédito', cred['fecha_credito']?.toString() ?? '-'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _miniStat('Monto total',
                            'S/ ${_asDouble(cred['monto_total']).toStringAsFixed(2)}',
                            primary),
                        const SizedBox(width: 8),
                        _miniStat('Saldo',
                            'S/ ${_asDouble(cred['saldo_pendiente']).toStringAsFixed(2)}',
                            const Color(0xFFB45309)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _miniStat('Cuotas venc.',
                            '${cred['cuotas_vencidas'] ?? 0}', danger),
                        const SizedBox(width: 8),
                        _miniStat('Total cuotas',
                            '${cred['cuotas_totales'] ?? 0}', secondary),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Productos', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _tablaProductos(cred['productos']),
                    const SizedBox(height: 16),
                    Text('Cuotas', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _tablaCuotas(cred['cuotas']),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: outlineVariant),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('CANCELAR',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _guardarVenta(confirmarCredito: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('CONFIRMAR',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
                width: 110,
                child: Text('$k:',
                    style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 13))),
            Expanded(
                child: Text(v,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 13, color: onSurface))),
          ],
        ),
      );

  Widget _miniStat(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.manrope(
                      fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      );

  Widget _tablaProductos(dynamic raw) {
    final list = (raw is List) ? raw : const [];
    if (list.isEmpty) {
      return Text('Sin productos registrados.',
          style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 12));
    }
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: outlineVariant), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: i.isEven ? surfaceContainerLowest : surfaceContainerLow,
              ),
              child: Row(
                children: [
                  Expanded(
                      child: Text(list[i]['nombre']?.toString() ?? '-',
                          style: GoogleFonts.inter(fontSize: 12))),
                  Text('x${list[i]['cantidad'] ?? 0}',
                      style: GoogleFonts.inter(fontSize: 12, color: onSurfaceVariant)),
                  const SizedBox(width: 12),
                  Text('S/ ${_asDouble(list[i]['importe']).toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                          fontSize: 13, fontWeight: FontWeight.w600, color: primary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tablaCuotas(dynamic raw) {
    final list = (raw is List) ? raw : const [];
    if (list.isEmpty) {
      return Text('Sin cuotas registradas.',
          style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 12));
    }
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: outlineVariant), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: i.isEven ? surfaceContainerLowest : surfaceContainerLow,
              ),
              child: Row(
                children: [
                  SizedBox(
                      width: 28,
                      child: Text('${list[i]['numero'] ?? (i + 1)}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                  Expanded(
                      child: Text(list[i]['vencimiento']?.toString() ?? '-',
                          style: GoogleFonts.inter(fontSize: 12))),
                  Text('S/ ${_asDouble(list[i]['monto']).toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                          fontSize: 12, fontWeight: FontWeight.w600, color: primary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  // =================== Build ===================

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Registrar Venta',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        actions: [
          if (_itemsCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag, color: primary, size: 16),
                      const SizedBox(width: 4),
                      Text('$_itemsCount',
                          style: GoogleFonts.manrope(
                              color: primary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
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
                : (_error != null
                    ? _buildError()
                    : (isDesktop ? _buildDesktopLayout() : _buildMobileLayout())),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(child: _buildProductosPanel()),
        _buildBottomCartBar(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildProductosPanel()),
        Container(
          width: 1,
          color: outlineVariant,
        ),
        SizedBox(
          width: 380,
          child: _buildCarritoPanel(),
        ),
      ],
    );
  }

  Widget _buildProductosPanel() {
    final productos = _data?.productos ?? const [];
    final filtered = _search.isEmpty
        ? productos
        : productos
            .where((p) => p.nombre.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    if (_data == null) return const SizedBox.shrink();

    if (productos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Sin productos cargados hoy',
                  style: GoogleFonts.manrope(
                      fontSize: 18, fontWeight: FontWeight.w600, color: onSurface)),
              const SizedBox(height: 8),
              Text(
                'No se encontraron productos en tu ubicación "Móviles" para hoy.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildSearchAndTabs(),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('No hay coincidencias para "$_search"',
                      style: GoogleFonts.inter(color: onSurfaceVariant)),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildProductCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndTabs() {
    return Container(
      color: surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: outlineVariant),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar producto...',
                      hintStyle: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: onSurfaceVariant),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _tipoChip('CONTADO', Icons.payments_outlined),
              const SizedBox(width: 8),
              _tipoChip('CRÉDITO', Icons.credit_card),
              const Spacer(),
              Text(
                '${productosFiltrados.length} productos',
                style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<ProductoVenta> get productosFiltrados {
    final all = _data?.productos ?? const [];
    if (_search.isEmpty) return all;
    return all
        .where((p) => p.nombre.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  Widget _tipoChip(String label, IconData icon) {
    final selected = _tipoVenta ==
        (label == 'CONTADO' ? 'CONTADO' : 'CREDITO');
    final color = selected ? onSecondaryContainer : onSurfaceVariant;
    final bg = selected ? secondaryContainer : surfaceContainerLow;
    return InkWell(
      onTap: () => _cambiarTipoVenta(label == 'CONTADO' ? 'CONTADO' : 'CREDITO'),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? secondary : outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductoVenta p) {
    final inCart = _cart.indexWhere((l) => l.idProducto == p.id);
    final cant = inCart >= 0 ? _cart[inCart].cantidad.toInt() : 0;
    final precio = _tipoVenta == 'CREDITO' ? p.precioCredito : p.precioContado;
    final color = _tipoVenta == 'CREDITO' ? const Color(0xFFB45309) : primary;

    return InkWell(
      onTap: p.stock > 0 ? () => _agregarProducto(p) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cant > 0 ? color : outlineVariant,
            width: cant > 0 ? 2 : 1,
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p.stock > 0
                        ? secondaryContainer.withOpacity(0.4)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Stock: ${p.stock}',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: p.stock > 0 ? secondary : Colors.grey[600]),
                  ),
                ),
                const Spacer(),
                if (cant > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration:
                        BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                    child: Text('x$cant',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Center(
                child: Text(
                  p.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 12, color: onSurface),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('S/ ${precio.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                          fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== Carrito panel / bottom bar ===================

  Widget _buildBottomCartBar() {
    return Container(
      decoration: BoxDecoration(
        color: primary,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () => _showCartSheet(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                const SizedBox(width: 8),
                Text('Ver carrito (${_itemsCount})',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('S/ ${_total.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                          color: primary, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, ctrl) => Container(
              decoration: const BoxDecoration(
                color: surfaceContainerLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
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
                  Expanded(child: _buildCarritoContent(ctrl, setSheetState)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarritoPanel() {
    return Container(
      color: surfaceContainerLowest,
      child: _buildCarritoContent(null),
    );
  }

  Widget _buildCarritoContent(ScrollController? scrollController, [StateSetter? setSheetState]) {
    // Helper to force rebuild the sheet
    void rebuild() {
      if (setSheetState != null) {
        setSheetState(() {});
      }
      setState(() {});
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white),
              const SizedBox(width: 8),
              Text('Carrito',
                  style: GoogleFonts.manrope(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: secondaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Text('$_itemsCount ítems',
                    style: GoogleFonts.manrope(
                        color: primary, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Carrito vacío',
                          style: GoogleFonts.inter(
                              color: onSurfaceVariant, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _cart.length,
                  itemBuilder: (_, i) => _buildCartItem(i, setSheetState),
                ),
        ),
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: surfaceContainerLowest,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: GoogleFonts.inter(
                          color: onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 14)),
                  Text('S/ ${_total.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                          fontSize: 28, fontWeight: FontWeight.w700, color: primary)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _cart.isEmpty ? null : _abrirCobro,
                  icon: const Icon(Icons.point_of_sale, size: 24),
                  label: Text('COBRAR',
                      style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(int index, [StateSetter? setSheetState]) {
    final item = _cart[index];

    void _handleEliminar() {
      _eliminarLinea(index);
      if (setSheetState != null) {
        setSheetState(() {});
      }
      setState(() {});
    }

    void _handleMenos() {
      _quitarCantidad(index);
      if (setSheetState != null) {
        setSheetState(() {});
      }
      setState(() {});
    }

    void _handleMas() {
      _aumentarCantidad(index);
      if (setSheetState != null) {
        setSheetState(() {});
      }
      setState(() {});
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila principal: info del producto
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombre,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'S/ ${item.precio.toStringAsFixed(2)} c/u',
                      style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Subtotal
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'S/ ${item.subtotal.toStringAsFixed(2)}',
                    style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700, fontSize: 16, color: primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.cantidad.toInt()} und.',
                    style: GoogleFonts.inter(color: onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Fila de controles
          Row(
            children: [
              // Botón eliminar
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleEliminar,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, size: 22, color: danger),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Controles de cantidad
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón menos
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleMenos,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.remove, size: 24, color: primary),
                          ),
                        ),
                      ),
                      // Cantidad
                      Text(
                        '${item.cantidad.toInt()}',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          color: primary,
                          fontSize: 20,
                        ),
                      ),
                      // Botón más
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleMas,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.add, size: 24, color: primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =================== Modelo interno ===================

class _CartLine {
  int idProducto;
  String nombre;
  double precio;
  double cantidad;
  int maxStock;
  int ubicacion;

  _CartLine({
    required this.idProducto,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.maxStock,
    required this.ubicacion,
  });

  double get subtotal => precio * cantidad;
}

// =================== Sheet de cobro ===================

class _CobroSheet extends StatefulWidget {
  final _SaleRegistrationScreenState state;
  const _CobroSheet({required this.state});

  @override
  State<_CobroSheet> createState() => _CobroSheetState();
}

class _CobroSheetState extends State<_CobroSheet> {
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final mq = MediaQuery.of(context);

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
            _header(s),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _seccion('Cliente'),
                    _clienteSearch(s),
                    if (s._clienteSugeridos.isNotEmpty) _clienteSugeridosList(s),
                    const SizedBox(height: 12),
                    _tipoDocRow(s),
                    const SizedBox(height: 12),
                    _field('N° Documento', s._numDocController,
                        suffix: s._isConsulting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                onPressed: s._consultarDniRuc,
                                icon: const Icon(Icons.search, color: Color(0xFF00236F)),
                                tooltip: 'Consultar',
                              )),
                    const SizedBox(height: 12),
                    _field('Nombre / Razón Social', s._nombreController),
                    const SizedBox(height: 12),
                    _field('Dirección', s._direccionController),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field('Celular', s._celularController, phone: true)),
                        const SizedBox(width: 8),
                        Expanded(child: _field('Correo', s._correoController, email: true)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _dropdown<SectorOpcion>(
                      label: 'Sector',
                      value: s._sector,
                      items: s._data?.sectores ?? [],
                      labelOf: (e) => e.nombre,
                      onChanged: (v) => setState(() => s._sector = v),
                    ),
                    const SizedBox(height: 16),
                    _seccion('Comprobante y pago'),
                    Row(
                      children: [
                        Expanded(
                          child: _dropdown<Comprobante>(
                            label: 'Comprobante',
                            value: s._comprobante,
                            items: s._data?.comprobantes ?? [],
                            labelOf: (e) => e.nombre,
                            onChanged: (v) => setState(() => s._comprobante = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dropdown<FormaPago>(
                            label: 'Forma de pago',
                            value: s._formaPago,
                            items: s._data?.formaPagos ?? [],
                            labelOf: (e) => e.nombre,
                            onChanged: (v) => setState(() => s._formaPago = v),
                          ),
                        ),
                      ],
                    ),
                    if (s._esEfectivo) ...[
                      const SizedBox(height: 12),
                      _field('Total recibido', s._totalRecibidoController,
                          numeric: true, prefix: 'S/ '),
                      if (s._totalRecibidoController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006C49).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text('Vuelto:',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500, color: const Color(0xFF006C49))),
                              const Spacer(),
                              Text('S/ ${s._cambio.toStringAsFixed(2)}',
                                  style: GoogleFonts.manrope(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF006C49))),
                            ],
                          ),
                        ),
                      ],
                    ],
                    if (s._esOperativo) ...[
                      const SizedBox(height: 12),
                      _field('N° de operación', s._numOperacionController),
                      const SizedBox(height: 12),
                      _dropdown<Banco>(
                        label: 'Banco',
                        value: s._banco,
                        items: s._data?.bancos ?? [],
                        labelOf: (e) => '${e.banco} - ${e.numeroCuenta ?? ''}',
                        onChanged: (v) => setState(() => s._banco = v),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _field('Observación', s._observacionController, maxLines: 2),
                    const SizedBox(height: 16),
                    _seccion('Resumen'),
                    _resumen(s),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          s._guardarVenta();
                        },
                        icon: s._isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save),
                        label: Text(
                          s._tipoVenta == 'CREDITO' ? 'REGISTRAR CRÉDITO' : 'PROCESAR VENTA',
                          style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
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

  Widget _header(_SaleRegistrationScreenState s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Text('Cobrar venta',
              style: GoogleFonts.manrope(
                  fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF00236F))),
          const Spacer(),
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

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool numeric = false,
    bool phone = false,
    bool email = false,
    int maxLines = 1,
    String? prefix,
    Widget? suffix,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: (numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : (phone
                  ? TextInputType.phone
                  : (email ? TextInputType.emailAddress : TextInputType.text))),
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixStyle: const TextStyle(color: Color(0xFF00236F), fontWeight: FontWeight.w600),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF0F3FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC5C5D3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC5C5D3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00236F), width: 2),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF0F3FF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFC5C5D3))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFC5C5D3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF00236F), width: 2)),
      ),
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(labelOf(e), overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _clienteSearch(_SaleRegistrationScreenState s) {
    return TextField(
      controller: s._searchClienteController,
      onChanged: s._onSearchCliente,
      decoration: InputDecoration(
        labelText: 'Buscar cliente (opcional)',
        hintText: 'Nombre, DNI o RUC...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF00236F)),
        filled: true,
        fillColor: const Color(0xFFF0F3FF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFC5C5D3))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFC5C5D3))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF00236F), width: 2)),
      ),
    );
  }

  Widget _clienteSugeridosList(_SaleRegistrationScreenState s) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC5C5D3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: s._clienteSugeridos.length,
          itemBuilder: (_, i) {
            final c = s._clienteSugeridos[i];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.person, color: Color(0xFF00236F)),
              title: Text(c.nombre, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text('${c.documento ?? '-'}',
                  style: GoogleFonts.inter(fontSize: 12)),
              onTap: () => s._seleccionarCliente(c),
            );
          },
        ),
      ),
    );
  }

  Widget _tipoDocRow(_SaleRegistrationScreenState s) {
    return _dropdown<TipoDocumento>(
      label: 'Tipo de documento',
      value: s._tipoDocIdentidad,
      items: s._data?.tipoDocumentos ?? [],
      labelOf: (e) => e.nombre,
      onChanged: (v) => setState(() => s._tipoDocIdentidad = v),
    );
  }

  Widget _resumen(_SaleRegistrationScreenState s) {
    final itemsCount = s._itemsCount;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _resumenRow('Ítems', '$itemsCount'),
          const SizedBox(height: 4),
          _resumenRow('Tipo', s._tipoVenta == 'CREDITO' ? 'A CRÉDITO' : 'AL CONTADO',
              color: s._tipoVenta == 'CREDITO' ? const Color(0xFFB45309) : const Color(0xFF00236F)),
          const Divider(height: 16, color: Color(0xFFC5C5D3)),
          _resumenRow('TOTAL', 'S/ ${s._total.toStringAsFixed(2)}',
              big: true, color: const Color(0xFF00236F)),
        ],
      ),
    );
  }

  Widget _resumenRow(String label, String value, {bool big = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontWeight: big ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF444651))),
        Text(value,
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: big ? 22 : 14,
                color: color ?? const Color(0xFF00236F))),
      ],
    );
  }
}
