import 'package:flutter/material.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  // Placeholder text for the lesson modules
  final List<Map<String, String>> lessons = const [
    {'title': 'Module 1: Insert Text', 'subtitle': 'Insert sub text'},
    {'title': 'Module 2: Insert Text', 'subtitle': 'Insert sub text'},
    {'title': 'Module 3: Insert Text', 'subtitle': 'Insert sub text'},
    {'title': 'Module 4: Insert Text', 'subtitle': 'Insert sub text'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top title. Feel free to change, this might be temporary
      appBar: AppBar(
        title: const Text('Water Safety Lessons'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),

      // Lesson list. Pretty basic right now.
      body: ListView.builder(
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListTile(
              title: Text(lesson['title']!),
              subtitle: Text(lesson['subtitle']!),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Starting ${lesson['title']}...')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}