// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:water_safety_app/widgets/homescreen_header_clipper.dart';
import 'lessons_screen.dart';
import 'dart:math';
// ADDED: Firebase imports for database access and authentication
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 

class HomeScreen extends StatefulWidget {
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
  
  // MODIFIED: Changed to a mutable, nullable String to hold the fetched username
  String? _userName;
  
  final String? _lessonInProgressId = "lesson_1"; 
  
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

  int get _completedCount => LessonsScreen.lessons.where((l) => l["isCompleted"] == true).length;
  int get _totalCount => LessonsScreen.lessons.length;
  double get _progressValue => _totalCount > 0 ? _completedCount / _totalCount : 0;

  late AnimationController _waveController;
  late Animation<double> _waveAnimation; 

  @override
  void initState() {
    super.initState();
    // ADDED: Load username from database as soon as the screen initializes
    _loadUsername(); 
    
    _dailyMessage = _selectDailyMessage();
    _contextualTitleSubText = _selectContextualTitleSubText();

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

  Future<void> _loadUsername() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; 

      String fetchedName = user.displayName ?? 'User';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        fetchedName = data['username'] ?? user.displayName ?? 'Parent';
      }
      _userName = fetchedName; 
  }


  String _selectDailyMessage() {
    final random = Random();
    return _dailyMessages[random.nextInt(_dailyMessages.length)];
  }

  String _selectContextualTitleSubText() {
    if (_lessonInProgressId != null) {
      return "${widget.nextLessonTitle} is next up. Click below to continue your learning!";
    }
    else { 
      return "Navigate to lessons or press the start lesson button to begin your learning!";
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLessonInProgress = _lessonInProgressId != null;
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

                  if (isLessonInProgress)
                    _buildContinueLessonCard(context, primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWavyHeader(BuildContext context, Color primaryColor, double wavePhase) {
    // MODIFIED: Safely use _userName with a fallback if it's still null while loading
    final String displayName = _userName ?? 'Parent'; 
    
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

  Widget _buildContinueLessonCard(BuildContext context, Color primaryColor) {
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
            colors: [primaryColor, primaryColor.withAlpha(204)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [            
            const Text(
              "🌊 Next Lesson",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  widget.onNavigateToLessons();
                },
                icon: Icon(widget.nextLessonIcon, size: 28),
                label: Text(
                  widget.nextLessonTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
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