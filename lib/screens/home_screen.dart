import 'package:flutter/material.dart';
import 'package:water_safety_app/widgets/homescreen_header_clipper.dart';
import 'lessons_screen.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 

// Main landing page. Shows user progress and daily messages

class HomeScreen extends StatefulWidget {

  // Receives data about next lesson from navigation_screen
  final String nextLessonTitle;
  final IconData nextLessonIcon; 
  final VoidCallback onNavigateToLessons; 

  const HomeScreen({
    super.key,
    required this.nextLessonTitle,
    required this.nextLessonIcon, 
    required this.onNavigateToLessons,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  
  String? _userName; // Holds fetched username
    
  late String _contextualTitleSubText;

  final List<String> _dailyMessages = const [
    "Always check water depth before diving in.",
    "Never swim alone—use the buddy system!",
    "Learn CPR. It can save a life near water.",
    "Be mindful of rip currents at the beach.",
    "Ensure all pool gates are securely locked.",
    "Know the signs of someone struggling in the water.",
  ];

  late String _dailyMessage;

  // Gets lesson progress for lesson progression visual
  int get _completedCount => LessonsScreen.lessons.where((l) => l["isCompleted"] == true).length;
  int get _totalCount => LessonsScreen.lessons.length;
  double get _progressValue => _totalCount > 0 ? _completedCount / _totalCount : 0;

  late AnimationController _waveController;
  late Animation<double> _waveAnimation; 

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Loads user name on screen init
    
    _dailyMessage = _selectDailyMessage();
    _contextualTitleSubText = _selectContextualTitleSubText();

    // Controls the waving effect of the header
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Speed of the wave movement
    )..repeat(); 

    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(_waveController);
  }
  
  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  // Fetches the user's display name from the database
  Future<void> _loadUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _userName = 'User';
        });
        return;
      }

      String fetchedName = user.displayName ?? 'User';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        fetchedName = data['username'] ?? user.displayName ?? 'User';
      }
      
      if (mounted) {
        setState(() {
          _userName = fetchedName;
        });
      }
    } catch (e) {
      debugPrint('Error loading username: $e');
      if (mounted) {
        setState(() {
          _userName = 'User';
        });
      }
    }
  }

  // Chooses a random message from the pool
  String _selectDailyMessage() {
    final random = Random();
    return _dailyMessages[random.nextInt(_dailyMessages.length)];
  }

  // Generates the subtitle on the header
  String _selectContextualTitleSubText() {
    // FIX: Check local progress instead of comparing incoming string
    final bool allComplete = _completedCount == _totalCount && _totalCount > 0;
    
    if (allComplete) {
      return "Congratulations! You've completed all lessons. Keep practicing!";
    }
    return "${widget.nextLessonTitle} is next up. Click below to continue your learning!";
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update contextual text when next lesson changes
    if (oldWidget.nextLessonTitle != widget.nextLessonTitle) {
      setState(() {
        _contextualTitleSubText = _selectContextualTitleSubText();
      });
    }
  }

  // Builds home_screen UI
  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[

            AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return _buildWavyHeader(context, primaryColor, _waveAnimation.value); 
              },
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  _buildDailyMessageCard(context, primaryColor),
                  const SizedBox(height: 40),

                  _buildContinueLessonCard(context, primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Builds the moving header
  Widget _buildWavyHeader(BuildContext context, Color primaryColor, double wavePhase) {
    // Show loading indicator or actual name
    final String displayName = (_userName ?? 'User');
    
    return ClipPath(
      clipper: WaveClipper(wavePhase: wavePhase),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 70), 
        width: double.infinity,
        decoration: BoxDecoration(
          color: primaryColor,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withAlpha(102), 
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back, $displayName!",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _contextualTitleSubText,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the daily message card
  Widget _buildDailyMessageCard(BuildContext context, Color primaryColor) {
    return Card(
      elevation: 10,
      shadowColor: primaryColor.withAlpha(76),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(25.0),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(229),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: primaryColor.withAlpha(25), 
            width: 1.5
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.spa_outlined, 
                  color: primaryColor.withAlpha(204),
                  size: 32,
                ),
                const SizedBox(width: 15),
                Text(
                  "Today's Safety Advice:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor.withAlpha(204),
                  ),
                ),
              ],
            ),
            const Divider(height: 25, thickness: 1.5),
            Text(
              _dailyMessage,
              style: const TextStyle(
                fontSize: 19,
                fontStyle: FontStyle.italic,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the continue lesson card
  Widget _buildContinueLessonCard(BuildContext context, Color primaryColor) {
    final bool allComplete = _completedCount == _totalCount && _totalCount > 0;
    
    final String buttonText = allComplete 
        ? "All Lessons Complete! - Review?"
        : widget.nextLessonTitle;
    
    return Card(
      elevation: 8,
      shadowColor: primaryColor.withAlpha(102),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: allComplete 
                ? [Colors.green.shade600, Colors.green.shade400]
                : [primaryColor, primaryColor.withAlpha(204)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [            
            Text(
              allComplete ? "🏆 All Complete!" : "🌊 Next Lesson",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onNavigateToLessons,
                icon: Icon(widget.nextLessonIcon, size: 28),
                label: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.white,
                  foregroundColor: allComplete ? Colors.green.shade600 : primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 5,),
            Text(
              'Progress: $_completedCount out of $_totalCount lessons completed',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 5,),
            LinearProgressIndicator(
              value: _progressValue,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightGreenAccent),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}