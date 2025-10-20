// lib/screens/navigation_screen.dart

import 'package:flutter/material.dart';
import '../widgets/water_transition_wrapper.dart'; 
import '../widgets/nav_bar_clipper.dart'; 
import 'home_screen.dart';
import 'lessons_screen.dart';
import 'profile_screen.dart';
import 'game_screen.dart';

// NOTE: This assumes LessonScreen.dart still contains the static finders:
// LessonsScreen.findNextUncompletedLessonTitle() and LessonsScreen.findNextUncompletedLessonIcon()

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  // FIX: Error 1 (Missing concrete implementation) is fixed by ensuring the build method is present and the final closing brace is correct.
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  
  Key _contentKey = const ValueKey(0); 
  int _selectedIndex = 0; 
  
  // Lesson data (used to pass required arguments to HomeScreen)
  final String _nextLessonTitle = LessonsScreen.findNextUncompletedLessonTitle();
  final IconData _nextLessonIcon = LessonsScreen.findNextUncompletedLessonIcon(); 

  // The persistent list of screens used by IndexedStack.
  late final List<Widget> _screens;
  
  // This method is called by WaterTransitionWrapper after the animation finishes
  void _updateSelectedIndex() {
    setState(() {
      _selectedIndex = (_contentKey as ValueKey<int>).value;
    });
  }

  // Handles both BottomNavigationBar taps and the HomeScreen's "Continue" button
  void _onItemTapped(int index, {bool autoOpen = false}) {
    // Note: The autoOpen flag is only passed when called from HomeScreen.
    if (index != _selectedIndex) {
      
      // If navigating to the Lessons screen from the Home screen's "Continue" button
      // we must rebuild the LessonsScreen widget instance to set autoOpenNextLesson = true.
      if (index == 1 && autoOpen) {
          _screens[1] = LessonsScreen(
              key: const PageStorageKey('lessons'),
              autoOpenNextLesson: true, // Rebuild with the flag set
          );
      } else if (index == 1) {
          // If navigating normally (from the bottom bar), ensure autoOpen is false.
          _screens[1] = LessonsScreen(
              key: const PageStorageKey('lessons'),
              autoOpenNextLesson: false,
          );
      }
      
      // Update the key to trigger the WaterTransitionWrapper animation.
      setState(() {
        _contentKey = ValueKey(index);
      });
    }
  }

  @override
  void initState() {
    // FIX: Removed unused 'initState' error. We need initState to initialize _screens.
    super.initState();
    
    // FIX: Errors 2, 3, 4 (Missing required arguments) are fixed by initializing
    // the persistent _screens list here, passing all required arguments to HomeScreen.
    _screens = [
      HomeScreen(
        key: const PageStorageKey('home'),
        nextLessonTitle: _nextLessonTitle, 
        nextLessonIcon: _nextLessonIcon,
        // The callback needs to use the correct _onItemTapped signature
        onNavigateToLessons: () => _onItemTapped(1, autoOpen: true),
      ),
      LessonsScreen(
        key: const PageStorageKey('lessons'),
        autoOpenNextLesson: false, // Default to false
      ),
      const GameScreen(key: PageStorageKey('game')),
      const ProfileScreen(key: PageStorageKey('profile')),
    ];
    
    // FIX: Removed the unused _setWidgetOptions call.
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Error 7 (The declaration 'build' isn't referenced) is fixed by ensuring the class structure is correct.
    return Scaffold(
      body: Stack(
        children: [
          // 1. WaterTransitionWrapper wraps the IndexedStack
          WaterTransitionWrapper(
            contentKey: _contentKey,
            onTransitionComplete: _updateSelectedIndex,
            child: IndexedStack(
              // The index to show is the one set by the key that started the animation
              index: (_contentKey as ValueKey<int>).value,
              children: _screens, // Use the persistent _screens list
            ),
          ),

          // 2. Navigation bar
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
                  // Pass index only, the internal logic handles the optional autoOpen param
                  onTap: (index) => _onItemTapped(index), 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}