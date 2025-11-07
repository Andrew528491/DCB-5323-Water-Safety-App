import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'dart:math';

// Logic for the Cpr  game

class CprGame extends FlameGame with PanDetector {
  final VoidCallback? onExit;

  static const String roundCompleteKey = 'RoundComplete';
  static const String gameOverKey = 'GameOver';
  static const String howToPlayKey = 'HowToPlay';
  static const String scoreUIKey = 'ScoreUI';
  
  // Game variables

  double score = 0; // Starting score
  int round = 1; // Starting round
  int lives = 3; // Bonus timer length
  double cprSpawnTimer = 0; // Incremented to spawn cprs
  double cprSpawnInterval = 1.8; // Interval cprs are spawned
  double cprSpeed = 100; // Base speed cprs move down screen

  // Timer Variables
  double timer = 0.0;
  double timerRange = 0.6;

  // Bools for game, overlay management

  bool gameOver = false;
  bool gameStarted = false; 
  bool showingRoundComplete = false;
  bool showingHowToPlay = true;
  
  int lastTimeBonus = 0;
  int lastRoundBonus = 0;


  CprGame({this.onExit});

  // Game setup

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    add(Background());
    add(Person());
    add(Guide());
    add(InnerGuide());
    
    
    gameStarted = false;
    overlays.add(howToPlayKey);
    overlays.add(scoreUIKey);
  }

  // Game management for each frame

  @override
  void update(double dt) {
    super.update(dt);
    
    if (gameOver || showingRoundComplete || showingHowToPlay) return;
    
    timer += dt;
    if (timer > timerRange) {
      if (score > 0) {
          lives--;
        }
        timer = 0;
    }

    if (lives == 0) {
      endGame();
    }
  }

  // Ends the game and displays the game over overlay

  void endGame() {
    gameOver = true;
    overlays.add(gameOverKey);
  }

  // Methods to remove overlays

  void dismissRoundComplete() {
    showingRoundComplete = false;
    overlays.remove(roundCompleteKey);
    gameStarted = true; 
  }
  
  void dismissHowToPlay() {
    showingHowToPlay = false;
    overlays.remove(howToPlayKey);
    gameStarted = true;
  }

  // Handles the game restart

  void restartGame() {
    score = 0;
    round = 1;
    lives = 3;
    gameOver = false;
    gameStarted = false;
    showingRoundComplete = false;
    showingHowToPlay = true;
  
    
    overlays.remove(gameOverKey);
    overlays.add(howToPlayKey);
  }

  // Handles exiting the game
  
  void exitGame() {
    if (onExit != null) {
      onExit!();
    }
  }

  // Methods for controls

  Vector2? panStart;
  Vector2? panEnd;
    
  @override
  void onPanStart(DragStartInfo info) {
    panStart = info.eventPosition.global;
    panEnd = null;
  }
    
  @override
  void onPanUpdate(DragUpdateInfo info) {
    panEnd = info.eventPosition.global;
  }
    
  @override
  void onPanEnd(DragEndInfo info) {
    if (gameOver) {
      restartGame();
      return;
    }
    
    if (showingHowToPlay) {
      dismissHowToPlay();
      return;
    }
    
    if (showingRoundComplete) {
      dismissRoundComplete();
      return;
    }
    
    if (panStart == null || panEnd == null) return;
    
    
    panStart = null;
    panEnd = null;
  }

}

// Ocean background
class Background extends Component with HasGameReference<CprGame> {
  double animationTime = 0;
  
  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameStarted) {
      animationTime += dt * 0.5;
    }
  }
  
  @override
  void render(Canvas canvas) {
    // Main ocean gradient
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromARGB(255, 100, 100, 100),
          Color.fromARGB(255, 109, 109, 109), 
        ],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, game.size.x, game.size.y));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      paint,
    );
  }
}

//Cpr patient
class Person extends SpriteAnimationComponent with HasGameReference<CprGame>, TapCallbacks {
  bool tapped = false;

  Future<void> onLoad() async {
    size = Vector2(400, 300);
    position = (game.size - size) / 2;
  }

  void render(Canvas canvas) {
    priority = 1;
    

    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.x, size.y),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20)
    );

    canvas.drawRRect(rrect, paint);
  }

  void onTapDown(TapDownEvent event) {
      tapped = true;
    }

  void update(double dt) {
    if (tapped) {
      if (game.timer > .5) {
        game.score++;
        game.timer = 0;
        
      } else if (game.timer > 0.15) {
        if (game.score > 0) {
          game.lives--;
        }
        game.timer = 0;
      }
      tapped = false;
    }
  }
}

class Guide extends SpriteAnimationComponent with HasGameReference<CprGame> {

  Vector2 initSize = Vector2(400, 300);
  late Vector2 fullSize = initSize;
  late Paint paint = Paint()..color = new Color.fromARGB(255, 41, 246, 99);
  late double transparency;
  Future<void> onLoad() async {
    size = initSize;
    position = (game.size - size) / 2;
  }
  void render(Canvas canvas) {
    priority = 1;
    

    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.x, size.y),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20)
    );

    canvas.drawRRect(rrect, paint);
  }

  void update(double dt) {
    double t = 1.0 - (game.timer / game.timerRange);

    // size shrinks from fullSize to 0
    size = fullSize * t;

    // Re-center as size changes
    position = (game.size - size) / 2;

    if(game.score < 15) {
      transparency = 255 - 255 * (game.score / 15);
    } else {
      transparency = 0;
    }
    int transparencyInt = transparency.toInt();
    paint = Paint()..color = new Color.fromARGB(transparencyInt, 41, 246, 99);
  }

  
}

class InnerGuide extends SpriteAnimationComponent with HasGameReference<CprGame> {
  late double transparency;
    void onLoad() {
      size = Vector2(50, 25);
      position = (game.size - size) / 2;
      transparency = 255;
    }

    void render(Canvas canvas) {
      priority = 2;

      final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.x, size.y),
      bottomLeft: Radius.circular(5),
      bottomRight: Radius.circular(5),
      topLeft: Radius.circular(5),
      topRight: Radius.circular(5)
    );

    canvas.drawRRect(rrect, paint);
    }

    void update(double dt) {
      if(game.score < 15) {
      transparency = 255 - 255 * (game.score / 15);
    } else {
      transparency = 0;
    }
    int transparencyInt = transparency.toInt();
    paint = Paint()..color = new Color.fromARGB(transparencyInt, 255, 0, 0);
    }
  }