import 'package:flutter/material.dart';

class LessonContentScreen extends StatelessWidget {
  final int lessonId;
  final VoidCallback onBack;

  const LessonContentScreen({
    super.key,
    required this.lessonId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    int lessonNum = lessonId + 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            //top bar
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lesson #$lessonNum',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            _buildTextBlock(context, "Here is some sample text. In the full version, this will be pulled from firebase. In fact, the entire block will probably be pulled from firebase. But for now, here's an example of what the text looks like."),
            _buildImageBlock("exploding-cat.gif"),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  //text block with rounded corners
  Widget _buildTextBlock(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 220, 220, 220).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        textAlign: TextAlign.left,
      ),
    );
  }

  //image block with rounded corners
  Widget _buildImageBlock(String imageName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Image.asset("assets/images/$imageName", fit: BoxFit.cover),
    );
  }
}