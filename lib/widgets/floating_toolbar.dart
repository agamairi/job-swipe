import 'package:flutter/material.dart';
import 'package:job_swipe/screens/home_screen.dart';
import 'package:job_swipe/screens/profile_page.dart';
import 'package:job_swipe/screens/sources_page.dart';

class FloatingToolbar extends StatelessWidget {
  final int currentIndex;

  const FloatingToolbar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 60, left: 32, right: 32),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Keep it compact
        children: [
          _buildNavItem(
            context,
            icon: Icons.home_rounded,
            index: 0,
            onTap: () {
              if (currentIndex != 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            },
          ),
          const SizedBox(width: 24),
          _buildNavItem(
            context,
            icon: Icons.api_rounded,
            index: 1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SourcesPage()),
              );
            },
          ),
          const SizedBox(width: 24),
          _buildNavItem(
            context,
            icon: Icons.person_rounded,
            index: 2,
            onTap: () {
              if (currentIndex != 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == index;
    final color =
        isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}
