import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Service to manage badge earning, tracking, and notifications

class Badge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final BadgeCategory category;
  final Function(Map<String, dynamic> userData) checkCondition;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.checkCondition,
  });
}

enum BadgeCategory {
  lessons,
  games,
  mastery,
  special,
}

class BadgeService {
  BadgeService._();
  static final BadgeService instance = BadgeService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Available badges
  static final List<Badge> allBadges = [
    // Lesson Completion Badges
    Badge(
      id: 'first_lesson',
      title: 'First Steps',
      description: 'Complete your first lesson',
      icon: Icons.school,
      color: Colors.blue,
      category: BadgeCategory.lessons,
      checkCondition: (userData) {
        return _countCompletedLessons(userData) >= 1;
      },
    ),
    Badge(
      id: 'three_lessons',
      title: 'Making Progress',
      description: 'Complete 3 lessons',
      icon: Icons.trending_up,
      color: Colors.green,
      category: BadgeCategory.lessons,
      checkCondition: (userData) {
        return _countCompletedLessons(userData) >= 3;
      },
    ),
    Badge(
      id: 'all_lessons',
      title: 'Water Safety Expert',
      description: 'Complete all 6 lessons',
      icon: Icons.emoji_events,
      color: Colors.amber,
      category: BadgeCategory.lessons,
      checkCondition: (userData) {
        return _countCompletedLessons(userData) >= 6;
      },
    ),
    
    // Quiz Performance Badges
    Badge(
      id: 'perfect_quiz',
      title: 'Perfect Score',
      description: 'Get 100% on any quiz',
      icon: Icons.stars,
      color: Colors.purple,
      category: BadgeCategory.mastery,
      checkCondition: (userData) {
        return _hasAnyPerfectQuiz(userData);
      },
    ),
    Badge(
      id: 'quiz_master',
      title: 'Quiz Master',
      description: 'Score 100% on 3 quizzes',
      icon: Icons.military_tech,
      color: Colors.indigo,
      category: BadgeCategory.mastery,
      checkCondition: (userData) {
        return _countHighScoreQuizzes(userData, 90) >= 3;
      },
    ),
    
    // Game Achievement Badges
    Badge(
      id: 'riptide_novice',
      title: 'Riptide Survivor',
      description: 'Score 50+ in Riptide Escape',
      icon: Icons.waves,
      color: Colors.cyan,
      category: BadgeCategory.games,
      checkCondition: (userData) {
        final score = userData['riptideHighScore'] ?? -1;
        return score >= 50;
      },
    ),
    Badge(
      id: 'riptide_expert',
      title: 'Riptide Master',
      description: 'Score 100+ in Riptide Escape',
      icon: Icons.pool,
      color: Colors.blue.shade700,
      category: BadgeCategory.games,
      checkCondition: (userData) {
        final score = userData['riptideHighScore'] ?? -1;
        return score >= 100;
      },
    ),
    Badge(
      id: 'cpr_hero',
      title: 'CPR Hero',
      description: 'Score 50+ in Poolside CPR',
      icon: Icons.favorite,
      color: Colors.red,
      category: BadgeCategory.games,
      checkCondition: (userData) {
        final score = userData['cprHighScore'] ?? -1;
        return score >= 50;
      },
    ),
    
    // Special Badges

    Badge(
      id: 'dedicated_learner',
      title: 'Dedicated Learner',
      description: 'Complete 10 quizzes total',
      icon: Icons.auto_stories,
      color: Colors.teal,
      category: BadgeCategory.special,
      checkCondition: (userData) {
        return _countTotalQuizCompletions(userData) >= 10;
      },
    ),
  ];

  // Helper methods for badge conditions
  static int _countCompletedLessons(Map<String, dynamic> userData) {
    int count = 0;
    for (int i = 1; i <= 6; i++) {
      final lessonKey = i.toString();
      if (userData.containsKey('lesson_$lessonKey')) {
        final lessonData = userData['lesson_$lessonKey'] as Map<String, dynamic>?;
        if (lessonData?['completion'] == true) {
          count++;
        }
      }
    }
    return count;
  }

