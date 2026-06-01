import '../models/historial_data.dart';
import 'api_client.dart';

class HistorialService {
  // =================== Cargas ===================
  static Future<HistorialCargas> getCargas({
    String? fechaDesde,
    String? fechaHasta,
    String? buscar,
  }) async {
    final params = <String, String>{};
    if (fechaDesde != null && fechaDesde.isNotEmpty) params['fecha_desde'] = fechaDesde;
    if (fechaHasta != null && fechaHasta.isNotEmpty) params['fecha_hasta'] = fechaHasta;
    if (buscar != null && buscar.isNotEmpty) params['buscar'] = buscar;
    final json = await ApiClient.get('/vendedor/historial-cargas${_qs(params)}');
    return HistorialCargas.fromJson(json);
  }

  static Future<CargaDetalle> getCargaDetalle(int id) async {
    final json = await ApiClient.get('/vendedor/historial-cargas/$id/detalle');
    return CargaDetalle.fromJson(json);
  }

  // =================== Ventas ===================
  static Future<HistorialVentas> getVentas({
    String? fechaDesde,
    String? fechaHasta,
    String? buscar,
  }) async {
    final params = <String, String>{};
    if (fechaDesde != null && fechaDesde.isNotEmpty) params['fecha_desde'] = fechaDesde;
    if (fechaHasta != null && fechaHasta.isNotEmpty) params['fecha_hasta'] = fechaHasta;
    if (buscar != null && buscar.isNotEmpty) params['buscar'] = buscar;
    final json = await ApiClient.get('/vendedor/historial-ventas${_qs(params)}');
    return HistorialVentas.fromJson(json);
  }

  static Future<VentaDetalle> getVentaDetalle(int id) async {
    final json = await ApiClient.get('/vendedor/historial-ventas/$id/detalle');
    return VentaDetalle.fromJson(json);
  }

  // =================== Cobros ===================
  static Future<HistorialCobrosList> getCobros({
    String? fechaDesde,
    String? fechaHasta,
    String? buscar,
  }) async {
    final params = <String, String>{};
    if (fechaDesde != null && fechaDesde.isNotEmpty) params['fecha_desde'] = fechaDesde;
    if (fechaHasta != null && fechaHasta.isNotEmpty) params['fecha_hasta'] = fechaHasta;
    if (buscar != null && buscar.isNotEmpty) params['buscar'] = buscar;
    final json = await ApiClient.get('/vendedor/historial-cobros${_qs(params)}');
    return HistorialCobrosList.fromJson(json);
  }

  static Future<CobroHistDetalle> getCobroDetalle(int id) async {
    final json = await ApiClient.get('/vendedor/historial-cobros/$id/detalle');
    return CobroHistDetalle.fromJson(json);
  }

  static String _qs(Map<String, String> params) {
    if (params.isEmpty) return '';
    final entries = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    return '?$entries';
  }
}
