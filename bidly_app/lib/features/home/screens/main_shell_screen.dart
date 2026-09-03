import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_theme.dart';
import '../services/reels_controller_manager.dart';
import 'home_feed_screen.dart';
import '../../explore/screens/explore_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../community/screens/communities_screen.dart';

final selectedNavIndexProvider = StateProvider<int>((ref) => 0);

class MainShellScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late int _currentIndex;

  final List<Widget> _pages = [
    const HomeFeedScreen(),
    const ExploreScreen(),
    const _PlaceholderTabScreen('Sell Product'),
    const CommunitiesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant MainShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != _currentIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
      ref.read(selectedNavIndexProvider.notifier).state = widget.initialIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(selectedNavIndexProvider);
    if (navIndex != _currentIndex) {
      _currentIndex = navIndex;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Home Tab
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                ),

                // Explore Tab
                _buildNavItem(
                  index: 1,
                  icon: Icons.search_rounded,
                  activeIcon: Icons.search_rounded,
                  label: 'Explore',
                ),

                // Center + Sell Button
                _buildSellButton(),

                // Community Tab (with notification badge '2')
                _buildNavItem(
                  index: 3,
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: 'Community',
                  badgeCount: 2,
                ),

                // Profile Tab
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int? badgeCount,
  }) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (index != 0) {
          ReelsControllerManager().pauseAll();
        } else if (_currentIndex != 0) {
          ReelsControllerManager().resumeCurrent();
        }
        ref.read(selectedNavIndexProvider.notifier).state = index;
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 26,
                  color: isActive ? const Color(0xFF004E54) : const Color(0xFF64748B),
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive ? const Color(0xFF004E54) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellButton() {
    return GestureDetector(
      onTap: () {
        ReelsControllerManager().pauseAll();
        context.push(AppRoutes.sell);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF004E54),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF004E54).withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Sell',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTabScreen extends StatelessWidget {
  final String title;
  const _PlaceholderTabScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard_customize_outlined, size: 48, color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              '$title coming in next step',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
