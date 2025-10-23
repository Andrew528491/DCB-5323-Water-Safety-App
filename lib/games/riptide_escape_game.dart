import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:math';

// Logic for the Riptide Escape game

class RiptideEscapeGame extends FlameGame with PanDetector {
  late Player player;
  final VoidCallback? onExit;

  static const String roundCompleteKey = 'RoundComplete';
  static const String gameOverKey = 'GameOver';
  static const String howToPlayKey = 'HowToPlay';
  static const String scoreUIKey = 'ScoreUI';
  
  // Game variables

  int score = 0; // Starting score
  int round = 1; // Starting round
  double bonusTimer = 10; // Bonus timer length
  double riptideSpawnTimer = 0; // Incremented to spawn riptides
  double riptideSpawnInterval = 1.8; // Interval riptides are spawned
  double riptideSpeed = 100; // Base speed riptides move down screen

  // Bools for game, overlay management

  bool gameOver = false;
  bool gameStarted = false; 
  bool showingRoundComplete = false;
  bool showingHowToPlay = true;
  
  int lastTimeBonus = 0;
  int lastRoundBonus = 0;
    
  final List<Riptide> riptides = [];
  final double laneWidth = 120;
  final int numLanes = 3;

  RiptideEscapeGame({this.onExit});

  // Game setup

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    add(OceanBackground());
    add(Shore());
    
    player = Player();
    add(player);
    
    gameStarted = false;
    overlays.add(howToPlayKey);
    overlays.add(scoreUIKey);
  }

  // Game management for each frame

  @override
  void update(double dt) {
    super.update(dt);
    
    if (gameOver || showingRoundComplete || showingHowToPlay) return;
    
    if (gameStarted){
      bonusTimer = max(bonusTimer - dt, 0);
    }
    
    riptides.removeWhere((r) => r.shouldRemove);
    
    riptideSpawnTimer += dt;

    if (riptideSpawnTimer >= riptideSpawnInterval) {
      riptideSpawnTimer = 0;
      spawnRiptide();
    }
    
    if (player.position.y <= 80) {
      reachedShore();
    }
    
    if (player.position.y >= size.y - 50) {
      endGame();
    }
  }

  // Logic to spawn riptides

  void spawnRiptide() {
    final random = Random();
    
    int lane;
    if (riptides.isNotEmpty) {
      final lastLane = riptides.last.lane;
      do {
        lane = random.nextInt(numLanes);
      } while (lane == lastLane);
    } else {
      lane = random.nextInt(numLanes);
    }
    
    final riptide = Riptide(lane: lane, speed: riptideSpeed);
    riptides.add(riptide);
    add(riptide);
  }

  // Handles when shore reached by player

  void reachedShore() {
    lastTimeBonus = bonusTimer.toInt() * 10;
    lastRoundBonus = 10 * round;
    
    score += lastRoundBonus + lastTimeBonus;
    
    round++;
    bonusTimer = 10; 
    riptideSpeed += 25; // Amount to increase speed of riptides by each round
    riptideSpawnInterval = max(0.3, riptideSpawnInterval - 0.10); // Amount to decrease the riptide spawn interval by each round
    
    for (final riptide in riptides) {
      riptide.removeFromParent();
    }
    riptides.clear();
    riptideSpawnTimer = 0;
    
    final resetX = getLaneCenter(1) - player.size.x / 2;
    player.position = Vector2(resetX, size.y - 100);
    player.currentLane = 1;
    
    showingRoundComplete = true;
    gameStarted = false;
    overlays.add(roundCompleteKey);
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
    bonusTimer = 10; 
    riptideSpeed = 100;
    riptideSpawnInterval = 1.8;
    gameOver = false;
    gameStarted = false;
    showingRoundComplete = false;
    showingHowToPlay = true;
    riptideSpawnTimer = 0;
    
    final resetX = getLaneCenter(1) - player.size.x / 2;
    player.position = Vector2(resetX, size.y - 100);
    player.currentLane = 1;
    
    for (final riptide in riptides) {
      riptide.removeFromParent();
    }
    riptides.clear();
    
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
    
    final delta = panEnd! - panStart!;
    final threshold = 30.0;
    
    if (gameStarted) {
      if (delta.x.abs() > delta.y.abs() && delta.x.abs() > threshold) {
        if (delta.x > 0) {
          player.moveRight();
        } else {
          player.moveLeft();
        }
      } else if (delta.y.abs() > threshold) {
        if (delta.y < 0) {
          player.speedBurst();
        }
      }
    }
    
    panStart = null;
    panEnd = null;
  }

  double getLaneCenter(int lane) {
    final startX = (size.x - (numLanes * laneWidth)) / 2;
    return startX + (lane * laneWidth) + (laneWidth / 2);
  }

  // Method to deterrmine if player is inside a riptide

  bool isPlayerInRiptide() {
    for (final riptide in riptides) {
      if (riptide.lane == player.currentLane && !riptide.shouldRemove) {
        final playerBottom = player.position.y + player.size.y;
        final playerTop = player.position.y;
        final riptideTop = riptide.position.y;
        final riptideBottom = riptide.position.y + riptide.size.y;
        
        if (playerBottom > riptideTop && playerTop < riptideBottom) {
          return true;
        }
      }
    }
    return false;
  }
}

