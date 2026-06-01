import '../models/dashboard_summary.dart';
import 'api_client.dart';

class DashboardService {
  static Future<DashboardSummary> getDashboard() async {
    final json = await ApiClient.get('/vendedor/dashboard');
    return DashboardSummary.fromJson(json);
  }

  static Future<Map<String, dynamic>> getStock() async {
    return ApiClient.get('/vendedor/stock');
  }
}
