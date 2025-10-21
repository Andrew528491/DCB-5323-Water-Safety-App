import 'package:flutter/material.dart';
import 'lesson_content_screen.dart';
import 'package:water_safety_app/widgets/water_transition_wrapper.dart';

// Displays the list of safety topics and manages transitions into the lesson content

final GlobalKey<_LessonsScreenState> lessonsScreenKey = GlobalKey<_LessonsScreenState>();

class LessonsScreen extends StatefulWidget {
  final bool autoOpenNextLesson;


  LessonsScreen({ 
    this.autoOpenNextLesson = false,
  }) : super(key: lessonsScreenKey);

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();

  // The list of lessons available. Currently have temp names and other info.
  static final List<Map<String, dynamic>> lessons = [
    {
      "title": "Lesson 1: TestName",
      "description": "Default description. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
      "isCompleted": true,
      "icon": Icons.water,
    },
    {
      "title": "Lesson 2: TestName",
      "description": "Default description. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
      "isCompleted": false,
      "icon": Icons.health_and_safety,
    },
    {
      "title": "Lesson 3: TestName",
      "description": "Default description. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
      "isCompleted": false,
      "icon": Icons.pool,
    },
    {
      "title": "Lesson 4: TestName",
      "description": "Default description. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
      "isCompleted": false,
      "icon": Icons.home,
    },
    {
      "title": "Lesson 5: TestName",
      "description": "Default description. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
      "isCompleted": false,
      "icon": Icons.bathtub,
    },
    {
      "title": "Lesson 6: TestName",
      "description": "Default description. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
      "isCompleted": false,
      "icon": Icons.waves,
    },
    {
      "title": "Lesson 7: TestName",
      "description": "Default description. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
      "isCompleted": false,
      "icon": Icons.beach_access,
    },
  ];

  // Helper method to find the next lesson for the user to complete in sequence
  static String findNextUncompletedLessonTitle() {
    for (var lesson in lessons) {
      if (lesson["isCompleted"] == false) {
        return lesson["title"] as String;
      }
    }
    return "Start Your Journey"; 
  }

  // Helper method to find the icon for the next lesson for the user to complete in sequence
  static IconData findNextUncompletedLessonIcon() {
    for (var lesson in lessons) {
      if (lesson["isCompleted"] == false) {
        return lesson["icon"] as IconData;
      }
    }
    return Icons.menu_book; 
  }

  // Helper method to retrieve the id of the next uncompleted lesson
  static int findNextUncompletedLessonId() {
    for (int i = 0; i < lessons.length; i++) {
      if (lessons[i]["isCompleted"] == false) {
        return i;
      }
    }
    return -1;
  }
}

class _LessonsScreenState extends State<LessonsScreen> {
  int _selectedLessonIndex = 0;
  
  int _currentView = 0; 
  
  late bool _shouldSkipAnimation;

  @override
  void initState() {
    super.initState();
    _shouldSkipAnimation = false; // Used by continue button on home_screen to smoothly move into lesson content
  }
  
  @override
  void didUpdateWidget(covariant LessonsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  // Method for continue button to open directly into lesson content
  void openNextLessonFromHome() {
    final int nextLessonIndex = LessonsScreen.findNextUncompletedLessonId();
    if (nextLessonIndex != -1) {
      setState(() {
        _selectedLessonIndex = nextLessonIndex;
        _currentView = 1; 
        _shouldSkipAnimation = true; 
      });
    }
  }

  // Method to open lesson content from the lesson list
  void _openLesson(int index) {
    setState(() {
      _selectedLessonIndex = index;
      _currentView = 1;
      _shouldSkipAnimation = false; 
    });
  }

  // Method to switch from the lesson content screenback to the lesson list
  void _goBack() {
    setState(() {
      _currentView = 0;
      _shouldSkipAnimation = false;
    });
  }
  
  // Builds the top lesson header
  Widget _buildLessonBanner(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final completedCount = LessonsScreen.lessons.where((l) => l["isCompleted"] == true).length;
    final totalCount = LessonsScreen.lessons.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: SafeArea(
        bottom: false, 
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.menu_book, color: Colors.white, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'Water Safety Lessons',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$completedCount out of ${LessonsScreen.lessons.length} lessons completed!',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: totalCount > 0 ? completedCount / totalCount : 0,
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightGreenAccent),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the individual lesson selection cards
  Widget _buildLessonCard(int index) {
    final lesson = LessonsScreen.lessons[index];
    final bool isCompleted = lesson["isCompleted"];
    final IconData lessonIcon = lesson["icon"];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isCompleted 
            ? BorderSide(color: Colors.green.shade400, width: 2) 
            : BorderSide.none,
      ),
      child: InkWell( 
        onTap: () => _openLesson(index),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                    Text(
                      lesson["title"],
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(width: 10), 
                  const Spacer(),
                  Icon(
                    lessonIcon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ],
              ),
              const Divider(height: 16, thickness: 1),
              Text(
                lesson["description"],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                isCompleted ? "Completed" : "Start Lesson",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green.shade500 : Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the scroll view
  Widget _buildScrollableLessonContent() {
    const Color shallowWater = Color(0xFF81D4FA); 
    const Color deepWater = Color(0xFF0D47A1); 
    const double bannerPadding = 160.0;

    return SingleChildScrollView(
      child: Stack(
        children: [
          Container(
            height: 1600.0, 
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [shallowWater, deepWater],
                stops: [0.0, 1.0], 
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(top: bannerPadding, left: 12, right: 12, bottom: 162),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(
                LessonsScreen.lessons.length,
                (index) => _buildLessonCard(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the lesson_screen UI
  Widget _buildLessonListScreen() {
    return Stack(
      children: [
        _buildScrollableLessonContent(),
        
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildLessonBanner(context),
        ),
      ],
    );
  }
  
  // Manages everything to do with moving in and out of lesson content
  @override
  Widget build(BuildContext context) {
    
    Widget lessonsContent = IndexedStack(
      index: _currentView,
      children: [
        _buildLessonListScreen(), 
        LessonContentScreen( 
          lessonId: _selectedLessonIndex,
          onBack: _goBack,
        ),
      ],
    );
    
    if (_shouldSkipAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_shouldSkipAnimation) {
              setState(() {
                _shouldSkipAnimation = false;
              });
        }
      });
      return lessonsContent; 
    }

    return WaterTransitionWrapper(
      contentKey: ValueKey(_currentView), 
      onTransitionComplete: () {}, 
      child: lessonsContent,
    );
  }
}