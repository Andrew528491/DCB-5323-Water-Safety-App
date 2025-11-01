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
    add(WaterParticles());
    add(ShoreWave());
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
    
    if (player.position.y <= 120) {
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
          Color(0xFF4FC3F7),
          Color(0xFF29B6F6), 
          Color(0xFF039BE5),
          Color(0xFF0277BD), 
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, game.size.x, game.size.y));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      paint,
    );
    
    final causticPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final yOffset = game.size.y * 0.3 * i;
      
      for (double x = 0; x <= game.size.x; x += 20) {
        final y = yOffset + 30 * sin(0.02 * x + animationTime + i * 2);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      path.lineTo(game.size.x, game.size.y);
      path.lineTo(0, game.size.y);
      path.close();
      
      canvas.drawPath(path, causticPaint);
    }
  }
}

// Floating water particles
class WaterParticles extends Component with HasGameReference<RiptideEscapeGame> {
  final List<_Particle> _particles = [];
  final Random random = Random();
  
  @override
  void onLoad() {
    // Create initial particles
    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: random.nextDouble() * game.size.x,
        y: random.nextDouble() * game.size.y,
        size: 1 + random.nextDouble() * 2,
        speed: 10 + random.nextDouble() * 20,
        opacity: 0.2 + random.nextDouble() * 0.3,
      ));
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (!game.gameStarted) return;
    
    for (final particle in _particles) {
      particle.y -= particle.speed * dt;
      particle.x += sin(particle.y * 0.05) * 0.5;
      
      // Reset particle if it goes off screen
      if (particle.y < 0) {
        particle.y = game.size.y;
        particle.x = random.nextDouble() * game.size.x;
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    priority = 2;
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (final particle in _particles) {
      paint.color = Colors.white.withValues(alpha: particle.opacity);
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// Shore at top
class Shore extends Component with HasGameReference<RiptideEscapeGame> {
  Sprite? shoreSprite;
  
  @override
  Future<void> onLoad() async {
    shoreSprite = await game.loadSprite('ShoreLine.png');
  }
  
  @override
  void render(Canvas canvas) {
    priority = 10;
    shoreSprite!.render(
      canvas,
      position: Vector2.zero(),
      size: Vector2(game.size.x, 200),
    );
  }
}

// Shore wave effect
class ShoreWave extends Component with HasGameReference<RiptideEscapeGame> {
  double waveTime = 0.0;
  final double waveAmplitude = 5.0; // Height of the wave crests
  final double waveFrequency = 0.04; // Tightness of the wave pattern
  final double waveSpeed = 5.0; // Speed of the wave movement
  final double waveHeight = 20.0; // The vertical size of the animated band
  
  // The y-coordinate where the wave starts
  final double shoreBottomY = 113.0; 

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameStarted) {
      waveTime += dt * waveSpeed;
    }
  }

  @override
  void render(Canvas canvas) {
    priority = 12; 
    
    final paint = Paint()
      ..color = Colors.lightBlue.shade300.withValues(alpha: 0.8) 
      ..style = PaintingStyle.fill;
      
    final wavePath = Path();
    
    wavePath.moveTo(0, shoreBottomY + waveHeight); 
    
    for (double x = 0; x <= game.size.x; x++) {
      final y = shoreBottomY - waveAmplitude * sin(waveFrequency * x + waveTime);
      wavePath.lineTo(x, y);
    }
    
    wavePath.lineTo(game.size.x, shoreBottomY + waveHeight); 
    wavePath.lineTo(0, shoreBottomY + waveHeight); 
    wavePath.close();

    canvas.drawPath(wavePath, paint);
  }
}

// Player class
class Player extends SpriteAnimationComponent with HasGameReference<RiptideEscapeGame> {
  int currentLane = 1;
  final double moveSpeed = 250;
  bool isMovingToLane = false;
  double targetX = 0;
  bool isBursting = false;
  bool burstInRiptide = false;
  double burstSpeed = 0;
  final double burstDuration = 0.3;
  double burstTimer = 0;
  final double normalStepTime = 0.15;
  final double burstStepTime = 0.05;
  
  double wakeTime = 0;
  final List<_WakeParticle> _wakeParticles = [];
    
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
      stepTime: normalStepTime,
      loop: true,
    );

    priority = 13;

    size = Vector2(40, 40);
    final startX = game.getLaneCenter(1) - size.x / 2;
    position = Vector2(startX, game.size.y - 100);
    targetX = startX;
    
    playing = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    wakeTime += dt;
    
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
      
      // Create wake particles
      if (wakeTime > 0.1) {
        wakeTime = 0;
        final random = Random();
        _wakeParticles.add(_WakeParticle(
          x: position.x + size.x / 2 + (random.nextDouble() - 0.5) * 10,
          y: position.y + size.y,
          life: 0.5,
          size: 3 + random.nextDouble() * 3,
        ));
      }
    } else {
      playing = false;
    }

    // Update wake particles
    _wakeParticles.removeWhere((p) => p.life <= 0);
    for (final particle in _wakeParticles) {
      particle.life -= dt;
      particle.y += 30 * dt;
      particle.size *= 0.98;
    }

    // Burst animation logic
    if (isBursting) {
      burstTimer += dt;
      final progress = (burstTimer / burstDuration).clamp(0.0, 1.0);
      final easeOut = 1 - pow(1 - progress, 3);
      
      if (burstInRiptide) {
        position.y += burstSpeed * dt * (1 - easeOut);
      } else {
        position.y -= burstSpeed * dt * (1 - easeOut);
      }
      
      if (burstTimer >= burstDuration) {
        isBursting = false;
        burstTimer = 0;
        animation?.stepTime = normalStepTime;
      }
    }

    // Vertical movement logic
    if (game.gameStarted && !isBursting) {
      if (game.isPlayerInRiptide()) {
        position.y += 120 * dt;
      } else {
        position.y -= 20 * dt;
      }
    }
    
    position.y = position.y.clamp(60, game.size.y - 50);
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw wake particles
    final wakePaint = Paint()..style = PaintingStyle.fill;
    
    for (final particle in _wakeParticles) {
      final opacity = (particle.life / 0.5).clamp(0.0, 1.0);
      wakePaint.color = Colors.white.withValues(alpha: opacity * 0.6);
      canvas.drawCircle(
        Offset(particle.x - position.x, particle.y - position.y),
        particle.size,
        wakePaint,
      );
    }
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
    burstInRiptide = game.isPlayerInRiptide();
    
    if (burstInRiptide) {
      burstSpeed = 1500;
    } else {
      burstSpeed = 400;
    }
    isBursting = true;
    burstTimer = 0;
    animation?.stepTime = burstStepTime;
  }
}

