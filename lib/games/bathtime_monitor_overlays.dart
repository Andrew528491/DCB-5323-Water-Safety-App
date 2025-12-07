import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreUIOverlay extends StatelessWidget {
  final dynamic game;
  const ScoreUIOverlay({super.key, required this.game});

  Future<int> _getHighScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data()?['bathtimeHighScore'] ?? -1;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    String livesString = '';
    int currentLives = game.lives; 
    while (currentLives > 0) {
      livesString = '$livesString❤️';
      currentLives--;
    }

    return FutureBuilder<int>(
      future: _getHighScore(),
      builder: (context, snapshot) {
        final highScore = snapshot.data ?? -1;
        return Positioned(
          top: 15,
          left: 15,
          right: 15,
          child: Card(
            elevation: 8,
            shadowColor: primaryColor.withAlpha(100),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                border: Border.all(color: primaryColor.withAlpha(51), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('${game.score}', 'Score', Colors.amber.shade700),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _buildStatItem(livesString, 'Lives', Colors.red.shade600),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _buildStatItem('${game.roundTimer.toStringAsFixed(1)}s', 'Time',
                      game.roundTimer <= 5.0 ? Colors.red.shade600 : Colors.cyan.shade700),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _buildStatItem(highScore == -1 ? '—' : '$highScore', 'High Score', Colors.green.shade700),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 6),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class HowToPlayOverlay extends StatelessWidget {
  final dynamic game;
  const HowToPlayOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Card(
        elevation: 15,
        shadowColor: primaryColor.withAlpha(150),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: primaryColor.withAlpha(76), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🛁 BATHTIME MONITOR',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor)),
              const Divider(height: 20, thickness: 2),
              const SizedBox(height: 10),
              _buildInstruction('Goal', 'Keep your attention on the child', Colors.green.shade700),
              const SizedBox(height: 15),
              _buildInstruction('Find the Hazards', 'Eyes will spawn on screen along with various distractions. Click on the eyes to keep your attention on the child while avoiding the distractions', Colors.red.shade700),
              const SizedBox(height: 15),
              _buildInstruction('Visual Scanning', 'If the attention bar reaches 0 or you click a distraction, you will lose a heart. Lose all 3 and the game is over',
                  Colors.orange.shade700),
              const SizedBox(height: 15),
              _buildInstruction('Progression', 'When you click all of the attention icons, the set disappears and a new one spawns instantly. Higher rounds have MORE items per set and LESS time to react!',
                  primaryColor.withAlpha(200)),
              const SizedBox(height: 20),
              const Divider(height: 20, thickness: 1.5),
              Text('SAFETY TIP:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryColor.withAlpha(200))),
              const Text('Never leave a child unattended and give them your full attention in the bath. Drowning or other accidents can happen silently in seconds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, height: 1.3, color: Colors.black87)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => game.dismissHowToPlay(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Start Watching!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

class RoundCompleteOverlay extends StatelessWidget {
  final dynamic game;
  final int round;
  final int totalBonus;
  final int roundBonus;

  const RoundCompleteOverlay({
    super.key,
    required this.game,
    required this.round,
    required this.totalBonus,
    required this.roundBonus,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Card(
        elevation: 15,
        shadowColor: primaryColor.withAlpha(150),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: primaryColor.withAlpha(76), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('👶 BABY SAFE!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor)),
              _buildBonusRow('Round Bonus', '+$roundBonus', Colors.green.shade600),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => game.dismissRoundComplete(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Continue to Round $round',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBonusRow(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final dynamic game;
  final int finalScore;
  final int finalRound;

  const GameOverOverlay({
    super.key,
    required this.game,
    required this.finalScore,
    required this.finalRound,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      color: Colors.black.withAlpha(204),
      child: Center(
        child: Card(
          elevation: 20,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.red.shade700.withAlpha(102), width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('LIVES LOST!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.red)),
                const Divider(height: 25, thickness: 2, color: Colors.red),
                Text('Final Score: $finalScore',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('Reached Round: $finalRound', style: const TextStyle(fontSize: 18, color: Colors.black54)),
                const SizedBox(height: 30),
                Text('SAFETY LESSON:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primaryColor.withAlpha(200))),
                const Text('Bath time requires constant supervision. Even small hazards can become dangerous in seconds!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, height: 1.4, color: Colors.black87)),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => game.exitGame(),
                        icon: const Icon(Icons.exit_to_app, size: 24),
                        label: const Text('Exit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.grey.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => game.restartGame(),
                        icon: const Icon(Icons.refresh, size: 24),
                        label: const Text('Retry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}