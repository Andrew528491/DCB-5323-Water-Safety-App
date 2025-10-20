import 'package:flutter/material.dart';
import '../widgets/water_transition_wrapper.dart'; 
import '../widgets/nav_bar_clipper.dart'; 
import 'home_screen.dart';
import 'lessons_screen.dart';
import 'profile_screen.dart';
import 'game_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  Key _contentKey = const ValueKey(0);
  int _selectedIndex = 0;

  // Keep persistent instances of screens
  late final List<Widget> _screens = [
    HomeScreen(key: const PageStorageKey('home')),
    LessonsScreen(key: const PageStorageKey('lessons')),
    GameScreen(key: const PageStorageKey('game')),
    ProfileScreen(key: const PageStorageKey('profile')),
  ];

  void _updateSelectedIndex() {
    setState(() {
      _selectedIndex = (_contentKey as ValueKey<int>).value;
    });
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _contentKey = ValueKey(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animate only the top screen, but keep all screens alive
          WaterTransitionWrapper(
            contentKey: _contentKey,
            onTransitionComplete: _updateSelectedIndex,
            child: IndexedStack(
              index: (_contentKey as ValueKey<int>).value,
              children: _screens,
            ),
          ),

          // Navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 150,
              child: ClipPath(
                clipper: NavBarClipper(),
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  unselectedItemColor: Colors.white70,
                  selectedItemColor: Colors.white,
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Lessons'),
                    BottomNavigationBarItem(icon: Icon(Icons.gamepad), label: 'Games'),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                  ],
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}