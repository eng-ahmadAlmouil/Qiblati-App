import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../prayer_times/presentation/prayer_times_page.dart';
import '../../qibla/presentation/qibla_page.dart';
import '../../quran/presentation/quran_page.dart';
import '../../tafsir/presentation/tafsir_page.dart';
import '../../devotions/presentation/devotions_page.dart';
import 'home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;
  late final PageController _pageController;

  final _pages = const [
    QiblaPage(),
    PrayerTimesPage(),
    QuranPage(),
    TafsirPage(),
    DevotionsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = HomeController()..addListener(_refresh);
    _pageController = PageController();
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFE8F8F5), AppColors.sand, Color(0xFFE5EEF8)],
            ),
          ),
          child: PageView(
            controller: _pageController,
            onPageChanged: _controller.selectTab,
            children: _pages,
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: LiquidGlass(
            borderRadius: 28,
            child: NavigationBar(
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              selectedIndex: _controller.selectedIndex,
              onDestinationSelected: (index) {
                _controller.selectTab(index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'القبلة',
                ),
                NavigationDestination(
                  icon: Icon(Icons.access_time_outlined),
                  selectedIcon: Icon(Icons.access_time_filled),
                  label: 'المواقيت',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: 'القرآن',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories),
                  label: 'التفسير',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'الأدعية',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