class _WakeParticle {
  double x;
  double y;
  double life;
  double size;
  
  _WakeParticle({
    required this.x,
    required this.y,
    required this.life,
    required this.size,
  });
}


// Riptide current
class Riptide extends PositionComponent with HasGameReference<RiptideEscapeGame> {
  final int lane;
  final double speed;
  bool shouldRemove = false;
  double lifetime = 0;
  final double waveSpeed = 3.0;
  final double waveFrequency = 0.15;
  final double waveAmplitude = 8.0;
    
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
    priority = 3;
    
    // Create gradient
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.blueGrey.shade800.withValues(alpha: 0.3),
        Colors.blueGrey.shade600.withValues(alpha: 0.5),
        Colors.blueGrey.shade800.withValues(alpha: 0.3),
      ],
      stops: [0.0, 0.5, 1.0],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.x, size.y))
      ..style = PaintingStyle.fill;
    
    // Draw rounded rectangle with bottom corners rounded
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.x, size.y),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
    );
    canvas.drawRRect(rrect, paint);
    
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Draw multiple wavy lines
    for (int i = 0; i < 4; i++) {
      final yOffset = (size.y / 4) * i;
      final path = Path();
      
      for (double x = 0; x <= size.x; x += 2) {
        final y = yOffset + waveAmplitude * sin(waveFrequency * x + lifetime * waveSpeed + i * 0.5);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(path, linePaint);
    }
    
    // Add some bubble/particle effects
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    
    final random = Random(lane * 1000);
    for (int i = 0; i < 5; i++) {
      final bubbleX = random.nextDouble() * size.x;
      final bubbleY = ((lifetime * 50 + i * 30) % size.y);
      final bubbleSize = 2 + random.nextDouble() * 3;
      
      canvas.drawCircle(
        Offset(bubbleX, bubbleY),
        bubbleSize,
        bubblePaint,
      );
    }
  }
}