import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/connectivity_service.dart';
import '../data/sync_service.dart';

/// Banner de estado de conexión + cola pendiente.
/// - Online + sin pendientes → invisible
/// - Online + N pendientes  → amarillo "Sincronizando N operaciones…"
/// - Offline                 → naranja "Sin conexión — se guarda aquí"
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  StreamSubscription<bool>? _connSub;
  StreamSubscription<int>? _countSub;
  bool _online = true;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _online = ConnectivityService.instance.current;
    _connSub = ConnectivityService.instance.isOnline.listen((v) {
      if (mounted) setState(() => _online = v);
    });
    _countSub = SyncService.instance.pendingCount.listen((v) {
      if (mounted) setState(() => _pending = v);
    });
    SyncService.instance.currentPending().then((n) {
      if (mounted) setState(() => _pending = n);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _countSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_online && _pending == 0) return const SizedBox.shrink();

    final isOffline = !_online;
    final bg = isOffline
        ? const Color(0xFFB45309)
        : const Color(0xFFF59E0B);
    final fg = Colors.white;
    final icon = isOffline ? Icons.cloud_off : Icons.cloud_sync;
    final text = isOffline
        ? 'Sin conexión — Las ventas y cobros se guardan aquí'
        : (_pending == 1
            ? 'Sincronizando 1 operación pendiente…'
            : 'Sincronizando $_pending operaciones pendientes…');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isOffline)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            ),
        ],
      ),
    );
  }
}
