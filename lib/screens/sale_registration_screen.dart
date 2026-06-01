import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SaleRegistrationScreen extends StatefulWidget {
  const SaleRegistrationScreen({super.key});

  @override
  State<SaleRegistrationScreen> createState() => _SaleRegistrationScreenState();
}

class _SaleRegistrationScreenState extends State<SaleRegistrationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();

  String _selectedPaymentType = 'CONTADO';
  double _amountPaid = 0;
  double _totalSale = 0;
  int _itemsCount = 0;

  // Sample products
  final List<Map<String, dynamic>> _products = [
    {'id': '1', 'name': 'Aceite Cocina 1L', 'price': 18.50, 'stock': 50},
    {'id': '2', 'name': 'Arroz Costeño 1kg', 'price': 5.50, 'stock': 100},
    {'id': '3', 'name': 'Azúcar Rubia 1kg', 'price': 6.00, 'stock': 80},
    {'id': '4', 'name': 'Fideos Doble Anillo', 'price': 4.50, 'stock': 60},
    {'id': '5', 'name': 'Leche Gloria 1L', 'price': 7.50, 'stock': 40},
    {'id': '6', 'name': 'Panetela Integral', 'price': 12.00, 'stock': 30},
    {'id': '7', 'name': 'Mantequillaella 500g', 'price': 22.00, 'stock': 25},
    {'id': '8', 'name': 'Huevos Los Andes x30', 'price': 16.00, 'stock': 45},
    {'id': '9', 'name': 'Harina Selecta 1kg', 'price': 5.80, 'stock': 70},
    {'id': '10', 'name': 'Sal Yodada 1kg', 'price': 3.50, 'stock': 90},
    {'id': '11', 'name': 'Detergente Omo 1kg', 'price': 14.00, 'stock': 55},
    {'id': '12', 'name': 'Jabón TOCOY 6und', 'price': 9.00, 'stock': 65},
  ];

  final List<Map<String, dynamic>> _cart = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _amountPaidController.addListener(_updateAmountPaid);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _amountPaidController.dispose();
    _clientController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _updateAmountPaid() {
    setState(() {
      _amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item['id'] == product['id']);
      if (existingIndex >= 0) {
        _cart[existingIndex]['quantity'] += 1;
      } else {
        _cart.add({
          'id': product['id'],
          'name': product['name'],
          'price': product['price'],
          'quantity': 1,
        });
      }
      _recalculateTotals();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cart[index]['quantity'] > 1) {
        _cart[index]['quantity'] -= 1;
      } else {
        _cart.removeAt(index);
      }
      _recalculateTotals();
    });
  }

  void _recalculateTotals() {
    _totalSale = 0;
    _itemsCount = 0;
    for (var item in _cart) {
      _totalSale += item['price'] * item['quantity'];
      _itemsCount += item['quantity'] as int;
    }
  }

  double get _change => _amountPaid > _totalSale ? _amountPaid - _totalSale : 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00236F),
        foregroundColor: Colors.white,
        title: Text(
          'Registrar Venta - POS',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6CF8BB),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'CONTADO'),
            Tab(text: 'CRÉDITO'),
          ],
          onTap: (index) {
            setState(() {
              _selectedPaymentType = index == 0 ? 'CONTADO' : 'CRÉDITO';
            });
          },
        ),
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left panel - Products
        Expanded(
          flex: 3,
          child: _buildProductsPanel(),
        ),
        // Right panel - Cart & Payment
        Expanded(
          flex: 2,
          child: _buildCartPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: _buildProductsPanel(),
        ),
        Container(
          height: 60,
          color: const Color(0xFF00236F),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCartModal(),
                  child: Container(
                    color: const Color(0xFF00236F),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Ver Carrito ($_itemsCount)',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6CF8BB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'S/ $_totalSale',
                              style: GoogleFonts.inter(color: const Color(0xFF00236F), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCartModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
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
              Expanded(child: _buildCartContent(scrollController)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsPanel() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
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
        ),
        // Products grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final inCart = _cart.any((item) => item['id'] == product['id']);
    final cartItem = inCart ? _cart.firstWhere((item) => item['id'] == product['id']) : null;

    return InkWell(
      onTap: () => _addToCart(product),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: inCart ? const Color(0xFF00236F) : const Color(0xFFC5C5D3),
            width: inCart ? 2 : 1,
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              product['name'],
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'S/ ${product['price'].toStringAsFixed(2)}',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: const Color(0xFF00236F),
                  ),
                ),
                if (inCart)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00236F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cartItem!['quantity']}',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    return Container(
      color: Colors.white,
      child: _buildCartContent(null),
    );
  }

  Widget _buildCartContent(ScrollController? scrollController) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF00236F),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Carrito de Venta',
                style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6CF8BB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_itemsCount items',
                  style: GoogleFonts.inter(color: const Color(0xFF00236F), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        // Cart items
        Expanded(
          child: _cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Carrito vacío',
                        style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _cart.length,
                  itemBuilder: (context, index) => _buildCartItem(index),
                ),
        ),
        // Payment section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total:', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    'S/ $_totalSale',
                    style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF00236F)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedPaymentType == 'CONTADO') ...[
                TextField(
                  controller: _amountPaidController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Monto Pagado',
                    prefixText: 'S/ ',
                    filled: true,
                    fillColor: const Color(0xFFF0F3FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                if (_amountPaid > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vuelto:', style: GoogleFonts.inter(fontSize: 16)),
                      Text(
                        'S/ ${_change.toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF006C49)),
                      ),
                    ],
                  ),
              ] else ...[
                TextField(
                  controller: _clientController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Cliente',
                    filled: true,
                    fillColor: const Color(0xFFF0F3FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText: 'Referencia / DNI',
                    filled: true,
                    fillColor: const Color(0xFFF0F3FF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _cart.isEmpty ? null : () => _processSale(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00236F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'PROCESAR VENTA',
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(int index) {
    final item = _cart[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                Text(
                  'S/ ${item['price']} x ${item['quantity']}',
                  style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            'S/ ${(item['price'] * item['quantity']).toStringAsFixed(2)}',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF00236F)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Color(0xFFBA1A1A)),
            onPressed: () => _removeFromCart(index),
          ),
        ],
      ),
    );
  }

  void _processSale() {
    if (_selectedPaymentType == 'CONTADO' && _amountPaid < _totalSale) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto pagado es menor al total de la venta'),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
      return;
    }

    // Show success dialog
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
              '¡Venta Registrada!',
              style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedPaymentType == 'CONTADO'
                  ? 'Vuelto: S/ ${_change.toStringAsFixed(2)}'
                  : 'Venta a crédito registrada',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            child: Text('ACEPTAR', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}