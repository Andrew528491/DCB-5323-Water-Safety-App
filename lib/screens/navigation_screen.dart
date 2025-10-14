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

  // Navigation bar options
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(), 
    const LessonsScreen(),
    const GameScreen(),
    const ProfileScreen(),
  ];

  // updates the current index for the navigation bar. Called by the wrapper after the animation is played
  void _updateSelectedIndex() {
    setState(() {
      _selectedIndex = (_contentKey as ValueKey<int>).value;
    });
  }

  // retrieves the screen that was selected via the navigation bar
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
          WaterTransitionWrapper(
            contentKey: _contentKey,
            child: _widgetOptions.elementAt((_contentKey as ValueKey<int>).value),
            onTransitionComplete: _updateSelectedIndex,
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
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