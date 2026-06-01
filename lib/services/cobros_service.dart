import 'package:uuid/uuid.dart';
import '../data/connectivity_service.dart';
import '../data/database_helper.dart';
import '../data/sync_service.dart';
import '../models/cobros_data.dart';
import 'api_client.dart';

class CobroResult {
  final bool exito;
  final String? mensaje;
  final int? reciboId;
  final double? saldoRestante;
  final bool pendienteOffline;
  final String? idLocal;

  CobroResult({
    required this.exito,
    this.mensaje,
    this.reciboId,
    this.saldoRestante,
    this.pendienteOffline = false,
    this.idLocal,
  });

  factory CobroResult.fromResponse(Map<String, dynamic> body) {
    return CobroResult(
      exito: body['status'] == true,
      mensaje: body['message']?.toString() ?? body['mensaje']?.toString(),
      reciboId: (body['recibo_id'] as num?)?.toInt(),
      saldoRestante: (body['saldo_restante'] as num?)?.toDouble(),
    );
  }
}

class CobrosService {
  static const _cacheKey = 'current';

  static Future<({CobrosData? data, bool vinoDeCache, String? error})>
      getCobros() async {
    try {
      final json = await ApiClient.get('/vendedor/cobros');
      await DatabaseHelper.instance.saveCache('cache_cobros_data', _cacheKey, json);
      return (data: CobrosData.fromJson(json), vinoDeCache: false, error: null);
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        final cached = await DatabaseHelper.instance
            .getCache('cache_cobros_data', _cacheKey);
        if (cached != null) {
          return (data: CobrosData.fromJson(cached), vinoDeCache: true, error: null);
        }
        return (data: null, vinoDeCache: false, error: e.message);
      }
      rethrow;
    }
  }

  static Future<CreditoDetalle?> getDetalle(int creditoId) async {
    try {
      final json =
          await ApiClient.get('/vendedor/cobros/$creditoId/detalle');
      return CreditoDetalle.fromJson(json);
    } on ApiException catch (e) {
      if (e.isNetworkError) return null;
      rethrow;
    }
  }

  static Future<CobroResult> guardarCobro({
    required int creditoId,
    required int clienteId,
    required double monto,
    required String fechaRecibo,
    required String fechaPago,
    String? observacion,
    String? docuRef,
  }) async {
    final idLocal = const Uuid().v4();
    final fechaOffline = DateTime.now().toIso8601String();

    final body = <String, dynamic>{
      'credito_id': creditoId,
      'cliente_id': clienteId,
      'mont_rec': monto,
      'fech_rec': fechaRecibo,
      'fpag_rec': fechaPago,
      'id_local': idLocal,
      'fecha_offline_created': fechaOffline,
      if (observacion != null && observacion.isNotEmpty) 'obse_rec': observacion,
      if (docuRef != null && docuRef.isNotEmpty) 'docu_ref': docuRef,
    };

    if (!ConnectivityService.instance.current) {
      return _encolarYDevolver(idLocal: idLocal, body: body);
    }

    try {
      final json = await ApiClient.post('/vendedor/cobros/guardar', body);
      return CobroResult.fromResponse(json);
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        return _encolarYDevolver(idLocal: idLocal, body: body);
      }
      rethrow;
    }
  }

  static Future<CobroResult> _encolarYDevolver({
    required String idLocal,
    required Map<String, dynamic> body,
  }) async {
    await DatabaseHelper.instance.encolar(
      idLocal: idLocal,
      tipo: 'cobro',
      endpoint: '/vendedor/cobros/guardar',
      payload: body,
    );
    SyncService.instance.flush();
    return CobroResult(
      exito: true,
      mensaje: 'Guardado sin conexión — se enviará al reconectar',
      pendienteOffline: true,
      idLocal: idLocal,
    );
  }
}
