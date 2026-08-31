import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/providers/live_location_provider.dart';
import '../providers/explore_provider.dart';
import '../widgets/deal_near_you_card.dart';
import '../widgets/top_seller_card.dart';
import '../widgets/recently_viewed_card.dart';
import '../widgets/marketplace_grid_card.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Electronics', 'icon': Icons.phone_iphone_rounded},
    {'name': 'Furniture', 'icon': Icons.chair_rounded},
    {'name': 'Fashion', 'icon': Icons.checkroom_rounded},
    {'name': 'Vehicles', 'icon': Icons.directions_car_rounded},
    {'name': 'Books', 'icon': Icons.menu_book_rounded},
    {'name': 'Sports', 'icon': Icons.fitness_center_rounded},
    {'name': 'Gaming', 'icon': Icons.sports_esports_rounded},
    {'name': 'Accessories', 'icon': Icons.watch_rounded},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(exploreProvider.notifier).updateSearchQuery(value);
  }

  void _showFilterModal(BuildContext context) {
    final state = ref.read(exploreProvider);
    String tempSortBy = state.sortBy;
    String tempMethod = state.selectedSellingMethod;
    String tempCondition = state.condition;
    String tempCategory = state.selectedCategory;
    int tempRadius = state.selectedRadiusKm;
    final minPriceCtrl = TextEditingController(text: state.minPrice != null ? state.minPrice!.toInt().toString() : '');
    final maxPriceCtrl = TextEditingController(text: state.maxPrice != null ? state.maxPrice!.toInt().toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.88,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Modal Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempSortBy = 'relevance';
                                tempMethod = 'ALL';
                                tempCondition = 'ANY';
                                tempCategory = 'All';
                                tempRadius = 10;
                                minPriceCtrl.clear();
                                maxPriceCtrl.clear();
                              });
                            },
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Scrollable Filters Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Sort By
                        _buildFilterSectionTitle('Sort By'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: [
                            _buildSelectablePill('Relevance', 'relevance', tempSortBy == 'relevance', () {
                              setModalState(() => tempSortBy = 'relevance');
                            }),
                            _buildSelectablePill('Price: Low to High', 'price_asc', tempSortBy == 'price_asc', () {
                              setModalState(() => tempSortBy = 'price_asc');
                            }),
                            _buildSelectablePill('Price: High to Low', 'price_desc', tempSortBy == 'price_desc', () {
                              setModalState(() => tempSortBy = 'price_desc');
                            }),
                            _buildSelectablePill('Newest First', 'newest', tempSortBy == 'newest', () {
                              setModalState(() => tempSortBy = 'newest');
                            }),
                            _buildSelectablePill('Ending Soon', 'ending_soon', tempSortBy == 'ending_soon', () {
                              setModalState(() => tempSortBy = 'ending_soon');
                            }),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // 2. Listing Type
                        _buildFilterSectionTitle('Listing Type'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: [
                            _buildSelectablePill('All', 'ALL', tempMethod == 'ALL', () {
                              setModalState(() => tempMethod = 'ALL');
                            }),
                            _buildSelectablePill('Bidding', 'AUCTION', tempMethod == 'AUCTION', () {
                              setModalState(() => tempMethod = 'AUCTION');
                            }),
                            _buildSelectablePill('Direct Buy', 'DIRECT_BUY', tempMethod == 'DIRECT_BUY', () {
                              setModalState(() => tempMethod = 'DIRECT_BUY');
                            }),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // 3. Price Range
                        _buildFilterSectionTitle('Price Range (₹)'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: TextField(
                                  controller: minPriceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Min',
                                    hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF94A3B8)),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('—', style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: TextField(
                                  controller: maxPriceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: 'Max',
                                    hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF94A3B8)),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // 4. Condition
                        _buildFilterSectionTitle('Condition'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: [
                            _buildSelectablePill('Any', 'ANY', tempCondition == 'ANY', () {
                              setModalState(() => tempCondition = 'ANY');
                            }),
                            _buildSelectablePill('New', 'NEW', tempCondition == 'NEW', () {
                              setModalState(() => tempCondition = 'NEW');
                            }),
                            _buildSelectablePill('Like New', 'LIKE_NEW', tempCondition == 'LIKE_NEW', () {
                              setModalState(() => tempCondition = 'LIKE_NEW');
                            }),
                            _buildSelectablePill('Good', 'GOOD', tempCondition == 'GOOD', () {
                              setModalState(() => tempCondition = 'GOOD');
                            }),
                            _buildSelectablePill('Fair', 'FAIR', tempCondition == 'FAIR', () {
                              setModalState(() => tempCondition = 'FAIR');
                            }),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // 5. Category (2-Column Grid of Pills)
                        _buildFilterSectionTitle('Category'),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth = (constraints.maxWidth - 10) / 2;
                            final cats = [
                              'Electronics',
                              'Furniture',
                              'Fashion',
                              'Vehicles',
                              'Books',
                              'Sports',
                              'Gaming',
                              'Accessories',
                            ];
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: cats.map((cat) {
                                final isSelected = tempCategory == cat;
                                return SizedBox(
                                  width: itemWidth,
                                  child: _buildSelectablePill(
                                    cat,
                                    cat,
                                    isSelected,
                                    () {
                                      setModalState(() {
                                        tempCategory = (tempCategory == cat) ? 'All' : cat;
                                      });
                                    },
                                    isExpanded: true,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 22),

                        // 6. Distance
                        _buildFilterSectionTitle('Distance'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: [
                            _buildSelectablePill('Any Distance', '0', tempRadius == 0, () {
                              setModalState(() => tempRadius = 0);
                            }),
                            _buildSelectablePill('< 1 km', '1', tempRadius == 1, () {
                              setModalState(() => tempRadius = 1);
                            }),
                            _buildSelectablePill('< 5 km', '5', tempRadius == 5, () {
                              setModalState(() => tempRadius = 5);
                            }),
                            _buildSelectablePill('< 10 km', '10', tempRadius == 10, () {
                              setModalState(() => tempRadius = 10);
                            }),
                            _buildSelectablePill('< 25 km', '25', tempRadius == 25, () {
                              setModalState(() => tempRadius = 25);
                            }),
                          ],
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // Sticky Apply Filters Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final minVal = double.tryParse(minPriceCtrl.text.replaceAll(',', '').trim());
                          final maxVal = double.tryParse(maxPriceCtrl.text.replaceAll(',', '').trim());

                          ref.read(exploreProvider.notifier).applyFilters(
                            sortBy: tempSortBy,
                            sellingMethod: tempMethod,
                            minPrice: minVal,
                            maxPrice: maxVal,
                            condition: tempCondition,
                            category: tempCategory,
                            radiusKm: tempRadius,
                          );

                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004E54),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildSelectablePill(
    String label,
    String value,
    bool isSelected,
    VoidCallback onTap, {
    bool isExpanded = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF004E54) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF004E54) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF004E54).withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        alignment: isExpanded ? Alignment.center : null,
        child: Row(
          mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 15, color: Colors.white),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exploreState = ref.watch(exploreProvider);
    final liveLoc = ref.watch(liveLocationProvider);
    final selectedCategory = exploreState.selectedCategory;
    final selectedMethod = exploreState.selectedSellingMethod;
    final radius = exploreState.selectedRadiusKm;

    final distText = radius == 0 ? 'Any distance' : '< ${radius}km';
    final locationStr = '${liveLoc.displayText} • $distText';

    final bool hasActiveFilters = selectedMethod != 'ALL' ||
        selectedCategory != 'All' ||
        radius != 10 ||
        exploreState.sortBy != 'relevance' ||
        exploreState.condition != 'ANY' ||
        exploreState.minPrice != null ||
        exploreState.maxPrice != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () => ref.read(exploreProvider.notifier).fetchExploreData(isRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Location & Real-Time Status Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Location Chip
                      GestureDetector(
                        onTap: () => _showFilterModal(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                locationStr,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.primary),
                            ],
                          ),
                        ),
                      ),

                      // Live Pulse Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F0),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Color(0xFF10B981), size: 7),
                            SizedBox(width: 4),
                            Text(
                              'Live Feed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Search Input & Filter Tune Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search electronics, bikes, furniture...',
                              hintStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppTheme.primary,
                                size: 22,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Filter Tune Button
                      GestureDetector(
                        onTap: () => _showFilterModal(context),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              if (hasActiveFilters)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Category Horizontal Filter Carousel
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = _categories[index];
                      final catName = item['name'] as String;
                      final catIcon = item['icon'] as IconData;
                      final isSelected = selectedCategory == catName;

                      return GestureDetector(
                        onTap: () => ref.read(exploreProvider.notifier).selectCategory(catName),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF004E54) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF004E54) : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF004E54).withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                catIcon,
                                size: 15,
                                color: isSelected ? Colors.white : const Color(0xFF004E54),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                catName,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Quick Selling Method Filter Tabs (All / Direct Buy / Auctions)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildMethodTab('ALL', 'All Items', selectedMethod == 'ALL'),
                      const SizedBox(width: 8),
                      _buildMethodTab('DIRECT_BUY', 'Direct Buy', selectedMethod == 'DIRECT_BUY'),
                      const SizedBox(width: 8),
                      _buildMethodTab('AUCTION', 'Live Bids', selectedMethod == 'AUCTION'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Deals Near You Section (Shown when browsing overview)
                if (!hasActiveFilters && exploreState.searchQuery.isEmpty && exploreState.dealsNearYou.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Deals Near You',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 236,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: exploreState.dealsNearYou.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return DealNearYouCard(listing: exploreState.dealsNearYou[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                ],

                // 6. Top Community Sellers Section (Shown when browsing overview)
                if (!hasActiveFilters && exploreState.searchQuery.isEmpty && exploreState.topSellers.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified, color: AppTheme.primary, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Verified Top Sellers',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: exploreState.topSellers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return TopSellerCard(seller: exploreState.topSellers[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                ],

                // 7. Recently Viewed Section (Shown when browsing overview)
                if (!hasActiveFilters && exploreState.searchQuery.isEmpty && exploreState.recentlyViewed.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Recently Viewed',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 124,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: exploreState.recentlyViewed.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return RecentlyViewedCard(listing: exploreState.recentlyViewed[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                ],

                // 8. Marketplace Feed Title & Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getFeedTitle(selectedMethod, selectedCategory),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${exploreState.marketplaceListings.length} items',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: exploreState.isLoading && exploreState.marketplaceListings.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          ),
                        )
                      : exploreState.marketplaceListings.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(36.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.search_off_rounded, size: 54, color: Color(0xFF94A3B8)),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No listings found',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Try changing your category, selling type, or expanding search radius.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        ref.read(exploreProvider.notifier).selectCategory('All');
                                        ref.read(exploreProvider.notifier).selectSellingMethod('ALL');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Reset Filters', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: exploreState.marketplaceListings.length,
                              itemBuilder: (context, index) {
                                return MarketplaceGridCard(
                                  listing: exploreState.marketplaceListings[index],
                                );
                              },
                            ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTab(String method, String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(exploreProvider.notifier).selectSellingMethod(method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  String _getFeedTitle(String method, String category) {
    if (category != 'All') {
      if (method == 'AUCTION') return '$category • Live Bids';
      if (method == 'DIRECT_BUY') return '$category • Direct Buy';
      return '$category Marketplace';
    }
    if (method == 'AUCTION') return 'Live Bids & Auctions';
    if (method == 'DIRECT_BUY') return 'Direct Buy Marketplace';
    return 'Marketplace Feed';
  }
}
