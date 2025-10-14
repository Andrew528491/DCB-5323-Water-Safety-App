import 'package:flutter/material.dart';
import '../widgets/water_transition_wrapper.dart'; 
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
      
      // Wrapper for the animation on navigation option chosen
      body: WaterTransitionWrapper(
        contentKey: _contentKey,
        child: _widgetOptions.elementAt((_contentKey as ValueKey<int>).value),
        onTransitionComplete: _updateSelectedIndex,
      ),
      
      // Bottom Navigation bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: 'Lessons'),
          BottomNavigationBarItem(icon: Icon(Icons.gamepad_outlined), label: 'Games'), 
          BottomNavigationBarItem(icon: Icon(Icons.person_outlined), label: 'Profile'),
        ],
        
        // 
        currentIndex: _selectedIndex, 
        selectedItemColor: Theme.of(context).colorScheme.primary, 
        onTap: _onItemTapped,
      ),
    );
  }
}