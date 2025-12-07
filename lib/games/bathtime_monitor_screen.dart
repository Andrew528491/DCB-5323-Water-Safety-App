import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'bathtime_monitor_game.dart';
import 'bathtime_monitor_overlays.dart';

// Initializes the game and handles exiting

class BathtimeMonitorScreen extends StatefulWidget {
  const BathtimeMonitorScreen({super.key});

  @override
  State<BathtimeMonitorScreen> createState() => _BathtimeMonitorScreenState();
}

class _BathtimeMonitorScreenState extends State<BathtimeMonitorScreen> {
  late BathtimeMonitorGame game;

  @override
  void initState() {
    super.initState();
    game = BathtimeMonitorGame(
      onExit: () {
        // Exit the game and return to previous screen
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: game,
        overlayBuilderMap: {
          BathtimeMonitorGame.scoreUIKey: (context, game) {
            final BathtimeMonitorGame bathtimeGame = game as BathtimeMonitorGame;
            return StreamBuilder(
              stream: Stream.periodic(const Duration(milliseconds: 100)),
              builder: (context, snapshot) {
                return ScoreUIOverlay(game: bathtimeGame);
              },
            );
          },
          BathtimeMonitorGame.howToPlayKey: (context, game) {
            final BathtimeMonitorGame bathtimeGame = game as BathtimeMonitorGame;
            return HowToPlayOverlay(game: bathtimeGame);
          },
          BathtimeMonitorGame.roundCompleteKey: (context, game) {
            final BathtimeMonitorGame bathtimeGame = game as BathtimeMonitorGame;
            
            return RoundCompleteOverlay(
              game: bathtimeGame,
              round: bathtimeGame.round,
              totalBonus: bathtimeGame.lastRoundBonus,
              roundBonus: bathtimeGame.lastRoundBonus,
            );
          },
          BathtimeMonitorGame.gameOverKey: (context, game) {
            final BathtimeMonitorGame bathtimeGame = game as BathtimeMonitorGame;
            return GameOverOverlay(
              game: bathtimeGame,
              finalScore: bathtimeGame.score,
              finalRound: bathtimeGame.round,
            );
          },
        },
      ),
    );
  }
}