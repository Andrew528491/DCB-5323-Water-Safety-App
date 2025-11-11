import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Logic for the Cpr game

class CprGame extends FlameGame with PanDetector {
  final VoidCallback? onExit;

  static const String roundCompleteKey = 'RoundComplete';
  static const String gameOverKey = 'GameOver';
  static const String howToPlayKey = 'HowToPlay';
  static const String scoreUIKey = 'ScoreUI';
  
  // Game variables

  int score = 0; // Starting score
  int round = 1; // Starting round
  int lives = 3; // Bonus timer length
  double cprSpawnTimer = 0; // Incremented to spawn cprs
  double cprSpawnInterval = 1.8; // Interval cprs are spawned
  double cprSpeed = 100; // Base speed cprs move down screen
  late PlayArea playArea;

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

    playArea = PlayArea();
    
    add(Background());
    add(playArea);
    add(Guide());
    add(InnerGuide());
    add(Person());
    
    
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

  void endGame() async {
    gameOver = true;
    overlays.add(gameOverKey);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userRef.get();
      final currentHighScore = doc.data()?['cprHighScore'] ?? -1;

      if (score > currentHighScore) {
        await userRef.update({'cprHighScore': score.toInt()});
      }
    }
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
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromARGB(255, 100, 100, 100),
          Color.fromARGB(255, 51, 51, 51), 
        ],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, game.size.x, game.size.y));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      paint,
    );

    final paintLine = Paint()..color = Color.fromARGB(207, 206, 206, 206);

    for (int i = 0; i < 10; i++) {
      canvas.drawRect(Rect.fromLTWH(0, game.size.y / 10 * i, game.size.x, game.size.y / 100), paintLine);

      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(game.size.x / 10 * i + 20, 0, game.size.y / 100, game.size.y), paintLine);
      }
      
    }
  }
}

//Cpr patient
class PlayArea extends SpriteAnimationComponent with HasGameReference<CprGame>, TapCallbacks {
  bool tapped = false;

  @override
  Future<void> onLoad() async {
    size = Vector2(300, 200);
    position = Vector2((game.size.x - size.x) / 2, (game.size.y - size.y) / 1.3);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
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

  @override
  void onTapDown(TapDownEvent event) {
      tapped = true;
    }

  @override
  void update(double dt) {
    super.update(dt);
    
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

  Vector2 initSize = Vector2(300, 200);
  late Vector2 fullSize = initSize;
  late Paint paint = Paint()..color = Color.fromARGB(255, 41, 246, 99);
  late double transparency;

  @override
  Future<void> onLoad() async {
    size = initSize;
    position = game.playArea.position + (game.playArea.size - size) / 2;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
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

  @override
  void update(double dt) {
    super.update(dt);
    double t = 1.0 - (game.timer / game.timerRange);

    // size shrinks from fullSize to 0
    size = fullSize * t;

    //keep centered on play area as size shrinks
    position = game.playArea.position + (game.playArea.size - size) / 2;

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

    @override
    void onLoad() {
      size = Vector2(38, 18);
      position = game.playArea.position + (game.playArea.size - size) / 2;
      transparency = 255;
    }

    @override
    void render(Canvas canvas) {
      super.render(canvas);
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

    @override
    void update(double dt) {
      super.update(dt);

      if(game.score < 15) {
      transparency = 255 - 255 * (game.score / 15);
    } else {
      transparency = 0;
    }
    int transparencyInt = transparency.toInt();
    paint = Paint()..color = new Color.fromARGB(transparencyInt, 255, 0, 0);
    }
  }

  class Person extends SpriteComponent with HasGameReference<CprGame> {

    @override
    Future<void> onLoad() async {
      sprite = await game.loadSprite('cprpatient.png');
      size = Vector2(600, 900);
      position = Vector2(((game.size.x - size.x) / 2), 40);
      return super.onLoad();
    }

    @override
    void render(Canvas canvas) {
      super.render(canvas);

      priority = 0;
    }

  }