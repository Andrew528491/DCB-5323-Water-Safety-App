import 'package:flutter/material.dart';
import 'lesson_content_screen.dart';
import 'package:water_safety_app/widgets/water_transition_wrapper.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  int _selectedLessonIndex = 0;
  Key _contentKey = const ValueKey(0);

  final List<String> lessonTitles = ["Lesson 1", "Lesson 2", "Lesson 3"];

  void _openLesson(int index) {
    setState(() {
      _selectedLessonIndex = index;
      _contentKey = const ValueKey(1);
    });
  }

  void _goBack() {
    setState(() {
      _contentKey = const ValueKey(0);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: WaterTransitionWrapper(
        contentKey: _contentKey,
        onTransitionComplete: () {}, // optional
        child: (_contentKey == const ValueKey(0))
            ? _buildLessonList()
            : LessonContentScreen(
                lessonId: _selectedLessonIndex,
                onBack: _goBack,
              ),
      ),
    );
  }

    Widget _buildLessonList() {
    return ListView.builder(
      itemCount: lessonTitles.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(lessonTitles[index]),
          onTap: () => _openLesson(index),
        );
      },
    );
  }
}