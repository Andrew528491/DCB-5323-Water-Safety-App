import 'package:flutter/material.dart';
import '../games/riptide_escape_screen.dart';

// Displays content for safety lessons

class LessonContentScreen extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final VoidCallback onBack;
  final VoidCallback onGamePlayed; 
  final bool gameCompleted;

  const LessonContentScreen({
    super.key,
    required this.lesson,
    required this.onBack,
    required this.onGamePlayed, 
    required this.gameCompleted,
  });

  // Launch game and mark lesson as completed when returning
  Future<void> _launchGameAndNotify(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RiptideEscapeScreen(),
      ),
    );
    if (context.mounted) {
      onGamePlayed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int lessonNum = lesson["lessonNumber"] ?? 0;
    final String title = lesson["title"] ?? "Untitled Lesson";
    final String description = lesson["description"] ?? "";
    final List<dynamic> content = lesson["content"] ?? [];
    // isCompleted is used for displaying the button status
    final bool isCompleted = lesson["isCompleted"] ?? false; 
    final String imageURL = lesson["imageURL"] ?? ""; 

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
                    color: Colors.black.withValues(alpha: 0.1), 
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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 200),
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
                  
                  if (imageURL.isNotEmpty) _buildImageBlock(imageURL),

                  // Description
                  if (description.isNotEmpty) _buildTextBlock(context, description),

                  // Firebase content
                  ...content.map((item) {
                    if (item is String) {
                      return _buildTextBlock(context, item);
                    }
                    return const SizedBox.shrink();
                  }).toList(),

                  // Complete lesson button at bottom of content
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isCompleted ? null : (gameCompleted ? null : () => _launchGameAndNotify(context)),
                      icon: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : (gameCompleted ? Icons.check_circle_outline : Icons.videogame_asset),
                        size: 24,
                      ),
                      label: Text(
                        isCompleted 
                          ? 'Lesson Completed!' 
                          : (gameCompleted ? 'Game Played! Return to List for Quiz' : 'Play Game to Unlock Quiz'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isCompleted
                            ? Colors.green.shade400
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isCompleted ? Colors.green.shade400 : Colors.grey.shade400,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Text block
  Widget _buildTextBlock(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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

  // Image block
  Widget _buildImageBlock(String imageSource) {
    final bool isUrl = imageSource.startsWith('http://') || imageSource.startsWith('https://');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: isUrl
          ? Image.network(
              imageSource,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
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
                          'Failed to load image',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Image.asset(
              "assets/images/$imageSource",
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