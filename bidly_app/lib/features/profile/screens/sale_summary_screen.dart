import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_theme.dart';

class SaleSummaryScreen extends ConsumerStatefulWidget {
  final String orderId;

  const SaleSummaryScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<SaleSummaryScreen> createState() => _SaleSummaryScreenState();
}

class _SaleSummaryScreenState extends ConsumerState<SaleSummaryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/orders/${widget.orderId}/sale-summary');
      if (res.data != null && res.data['success'] == true && res.data['data'] != null) {
        setState(() {
          _summary = Map<String, dynamic>.from(res.data['data'] as Map);
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
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
    final title = _summary?['listingTitle']?.toString() ?? 'Product';
    final price = _summary?['finalPrice'] != null
        ? (double.tryParse(_summary!['finalPrice'].toString()) ?? 0.0)
        : 0.0;
    final buyer = _summary?['buyerName']?.toString() ?? 'Buyer';
    final saleDate = _summary?['saleDateFormatted']?.toString() ?? 'Recent';
    final payoutStatus = _summary?['payoutStatus']?.toString() ?? 'Processing';
    final listingId = _summary?['listingCustomId']?.toString() ?? '#LST-${widget.orderId.substring(0, widget.orderId.length > 8 ? 8 : widget.orderId.length).toUpperCase()}';
    final imageUrl = _summary?['listingImageUrl']?.toString();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Sale Summary',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.border.withValues(alpha: 0.7), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF004E54)),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 44),
                        const SizedBox(height: 12),
                        Text('Error loading sale summary: $_errorMessage'),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Large Product Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            color: const Color(0xFFF2F4F3),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : const Center(
                                    child: Icon(Icons.laptop_chromebook_rounded, size: 64, color: Color(0xFF004E54)),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Green SOLD badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 14, color: Color(0xFF2E7D32)),
                              SizedBox(width: 4),
                              Text(
                                'SOLD',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2E7D32),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Price
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF004E54),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sale Details Card
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
                                'Sale Details',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildDetailRow('Sale Type', 'Direct Buy'),
                              _buildDetailRow('Final Price', '₹${price.toStringAsFixed(0)}', isHighlighted: true),
                              _buildDetailRow('Buyer', buyer),
                              _buildDetailRow('Sale Date', saleDate),
                              _buildDetailRow('Payout Status', payoutStatus),
                              _buildDetailRow('Listing ID', listingId),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
