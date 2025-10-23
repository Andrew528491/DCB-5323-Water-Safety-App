import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'riptide_escape_game.dart';
import 'riptide_escape_overlays.dart';

// Initializes the game and handles exiting

class RiptideEscapeScreen extends StatefulWidget {
  const RiptideEscapeScreen({super.key});

  @override
  State<RiptideEscapeScreen> createState() => _RiptideEscapeScreenState();
}

class _RiptideEscapeScreenState extends State<RiptideEscapeScreen> {
  late RiptideEscapeGame game;

  @override
  void initState() {
    super.initState();
    game = RiptideEscapeGame(
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
          RiptideEscapeGame.scoreUIKey: (context, game) {
            final RiptideEscapeGame riptideGame = game as RiptideEscapeGame;
            return StreamBuilder(
              stream: Stream.periodic(const Duration(milliseconds: 100)),
              builder: (context, snapshot) {
                return ScoreUIOverlay(game: riptideGame);
              },
            );
          },
          RiptideEscapeGame.howToPlayKey: (context, game) {
            final RiptideEscapeGame riptideGame = game as RiptideEscapeGame;
            return HowToPlayOverlay(game: riptideGame);
          },
          RiptideEscapeGame.roundCompleteKey: (context, game) {
            final RiptideEscapeGame riptideGame = game as RiptideEscapeGame;
            
            return RoundCompleteOverlay(
              game: riptideGame,
              round: riptideGame.round,
              totalBonus: riptideGame.lastRoundBonus + riptideGame.lastTimeBonus,
              timeBonus: riptideGame.lastTimeBonus,
              roundBonus: riptideGame.lastRoundBonus,
            );
          },
          RiptideEscapeGame.gameOverKey: (context, game) {
            final RiptideEscapeGame riptideGame = game as RiptideEscapeGame;
            return GameOverOverlay(
              game: riptideGame,
              finalScore: riptideGame.score,
              finalRound: riptideGame.round,
            );
          },
        },
      ),
    );
  }
}