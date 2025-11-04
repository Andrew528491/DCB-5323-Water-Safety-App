import 'package:flutter/material.dart';

// This screen simulates a quiz and returns a result to the calling screen.
class QuizScreen extends StatelessWidget {
  final Map<String, dynamic> lesson;

  const QuizScreen({
    super.key,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${lesson["title"]}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Quiz content for this lesson will go here.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            // Placeholder button to simulate quiz completion
            ElevatedButton(
              onPressed: () {
                // Pop the screen and return 'true' as the result
                Navigator.of(context).pop(true); 
              },
              child: const Text('Simulate Quiz Completion'),
            ),
          ],
        ),
      ),
    );
  }
}