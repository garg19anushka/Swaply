import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import 'feed_screen.dart';
import '../explore/explore_screen.dart';
import '../posts/create_post_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late List<AnimationController> _iconCtrl;
  late List<Animation<double>> _iconScale;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Build screens here so FeedScreen can reference _onNavTap
    _screens = [
      FeedScreen(onSwitchTab: _onNavTap),
      const ExploreScreen(),
      const CreatePostScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];
    _iconCtrl = List.generate(
      5,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 160),
        lowerBound: 0.85,
        upperBound: 1.0,
        value: 1.0,
      ),
    );
    _iconScale = _iconCtrl
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();

    context.read<NotificationService>().subscribeToNotifications();
    context.read<NotificationService>().fetchNotifications();
  }

  @override
  void dispose() {
    for (final c in _iconCtrl) c.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    _iconCtrl[index].reverse().then((_) => _iconCtrl[index].forward());
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        iconScales: _iconScale,
        onTap: _onNavTap,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
//  Bottom Nav
// ────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<Animation<double>> iconScales;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.iconScales,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;
    final inactiveColor = isDark ? AppColors.darkTextLight : AppColors.textLight;
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(color: dividerColor, width: 1),
        ),
        boxShadow: AppShadows.bottomNav,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Home', inactiveColor),
              _navItem(
                1,
                Icons.search_outlined,
                Icons.search_rounded,
                'Explore',
                inactiveColor,
              ),
              _createBtn(inactiveColor),
              _chatItem(inactiveColor),
              _navItem(
                4,
                Icons.person_outline_rounded,
                Icons.person_rounded,
                'Profile',
                inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData outline, IconData filled, String label, Color inactiveColor) {
    final active = currentIndex == idx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(idx),
        child: ScaleTransition(
          scale: iconScales[idx],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active ? filled : outline,
                size: 25,
                color: active ? AppColors.primary : inactiveColor,
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? AppColors.primary : inactiveColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createBtn(Color inactiveColor) {
    final active = currentIndex == 2;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(2),
        child: ScaleTransition(
          scale: iconScales[2],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active
                    ? Icons.add_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 25,
                color: active ? AppColors.primary : inactiveColor,
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? AppColors.primary : inactiveColor,
                ),
                child: const Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatItem(Color inactiveColor) {
    return Consumer<NotificationService>(
      builder: (_, ns, __) {
        final active = currentIndex == 3;
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(3),
            child: ScaleTransition(
              scale: iconScales[3],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  badges.Badge(
                    showBadge: ns.unreadCount > 0,
                    badgeContent: Text(
                      ns.unreadCount > 9 ? '9+' : ns.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: AppColors.secondary,
                      padding: EdgeInsets.all(4),
                    ),
                    child: Icon(
                      active
                          ? Icons.chat_bubble_rounded
                          : Icons.chat_bubble_outline_rounded,
                      size: 25,
                      color: active ? AppColors.primary : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? AppColors.primary : inactiveColor,
                    ),
                    child: const Text('Chats'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}