import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../explore/models/listing_model.dart';
import '../models/chat_message_model.dart';
import '../models/offer_model.dart';
import '../providers/chat_provider.dart';
import '../providers/offer_provider.dart';
import '../widgets/reject_offer_bottom_sheet.dart';
import '../widgets/schedule_meetup_bottom_sheet.dart';
import '../widgets/buyer_show_otp_modal.dart';
import 'seller_otp_verification_screen.dart';
import '../../auction/models/auction_model.dart';
import '../../auction/providers/order_provider.dart';

class OfferChatScreen extends ConsumerStatefulWidget {
  final String listingId;
  final ListingModel? listing;
  final String? buyerId;
  final String? offerId;
  final String? buyerName;

  const OfferChatScreen({
    super.key,
    required this.listingId,
    this.listing,
    this.buyerId,
    this.offerId,
    this.buyerName,
  });

  @override
  ConsumerState<OfferChatScreen> createState() => _OfferChatScreenState();
}

class _OfferChatScreenState extends ConsumerState<OfferChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _confirmedMeetupOrderIds = {};
  double _offerAmount = 0.0;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _offerAmount = widget.listing?.price ?? 0.0;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger loading older messages when scrolled near the top
    if (currentScroll <= 100) {
      ref.read(chatRoomNotifierProvider.notifier).loadOlderMessages();
    }

    // Toggle "Scroll to Bottom" button
    final isAwayFromBottom = maxScroll - currentScroll > 200;
    if (isAwayFromBottom != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = isAwayFromBottom;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    final chatNotifier = ref.read(chatRoomNotifierProvider.notifier);
    final offerNotifier = ref.read(offerProvider.notifier);
    final room = await chatNotifier.initRoomForListing(
      widget.listingId,
      _offerAmount,
      buyerId: widget.buyerId,
      offerId: widget.offerId,
    );
    if ((_offerAmount == 0.0 || _offerAmount == 100.0) && room != null && room.listingPrice > 0) {
      if (mounted) {
        setState(() {
          _offerAmount = room.listingPrice;
        });
      }
    }
    await offerNotifier.fetchLatestOffer(
      widget.listingId,
      buyerId: widget.buyerId ?? room?.buyerId,
    );
    ref.read(orderProvider.notifier).fetchOrderByListing(widget.listingId);
    if (mounted) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    final notifier = ref.read(chatRoomNotifierProvider.notifier);
    final ok = await notifier.sendTextMessage(text);
    if (ok) _scrollToBottom();
  }

  Future<void> _sendQuickReply(String reply) async {
    final notifier = ref.read(chatRoomNotifierProvider.notifier);
    final ok = await notifier.sendQuickReply(reply);
    if (ok) _scrollToBottom();
  }

  Future<void> _submitNewOffer() async {
    final offerNotifier = ref.read(offerProvider.notifier);
    final chatNotifier = ref.read(chatRoomNotifierProvider.notifier);

    final success = await offerNotifier.submitOffer(
      listingId: widget.listingId,
      amount: _offerAmount,
      message: 'Submitted offer of ₹${_offerAmount.toInt()}',
    );

    if (success) {
      final roomId = ref.read(chatRoomNotifierProvider).room?.id;
      if (roomId != null) {
        await chatNotifier.loadMessages(roomId, isSilent: true);
      }
      _scrollToBottom();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offer of ₹${_offerAmount.toInt()} submitted successfully!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } else {
      if (mounted) {
        final err = ref.read(offerProvider).errorMessage ?? 'Failed to submit offer';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showCounterDialog(OfferModel offer) {
    double counterVal = offer.currentEffectiveAmount;
    final textCtrl = TextEditingController(text: counterVal.toInt().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Counter Offer',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Current offer: ₹${offer.currentEffectiveAmount.toInt()}',
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary),
                labelText: 'Your Counter Price',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final parsed = double.tryParse(textCtrl.text.replaceAll(',', '').trim());
                  if (parsed != null && parsed > 0) {
                    Navigator.pop(ctx);
                    final ok = await ref.read(offerProvider.notifier).counterOffer(
                          offerId: offer.id,
                          counterAmount: parsed,
                          message: 'Counter offer of ₹${parsed.toInt()}',
                        );
                    if (ok && mounted) {
                      _scrollToBottom();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Counter Offer', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAcceptDialog(OfferModel offer) {
    String selectedDelivery = 'IN_PERSON_MEETUP';
    final locationCtrl = TextEditingController(text: 'T. Nagar, Chennai');
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Accept Offer & Select Delivery',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Agreed amount: ₹${offer.currentEffectiveAmount.toInt()}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              // Option A: In-Person Meetup
              GestureDetector(
                onTap: () => setSheetState(() => selectedDelivery = 'IN_PERSON_MEETUP'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selectedDelivery == 'IN_PERSON_MEETUP' ? const Color(0xFFE6F4F1) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selectedDelivery == 'IN_PERSON_MEETUP' ? AppTheme.primary : const Color(0xFFE2E8F0),
                      width: selectedDelivery == 'IN_PERSON_MEETUP' ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.handshake_outlined,
                        color: selectedDelivery == 'IN_PERSON_MEETUP' ? AppTheme.primary : const Color(0xFF64748B),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'In-Person Meetup (Instant)',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                            Text(
                              'Inspect item in person, verify OTP code on pickup.',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      if (selectedDelivery == 'IN_PERSON_MEETUP')
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Option B: Courier
              GestureDetector(
                onTap: () => setSheetState(() => selectedDelivery = 'COURIER'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selectedDelivery == 'COURIER' ? const Color(0xFFE6F4F1) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selectedDelivery == 'COURIER' ? AppTheme.primary : const Color(0xFFE2E8F0),
                      width: selectedDelivery == 'COURIER' ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: selectedDelivery == 'COURIER' ? AppTheme.primary : const Color(0xFF64748B),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Courier Dispatch',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                            Text(
                              'Doorstep delivery with tracked timeline and buyer protection.',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      if (selectedDelivery == 'COURIER')
                        const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                    ],
                  ),
                ),
              ),

              if (selectedDelivery == 'IN_PERSON_MEETUP') ...[
                const SizedBox(height: 14),
                const Text(
                  'Meetup Location:',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 18),
                    hintText: 'e.g. Metro Station, Coffee Shop, Mall',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],

              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final orderId = await ref.read(offerProvider.notifier).acceptOffer(
                          offerId: offer.id,
                          deliveryType: selectedDelivery,
                          meetupLocation: locationCtrl.text.trim(),
                        );
                    if (!mounted || !parentContext.mounted) return;
                    if (orderId != null) {
                      await ref.read(chatRoomNotifierProvider.notifier).sendTextMessage('🎉 Offer accepted! Order created.');
                      await ref.read(offerProvider.notifier).fetchLatestOffer(widget.listingId);
                      final roomId = ref.read(chatRoomNotifierProvider).room?.id;
                      if (roomId != null) {
                        await ref.read(chatRoomNotifierProvider.notifier).loadMessages(roomId, isSilent: true);
                      }
                      _scrollToBottom();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Offer accepted! Schedule meetup details below.'),
                          backgroundColor: Color(0xFF004E54),
                        ),
                      );
                      if (selectedDelivery == 'IN_PERSON_MEETUP') {
                        ScheduleMeetupBottomSheet.show(
                          context,
                          orderId: orderId,
                          initialLocation: locationCtrl.text.trim(),
                          onMeetupScheduled: () async {
                            await ref.read(offerProvider.notifier).fetchLatestOffer(widget.listingId);
                            final rId = ref.read(chatRoomNotifierProvider).room?.id;
                            if (rId != null) {
                              await ref.read(chatRoomNotifierProvider.notifier).loadMessages(rId, isSilent: true);
                            }
                            _scrollToBottom();
                          },
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Confirm Acceptance: ₹${offer.currentEffectiveAmount.toInt()}',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 16, minute: 30);
    final locationCtrl = TextEditingController(text: 'T. Nagar, Chennai');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Schedule In-Person Meetup',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Propose a date, time, and location to inspect the product in person.',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              // Date & Time pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 14)),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month, color: AppTheme.primary, size: 18),
                      label: Text(DateFormat('EEE, d MMM').format(selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setSheetState(() => selectedTime = picked);
                        }
                      },
                      icon: const Icon(Icons.access_time, color: AppTheme.primary, size: 18),
                      label: Text(selectedTime.format(ctx)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text(
                'Meetup Location:',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: locationCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 18),
                  hintText: 'e.g. Metro Station, Coffee Shop, Mall',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final finalDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    await ref.read(chatRoomNotifierProvider.notifier).sendMeetupRequest(
                          meetupTime: finalDateTime,
                          location: locationCtrl.text.trim(),
                        );
                    _scrollToBottom();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Send Meetup Request', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatRoomNotifierProvider);
    final offerState = ref.watch(offerProvider);
    final activeOffer = offerState.activeOffer;
    final currentUserId = ref.watch(authProvider).user?.id ?? '';
    final orderState = ref.watch(orderProvider);
    final order = orderState.order;
    final room = chatState.room;
    final listing = widget.listing;

    final isSeller = (activeOffer != null && activeOffer.isSeller) ||
        (currentUserId.isNotEmpty &&
            (room?.sellerId == currentUserId || widget.listing?.sellerId == currentUserId));

    final peerName = isSeller
        ? (room?.buyerName ?? widget.buyerName ?? activeOffer?.buyerName ?? 'Buyer')
        : (room?.sellerName ?? listing?.sellerName ?? 'Seller');
    final peerInitials = peerName.isNotEmpty
        ? peerName.substring(0, peerName.length > 2 ? 2 : peerName.length).toUpperCase()
        : (isSeller ? 'BU' : 'SE');
    final listingTitle = room?.listingTitle ?? listing?.title ?? 'Product';
    final listingPrice = room?.listingPrice != 0.0 ? (room?.listingPrice ?? 0.0) : (listing?.price ?? 0.0);
    final listingImg = room?.listingImageUrl ?? listing?.primaryImageUrl;

    final effOrderId = activeOffer?.orderId ?? order?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 18, color: AppTheme.textPrimary),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFF004E54),
              child: Text(
                peerInitials,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peerName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        color: Color(0xFF10B981),
                        size: 7,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSeller ? 'Online now · Buyer' : 'Online now',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Color(0xFF004E54), size: 21),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling peer via secure relay...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 21),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Mini Product Card (Matching Image 1 & Image 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFEBF1F5))),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: const Color(0xFFEDF5F5),
                        child: listingImg != null && listingImg.isNotEmpty
                            ? Image.network(
                                ApiClient.resolveMediaUrl(listingImg),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Color(0xFF004E54), size: 24),
                              )
                            : const Icon(Icons.image, color: Color(0xFF004E54), size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listingTitle,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          if (order != null || (listing?.sellingMethod.toUpperCase() == 'AUCTION') || (activeOffer?.isAccepted ?? false))
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF004E54),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'WON',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '₹${(order?.totalAmount ?? order?.wonAmount ?? activeOffer?.currentEffectiveAmount ?? listingPrice).toInt()}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F6F6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (order?.isMeetupDelivery ?? true) ? Icons.handshake_outlined : Icons.local_shipping_outlined,
                                        size: 11,
                                        color: const Color(0xFF004E54),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        (order?.isMeetupDelivery ?? true) ? 'In-Person' : 'Courier',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF004E54),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'Asking: ₹${listingPrice.toInt()}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF004E54),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Schedule Meetup button (Available for both Buyer and Seller)
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF7F7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC4E8E8), width: 1.2),
                      ),
                      child: TextButton.icon(
                        onPressed: () {
                          if (effOrderId != null) {
                            ScheduleMeetupBottomSheet.show(
                              context,
                              orderId: effOrderId,
                              initialLocation: activeOffer?.meetupLocation,
                              onMeetupScheduled: () {
                                ref.read(offerProvider.notifier).fetchLatestOffer(widget.listingId, buyerId: widget.buyerId ?? room?.buyerId);
                                ref.read(orderProvider.notifier).fetchOrderByListing(widget.listingId);
                                final rId = ref.read(chatRoomNotifierProvider).room?.id;
                                if (rId != null) {
                                  ref.read(chatRoomNotifierProvider.notifier).loadMessages(rId, isSilent: true);
                                }
                              },
                            );
                          } else {
                            _showScheduleDialog();
                          }
                        },
                        icon: const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF004E54)),
                        label: const Text(
                          'Schedule',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF004E54),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Notice Banners (Matching Image 1 & 2)
              _buildBuyerProtectionBanner(isSeller, order),

              // Message List
              Expanded(
                child: chatState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : chatState.messages.isEmpty
                        ? _buildEmptyState(peerName)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: chatState.messages.length + (chatState.isLoadingOlder ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (chatState.isLoadingOlder && index == 0) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                                    ),
                                  ),
                                );
                              }

                              final actualIndex = chatState.isLoadingOlder ? index - 1 : index;
                              final msg = chatState.messages[actualIndex];
                              final isMe = msg.senderId == currentUserId || msg.isMine;

                              // Check if date header should be shown
                              bool showDateHeader = false;
                              if (actualIndex == 0) {
                                showDateHeader = true;
                              } else {
                                final prevMsg = chatState.messages[actualIndex - 1];
                                showDateHeader = !msg.isSameDay(prevMsg);
                              }

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (showDateHeader) _buildDateHeader(msg.formattedDateHeader),
                                  _buildMessageItem(msg, isMe, peerInitials, activeOffer),
                                ],
                              );
                            },
                          ),
              ),

              // Ephemeral Typing Indicator Banner
              if (chatState.typingUser != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${chatState.typingUser} is typing...',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

              // Quick Replies (Image 1 & 2)
              Builder(
                builder: (context) {
                  final replies = isSeller
                      ? [
                          "Thanks for the update!",
                          "Looks good!",
                          "When will you pick it up?",
                          "Item is packed and ready",
                        ]
                      : [
                          "Great! I'm available today",
                          "Can we meet tomorrow?",
                          "Is the price negotiable?",
                          "Where can we meet for pickup?",
                        ];

                  return Container(
                    height: 38,
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: replies.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(
                              replies[index],
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFF004E54),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: const Color(0xFFE8F6F6),
                            side: const BorderSide(color: Color(0xFFC4E8E8), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            onPressed: () => _sendQuickReply(replies[index]),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // Bottom Action / Negotiation Bar (Matching Image 1 Screen 2 & Image 3 Screen 4 & Screen 5)
              _buildBottomOfferBar(activeOffer, listingPrice, offerState),

              // Text Input Bar (Image 1 & 2)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined, color: Color(0xFF94A3B8), size: 24),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Select image from gallery')),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TextField(
                            controller: _textController,
                            onChanged: (text) {
                              setState(() {});
                              ref.read(chatRoomNotifierProvider.notifier).onTextChanged(text);
                            },
                            onSubmitted: (_) => _sendText(),
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendText,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF004E54),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating "New Messages" / Scroll-to-Bottom Pill
          if (_showScrollToBottom)
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: _scrollToBottom,
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                elevation: 3,
                icon: const Icon(Icons.arrow_downward, size: 16),
                label: const Text(
                  'Latest',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBuyerProtectionBanner(bool isSeller, OrderModel? order) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F6F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC4E8E8), width: 1),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: Color(0xFF004E54)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'BIDLY Buyer Protection is active for this transaction.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF004E54),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isSeller && (order != null || widget.listing?.sellingMethod.toUpperCase() == 'AUCTION'))
          Container(
            margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE2ECED),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'BIDLY has notified the buyer they won the auction. Delivery method selection in progress.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF004E54),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomOfferBar(
      OfferModel? activeOffer, double listingPrice, OfferState offerState) {
    final currentUserId = ref.watch(authProvider).user?.id ?? '';
    final room = ref.watch(chatRoomNotifierProvider).room;
    final isSeller = (activeOffer != null && activeOffer.isSeller) ||
        (currentUserId.isNotEmpty &&
            (room?.sellerId == currentUserId || widget.listing?.sellerId == currentUserId));
    final isBuyer = !isSeller;

    // Seller view: ONLY show seller actions if an active offer is pending or accepted
    if (isSeller) {
      // Case 1: Seller with pending offer (Image 3 Screen 4)
      if (activeOffer != null && activeOffer.isPending) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => RejectOfferBottomSheet.show(
                      context,
                      offerId: activeOffer.id,
                      onRejected: () => ref
                          .read(offerProvider.notifier)
                          .fetchLatestOffer(widget.listingId, buyerId: widget.buyerId ?? room?.buyerId),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Reject Offer',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => _showAcceptDialog(activeOffer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004E54),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Accept Offer',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Case 2: Seller with accepted offer
      if (activeOffer != null && activeOffer.isAccepted) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => RejectOfferBottomSheet.show(
                      context,
                      offerId: activeOffer.id,
                      onRejected: () => ref
                          .read(offerProvider.notifier)
                          .fetchLatestOffer(widget.listingId, buyerId: widget.buyerId ?? room?.buyerId),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Reject Offer',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      if (activeOffer.orderId != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => SellerOtpVerificationScreen(
                              orderId: activeOffer.orderId!,
                              buyerName: activeOffer.buyerName,
                              meetupLocation: activeOffer.meetupLocation,
                              productTitle: activeOffer.listingTitle ?? 'Product',
                              productPrice: activeOffer.currentEffectiveAmount,
                              productImageUrl: activeOffer.listingImageUrl,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004E54),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Mark as sold',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Seller NEVER sees "Make Offer" or buyer increment pills!
      return const SizedBox.shrink();
    }

    // Buyer view before offer accepted (Image 1)
    if (isBuyer &&
        (activeOffer == null ||
            activeOffer.isPending ||
            activeOffer.isRejected ||
            activeOffer.isCancelled)) {
      final increments = [500, 1000, 2000, 4000, 6000];

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick Increment Pills ($ 500, $ 1,000, $ 2,000... - Image 1)
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: increments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final inc = increments[i];
                  final formattedInc = NumberFormat('#,###').format(inc);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _offerAmount = (_offerAmount + inc);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      ),
                      child: Text(
                        '\$ $formattedInc',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Stepper box: [ ₹ 43500    ▲ ▼ ] and [ Make Offer ] button (Image 1)
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹ ${_offerAmount.toInt()}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF004E54),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _offerAmount = (_offerAmount + 500);
                                });
                              },
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF004E54),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _offerAmount = (_offerAmount - 500).clamp(100.0, 10000000.0);
                                });
                              },
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: offerState.isSubmitting ? null : _submitNewOffer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004E54),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: offerState.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Make Offer',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMeetingScheduledCard(
      ChatMessageModel msg, OfferModel? activeOffer, bool isMe, String timeStr, String peerInitials) {
    String date = '';
    String time = '';
    String location = '';
    final lines = (msg.content ?? '').split('\n');
    for (final line in lines) {
      if (line.toLowerCase().startsWith('date:')) date = line.substring(5).trim();
      if (line.toLowerCase().startsWith('time:')) time = line.substring(5).trim();
      if (line.toLowerCase().startsWith('location:')) location = line.substring(9).trim();
    }
    final meta = msg.parsedMetadata ?? {};
    if (date.isEmpty && meta['meetupDate'] != null) {
      date = meta['meetupDate'].toString();
    }
    if (time.isEmpty && meta['meetupTime'] != null) {
      time = meta['meetupTime'].toString();
    }
    if (location.isEmpty && meta['meetupLocation'] != null) {
      location = meta['meetupLocation'].toString();
    }
    if (date.isEmpty && activeOffer?.meetupTime != null) {
      date = DateFormat('dd/MM/yy').format(activeOffer!.meetupTime!);
    }
    if (time.isEmpty && activeOffer?.meetupTime != null) {
      time = DateFormat('hh.mma').format(activeOffer!.meetupTime!);
    }
    if (location.isEmpty && (activeOffer?.meetupLocation?.isNotEmpty ?? false)) {
      location = activeOffer!.meetupLocation!;
    }
    if (date.isEmpty) {
      date = DateFormat('dd/MM/yy').format(msg.createdAt);
    }
    if (time.isEmpty) {
      time = DateFormat('hh.mma').format(msg.createdAt);
    }
    if (location.isEmpty) {
      location = 'T.Nagar, Chennai';
    }

    final currentUserId = ref.watch(authProvider).user?.id ?? '';
    final room = ref.watch(chatRoomNotifierProvider).room;
    final order = ref.watch(orderProvider).order;
    final isSeller = (activeOffer != null && activeOffer.isSeller) ||
        (currentUserId.isNotEmpty &&
            (room?.sellerId == currentUserId || widget.listing?.sellerId == currentUserId));
    final orderId = activeOffer?.orderId ?? order?.id ?? meta['orderId']?.toString();

    final isConfirmed = order?.isMeetupConfirmed == true ||
        (orderId != null && _confirmedMeetupOrderIds.contains(orderId)) ||
        msg.type == 'MEETUP_ACCEPTED';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.centerLeft, // Left aligned matching Image 2
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF004E54), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dark Teal Header: Meeting Scheduled (Image 2)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF004E54),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Text(
                      isConfirmed ? 'Meeting Confirmed' : 'Meeting Scheduled',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Row with chip (Image 2)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              date,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Time Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Time',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            time,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Location Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            location,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Action Button:
                      // For Seller: [ Mark As Sold ] (Enabled only after Buyer confirms meetup!)
                      // For Buyer: [ Confirm Meetup ] -> when clicked switches to [ Show OTP ]!
                      if (isSeller) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: isConfirmed
                                ? () {
                                    final effectiveOrderId = orderId ?? ref.read(orderProvider).order?.id;
                                    if (effectiveOrderId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Loading order details... Please tap again.')),
                                      );
                                      ref.read(orderProvider.notifier).fetchOrderByListing(widget.listingId);
                                      return;
                                    }

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => SellerOtpVerificationScreen(
                                          orderId: effectiveOrderId,
                                          buyerName: activeOffer?.buyerName ?? widget.buyerName ?? room?.buyerName ?? 'Buyer',
                                          meetupTime: time,
                                          meetupLocation: location,
                                          productTitle: activeOffer?.listingTitle ?? room?.listingTitle ?? widget.listing?.title ?? 'Product',
                                          productPrice: activeOffer?.currentEffectiveAmount ?? (room?.listingPrice != 0.0 ? room?.listingPrice : null) ?? widget.listing?.price ?? 0.0,
                                          productImageUrl: activeOffer?.listingImageUrl ?? room?.listingImageUrl ?? widget.listing?.primaryImageUrl,
                                        ),
                                      ),
                                    );
                                  }
                                : null, // Disabled until buyer confirms!
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004E54),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFCBD5E1),
                              disabledForegroundColor: const Color(0xFF64748B),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isConfirmed ? 'Mark As Sold' : 'Mark As Sold (Awaiting Confirmation)',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ] else if (!isConfirmed) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final effectiveOrderId = orderId ?? ref.read(orderProvider).order?.id;
                              if (effectiveOrderId == null) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Loading order details... Please tap again.')),
                                );
                                ref.read(orderProvider.notifier).fetchOrderByListing(widget.listingId);
                                return;
                              }

                              final ok = await ref.read(orderProvider.notifier).confirmMeetup(effectiveOrderId);
                              if (!mounted) return;
                              if (ok) {
                                setState(() {
                                  _confirmedMeetupOrderIds.add(effectiveOrderId);
                                });
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Meetup confirmed! Tap "Show OTP" when you meet the seller.'),
                                    backgroundColor: Color(0xFF004E54),
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
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
                              'Confirm Meetup',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final effectiveOrderId = orderId ?? ref.read(orderProvider).order?.id;
                              if (effectiveOrderId != null) {
                                BuyerShowOtpModal.show(context, orderId: effectiveOrderId);
                              }
                            },
                            icon: const Icon(Icons.lock_open_rounded, size: 16, color: Colors.white),
                            label: const Text(
                              'Show OTP',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004E54),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // TD avatar + Timestamp below the card (Image 2)
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF004E54),
                child: Text(
                  peerInitials,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String dateText) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateText,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF475569),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildOfferNegotiationBanner(OfferModel offer) {
    if (offer.isAccepted) {
      final isBuyer = offer.isBuyer;
      final isSeller = offer.isSeller;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.celebration_rounded, color: Color(0xFF15803D), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Offer Accepted!',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                      ),
                      Text(
                        'Agreed Price: ₹${offer.currentEffectiveAmount.toInt()}',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
                if (offer.orderId != null && isBuyer)
                  ElevatedButton.icon(
                    onPressed: () => BuyerShowOtpModal.show(context, orderId: offer.orderId!),
                    icon: const Icon(Icons.lock_open_rounded, size: 13, color: Colors.white),
                    label: const Text('Show OTP', style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004E54),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            if (offer.orderId != null && isSeller) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ScheduleMeetupBottomSheet.show(context, orderId: offer.orderId!),
                      icon: const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF004E54)),
                      label: const Text('Schedule', style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF004E54))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF004E54)),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => SellerOtpVerificationScreen(
                              orderId: offer.orderId!,
                              buyerName: offer.buyerName,
                              productTitle: offer.listingTitle ?? 'Product',
                              productPrice: offer.currentEffectiveAmount,
                              productImageUrl: offer.listingImageUrl,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 12, color: Colors.white),
                      label: const Text('Verify OTP', style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004E54),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    if (offer.isPending) {
      final isSeller = offer.isSeller;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_offer, color: Color(0xFF1D4ED8), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isSeller ? 'Offer Received:' : 'Your Offer:',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
                Text(
                  '₹${offer.amount.toInt()}',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                ),
              ],
            ),
            if (isSeller) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => RejectOfferBottomSheet.show(
                        context,
                        offerId: offer.id,
                        onRejected: () => ref.read(offerProvider.notifier).fetchLatestOffer(widget.listingId),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Decline', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCounterDialog(offer),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Counter', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showAcceptDialog(offer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Accept', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Awaiting seller response...',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (offer.isCountered) {
      final isBuyer = offer.isBuyer;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sync_alt_rounded, color: Color(0xFFB45309), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isBuyer ? 'Seller Countered:' : 'Your Counter Offer:',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
                Text(
                  '₹${offer.counterAmount?.toInt() ?? 0}',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                ),
              ],
            ),
            if (isBuyer) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref.read(offerProvider.notifier).rejectOffer(offer.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Decline', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCounterDialog(offer),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Counter Back', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showAcceptDialog(offer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Accept', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(String sellerName) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: Color(0xFFE0F2F1),
              child: Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primary, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              'Start Negotiation with $sellerName',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Discuss product condition, delivery methods, or submit a direct offer below.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessageModel msg, bool isMe, String peerInitials, OfferModel? activeOffer) {
    final timeStr = msg.formattedTime;

    if (msg.isDeliveryAddressShared) {
      final meta = msg.parsedMetadata;
      final recipient = meta?['recipientName']?.toString() ?? '';
      final phone = meta?['phone']?.toString() ?? '';
      final addressLine = meta?['addressLine']?.toString() ?? '';
      final city = meta?['city']?.toString() ?? '';
      final pincode = meta?['pincode']?.toString() ?? '';

      final fullAddress = addressLine.isNotEmpty
          ? '$addressLine, $city - $pincode'
          : (msg.content?.replaceFirst(RegExp(r'Delivery Address:\s*', caseSensitive: false), '') ?? '');

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 290,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF004E54).withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF004E54),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: Color(0xFF5EEAD4), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Delivery Address Shared',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recipient.isNotEmpty) ...[
                      Text(
                        recipient + (phone.isNotEmpty ? ' ($phone)' : ''),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      fullAddress,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: Color(0xFF334155), height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Seller can courier product to this address.',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        timeStr,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (msg.isShipmentDispatched) {
      final meta = msg.parsedMetadata;
      final trackingNum = meta?['trackingNumber']?.toString() ?? 'N/A';
      final courierPartner = meta?['courierPartner']?.toString() ?? 'Courier';
      final estDelivery = meta?['estimatedDeliveryDate']?.toString() ?? 'Estimated delivery TBD';
      final orderId = meta?['orderId']?.toString();

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 290,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF004E54).withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF004E54),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_shipping_rounded, color: Color(0xFF5EEAD4), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Shipment Dispatched',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tracking No:',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        Text(
                          trackingNum,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Courier:',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        Text(
                          courierPartner,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Est. Delivery:',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        Text(
                          estDelivery,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F766E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (orderId != null) {
                            context.push('/orders/$orderId/track');
                          } else {
                            context.push('/orders/listing/${widget.listingId}/track');
                          }
                        },
                        icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                        label: const Text(
                          'Track My Order',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004E54),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        timeStr,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (msg.isOffer) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFE8F5F5) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF004E54).withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    isMe ? 'You made an offer' : 'Offer received',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '₹${msg.offerAmount?.toInt() ?? 0}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(msg),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (msg.isMeetup || (msg.content != null && msg.content!.contains('Meeting Scheduled'))) {
      return _buildMeetingScheduledCard(msg, activeOffer, isMe, timeStr, peerInitials);
    }

    if (isMe) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: const BoxConstraints(maxWidth: 290),
              decoration: BoxDecoration(
                color: const Color(0xFF004E54),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                msg.content ?? '',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                _buildStatusIcon(msg),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: const BoxConstraints(maxWidth: 290),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.content ?? '',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF1E293B),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF004E54),
                  child: Text(
                    peerInitials,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatusIcon(ChatMessageModel msg) {
    if (msg.isSending) {
      return const SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF94A3B8)),
      );
    }
    if (msg.isFailed) {
      return GestureDetector(
        onTap: () {
          if (msg.content != null) {
            ref.read(chatRoomNotifierProvider.notifier).sendTextMessage(
                  msg.content!,
                  retryClientMessageId: msg.clientMessageId,
                );
          }
        },
        child: const Icon(Icons.error_outline, size: 13, color: Color(0xFFEF4444)),
      );
    }
    if (msg.isRead) {
      return const Icon(Icons.done_all, size: 14, color: AppTheme.primary);
    }
    if (msg.status.toUpperCase() == 'DELIVERED') {
      return const Icon(Icons.done_all, size: 14, color: Color(0xFF94A3B8));
    }
    return const Icon(Icons.done, size: 13, color: Color(0xFF94A3B8));
  }
}
