import 'package:flutter/material.dart';

class ScoreUIOverlay extends StatelessWidget {
  final dynamic game;
  const ScoreUIOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    
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
              _buildStatItem('${game.bonusTimer.toStringAsFixed(1)}s', 'Time',
                  game.bonusTimer <= 3.0 ? Colors.red.shade600 : Colors.cyan.shade700),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatItem('${game.round}', 'Round', primaryColor.withAlpha(200)),
            ],
          ),
        ),
      ),
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
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
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
              Text('RIPTIDE ESCAPE',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor)),
              const Divider(height: 20, thickness: 2),
              const SizedBox(height: 10),
              _buildInstruction('Goal', 'Swim to shore before time runs out!', Colors.green.shade700),
              const SizedBox(height: 15),
              _buildInstruction('Danger', 'Riptides push you backward - avoid them!', Colors.red.shade700),
              const SizedBox(height: 15),
              _buildInstruction( 'Controls', 'Swipe LEFT/RIGHT to change lanes\nSwipe UP to burst forward. But be careful, bursting forward in a riptide will push you further backwards',
                  primaryColor.withAlpha(200)),
              const SizedBox(height: 15),
              _buildInstruction('Scoring', 'Beat the timer for bonus points!\nEach round gets harder and faster',
                  Colors.orange.shade700),
              const SizedBox(height: 20),
              const Divider(height: 20, thickness: 1.5),
              Text('SAFETY TIP:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryColor.withAlpha(200))),
              const Text('In real life, swim parallel to shore to escape a riptide!',
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
                  child: const Text('Start Swimming!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
  final int timeBonus;
  final int roundBonus;

  const RoundCompleteOverlay({
    super.key,
    required this.game,
    required this.round,
    required this.totalBonus,
    required this.timeBonus,
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
              Text('🌊 SHORE REACHED!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor)),
              const Divider(height: 20, thickness: 2),
              _buildBonusRow('Round Score', '+$roundBonus', primaryColor.withAlpha(200)),
              _buildBonusRow('Time Bonus', '+$timeBonus', Colors.yellow.shade700),
              const Divider(height: 20, thickness: 1.5),
              _buildBonusRow('Total Bonus', '+$totalBonus', Colors.green.shade600, isTotal: true),
              const SizedBox(height: 20),
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

  Widget _buildBonusRow(String title, String value, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87)),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 20 : 16, fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final dynamic game;
  final double finalScore;
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
                const Text('PUSHED OUT TO SEA!',
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
                const Text('Always swim parallel to the shore to get out of a riptide, then swim back in!',
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