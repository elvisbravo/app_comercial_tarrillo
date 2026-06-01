import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CollectionRegistrationScreen extends StatefulWidget {
  const CollectionRegistrationScreen({super.key});

  @override
  State<CollectionRegistrationScreen> createState() => _CollectionRegistrationScreenState();
}

class _CollectionRegistrationScreenState extends State<CollectionRegistrationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _observationsController = TextEditingController();

  String _searchQuery = '';
  String _filterStatus = 'TODOS';
  double _collectionAmount = 0;

  // Sample clients with credits
  final List<Map<String, dynamic>> _clients = [
    {
      'id': '1',
      'name': 'Ricardo Sánchez',
      'dni': '47825634',
      'zone': 'Pampa Hermosa',
      'totalDebt': 4500.00,
      'paidAmount': 2000.00,
      'lastPaymentDate': '2026-05-28',
      'lastPaymentAmount': 450.00,
      'installments': 12,
      'paidInstallments': 5,
      'status': 'AL_DIA',
    },
    {
      'id': '2',
      'name': 'Elena Portocarrero',
      'dni': '28945671',
      'zone': 'Alianza',
      'totalDebt': 3200.00,
      'paidAmount': 2800.00,
      'lastPaymentDate': '2026-05-25',
      'lastPaymentAmount': 200.00,
      'installments': 10,
      'paidInstallments': 8,
      'status': 'AL_DIA',
    },
    {
      'id': '3',
      'name': 'Marcos Trigoso',
      'dni': '40123567',
      'zone': 'Yurimaguas',
      'totalDebt': 6000.00,
      'paidAmount': 1500.00,
      'lastPaymentDate': '2026-05-20',
      'lastPaymentAmount': 300.00,
      'installments': 15,
      'paidInstallments': 4,
      'status': 'MOROSO',
    },
    {
      'id': '4',
      'name': 'Carmen López',
      'dni': '21567890',
      'zone': 'Pampa Hermosa',
      'totalDebt': 2800.00,
      'paidAmount': 2800.00,
      'lastPaymentDate': '2026-05-15',
      'lastPaymentAmount': 400.00,
      'installments': 8,
      'paidInstallments': 8,
      'status': 'PAGADO',
    },
    {
      'id': '5',
      'name': 'José Mendoza',
      'dni': '35678912',
      'zone': 'Alianza',
      'totalDebt': 5500.00,
      'paidAmount': 1000.00,
      'lastPaymentDate': '2026-05-10',
      'lastPaymentAmount': 500.00,
      'installments': 12,
      'paidInstallments': 2,
      'status': 'MOROSO',
    },
    {
      'id': '6',
      'name': 'María Fernández',
      'dni': '46789023',
      'zone': 'Yurimaguas',
      'totalDebt': 4000.00,
      'paidAmount': 2500.00,
      'lastPaymentDate': '2026-05-22',
      'lastPaymentAmount': 250.00,
      'installments': 10,
      'paidInstallments': 6,
      'status': 'AL_DIA',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredClients {
    return _clients.where((client) {
      final matchesSearch = _searchQuery.isEmpty ||
          client['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          client['dni'].contains(_searchQuery);

      final matchesFilter = _filterStatus == 'TODOS' ||
          (_filterStatus == 'AL_DIA' && client['status'] == 'AL_DIA') ||
          (_filterStatus == 'MOROSO' && client['status'] == 'MOROSO') ||
          (_filterStatus == 'PAGADO' && client['status'] == 'PAGADO');

      return matchesSearch && matchesFilter;
    }).toList();
  }

  double _getRemainingDebt(Map<String, dynamic> client) {
    return (client['totalDebt'] as double) - (client['paidAmount'] as double);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00236F),
        foregroundColor: Colors.white,
        title: Text(
          'Registrar Cobranza',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o DNI...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF0F3FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('TODOS'),
                      const SizedBox(width: 8),
                      _buildFilterChip('AL_DIA'),
                      const SizedBox(width: 8),
                      _buildFilterChip('MOROSO'),
                      const SizedBox(width: 8),
                      _buildFilterChip('PAGADO'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Clients list
          Expanded(
            child: _filteredClients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron clientes',
                          style: GoogleFonts.inter(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = _filteredClients[index];
                      return _buildClientCard(client);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterStatus == label;
    Color bgColor;
    Color textColor;

    switch (label) {
      case 'AL_DIA':
        bgColor = isSelected ? const Color(0xFF006C49) : const Color(0xFFF0F3FF);
        textColor = isSelected ? Colors.white : const Color(0xFF006C49);
        break;
      case 'MOROSO':
        bgColor = isSelected ? const Color(0xFFBA1A1A) : const Color(0xFFF0F3FF);
        textColor = isSelected ? Colors.white : const Color(0xFFBA1A1A);
        break;
      case 'PAGADO':
        bgColor = isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF0F3FF);
        textColor = isSelected ? Colors.white : const Color(0xFF7C3AED);
        break;
      default:
        bgColor = isSelected ? const Color(0xFF00236F) : const Color(0xFFF0F3FF);
        textColor = isSelected ? Colors.white : const Color(0xFF00236F);
    }

    return GestureDetector(
      onTap: () => setState(() => _filterStatus = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textColor.withOpacity(0.3)),
        ),
        child: Text(
          label == 'AL_DIA' ? 'Al día' : label == 'MOROSO' ? 'Moroso' : label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    final remainingDebt = _getRemainingDebt(client);
    final progress = (client['paidAmount'] as double) / (client['totalDebt'] as double);

    Color statusColor;
    String statusLabel;
    switch (client['status']) {
      case 'AL_DIA':
        statusColor = const Color(0xFF006C49);
        statusLabel = 'Al día';
        break;
      case 'MOROSO':
        statusColor = const Color(0xFFBA1A1A);
        statusLabel = 'Moroso';
        break;
      case 'PAGADO':
        statusColor = const Color(0xFF7C3AED);
        statusLabel = 'Pagado';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = client['status'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC5C5D3)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Color(0xFF00236F)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client['name'],
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${client['dni']} • ${client['zone']}',
                        style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Debt info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Deuda total:', style: GoogleFonts.inter(color: Colors.grey[600])),
                    Text(
                      'S/ ${(client['totalDebt'] as double).toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: Colors.grey[800]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pagado:', style: GoogleFonts.inter(color: Colors.grey[600])),
                    Text(
                      'S/ ${(client['paidAmount'] as double).toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: const Color(0xFF006C49)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFF0F3FF),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Por cobrar:',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'S/ ${remainingDebt.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00236F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cuotas: ${client['paidInstallments']}/${client['installments']}',
                      style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      'Último pago: S/ ${(client['lastPaymentAmount'] as double).toStringAsFixed(2)} - ${client['lastPaymentDate']}',
                      style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Actions
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0F3FF))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _showPaymentModal(client, isAmortization: false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'COBRAR',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00236F),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFFF0F3FF),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _showPaymentModal(client, isAmortization: true),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'AMORTIZAR',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF006C49),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentModal(Map<String, dynamic> client, {required bool isAmortization}) {
    final remainingDebt = _getRemainingDebt(client);
    _amountController.clear();
    _observationsController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isAmortization ? 'Amortizar Deuda' : 'Registrar Cobranza',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF00236F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${client['name']} - DNI: ${client['dni']}',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              // Quick amounts
              Text(
                'Monto rápido',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickAmountChip(50),
                  _buildQuickAmountChip(100),
                  _buildQuickAmountChip(200),
                  _buildQuickAmountChip(500),
                  _buildQuickAmountChip(remainingDebt >= 100 ? 1000.0 : remainingDebt.toDouble()),
                ],
              ),
              const SizedBox(height: 16),
              // Custom amount
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Monto a ${isAmortization ? 'amortizar' : 'cobrar'}',
                  prefixText: 'S/ ',
                  filled: true,
                  fillColor: const Color(0xFFF0F3FF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _observationsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  filled: true,
                  fillColor: const Color(0xFFF0F3FF),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Por cobrar:',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'S/ ${remainingDebt.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00236F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(_amountController.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ingrese un monto válido'),
                          backgroundColor: Color(0xFFBA1A1A),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _showSuccessDialog(client, amount, isAmortization);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAmortization ? const Color(0xFF006C49) : const Color(0xFF00236F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'CONFIRMAR ${isAmortization ? 'AMORTIZACIÓN' : 'COBRANZA'}',
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(double amount) {
    return GestureDetector(
      onTap: () {
        _amountController.text = amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00236F)),
        ),
        child: Text(
          'S/ ${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF00236F),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> client, double amount, bool isAmortization) {
    final remainingDebt = _getRemainingDebt(client) - amount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF6CF8BB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Color(0xFF00236F), size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              isAmortization ? '¡Amortización Registrada!' : '¡Cobranza Registrada!',
              style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'S/ ${amount.toStringAsFixed(2)}',
              style: GoogleFonts.manrope(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00236F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              client['name'],
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
            if (remainingDebt > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Saldo remaining: S/ ${remainingDebt.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(color: const Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('NUEVA COBRANZA', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('VOLVER', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}