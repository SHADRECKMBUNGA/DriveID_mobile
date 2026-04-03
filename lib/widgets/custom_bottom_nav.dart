import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        onTap(index);
      },
      selectedItemColor: AppTheme.gold,
      unselectedItemColor: Colors.white38,
      backgroundColor: AppTheme.cardDark,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Verify"),
        BottomNavigationBarItem(icon: Icon(Icons.warning), label: "Offenses"),
      ],
    );
  }
}
