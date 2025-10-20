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
  late List<Widget> _widgetOptions; 
  
  final String _nextLessonTitle = LessonsScreen.findNextUncompletedLessonTitle();
  final IconData _nextLessonIcon = LessonsScreen.findNextUncompletedLessonIcon(); 

  void _updateSelectedIndex() {
    setState(() {
      _selectedIndex = (_contentKey as ValueKey<int>).value;
    });
  }

  void _setWidgetOptions({bool autoOpenLessons = false}) {
    _widgetOptions = <Widget>[
      HomeScreen(
        onNavigateToLessons: () => _onItemTapped(1, autoOpen: true),
        nextLessonTitle: _nextLessonTitle, 
        nextLessonIcon: _nextLessonIcon,
      ),
      LessonsScreen(
        autoOpenNextLesson: autoOpenLessons,
      ), 
      const GameScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index, {bool autoOpen = false}) {
    if (index != _selectedIndex) {
      
      _setWidgetOptions(autoOpenLessons: autoOpen && index == 1); 

      setState(() {
        _contentKey = ValueKey(index); 
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _setWidgetOptions(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WaterTransitionWrapper(
            contentKey: _contentKey,
            onTransitionComplete: _updateSelectedIndex,
            child: _widgetOptions.elementAt((_contentKey as ValueKey<int>).value),
          ),

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