  static bool _hasAnyPerfectQuiz(Map<String, dynamic> userData) {
    for (int i = 1; i <= 6; i++) {
      final lessonKey = i.toString();
      if (userData.containsKey('lesson_$lessonKey')) {
        final lessonData = userData['lesson_$lessonKey'] as Map<String, dynamic>?;
        final quizScore = lessonData?['quizScore'] ?? -1;
        if (quizScore == 100) return true;
      }
    }
    return false;
  }

  static int _countHighScoreQuizzes(Map<String, dynamic> userData, int threshold) {
    int count = 0;
    for (int i = 1; i <= 6; i++) {
      final lessonKey = i.toString();
      if (userData.containsKey('lesson_$lessonKey')) {
        final lessonData = userData['lesson_$lessonKey'] as Map<String, dynamic>?;
        final quizScore = lessonData?['quizScore'] ?? -1;
        if (quizScore >= threshold) {
          count++;
        }
      }
    }
    return count;
  }

  static int _countTotalQuizCompletions(Map<String, dynamic> userData) {
    int total = 0;
    for (int i = 1; i <= 6; i++) {
      final lessonKey = i.toString();
      if (userData.containsKey('lesson_$lessonKey')) {
        final lessonData = userData['lesson_$lessonKey'] as Map<String, dynamic>?;
        final completions = lessonData?['quizCompletions'] ?? 0;
        total += completions is int ? completions : 0;
      }
    }
    return total;
  }

  // Stream user's badges in real-time
  Stream<List<String>> getUserBadgesStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data()!;
      final badges = data['badges'] as List<dynamic>?;
      return badges?.cast<String>() ?? [];
    });
  }

  // Fetch user's earned badges
  Future<List<String>> getUserBadges() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return [];

    final data = doc.data()!;
    final badges = data['badges'] as List<dynamic>?;
    return badges?.cast<String>() ?? [];
  }

  // Check and award new badges
  Future<List<Badge>> checkAndAwardBadges(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    // Fetch user document and lesson tracker
    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return [];

    final userData = userDoc.data()!;
    final currentBadges = (userData['badges'] as List<dynamic>?)?.cast<String>() ?? [];

    // Fetch all lesson progress
    final lessonTrackerSnapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('lessonTracker')
        .get();

    // Merge lesson data into userData for condition checking
    for (var doc in lessonTrackerSnapshot.docs) {
      userData['lesson_${doc.id}'] = doc.data();
    }

    // Check each badge
    List<Badge> newlyEarnedBadges = [];
    for (var badge in allBadges) {
      if (!currentBadges.contains(badge.id) && badge.checkCondition(userData)) {
        newlyEarnedBadges.add(badge);
      }
    }

    // Award new badges
    if (newlyEarnedBadges.isNotEmpty) {
      final newBadgeIds = newlyEarnedBadges.map((b) => b.id).toList();
      await _db.collection('users').doc(user.uid).update({
        'badges': FieldValue.arrayUnion(newBadgeIds),
      });

      // Show notifications for each new badge
      if (context.mounted) {
        for (var badge in newlyEarnedBadges) {
          await _showBadgeNotification(context, badge);
        }
      }
    }

    return newlyEarnedBadges;
  }

  // Show badge earned notification
  Future<void> _showBadgeNotification(BuildContext context, Badge badge) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BadgeEarnedDialog(badge: badge),
    );
  }

  // Get badge by ID
  static Badge? getBadgeById(String id) {
    return allBadges.firstWhere((b) => b.id == id);
  }
}

// Badge earned notification dialog
class BadgeEarnedDialog extends StatefulWidget {
  final Badge badge;

  const BadgeEarnedDialog({super.key, required this.badge});

  @override
  State<BadgeEarnedDialog> createState() => _BadgeEarnedDialogState();
}

class _BadgeEarnedDialogState extends State<BadgeEarnedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.badge.color.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Badge Earned!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: widget.badge.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.badge.icon,
                    size: 80,
                    color: widget.badge.color,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.badge.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: widget.badge.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.badge.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.badge.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}