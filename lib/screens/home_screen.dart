import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'sale_registration_screen.dart';
import 'collection_registration_screen.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const HomeScreen({super.key, this.userData});

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
  Widget build(BuildContext context) {
    // Basic responsive check
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 80.0,
              ),
              child: _buildMainContent(context),
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: _buildMainContent(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    String userName = userData?['name'] ?? 'Agente Cobrador';

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          Text(
                            'Zona Norte',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildDrawerItem(
                  Icons.location_on,
                  'Pampa Hermosa',
                  isActive: true,
                ),
                _buildDrawerItem(Icons.location_on, 'Alianza'),
                _buildDrawerItem(Icons.location_on, 'Yurimaguas'),
                const SizedBox(height: 24),
                _buildDrawerItem(Icons.settings, 'Configuración'),
                const Divider(color: outlineVariant),
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
                  title: Text(
                    'Cerrar Sesión',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFBA1A1A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('userData');
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
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
        // Stats Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 600;
            final cards = [
              _buildStatCard('Total Ventas', 'S/ 45,200.00', Icons.attach_money, primary),
              _buildStatCard('Total Cobranzas', 'S/ 12,450.00', Icons.payments, secondary),
              _buildStatCard('Total Stock Productos', '1,245', Icons.inventory_2, const Color(0xFF6E2C00)),
              _buildStatCard('Por Cobrar', 'S/ 32,750.00', Icons.pending_actions, const Color(0xFFB45309)),
              _buildStatCard('Total Sectores', '8', Icons.location_city, const Color(0xFF7C3AED)),
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
        ),
        const SizedBox(height: 32),

        // Action Links
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROGRESO DE RECAUDACIÓN DIARIA',
            style: GoogleFonts.workSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/ 12,450.00',
                style: GoogleFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: secondary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+12% vs ayer',
                      style: GoogleFonts.inter(color: secondary, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meta del Día',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: onSurface,
                ),
              ),
              Text(
                'S/ 15,000.00 (83%)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.83,
              backgroundColor: surfaceContainer,
              valueColor: const AlwaysStoppedAnimation<Color>(primary),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: primaryContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.map, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Mi Ruta',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.pending_actions,
                      color: onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Pendientes',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                '24',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildZoneCard(
    String name,
    String amount,
    String visits,
    String statusLabel,
    Color statusBg,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECAUDADO',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceVariant,
                    ),
                  ),
                  Text(
                    amount,
                    style: GoogleFonts.workSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'VISITAS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceVariant,
                    ),
                  ),
                  Text(
                    visits,
                    style: GoogleFonts.workSans(fontSize: 14, color: onSurface),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataGrid() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Últimas Cobranzas Realizadas',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.filter_list,
                        color: onSurfaceVariant,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, color: onSurfaceVariant),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(surfaceContainer),
              columns: [
                DataColumn(
                  label: Text(
                    'CLIENTE',
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'ZONA',
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'MONTO',
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'ESTADO',
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'HORA',
                    style: GoogleFonts.workSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              rows: [
                _buildDataRow(
                  'Ricardo Sánchez',
                  'Pampa Hermosa',
                  'S/ 450.00',
                  'Pagado',
                  secondary,
                  secondary.withOpacity(0.1),
                  '10:45 AM',
                ),
                _buildDataRow(
                  'Elena Portocarrero',
                  'Alianza',
                  'S/ 200.00',
                  'Pagado',
                  secondary,
                  secondary.withOpacity(0.1),
                  '10:30 AM',
                ),
                _buildDataRow(
                  'Marcos Trigoso',
                  'Yurimaguas',
                  'S/ 1,200.00',
                  'Compromiso',
                  tertiaryContainer,
                  tertiaryContainer.withOpacity(0.1),
                  '09:55 AM',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(
    String client,
    String zone,
    String amount,
    String status,
    Color statusColor,
    Color statusBg,
    String time,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(client, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
        DataCell(
          Text(
            zone,
            style: GoogleFonts.inter(fontSize: 14, color: onSurfaceVariant),
          ),
        ),
        DataCell(
          Text(
            amount,
            style: GoogleFonts.workSans(
              fontWeight: FontWeight.w500,
              color: primary,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusBg,
              border: Border.all(color: statusColor.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            time,
            style: GoogleFonts.inter(fontSize: 12, color: onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
