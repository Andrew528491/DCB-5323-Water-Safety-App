import 'package:flutter/material.dart';

// Displays content for safety lessons

class LessonContentScreen extends StatelessWidget {
  //final int lessonId;
  final Map<String, dynamic> lesson;
  final VoidCallback onBack;

  const LessonContentScreen({
    super.key,
    required this.lesson,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final int lessonNum = lesson["lessonNumber"] ?? 0;
    final String title = lesson["title"] ?? "Untitled Lesson";
    final String description = lesson["description"] ?? "";
    final List<dynamic> content = lesson["content"] ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 8),

              //Title
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),

              //Description
              if (description.isNotEmpty)
                _buildTextBlock(context, description),

                //firebase content
                ...content.map((item) {
                  if (item is String) {
                    return _buildTextBlock(context, item);
                  } else if (item is Map<String, dynamic> && item["image"] != null) {
                    //for images in Firebase
                    return _buildImageBlock(item["image"]);
                  } else {
                    return const SizedBox.shrink();
                  }
              }).toList(),
            
              const SizedBox(height: 10),
            ],
          ),
        ),
      )
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