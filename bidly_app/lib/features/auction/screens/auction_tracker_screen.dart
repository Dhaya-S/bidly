import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../models/auction_model.dart';
import '../providers/auction_provider.dart';

class AuctionTrackerScreen extends ConsumerStatefulWidget {
  final String listingId;

  const AuctionTrackerScreen({
    super.key,
    required this.listingId,
  });

  @override
  ConsumerState<AuctionTrackerScreen> createState() => _AuctionTrackerScreenState();
}

class _AuctionTrackerScreenState extends ConsumerState<AuctionTrackerScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(auctionProvider.notifier);
      notifier.fetchAuctionDetails(widget.listingId);
      notifier.fetchWallet();
      notifier.startLivePolling(widget.listingId);
    });
  }

  @override
  void dispose() {
    ref.read(auctionProvider.notifier).stopLivePolling();
    super.dispose();
  }

  void _showIncreaseBidModal(BuildContext context, AuctionDetailsModel details, double currentHighest, double userBid) {
    double newAmount = currentHighest + (details.minBidIncrement > 0 ? details.minBidIncrement : 1000);
    final wallet = ref.read(auctionProvider).wallet;
    final balance = wallet?.availableBalance ?? 48000.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final sufficient = balance >= newAmount;

          return Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Increase Your Bid',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                const Text('New Bid Amount', style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF004E54), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        currencyFormatter.format(newAmount),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Current highest: ${currencyFormatter.format(currentHighest)} • Min raise: ${currencyFormatter.format(currentHighest + details.minBidIncrement)}',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                // Quick Add Pills
                Row(
                  children: [
                    _buildModalQuickAdd('+₹1,000', () => setModalState(() => newAmount += 1000)),
                    const SizedBox(width: 8),
                    _buildModalQuickAdd('+₹2,000', () => setModalState(() => newAmount += 2000)),
                    const SizedBox(width: 8),
                    _buildModalQuickAdd('+₹5,000', () => setModalState(() => newAmount += 5000)),
                    const SizedBox(width: 8),
                    _buildModalQuickAdd('+₹10,000', () => setModalState(() => newAmount += 10000)),
                  ],
                ),
                const SizedBox(height: 16),

                // Wallet status pill
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sufficient ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sufficient ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(sufficient ? Icons.check_circle_outline : Icons.error_outline, color: sufficient ? const Color(0xFF15803D) : const Color(0xFFB91C1C), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            sufficient ? 'Wallet has sufficient funds' : 'Insufficient wallet funds',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w700, color: sufficient ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Wallet Balance: ${currencyFormatter.format(balance)}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          Text('New Bid: ${currencyFormatter.format(newAmount)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm Increase CTA
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: sufficient
                        ? () async {
                            Navigator.pop(ctx);
                            await ref.read(auctionProvider.notifier).placeBid(widget.listingId, newAmount);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004E54),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Confirm • ${currencyFormatter.format(newAmount)}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalQuickAdd(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0369A1)),
          ),
        ),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Withdraw Bid?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text('Withdrawing will cancel your bid and immediately return your reserved funds to your available wallet balance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final parentContext = context;
              nav.pop();
              await ref.read(auctionProvider.notifier).withdrawBid(widget.listingId);
              if (mounted && parentContext.mounted) parentContext.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auctionProvider);
    final details = state.auctionDetails;
    final live = state.liveStatus;
    final wallet = state.wallet;

    if (details == null && state.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF004E54))),
      );
    }

    if (details == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auction Tracker')),
        body: const Center(child: Text('Auction not found')),
      );
    }

    final currentHighest = live?.currentHighestBid ?? details.currentHighestBid;
    final userBid = live?.currentUserBid ?? details.currentUserBid ?? currentHighest;
    final isWinning = live != null ? live.isCurrentUserWinning : details.isCurrentUserWinning;
    final isOutbid = live != null ? live.isCurrentUserOutbid : (!isWinning && currentHighest > userBid);
    final totalBids = live?.totalBids ?? details.totalBids;
    final watchingCount = live?.watchingCount ?? details.watchingCount;
    final timeLeft = live?.timeLeftFormatted ?? details.timeLeftFormatted;

    final totalBalance = wallet?.balance ?? 48000.0;
    final reservedBalance = isWinning ? userBid : (wallet?.reservedBalance ?? 0.0);
    final availableBalance = totalBalance - reservedBalance;

    final bidFeed = (live?.liveBidFeed.isNotEmpty == true)
        ? live!.liveBidFeed
        : details.recentBids;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auction Tracker',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            Text(
              details.title,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text('$watchingCount', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status Banner (Teal if winning, Red if outbid)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isOutbid ? const Color(0xFFEF4444) : const Color(0xFF004E54),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isOutbid ? "You've been outbid" : "You are the highest bidder!",
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(currentHighest),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 14),

                      // 3 Mini Stat Pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildHeaderPill(Icons.access_time_rounded, timeLeft, 'Time Left'),
                          _buildHeaderPill(Icons.trending_up_rounded, '$totalBids', 'Total Bids'),
                          _buildHeaderPill(Icons.people_alt_outlined, '$watchingCount', 'Watching'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. BIDLY Wallet Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFF004E54)),
                              SizedBox(width: 6),
                              Text('BIDLY Wallet', style: TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          if (reservedBalance > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.lock_outline, size: 12, color: Color(0xFFD97706)),
                                  SizedBox(width: 4),
                                  Text('Funds Reserved', style: TextStyle(fontFamily: 'Poppins', fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildWalletStat('Total Balance', currencyFormatter.format(totalBalance)),
                          _buildWalletStat('Reserved', currencyFormatter.format(reservedBalance), color: const Color(0xFFD97706)),
                          _buildWalletStat('Available', currencyFormatter.format(availableBalance), color: const Color(0xFF004E54)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Reserved amount will be released if you\'re outbid • Moved to escrow if you win',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. User's Current Position / Bid Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your bid', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormatter.format(userBid),
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isWinning
                                ? '✓ Currently winning'
                                : 'Behind by ${currencyFormatter.format(currentHighest - userBid)}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isWinning ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                      if (isOutbid)
                        ElevatedButton.icon(
                          onPressed: () => _showIncreaseBidModal(context, details, currentHighest, userBid),
                          icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                          label: const Text('Increase Bid', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Live Bid Feed Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text(
                          'Live Bid Feed',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    Text(
                      '$totalBids total',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Live Bid Feed Items
                if (bidFeed.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No bids yet. Be the first to bid!')),
                  )
                else
                  ...bidFeed.map((b) => _buildBidFeedItem(b)),

                const SizedBox(height: 16),

                // 5. Withdraw from Auction Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFF64748B), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Withdraw from Auction',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Withdrawing releases your reserved funds back to your wallet immediately.',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => _showWithdrawDialog(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            backgroundColor: const Color(0xFFFEF2F2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Withdraw My Bid', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Actions: [ 🔼 Increase Bid ] [ 👁️ View Product ]
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _showIncreaseBidModal(context, details, currentHighest, userBid),
                          icon: const Icon(Icons.arrow_upward_rounded, size: 18, color: Color(0xFF004E54)),
                          label: const Text('Increase Bid', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFF004E54))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF004E54), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/listing/${widget.listingId}'),
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                          label: const Text('View Product', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004E54),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPill(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBidFeedItem(BidHistoryItemModel b) {
    final isTop = b.isHighest;
    final isUser = b.isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFFF0FDFA) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUser ? const Color(0xFF004E54) : const Color(0xFFE2E8F0),
          width: isUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isUser
                ? const Color(0xFF004E54)
                : (isTop ? const Color(0xFF8B5CF6) : const Color(0xFFF59E0B)),
            child: Text(
              b.bidderInitials,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      b.bidderName,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    if (isTop)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(4)),
                        child: const Text('TOP', style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    if (isUser) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(4)),
                        child: const Text('YOU', style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF004E54))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  b.relativeTime,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Text(
            currencyFormatter.format(b.amount),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isTop ? const Color(0xFFEF4444) : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
