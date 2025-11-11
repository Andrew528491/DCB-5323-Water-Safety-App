import 'package:flutter/material.dart';
import 'lesson_content_screen.dart';
import 'package:water_safety_app/widgets/water_transition_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_screen.dart'; 

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
    setState(() { _isLoading = true; });

    try {
      final snapshot = await _db
          .collection('lessons')
          .orderBy('lessonNumber')
          .get();

      final lessons = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "title": data["title"] ?? "Untitled Lesson",
          "description": data["description"] ?? "",
          "lessonNumber": (data["lessonNumber"] as num?)?.toInt() ?? 0, 
          "content": List<String>.from(data["content"] ?? []),
          "imageURL": data["imageURL"],
          "icon": data["icon"],
          "isCompleted": false, 
          "gameCompleted": false, 
          "quizScore": 0,
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

  // Fetch the current user's lesson progress from the lessonTracker subcollection
  Future<void> _fetchUserProgress() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        for (var l in _lessonsFromFirebase) {
          l["isCompleted"] = false;
          l["gameCompleted"] = false; 
          l["quizScore"] = 0; 
        }
      });
      return;
    }

    // Fetch all documents from the lessonTracker subcollection
    final trackerSnapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('lessonTracker')
        .get();
        
    final Map<String, Map<String, dynamic>> tracker = {};
    for (var doc in trackerSnapshot.docs) {
      tracker[doc.id] = doc.data();
    }

    setState(() {
      for (var l in _lessonsFromFirebase) {
        final String lessonNumId = (l["lessonNumber"] ?? 0).toString(); // Get lessonNumber as string key
        final progress = tracker[lessonNumId];

        if (progress != null) {
          final bool playedGame = progress['playedGame'] ?? false;
          // quizScore is stored as -1 for unattempted, 0-100 for attempted
          final int quizScore = progress['quizScore'] is num 
              ? (progress['quizScore'] as num).toInt() 
              : 0; 

          // Use the stored completion status, or check for a passing score >= 70
          l["isCompleted"] = (progress['completion'] as bool? ?? false) || (quizScore >= 70); 
          l["gameCompleted"] = playedGame;
          l["quizScore"] = quizScore; 
        } else {
            l["isCompleted"] = false;
            l["gameCompleted"] = false;
            l["quizScore"] = 0;
        }
      }
    });
  }

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

  void _openLesson(int index) {
    setState(() {
      _selectedLessonIndex = index;
      _currentView = 1;
      _shouldSkipAnimation = false;
    });
  }

  void _goBack() {
    setState(() {
      _currentView = 0;
      _shouldSkipAnimation = false;
    });
  }


  // Mark game as played in the lessonTracker subcollection
  void _markGameCompletedLocally(int lessonNumber) async {
    final user = _auth.currentUser;
    if (user == null) {
      _goBack();
      return;
    }

    final String lessonNumId = lessonNumber.toString();
    final progressDocRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('lessonTracker')
        .doc(lessonNumId);
    
      await progressDocRef.set({
            'playedGame': true,
          }, SetOptions(merge: true)); 

      final lesson = _lessonsFromFirebase.firstWhere((l) => l["lessonNumber"] == lessonNumber);
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

    // Check if a quiz was submitted
    if (quizResult is Map<String, dynamic> && quizResult['total'] != null && quizResult['total'] > 0) {
      final int rawScore = quizResult['score'] as int;
      final int totalQuestions = quizResult['total'] as int;
      final bool passed = quizResult['passed'] as bool;

      // Calculate the score as a percentage 
      final int finalScorePercentage = totalQuestions > 0 
          ? ((rawScore / totalQuestions) * 100).round()
          : 0;
      
      if (context.mounted) {
        // Save Score and update completion status
        await _saveLessonScore(context, lesson, finalScorePercentage, passed); 
      }
    }
    
    if (context.mounted) {
      _goBack(); 
    }
  }
  
  // Helper method to save the final score to the subcollection
  Future<void> _saveLessonScore(BuildContext context, Map<String, dynamic> lesson, int finalScore, bool passed) async {
    final user = _auth.currentUser;
    final int lessonNumber = lesson["lessonNumber"] as int;
    final String lessonNumId = lessonNumber.toString();

    if (user == null || lessonNumber == 0) {
      return;
    }

    final progressDocRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('lessonTracker')
        .doc(lessonNumId);


    // Get the current progress document to check the best score and game completion
    final lessonDoc = await progressDocRef.get();

    final int currentSavedScore = lessonDoc.exists && lessonDoc['quizScore'] is num
        ? (lessonDoc['quizScore'] as num).toInt()
        : 0;

        // Get current quiz completions count
    final int currentCompletions = lessonDoc.exists && lessonDoc.data()?['quizCompletions'] is num
        ? (lessonDoc.data()!['quizCompletions'] as num).toInt()
        : 0;
    
    // Determine the score to save
    final int scoreToSave = finalScore > currentSavedScore ? finalScore : currentSavedScore;

    // Determine the final completion status
    final bool finalCompletedStatus = passed || (currentSavedScore >= 70);

    // Update/Set the lesson progress document in the subcollection
    final Map<String, dynamic> updateData = {
      'completion': finalCompletedStatus, 
      'playedGame': true,
      'quizScore': scoreToSave,
    };

    // Increment quizCompletions only if the user passed this time
    if (passed) {
      updateData['quizCompletions'] = currentCompletions + 1;
    }

    // Update/Set the lesson progress document in the subcollection
    await progressDocRef.set(updateData, SetOptions(merge: true)); 

    lesson["isCompleted"] = finalCompletedStatus; 
    lesson["gameCompleted"] = true; 
    lesson["quizScore"] = scoreToSave; // Store the best score
    
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

  // Builds the individual lesson selection cards with score display
  Widget _buildLessonCard(int index) {
    final lesson = _lessonsFromFirebase[index];
    final bool isCompleted = lesson["isCompleted"] ?? false;
    final bool gameCompleted = lesson["gameCompleted"] ?? false; 
    final int quizScore = lesson["quizScore"] ?? 0; 
    final IconData lessonIcon = getLessonIcon(lesson["icon"]);
    
    String buttonText;
    IconData buttonIcon;
    Color buttonColor;
    VoidCallback? onPressed;
    String statusText;

    if (isCompleted) {
      buttonText = 'Completed - Take Again?';
      buttonIcon = Icons.check_circle;
      buttonColor = Colors.green.shade400;
      // TODO: Change this in sprint 3 to something else?
      onPressed = () => _launchQuizAndComplete(context, lesson);
      statusText = "Completed with $quizScore%";
    } else if (gameCompleted) {
      buttonText = 'Take Quiz';
      buttonIcon = Icons.quiz;
      buttonColor = Theme.of(context).colorScheme.primary; 
      onPressed = () => _launchQuizAndComplete(context, lesson);
      // Show the best score if they attempted it but didn't pass
      statusText = quizScore >= 0 ? "Best Score: $quizScore%" : "Game Played! Quiz Ready.";
    } else {
      buttonText = 'Play Game to Unlock Quiz';
      buttonIcon = Icons.lock; 
      buttonColor = Colors.grey.shade400;
      onPressed = null; 
      statusText = "Read Lesson Content";
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
                  // Show detailed status
                  Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green.shade500 : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom section is the Quiz/Game/Completion button
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
                  disabledBackgroundColor: isCompleted ? Colors.green.shade400 : Colors.grey.shade400,
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

    // Get the lesson number for the current selected lesson to pass to the game completion callback
    final int selectedLessonNumber = _lessonsFromFirebase[_selectedLessonIndex]["lessonNumber"] as int;

    Widget lessonsContent = IndexedStack(
      index: _currentView,
      children: [
        _buildLessonListScreen(),
        LessonContentScreen(
          lesson: _lessonsFromFirebase[_selectedLessonIndex],
          onBack: _goBack,
          onGamePlayed: () => _markGameCompletedLocally(selectedLessonNumber),
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