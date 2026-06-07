import 'package:flutter/material.dart';
import 'package:job_swipe/screens/home_screen.dart';
import 'package:job_swipe/screens/profile_page.dart';
import 'package:job_swipe/screens/sources_page.dart';

class FooterNavigationBar extends StatelessWidget {
  final int currentIndex;

  const FooterNavigationBar({super.key, this.currentIndex = 0});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;

        Widget destination;
        switch (index) {
          case 0:
            destination = const HomeScreen();
            break;
          case 1:
            destination = const SourcesPage();
            break;
          case 2:
            destination = const ProfilePage();
            break;
          default:
            return;
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => destination,
            transitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.api_outlined),
          selectedIcon: Icon(Icons.api_rounded),
          label: 'Sources',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
