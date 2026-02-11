import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/media/screens/home_screen.dart';
import 'features/media/screens/statistics_screen.dart';
import 'features/media/screens/profile_screen.dart';

class InnerArchiveApp extends StatelessWidget {
  const InnerArchiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inner Archive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          StatisticsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library_outlined),
            activeIcon: Icon(Icons.video_library),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
