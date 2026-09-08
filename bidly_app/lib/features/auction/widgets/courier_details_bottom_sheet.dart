import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../models/auction_model.dart';
import '../providers/order_provider.dart';

class CourierDetailsBottomSheet extends ConsumerStatefulWidget {
  final String orderId;
  final String listingId;
  final AuctionWinnerModel winner;

  const CourierDetailsBottomSheet({
    super.key,
    required this.orderId,
    required this.listingId,
    required this.winner,
  });

  static Future<void> show(
    BuildContext context, {
    required String orderId,
    required String listingId,
    required AuctionWinnerModel winner,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: CourierDetailsBottomSheet(
          orderId: orderId,
          listingId: listingId,
          winner: winner,
        ),
      ),
    );
  }

  @override
  ConsumerState<CourierDetailsBottomSheet> createState() => _CourierDetailsBottomSheetState();
}

class _CourierDetailsBottomSheetState extends ConsumerState<CourierDetailsBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _trackingController = TextEditingController();
  String? _selectedCourier;
  DateTime _estimatedDeliveryDate = DateTime.now().add(const Duration(days: 3));
  bool _isSubmitting = false;

  final List<String> _courierPartners = [
    'Ekart Logistics',
    'Blue Dart',
    'DTDC',
    'Delhivery',
    'Shadowfax',
    'India Post',
  ];

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _estimatedDeliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004E54),
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _estimatedDeliveryDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a courier partner')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref.read(orderProvider.notifier).createCourierShipment(
      widget.orderId,
      trackingNumber: _trackingController.text.trim(),
      courierPartner: _selectedCourier!,
      estimatedDeliveryDate: _estimatedDeliveryDate,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop(); // Close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipment dispatched! Buyer has been notified with tracking info.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      // Navigate to chat with winner (Container 6)
      context.push('/chat/${widget.listingId}?buyerId=${widget.winner.winnerId ?? ''}');
    } else {
      final err = ref.read(orderProvider).errorMessage ?? 'Failed to dispatch shipment';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Back arrow and title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Courier Details',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Share tracking info with the buyer',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tracking Number Field
              const Text(
                'Tracking Number *',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _trackingController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Enter courier tracking number',
                  prefixIcon: const Icon(Icons.inventory_2_outlined, color: Color(0xFF004E54), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF004E54), width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Tracking number cannot be empty';
                  }
                  if (val.trim().length < 4) {
                    return 'Please enter a valid tracking number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Courier Partner Dropdown
              const Text(
                'Courier Partner *',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCourier,
                hint: const Text('Select courier partner', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF94A3B8))),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.local_shipping_outlined, color: Color(0xFF004E54), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF004E54), width: 1.5),
                  ),
                ),
                items: _courierPartners.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Text(
                      c,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedCourier = val);
                },
              ),
              const SizedBox(height: 16),

              // Estimated Delivery Date
              const Text(
                'Estimated Delivery Date *',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Color(0xFF004E54), size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateFormat.format(_estimatedDeliveryDate),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit_calendar_outlined, color: Color(0xFF64748B), size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004E54),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF004E54),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Share Tracking with Buyer',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
