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

class OfferChatScreen extends ConsumerStatefulWidget {
  final String listingId;
  final ListingModel? listing;

  const OfferChatScreen({
    super.key,
    required this.listingId,
    this.listing,
  });

  @override
  ConsumerState<OfferChatScreen> createState() => _OfferChatScreenState();
}

class _OfferChatScreenState extends ConsumerState<OfferChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _offerAmount = 0.0;
  bool _showScrollToBottom = false;

  final List<String> _quickReplies = [
    "Great! I'm available today",
    "Can we meet tomorrow?",
    "Is the price negotiable?",
    "Where can we meet for pickup?",
  ];

  @override
  void initState() {
    super.initState();
    _offerAmount = widget.listing?.price ?? 1000.0;
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
    await chatNotifier.initRoomForListing(widget.listingId, _offerAmount);
    await offerNotifier.fetchLatestOffer(widget.listingId);
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
                              'Courier / Ekart Logistics',
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
                      if (!mounted || !parentContext.mounted) return;
                      parentContext.push('/orders/$orderId/track');
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
    final room = chatState.room;
    final listing = widget.listing;

    final sellerName = room?.sellerName ?? listing?.sellerName ?? 'Seller';
    final sellerInitials = sellerName.isNotEmpty ? sellerName.substring(0, sellerName.length > 2 ? 2 : sellerName.length).toUpperCase() : 'SE';
    final listingTitle = room?.listingTitle ?? listing?.title ?? 'Product';
    final listingPrice = room?.listingPrice != 0.0 ? (room?.listingPrice ?? 0.0) : (listing?.price ?? 0.0);
    final listingImg = room?.listingImageUrl ?? listing?.primaryImageUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppTheme.primary,
              child: Text(
                sellerInitials,
                style: const TextStyle(
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
                    sellerName,
                    style: const TextStyle(
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
                      Icon(
                        Icons.circle,
                        color: chatState.isWebSocketConnected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        size: 7,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        chatState.isWebSocketConnected ? 'Active now' : 'Connecting...',
                        style: TextStyle(
                          fontSize: 12,
                          color: chatState.isWebSocketConnected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
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
            icon: const Icon(Icons.phone_outlined, color: AppTheme.primary, size: 21),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling seller via secure relay...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 21),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Auction Won / Finalized Banner
              if ((listing?.sellingMethod.toUpperCase() == 'AUCTION') || (activeOffer?.isAccepted ?? false))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFF004E54),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Color(0xFF5EEAD4), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Auction Won · ₹${listingPrice.toInt()} · $listingTitle',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          onPressed: () {
                            if (activeOffer?.orderId != null) {
                              context.push('/orders/${activeOffer!.orderId}/track');
                            } else {
                              context.push('/orders/listing/${widget.listingId}/track');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF5EEAD4), width: 1.2),
                            foregroundColor: const Color(0xFF5EEAD4),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Track', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),

              // Mini Product Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFEBF1F5))),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 46,
                        height: 46,
                        color: const Color(0xFFEDF5F5),
                        child: listingImg != null && listingImg.isNotEmpty
                            ? Image.network(
                                ApiClient.resolveMediaUrl(listingImg),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image, color: AppTheme.primary, size: 24),
                              )
                            : const Icon(Icons.image, color: AppTheme.primary, size: 24),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Asking: ₹${listingPrice.toInt()}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (activeOffer != null && activeOffer.orderId != null && activeOffer.isBuyer) ...[
                      ElevatedButton.icon(
                        onPressed: () => BuyerShowOtpModal.show(context, orderId: activeOffer.orderId!),
                        icon: const Icon(Icons.lock_open_rounded, size: 13, color: Colors.white),
                        label: const Text(
                          'Show OTP',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004E54),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ] else if (activeOffer != null && activeOffer.orderId != null && activeOffer.isSeller) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => ScheduleMeetupBottomSheet.show(context, orderId: activeOffer.orderId!),
                            icon: const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF004E54)),
                            label: const Text(
                              'Schedule',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF004E54)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF004E54)),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => SellerOtpVerificationScreen(
                                    orderId: activeOffer.orderId!,
                                    buyerName: activeOffer.buyerName,
                                    productTitle: activeOffer.listingTitle ?? 'Product',
                                    productPrice: activeOffer.currentEffectiveAmount,
                                    productImageUrl: activeOffer.listingImageUrl,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 12, color: Colors.white),
                            label: const Text(
                              'Verify OTP',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004E54),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: _showScheduleDialog,
                        icon: const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.primary),
                        label: const Text(
                          'Schedule',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Negotiation Action Banner
              if (activeOffer != null) _buildOfferNegotiationBanner(activeOffer),

              // Message List
              Expanded(
                child: chatState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : chatState.messages.isEmpty
                        ? _buildEmptyState(sellerName)
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
                                  _buildMessageItem(msg, isMe, sellerInitials, activeOffer),
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

              // Quick Replies
              Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickReplies.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          _quickReplies[index],
                          style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: const Color(0xFFE8F5F5),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () => _sendQuickReply(_quickReplies[index]),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Offer Negotiation Card
              if (activeOffer == null || activeOffer.isRejected || activeOffer.isCancelled) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Make Direct Offer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '₹${_offerAmount.toInt()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildPresetOfferChip(listingPrice * 0.85),
                          _buildPresetOfferChip(listingPrice * 0.90),
                          _buildPresetOfferChip(listingPrice * 0.95),
                          _buildPresetOfferChip(listingPrice),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _offerAmount = (_offerAmount - 500).clamp(100.0, 10000000.0);
                              });
                            },
                            icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                            visualDensity: VisualDensity.compact,
                          ),
                          Expanded(
                            child: Slider(
                              value: _offerAmount.clamp(listingPrice * 0.5, listingPrice * 1.2),
                              min: (listingPrice * 0.5).roundToDouble(),
                              max: (listingPrice * 1.2).roundToDouble(),
                              activeColor: AppTheme.primary,
                              inactiveColor: const Color(0xFFCBD5E1),
                              onChanged: (val) {
                                setState(() {
                                  _offerAmount = val.roundToDouble();
                                });
                              },
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _offerAmount = _offerAmount + 500;
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: offerState.isSubmitting ? null : _submitNewOffer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: offerState.isSubmitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Send Offer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Text Input Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TextField(
                            controller: _textController,
                            onChanged: (text) => ref.read(chatRoomNotifierProvider.notifier).onTextChanged(text),
                            onSubmitted: (_) => _sendText(),
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
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
                            color: AppTheme.primary,
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

  Widget _buildPresetOfferChip(double amount) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _offerAmount = amount.roundToDouble()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _offerAmount == amount.roundToDouble() ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          alignment: Alignment.center,
          child: Text(
            '₹${amount.toInt()}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _offerAmount == amount.roundToDouble() ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
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

  Widget _buildMessageItem(ChatMessageModel msg, bool isMe, String sellerInitials, OfferModel? activeOffer) {
    final timeStr = msg.formattedTime;

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

    if (msg.isMeetup) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), width: 1.5),
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
              const Row(
                children: [
                  Icon(Icons.handshake_outlined, color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'In-Person Meetup',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                msg.content ?? '',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
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

    if (isMe) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                msg.content ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primary,
              child: Text(
                sellerInitials,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Text(
                      msg.content ?? '',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
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
    return const Icon(Icons.done, size: 13, color: Color(0xFF94A3B8));
  }
}
