import 'package:flutter/material.dart';
import 'package:job_swipe/screens/home_screen.dart';
import 'package:job_swipe/screens/profile_page.dart';

class FooterNavigationBar extends StatefulWidget {
  final VoidCallback? onTap;

  const FooterNavigationBar({super.key, this.onTap});

  @override
  createState() => _FooterNavigationBarState();
}

class _FooterNavigationBarState extends State<FooterNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0, // Border thickness
          ),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0), // Curved top-left corner
          topRight: Radius.circular(20.0), // Curved top-right corner
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => HomeScreen(),
                ),
              );
            },
            icon: Icon(Icons.home_outlined, size: 48),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => ProfilePage(),
                ),
              );
            },
            icon: Icon(Icons.person_outline, size: 48),
          ),
        ],
      ),
    );
  }
}
