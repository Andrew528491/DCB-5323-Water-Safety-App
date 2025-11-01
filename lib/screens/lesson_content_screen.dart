import 'package:flutter/material.dart';

// Displays content for safety lessons

class LessonContentScreen extends StatelessWidget {
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
      backgroundColor: const Color(0xFFF0F8FF), 
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack,
                    tooltip: 'Back to lessons',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lesson #$lessonNum',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 300), // Extra bottom padding for navigation bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  if (description.isNotEmpty)
                    _buildTextBlock(context, description),

                  // Firebase content
                  ...content.map((item) {
                    if (item is String) {
                      return _buildTextBlock(context, item);
                    } else if (item is Map<String, dynamic> && item["image"] != null) {
                      return _buildImageBlock(item["image"]);
                    } else {
                      return const SizedBox.shrink();
                    }
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Text block with rounded corners and better contrast
  Widget _buildTextBlock(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.6,
          fontSize: 16,
          color: Colors.black87,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  // Image block with rounded corners
  Widget _buildImageBlock(String imageName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Image.asset(
        "assets/images/$imageName",
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    'Image not found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}