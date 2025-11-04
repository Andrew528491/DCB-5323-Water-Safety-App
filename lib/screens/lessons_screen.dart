import 'package:flutter/material.dart';
import 'lesson_content_screen.dart';
import 'package:water_safety_app/widgets/water_transition_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_screen.dart'; 
import '../games/riptide_escape_screen.dart';

// Displays the list of safety topics and manages transitions into the lesson content

final GlobalKey<_LessonsScreenState> lessonsScreenKey = GlobalKey<_LessonsScreenState>();

// Method to fetch icon
IconData getLessonIcon(String? iconName) {
  switch (iconName) {
    case 'fence':
      return Icons.fence;
    case 'medical_services_outlined':
      return Icons.medical_services_outlined;
    case 'pool_outlined':
      return Icons.pool_outlined;
    case 'water':
      return Icons.water;
    case 'remove_red_eye':
      return Icons.remove_red_eye;
    default:
      return Icons.help_outline;
  }
}

class LessonsScreen extends StatefulWidget {
  final bool autoOpenNextLesson;

  LessonsScreen({
    this.autoOpenNextLesson = false,
  }) : super(key: lessonsScreenKey);

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
  static List<Map<String, dynamic>> get lessons {
    final state = lessonsScreenKey.currentState;
    return state?._lessonsFromFirebase ?? [];
  }

  static String findNextUncompletedLessonTitle() {
    for (var lesson in lessons) {
      if (lesson["isCompleted"] == false) {
        return lesson["title"] as String;
      }
    }
    return "Start Your Journey";
  }

  static IconData findNextUncompletedLessonIcon() {
    for (var lesson in lessons) {
      if (lesson["isCompleted"] == false) {
        return getLessonIcon(lesson["icon"]);
      }
    }
    return Icons.menu_book;
  }

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

