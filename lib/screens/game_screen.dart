import 'package:flutter/material.dart';
import '../games/riptide_escape_screen.dart';

// Displays the list of games that a user can select from to play

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  // Builds
  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    const Color shallowWater = Color(0xFF81D4FA); 
    const Color deepWater = Color(0xFF0D47A1); 
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [shallowWater, deepWater],
          ),
        ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videogame_asset,
                  size: 80,
                  color: primaryColor.withAlpha(178),
                ),
                const SizedBox(height: 24),
                Text(
                  'Water Safety Games',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Learn through play!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildGameCard(
                  context,
                  title: '🌊 Riptide Escape',
                  description: 'Learn how to escape a riptide by swimming parallel to shore!',
                  primaryColor: primaryColor,
                  onTap: () {

                    // HERE IS THE CALL FOR THE GAME
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RiptideEscapeScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color primaryColor,
    required VoidCallback? onTap,
    bool isLocked = false,
  }) {
    return Card(
      elevation: 8,
      shadowColor: primaryColor.withAlpha(100),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isLocked
                  ? [Colors.grey.shade300, Colors.grey.shade400]
                  : [primaryColor.withAlpha(25), primaryColor.withAlpha(13)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isLocked ? Colors.grey.shade600 : primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isLocked ? Colors.grey.shade600 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isLocked ? Icons.lock : Icons.play_circle_filled,
                size: 48,
                color: isLocked ? Colors.grey.shade500 : primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}