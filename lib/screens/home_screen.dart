import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dashboard_summary.dart';
import '../services/api_client.dart';
import '../services/dashboard_service.dart';
import 'login_screen.dart';
import 'sale_registration_screen.dart';
import 'collection_registration_screen.dart';
import 'history_sales_screen.dart';
import 'history_collections_screen.dart';
import 'history_loads_screen.dart';
import '../widgets/offline_banner.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const HomeScreen({super.key, this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardSummary? _dashboard;
  String? _error;
  bool _isLoading = true;

  // Theme Colors
  static const Color background = Color(0xFFF9F9FF);
  static const Color primary = Color(0xFF00236F);
  static const Color primaryContainer = Color(0xFF1E3A8A);
  static const Color onPrimaryContainer = Color(0xFF90A8FF);
  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color onSecondaryContainer = Color(0xFF00714D);
  static const Color tertiaryContainer = Color(0xFF6E2C00);
  static const Color onTertiaryContainer = Color(0xFFF39461);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF0F3FF);
  static const Color surfaceContainer = Color(0xFFE7EEFE);
  static const Color outlineVariant = Color(0xFFC5C5D3);
  static const Color onSurface = Color(0xFF151C27);
  static const Color onSurfaceVariant = Color(0xFF444651);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final summary = await DashboardService.getDashboard();
      if (!mounted) return;
      setState(() {
        _dashboard = summary;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
      if (e.statusCode == 401) {
        _logout();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Error de conexión. Verifica tu conexión a internet.';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await ApiClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: background,
      drawer: isDesktop ? null : _buildDrawer(context),
      body: isDesktop
          ? _buildDesktopLayout(context)
          : _buildMobileLayout(context),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: () {},
              backgroundColor: primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildTopAppBar(context),
          const OfflineBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 80.0,
                ),
                child: _buildMainContent(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _buildDrawer(context),
        Expanded(
          child: Column(
            children: [
              _buildTopAppBar(context, isDesktop: true),
              const OfflineBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32.0),
                    child: _buildMainContent(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final userName = widget.userData?['name'] ?? 'Vendedor';
    final sectores = _dashboard?.sectores ?? const <SectorAsignado>[];

    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: surfaceContainerLowest,
        border: Border(right: BorderSide(color: outlineVariant)),
        borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Créditos Tarrillo',
                  style: GoogleFonts.manrope(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.72,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _dashboard == null && _isLoading
                                  ? 'Cargando sectores...'
                                  : '${_dashboard?.sectoresTotal ?? 0} sectores asignados',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
            child: Text(
              'MIS SECTORES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                if (sectores.isEmpty && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No tienes sectores asignados hoy.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (sectores.isEmpty && _isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                for (var i = 0; i < sectores.length; i++)
                  _buildDrawerItem(
                    Icons.location_on,
                    sectores[i].nombre,
                    isActive: i == 0,
                  ),
              ],
            ),
          ),
          const Divider(color: outlineVariant, height: 1),
          _buildDrawerItem(Icons.settings, 'Configuración'),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
            title: Text(
              'Cerrar Sesión',
              style: GoogleFonts.inter(
                color: const Color(0xFFBA1A1A),
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: _logout,
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: outlineVariant)),
            ),
            child: Text(
              'v2.1.0',
              style: GoogleFonts.inter(fontSize: 12, color: onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title, {
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? onSecondaryContainer : onSurfaceVariant,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? onSecondaryContainer : onSurfaceVariant,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, {bool isDesktop = false}) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32.0 : 16.0),
      decoration: const BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isDesktop) ...[
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: primary),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                'Resumen',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: primary),
                onPressed: _isLoading ? null : _loadDashboard,
                tooltip: 'Actualizar',
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: primary),
                onPressed: () {},
              ),
              if (!isDesktop) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: outlineVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) _buildErrorBanner(),
        if (_dashboard == null && _isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _buildStatsGrid(context),
        const SizedBox(height: 32),
        Text(
          'Acciones Rápidas',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionLink('Registrar Venta', Icons.add_shopping_cart, context),
            _buildActionLink('Registrar Cobranza', Icons.money_off, context),
            _buildActionLink('Historial de Ventas', Icons.history, context),
            _buildActionLink('Historial de Cobranzas', Icons.receipt_long, context),
            _buildActionLink('Historial de Carga', Icons.inventory, context),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        border: Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFBA1A1A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.inter(
                color: const Color(0xFFBA1A1A),
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadDashboard,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final d = _dashboard;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
        final cards = [
          _buildStatCard(
            'Total Ventas',
            _formatCurrency(d?.ventasTotal ?? 0),
            Icons.attach_money,
            primary,
            subtitle: d == null ? null : '${d.ventasCantidad} operaciones',
          ),
          _buildStatCard(
            'Total Cobranzas',
            _formatCurrency(d?.cobranzasTotal ?? 0),
            Icons.payments,
            secondary,
            subtitle: d == null ? null : '${d.cobranzasCantidad} cobros',
          ),
          _buildStatCard(
            'Total Stock Productos',
            _formatNumber(d?.stockUnidades ?? 0),
            Icons.inventory_2,
            const Color(0xFF6E2C00),
            subtitle: d == null ? null : '${d?.stockItems ?? 0} productos',
          ),
          _buildStatCard(
            'Por Cobrar',
            _formatCurrency(d?.porCobrar ?? 0),
            Icons.pending_actions,
            const Color(0xFFB45309),
          ),
          _buildStatCard(
            'Total Sectores',
            _formatNumber(d?.sectoresTotal ?? 0),
            Icons.location_city,
            const Color(0xFF7C3AED),
            subtitle: d == null ? null : 'asignados hoy',
          ),
        ];

        if (isDesktop) {
          return GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: cards,
          );
        } else {
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: cards.map((c) => SizedBox(
              width: (constraints.maxWidth - 16) / 2 - 8,
              child: c,
            )).toList(),
          );
        }
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: onSurfaceVariant,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionLink(String label, IconData icon, BuildContext context) {
    return InkWell(
      onTap: () {
        if (label == 'Registrar Venta') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SaleRegistrationScreen()),
          );
        } else if (label == 'Registrar Cobranza') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CollectionRegistrationScreen()),
          );
        } else if (label == 'Historial de Ventas') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistorySalesScreen()),
          );
        } else if (label == 'Historial de Cobranzas') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoryCollectionsScreen()),
          );
        } else if (label == 'Historial de Carga') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoryLoadsScreen()),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCurrency(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts[1];
  final withCommas = intPart.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})*$)'),
    (m) => '${m[1]},',
  );
  return 'S/ $withCommas.$decPart';
}

String _formatNumber(num value) {
  return value.toInt().toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})*$)'),
    (m) => '${m[1]},',
  );
}