  // firebase var
  List<Map<String, dynamic>> _lessonsFromFirebase = [];
  bool _isLoading = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _shouldSkipAnimation = false; 
    _fetchLessonsFromFirebase();
  }

  // fetch lessons from firestore 
  Future<void> _fetchLessonsFromFirebase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _db
          .collection('lessons')
          .orderBy('lessonNumber')
          .get();

      // firebase var
      final lessons = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "title": data["title"] ?? "Untitled Lesson",
          "description": data["description"] ?? "",
          "lessonNumber": data["lessonNumber"] ?? 0,
          "content": List<String>.from(data["content"] ?? []),
          "imageURL": data["imageURL"],
          "icon": data["icon"],
          "isCompleted": false, // set from user progress afterwards
          "gameCompleted": false, 
        };
      }).toList();

      setState(() {
        _lessonsFromFirebase = lessons;
        _isLoading = false;
      });

      await _fetchUserProgress();
    } catch (e) {
      debugPrint("Error loading lessons: $e");
      setState(() => _isLoading = false);
    }
  }

  // Fetch the current user's lessonTracker map and apply to lessons list
  Future<void> _fetchUserProgress() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        for (var l in _lessonsFromFirebase) {
          l["isCompleted"] = false;
          l["gameCompleted"] = false; 
        }
      });
      return;
    }


    final userDoc = await _db.collection('users').doc(user.uid).get();
    final data = userDoc.data();
    final Map<String, dynamic> tracker = (data != null && data["lessonTracker"] is Map)
        ? Map<String, dynamic>.from(data["lessonTracker"])
        : {};

    setState(() {
      for (var l in _lessonsFromFirebase) {
        final String lessonId = l["id"] as String;
        l["isCompleted"] = tracker[lessonId] == true; 
        l["gameCompleted"] = tracker[lessonId] == true; 
      }
    });
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

  // Method to switch from the lesson content screen back to the lesson list
  void _goBack() {
    setState(() {
      _currentView = 0;
      _shouldSkipAnimation = false;
    });
  }


  // Callback used by LessonContentScreen to mark game as played
  void _markGameCompletedLocally(String lessonId) {
    final lesson = _lessonsFromFirebase.firstWhere((l) => l["id"] == lessonId);
    lesson["gameCompleted"] = true;
    _goBack();
  }


  // Method to launch the quiz and then save full completion
  Future<void> _launchQuizAndComplete(BuildContext context, Map<String, dynamic> lesson) async {
    final quizResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(lesson: lesson),
      ),
    );

    if (quizResult == true && context.mounted) {
      await _saveLessonCompletion(context, lesson);
    }
  }
  
  // Helper function to save lesson completion
  Future<void> _saveLessonCompletion(BuildContext context, Map<String, dynamic> lesson) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save progress: user not signed in.')),
        );
      }
      return;
    }

    final lessonId = lesson["id"] as String?;
    if (lessonId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save progress: lesson id missing.')),
        );
      }
      return;
    }

    // Update user's lessonTracker map for this lesson to true in Firestore
    await _db
        .collection('users')
        .doc(user.uid)
        .update({'lessonTracker.$lessonId': true});

    // Update local state
    lesson["isCompleted"] = true;
    lesson["gameCompleted"] = true; 
    setState(() {});
  }


  // Builds the top lesson header
  Widget _buildLessonBanner(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final completedCount = _lessonsFromFirebase.where((l) => l["isCompleted"] == true).length;
    final totalCount = _lessonsFromFirebase.length;

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
                '$completedCount out of $totalCount lessons completed!',
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
    final lesson = _lessonsFromFirebase[index];
    final bool isCompleted = lesson["isCompleted"] ?? false;
    final bool gameCompleted = lesson["gameCompleted"] ?? false; 
    final IconData lessonIcon = getLessonIcon(lesson["icon"]);
    
    // Determine button text and color based on state
    String buttonText;
    IconData buttonIcon;
    Color buttonColor;
    VoidCallback? onPressed;

    if (isCompleted) {
      buttonText = 'Lesson Completed!';
      buttonIcon = Icons.check_circle;
      buttonColor = Colors.green.shade400;
      onPressed = null;
    } else if (gameCompleted) {
      buttonText = 'Take Quiz';
      buttonIcon = Icons.quiz;
      buttonColor = Theme.of(context).colorScheme.primary; 
      onPressed = () => _launchQuizAndComplete(context, lesson);
    } else {
      buttonText = 'Play Game to Unlock Quiz';
      buttonIcon = Icons.lock; 
      buttonColor = Colors.grey.shade400;
      onPressed = null; 
    }


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
      child: Column(
        children: [
          // Top section is the lesson content link
          InkWell(
            onTap: () => _openLesson(index),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15), bottom: Radius.circular(0)),
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
                    isCompleted ? "Completed" : "Read Lesson Content",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green.shade500 : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom section is the Quiz button
          const Divider(height: 0, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(buttonIcon, size: 24),
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: buttonColor, 
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400, 
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the scroll view with dynamic gradient background
  Widget _buildScrollableLessonContent() {
    const Color shallowWater = Color(0xFF81D4FA);
    const Color deepWater = Color(0xFF0D47A1);
    const double bannerPadding = 160.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox( 
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight, 
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [shallowWater, deepWater],
                  stops: [0.0, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: bannerPadding, left: 12, right: 12, bottom: 162),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(
                    _lessonsFromFirebase.length,
                    (index) => _buildLessonCard(index),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_lessonsFromFirebase.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No lessons available.")),
      );
    }

    Widget lessonsContent = IndexedStack(
      index: _currentView,
      children: [
        _buildLessonListScreen(),
        // Pass the game completion callback and state
        LessonContentScreen(
          lesson: _lessonsFromFirebase[_selectedLessonIndex],
          onBack: _goBack,
          onGamePlayed: () => _markGameCompletedLocally(_lessonsFromFirebase[_selectedLessonIndex]["id"]),
          gameCompleted: _lessonsFromFirebase[_selectedLessonIndex]["gameCompleted"] ?? false,
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