import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../../profile/providers/my_listings_provider.dart';

class ProductSoldSuccessScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String productTitle;
  final String buyerName;
  final double productPrice;
  final String transactionId;
  final String dateFormatted;

  const ProductSoldSuccessScreen({
    super.key,
    required this.orderId,
    required this.productTitle,
    required this.buyerName,
    required this.productPrice,
    required this.transactionId,
    required this.dateFormatted,
  });

  @override
  ConsumerState<ProductSoldSuccessScreen> createState() => _ProductSoldSuccessScreenState();
}

class _ProductSoldSuccessScreenState extends ConsumerState<ProductSoldSuccessScreen> {
  late String _productTitle;
  late String _buyerName;
  late double _productPrice;
  late String _transactionId;
  late String _dateFormatted;

  @override
  void initState() {
    super.initState();
    _productTitle = widget.productTitle;
    _buyerName = widget.buyerName;
    _productPrice = widget.productPrice;
    _transactionId = widget.transactionId;
    _dateFormatted = widget.dateFormatted;
    if (_transactionId.isEmpty || _productTitle.isEmpty || _buyerName.isEmpty) {
      _fetchSummary();
    }
  }

  Future<void> _fetchSummary() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/orders/${widget.orderId}/sale-summary');
      if (res.data != null && res.data['success'] == true && res.data['data'] != null) {
        final data = Map<String, dynamic>.from(res.data['data'] as Map);
        if (mounted) {
          setState(() {
            _productTitle = data['productTitle']?.toString() ?? _productTitle;
            _buyerName = data['buyerName']?.toString() ?? _buyerName;
            _productPrice = (data['productPrice'] is num) ? (data['productPrice'] as num).toDouble() : _productPrice;
            _transactionId = data['transactionId']?.toString() ?? data['orderNumber']?.toString() ?? _transactionId;
            _dateFormatted = data['saleDateFormatted']?.toString() ?? _dateFormatted;
          });
        }
      }
    } catch (_) {}
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
              color: isHighlighted ? const Color(0xFF004E54) : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22, color: AppTheme.textPrimary),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Green check circle
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Congratulations Title
              const Text(
                'Product Sold Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Congratulations! Your ${_productTitle.isNotEmpty ? _productTitle : "item"} has been sold to ${_buyerName.isNotEmpty ? _buyerName : "the buyer"} for ₹${_productPrice.toStringAsFixed(0)}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Transaction Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRANSACTION DETAILS',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('Transaction ID', _transactionId),
                    _buildDetailRow('Buyer', _buyerName),
                    _buildDetailRow('Amount', '₹${_productPrice.toStringAsFixed(0)}', isHighlighted: true),
                    _buildDetailRow('Date', _dateFormatted),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // View Sold Items Dashboard Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final notifier = ref.read(myListingsProvider.notifier);
                    notifier.setTab('DIRECT');
                    notifier.setFilter('COMPLETED');
                    notifier.fetchMyListings();
                    context.go(AppRoutes.myListings);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004E54),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Sold Items Dashboard',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // List Another Item Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.sell),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF004E54)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'List Another Item',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF004E54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
