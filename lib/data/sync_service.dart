import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'connectivity_service.dart';
import 'database_helper.dart';
import '../services/api_client.dart';

class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _pendingCountController = StreamController<int>.broadcast();
  StreamSubscription<bool>? _connSub;
  bool _running = false;
  bool _flushing = false;

  Stream<int> get pendingCount => _pendingCountController.stream;

  Future<void> start() async {
    await ConnectivityService.instance.start();
    _connSub = ConnectivityService.instance.isOnline.listen((online) {
      if (online) {
        flush();
      }
    });
    await _emitCount();
  }

  Future<void> _emitCount() async {
    final n = await DatabaseHelper.instance.contarPendientes();
    if (!_pendingCountController.isClosed) {
      _pendingCountController.add(n);
    }
  }

  Future<void> flush() async {
    if (_running) return;
    if (!ConnectivityService.instance.current) return;
    _running = true;
    try {
      final pendientes =
          await DatabaseHelper.instance.obtenerPendientes();
      for (final op in pendientes) {
        if (!ConnectivityService.instance.current) break;
        await _procesarUna(op);
      }
    } finally {
      _running = false;
      await _emitCount();
    }
  }

  Future<void> flushNow() async {
    if (_flushing) return;
    _flushing = true;
    try {
      await flush();
    } finally {
      _flushing = false;
    }
  }

  Future<void> _procesarUna(Map<String, dynamic> op) async {
    final idLocal = op['id_local'] as String;
    final endpoint = op['endpoint'] as String;
    final payload = jsonDecode(op['payload'] as String) as Map<String, dynamic>;
    final intentos = (op['intentos'] as int?) ?? 0;

    if (intentos >= 5) {
      await DatabaseHelper.instance
          .marcarError(idLocal, 'Máx. intentos alcanzados');
      return;
    }

    await DatabaseHelper.instance.marcarEnviando(idLocal);
    await _emitCount();

    try {
      final resp = await ApiClient.post(endpoint, payload);
      final serverId = _extractId(resp);
      await DatabaseHelper.instance.marcarOk(idLocal, serverId);
    } on ApiException catch (e) {
      if (e.statusCode >= 400 && e.statusCode < 500) {
        await DatabaseHelper.instance.marcarError(idLocal, e.message);
      } else {
        await DatabaseHelper.instance.devolverAPendiente(idLocal);
      }
    } catch (e) {
      await DatabaseHelper.instance.devolverAPendiente(idLocal);
    } finally {
      await _emitCount();
    }
  }

  int _extractId(Map<String, dynamic> resp) {
    if (resp['id'] is num) return (resp['id'] as num).toInt();
    if (resp['recibo_id'] is num) return (resp['recibo_id'] as num).toInt();
    return 0;
  }

  Future<int> currentPending() async {
    return DatabaseHelper.instance.contarPendientes();
  }

  @visibleForTesting
  void dispose() {
    _connSub?.cancel();
    _pendingCountController.close();
  }
}
