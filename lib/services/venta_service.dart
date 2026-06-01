import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../data/connectivity_service.dart';
import '../data/database_helper.dart';
import '../data/sync_service.dart';
import '../models/venta_data.dart';
import 'api_client.dart';

class ItemVenta {
  final int idProducto;
  final String nombre;
  final double cantidad;
  final double precio;
  final int ubicacion;

  ItemVenta({
    required this.idProducto,
    required this.nombre,
    required this.cantidad,
    required this.precio,
    required this.ubicacion,
  });

  double get importe => cantidad * precio;

  Map<String, dynamic> toJson() => {
        'idproducto': idProducto,
        'nameproducto': nombre,
        'quanty': cantidad,
        'priceproducto': precio,
        'importe': importe,
        'ubicacion': ubicacion,
      };
}

class VentaResult {
  final bool exito;
  final String? mensaje;
  final bool creditoActivo;
  final Map<String, dynamic>? credito;
  final Map<String, dynamic>? raw;
  final bool pendienteOffline;
  final String? idLocal;

  VentaResult({
    required this.exito,
    this.mensaje,
    this.creditoActivo = false,
    this.credito,
    this.raw,
    this.pendienteOffline = false,
    this.idLocal,
  });

  factory VentaResult.fromResponse(Map<String, dynamic> body) {
    final respuesta = (body['respuesta'] ?? '').toString().toLowerCase();
    final creditoActivo =
        body['credito_activo'] == true && body['credito'] is Map;
    return VentaResult(
      exito: respuesta == 'ok' && !creditoActivo,
      mensaje: body['mensaje']?.toString() ?? body['message']?.toString(),
      creditoActivo: creditoActivo,
      credito:
          creditoActivo ? Map<String, dynamic>.from(body['credito'] as Map) : null,
      raw: body,
    );
  }
}

class VentaService {
  static const _cacheKey = 'current';

  /// Trae los datos del día. Si está online, consulta la API y cachea.
  /// Si falla por red, devuelve lo último cacheado (puede ser null).
  /// Devuelve también [vinoDeCache] para que la UI lo sepa.
  static Future<({VentaData? data, bool vinoDeCache, String? error})>
      getVentaData() async {
    try {
      final json = await ApiClient.get('/vendedor/venta');
      await DatabaseHelper.instance.saveCache('cache_venta_data', _cacheKey, json);
      return (data: VentaData.fromJson(json), vinoDeCache: false, error: null);
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        final cached = await DatabaseHelper.instance
            .getCache('cache_venta_data', _cacheKey);
        if (cached != null) {
          return (data: VentaData.fromJson(cached), vinoDeCache: true, error: null);
        }
        return (data: null, vinoDeCache: false, error: e.message);
      }
      rethrow;
    }
  }

  static Future<List<ClienteVenta>> buscarClientes(String query) async {
    final json = await ApiClient.get(
        '/vendedor/clientes/buscar?q=${Uri.encodeQueryComponent(query)}');
    final list = (json['clientes'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ClienteVenta.fromJson)
        .toList();
  }

  /// Construye el body y lo envía. Si está offline (o falla por red), encola
  /// y devuelve un [VentaResult] con `pendienteOffline=true` y `idLocal` para
  /// que la UI muestre el ticket.
  static Future<VentaResult> guardarVenta({
    required int tipoComprobante,
    required String numeroDocumento,
    required int tipoDocumentoIdentidad,
    required String nombreCliente,
    required String? celularCliente,
    required String? direccionCliente,
    required String? correoCliente,
    required int? sectores,
    required int tipoVenta,
    required int formaPago,
    required double totalVenta,
    required List<num> montosParticionados,
    required List<ItemVenta> items,
    int? idVendedor,
  }) async {
    final idLocal = const Uuid().v4();
    final fechaOffline = DateTime.now().toIso8601String();

    final body = <String, dynamic>{
      'documento': tipoComprobante,
      'numeroDocumento': numeroDocumento,
      'tipoDocumentoIdentidad': tipoDocumentoIdentidad,
      'nombre_cliente': nombreCliente,
      'celular_cliente': celularCliente ?? '',
      'direccion_cliente': direccionCliente ?? '',
      'correo_cliente': correoCliente ?? '',
      'sectores': sectores,
      'tipo_venta': tipoVenta,
      'forma_pago': formaPago,
      'total_venta': totalVenta,
      'montoParticionado': montosParticionados.map((e) => e.toDouble()).toList(),
      'idproducto': <int>[],
      'nameproducto': <String>[],
      'quanty': <double>[],
      'priceproducto': <double>[],
      'importe': <double>[],
      'ubicacion': <int>[],
      'id_local': idLocal,
      'fecha_offline_created': fechaOffline,
    };

    for (final item in items) {
      (body['idproducto'] as List).add(item.idProducto);
      (body['nameproducto'] as List).add(item.nombre);
      (body['quanty'] as List).add(item.cantidad);
      (body['priceproducto'] as List).add(item.precio);
      (body['importe'] as List).add(item.importe);
      (body['ubicacion'] as List).add(item.ubicacion);
    }

    if (idVendedor != null) body['vendedor'] = idVendedor;

    if (!ConnectivityService.instance.current) {
      return _encolarYDevolver(idLocal: idLocal, body: body);
    }

    try {
      final raw = await ApiClient.post('/vendedor/venta/guardar', body);
      return VentaResult.fromResponse(raw);
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        return _encolarYDevolver(idLocal: idLocal, body: body);
      }
      rethrow;
    }
  }

  static Future<VentaResult> _encolarYDevolver({
    required String idLocal,
    required Map<String, dynamic> body,
  }) async {
    await DatabaseHelper.instance.encolar(
      idLocal: idLocal,
      tipo: 'venta',
      endpoint: '/vendedor/venta/guardar',
      payload: body,
    );
    SyncService.instance.flush();
    return VentaResult(
      exito: true,
      mensaje: 'Guardado sin conexión — se enviará al reconectar',
      pendienteOffline: true,
      idLocal: idLocal,
    );
  }

  /// DNI = 1, RUC = 6.
  static Future<Map<String, dynamic>> consultarDniRuc({
    required int tipoDocumento,
    required String numDoc,
  }) async {
    final raw = await ApiClient.post('/consultar-dni-ruc', {
      'tipo_documento': tipoDocumento,
      'num_doc': numDoc,
    });
    return raw;
  }

  /// Helper estático para serializar un body antes de enviarlo (útil para debug).
  static String debugBody(Map<String, dynamic> body) =>
      const JsonEncoder.withIndent('  ').convert(body);
}
