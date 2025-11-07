import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import './cpr_game.dart';
import 'cpr_overlays.dart';

// Initializes the game and handles exiting

class CprScreen extends StatefulWidget {
  const CprScreen({super.key});

  @override
  State<CprScreen> createState() => _CprScreenState();
}

class _CprScreenState extends State<CprScreen> {
  late CprGame game;

  @override
  void initState() {
    super.initState();
    game = CprGame(
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
          CprGame.scoreUIKey: (context, game) {
            final CprGame cprGame = game as CprGame;
            return StreamBuilder(
              stream: Stream.periodic(const Duration(milliseconds: 100)),
              builder: (context, snapshot) {
                return ScoreUIOverlay(game: cprGame);
              },
            );
          },
          CprGame.howToPlayKey: (context, game) {
            final CprGame cprGame = game as CprGame;
            return HowToPlayOverlay(game: cprGame);
          },
          CprGame.gameOverKey: (context, game) {
            final CprGame cprGame = game as CprGame;
            return GameOverOverlay(
              game: cprGame,
              finalScore: cprGame.score,
            );
          },
        },
      ),
    );
  }
}