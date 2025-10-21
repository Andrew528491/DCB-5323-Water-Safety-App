import 'package:flutter/material.dart';
import '../widgets/water_transition_wrapper.dart'; 
import '../widgets/nav_bar_clipper.dart'; 
import 'home_screen.dart';
import 'lessons_screen.dart';
import 'profile_screen.dart';
import 'game_screen.dart';

// Main container for the app. Handles the navigation bar and custom water transition effects between screens

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  
  Key _contentKey = const ValueKey(0); // Used to trigger WaterTransitioWrapper
  int _selectedIndex = 0; 
  
  Key _homeScreenKey = const PageStorageKey('home_initial'); 
  
  // Values puled from lesson_screen to display on the continue button
  final String _nextLessonTitle = LessonsScreen.findNextUncompletedLessonTitle();
  final IconData _nextLessonIcon = LessonsScreen.findNextUncompletedLessonIcon(); 

  late List<Widget> _screens;
  
  void _updateSelectedIndex() {
    setState(() {
      _selectedIndex = (_contentKey as ValueKey<int>).value;
    });
  }
  
  // Screens are defined and ready to be loaded via the navigation baar
  void _createScreens() {
    _screens = <Widget>[
      HomeScreen(
        key: _homeScreenKey, 
        nextLessonTitle: _nextLessonTitle, 
        nextLessonIcon: _nextLessonIcon,
        // Used via the continue button to access the next lesson
        onNavigateToLessons: () => _onItemTapped(1, autoOpen: true),
      ),
      LessonsScreen(
        autoOpenNextLesson: false, 
      ),
      const GameScreen(key: PageStorageKey('game')),
      const ProfileScreen(key: PageStorageKey('profile')),
    ];
  }

  @override
  void initState() {
    super.initState();
    _createScreens();
  }

  void _onItemTapped(int index, {bool autoOpen = false}) {
    
    if (index == 0) {
      // Refreshes homescreen to update username
      _homeScreenKey = ValueKey('home_refresh_${DateTime.now().microsecondsSinceEpoch}');
      
      _screens[0] = HomeScreen(
          key: _homeScreenKey, 
          nextLessonTitle: _nextLessonTitle, 
          nextLessonIcon: _nextLessonIcon,
          onNavigateToLessons: () => _onItemTapped(1, autoOpen: true),
      );
    }
    
    // Used by continue button to open lesson content
    if (index == 1 && autoOpen) {
        final state = lessonsScreenKey.currentState;
        if (state != null) {
            state.openNextLessonFromHome();
        }
    }
    
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
          // Custom transition wrapper to apply water rising effect
          WaterTransitionWrapper(
            contentKey: _contentKey,
            onTransitionComplete: _updateSelectedIndex,
            child: IndexedStack(
              index: (_contentKey as ValueKey<int>).value,
              children: _screens, 
            ),
          ),

          // Navigation bar UI
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 150,
              child: ClipPath(
                // Clipper that gives concave shape
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