// Ocean background
class OceanBackground extends Component with HasGameReference<RiptideEscapeGame> {
  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.shade300,
          Colors.blue.shade500,
          Colors.blue.shade700,
        ],
      ).createShader(Rect.fromLTWH(0, 0, game.size.x, game.size.y));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      paint,
    );
  }
}

// Shore at top
class Shore extends Component with HasGameReference<RiptideEscapeGame> {
  Sprite? shoreSprite;
  
  @override
  Future<void> onLoad() async {
    // TODO: Replace this with a better asset
    shoreSprite = await game.loadSprite('ShoreLine.png');
  }
  
  @override
  void render(Canvas canvas) {
    priority = 10;
    shoreSprite!.render(
      canvas,
      position: Vector2.zero(),
      size: Vector2(game.size.x, 80),
    );
  }
}

// Player class
class Player extends SpriteAnimationComponent with HasGameReference<RiptideEscapeGame> {
  int currentLane = 1;
  final double moveSpeed = 250; // Player horizontal move speed
  bool isMovingToLane = false;
  double targetX = 0;
    
  @override
  Future<void> onLoad() async {
    final sprites = [
      await game.loadSprite('swimmer_0.png'),
      await game.loadSprite('swimmer_1.png'),
      await game.loadSprite('swimmer_0.png'),
      await game.loadSprite('swimmer_2.png'),
    ];

    animation = SpriteAnimation.spriteList(
      sprites,
      stepTime: 0.15,
      loop: true,
    );

    size = Vector2(40, 40);
    final startX = game.getLaneCenter(1) - size.x / 2;
    position = Vector2(startX, game.size.y - 100);
    targetX = startX;
    
    playing = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Lane movement logic
    if (isMovingToLane) {
      final diff = targetX - position.x;
      if (diff.abs() < 5) {
        position.x = targetX;
        isMovingToLane = false;
      } else {
        position.x += diff.sign * moveSpeed * dt;
      }
    }
    
    if (game.gameStarted && !game.showingRoundComplete) {
      playing = true;
    } else {
      playing = false;
    }

    // Vertical movement logic
    if (game.gameStarted) {
      if (game.isPlayerInRiptide()) {
        position.y += 120 * dt; // Distance pushed back if in riptide
      } else {
        position.y -= 20 * dt; // Distance player moves forward automatically when not in riptide
      }
    }
    
    position.y = position.y.clamp(60, game.size.y - 50);
  }

  void moveLeft() {
    if (currentLane > 0) {
      currentLane--;
      targetX = game.getLaneCenter(currentLane) - size.x / 2;
      isMovingToLane = true;
    }
  }

  void moveRight() {
    if (currentLane < game.numLanes - 1) {
      currentLane++;
      targetX = game.getLaneCenter(currentLane) - size.x / 2;
      isMovingToLane = true;
    }
  }

  void speedBurst() {
    if (game.isPlayerInRiptide()) {
      position.y += 150; // Distance moved back if speed burst in riptide
    } else {
      position.y -= 30; // Distance moved forward if using speed burst
    }
  }
}

// Riptide current
class Riptide extends PositionComponent with HasGameReference<RiptideEscapeGame> {
  final int lane;
  final double speed;
  bool shouldRemove = false;
  double lifetime = 0;
    
  Riptide({required this.lane, required this.speed});

  @override
  Future<void> onLoad() async {
    final laneCenter = game.getLaneCenter(lane);
    size = Vector2(game.laneWidth - 10, 150);
    position = Vector2(laneCenter - size.x / 2, -150);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    lifetime += dt;
    position.y += speed * dt;
    
    if (position.y > game.size.y) {
      shouldRemove = true;
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    priority = 1;
    final paint = Paint()
      ..color = Colors.blueGrey.shade700.withAlpha(50)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}