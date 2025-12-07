import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../services/badge_service.dart' as badge_system;

// Logic for the Bathtime Monitor game

class BathtimeMonitorGame extends FlameGame with TapDetector {
  final VoidCallback? onExit;

  static const String roundCompleteKey = 'RoundComplete';
  static const String gameOverKey = 'GameOver';
  static const String howToPlayKey = 'HowToPlay';
  static const String scoreUIKey = 'ScoreUI';
  
  // Game variables
  int score = 0;
  int round = 1;
  int lives = 3;
  double roundTimer = 20.0;
  double hazardLifetime = 5.0; // Time to react - decreases each round
  int hazardsPerSet = 1; // Number of hazards spawned per set
  int distractionsPerSet = 3; // Number of distractions spawned per set
  bool waitingForNextSet = false;

  // Bools for game, overlay management
  bool gameOver = false;
  bool gameStarted = false;
  bool showingRoundComplete = false;
  bool showingHowToPlay = true;
  
  int lastTimeBonus = 0;
  int lastRoundBonus = 0;
  int hazardsCleared = 0;
  int distractionsAvoided = 0;

  late Bathtub bathtub;
  late Baby baby;
  final List<Hazard> hazards = [];
  final List<Distraction> distractions = [];
  final Random random = Random();

  BathtimeMonitorGame({this.onExit});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    add(BathroomBackground());
    
    bathtub = Bathtub();
    add(bathtub);
    
    baby = Baby();
    add(baby);
    
    add(HazardTimerBar());
    
    gameStarted = false;
    overlays.add(howToPlayKey);
    overlays.add(scoreUIKey);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (gameOver || showingRoundComplete || showingHowToPlay) return;
    
    if (gameStarted) {
      roundTimer = max(roundTimer - dt, 0);
      
      // Check for game over
      if (lives <= 0) {
        endGame();
        return;
      }
      
      // Check for round complete
      if (roundTimer <= 0) {
        completeRound();
        return;
      }
      
      // Spawn initial set or wait for all hazards to be cleared
      if (hazards.isEmpty && !waitingForNextSet) {
        spawnSet();
      }
      
      // Update hazards - lose life if not cleared in time
      for (final hazard in hazards) {
        if (!hazard.isCleared && hazard.lifetime >= hazard.maxLifetime) {
          lives--;
          hazard.shouldRemove = true;
        }
      }
      
      // Remove expired items
      hazards.removeWhere((h) => h.shouldRemove);
      distractions.removeWhere((d) => d.shouldRemove);
      
      // Check if all hazards in current set are cleared
      if (hazards.isNotEmpty && hazards.every((h) => h.isCleared)) {
        for (final distraction in distractions) {
          distraction.removeFromParent();
        }
        distractions.clear();
        
        for (final hazard in hazards) {
          hazard.removeFromParent();
        }
        hazards.clear();
        
        waitingForNextSet = true;
        Future.delayed(Duration(milliseconds: 300), () {
          if (gameStarted && !gameOver && !showingRoundComplete) {
            waitingForNextSet = false;
          }
        });
      }
    }
  }

  void spawnSet() {
    List<Vector2> usedPositions = [];
    
    // Spawn hazards
    for (int i = 0; i < hazardsPerSet; i++) {
      final types = [HazardType.soap, HazardType.toy, HazardType.water, HazardType.temperature];
      final type = types[random.nextInt(types.length)];
      
      double x, y;
      bool tooClose;
      int attempts = 0;
      
      do {
        tooClose = false;
        x = 50 + random.nextDouble() * (size.x - 100);
        y = 100 + random.nextDouble() * (size.y - 300);
        
        // Check distance from bathtub center - avoid overlapping
        final bathtubCenterX = bathtub.position.x + bathtub.size.x / 2;
        final bathtubCenterY = bathtub.position.y + bathtub.size.y / 2;
        if ((x - bathtubCenterX).abs() < 120 && (y - bathtubCenterY).abs() < 100) {
          tooClose = true;
        }
        
        // Check distance from already placed items
        for (final pos in usedPositions) {
          if ((x - pos.x).abs() < 70 && (y - pos.y).abs() < 70) {
            tooClose = true;
            break;
          }
        }
        
        attempts++;
        if (attempts > 50) break;
      } while (tooClose && attempts < 50);
      
      final hazard = Hazard(type: type, maxLifetime: hazardLifetime, position: Vector2(x - 25, y - 25));
      hazards.add(hazard);
      add(hazard);
      usedPositions.add(Vector2(x, y));
    }
    
    // Spawn distractions
    for (int i = 0; i < distractionsPerSet; i++) {
      final types = [DistractionType.phone, DistractionType.doorbell, DistractionType.pet];
      final type = types[random.nextInt(types.length)];
      
      double x, y;
      bool tooClose;
      int attempts = 0;
      
      do {
        tooClose = false;
        x = 50 + random.nextDouble() * (size.x - 100);
        y = 100 + random.nextDouble() * (size.y - 300);
        
        // Check distance from bathtub center
        final bathtubCenterX = bathtub.position.x + bathtub.size.x / 2;
        final bathtubCenterY = bathtub.position.y + bathtub.size.y / 2;
        if ((x - bathtubCenterX).abs() < 120 && (y - bathtubCenterY).abs() < 100) {
          tooClose = true;
        }
        
        // Check distance from already placed items
        for (final pos in usedPositions) {
          if ((x - pos.x).abs() < 70 && (y - pos.y).abs() < 70) {
            tooClose = true;
            break;
          }
        }
        
        attempts++;
        if (attempts > 50) break;
      } while (tooClose && attempts < 50);
      
      final distraction = Distraction(type: type, position: Vector2(x, y));
      distractions.add(distraction);
      add(distraction);
      usedPositions.add(Vector2(x, y));
    }
  }

  void onHazardClicked(Hazard hazard) {
    if (!hazard.isCleared) {
      hazard.clear();
      hazardsCleared++;
      score += 10;
    }
  }

  void onDistractionClicked(Distraction distraction) {
    distraction.wasClicked = true;
    lives--;
    if (score >= 5) {
      score -= 5;
    }
    distraction.shouldRemove = true;
  }



  void completeRound() {
    lastRoundBonus = 100 * round;
    lastTimeBonus = (hazardsCleared * 5) + (distractionsAvoided * 3);
    
    score += lastRoundBonus + lastTimeBonus;
    
    round++;
    roundTimer = 20.0;
    
    // Increase difficulty
    hazardLifetime = max(2.0, hazardLifetime - 0.4); // Reaction time decreases
    
    // Increase number of items per set
    if (round >= 3 && round % 2 == 1) {
      hazardsPerSet = min(3, hazardsPerSet + 1);
    }
    if (round >= 2 && round % 3 == 0) {
      distractionsPerSet = min(6, distractionsPerSet + 1);
    }
    
    hazardsCleared = 0;
    distractionsAvoided = 0;
    
    for (final hazard in hazards) {
      hazard.removeFromParent();
    }
    hazards.clear();
    
    for (final distraction in distractions) {
      distraction.removeFromParent();
    }
    distractions.clear();
    
    showingRoundComplete = true;
    gameStarted = false;
    overlays.add(roundCompleteKey);
  }

  void endGame() async {
    gameOver = true;
    overlays.add(gameOverKey);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userRef.get();
      final currentHighScore = doc.data()?['bathtimeHighScore'] ?? -1;

      if (score > currentHighScore) {
        await userRef.update({'bathtimeHighScore': score});
        
        final overlayContext = buildContext;
        if (overlayContext != null && overlayContext.mounted) {
          await badge_system.BadgeService.instance.checkAndAwardBadges(overlayContext);
        }
      }
    }
  }

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

  void restartGame() {
    score = 0;
    round = 1;
    lives = 3;
    roundTimer = 20.0;
    hazardLifetime = 5.0;
    hazardsPerSet = 1;
    distractionsPerSet = 3;
    gameOver = false;
    gameStarted = false;
    showingRoundComplete = false;
    showingHowToPlay = true;
    hazardsCleared = 0;
    distractionsAvoided = 0;
    waitingForNextSet = false;
    
    for (final hazard in hazards) {
      hazard.removeFromParent();
    }
    hazards.clear();
    
    for (final distraction in distractions) {
      distraction.removeFromParent();
    }
    distractions.clear();
    
    overlays.remove(gameOverKey);
    overlays.add(howToPlayKey);
  }

  void exitGame() {
    if (onExit != null) {
      onExit!();
    }
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (!gameStarted || gameOver || showingRoundComplete || showingHowToPlay) return;
    
    final tapPosition = info.eventPosition.global;
    
    // Check if tapped on hazard first (priority)
    for (final hazard in hazards) {
      if (hazard.containsPoint(tapPosition) && !hazard.isCleared) {
        onHazardClicked(hazard);
        return;
      }
    }
    
    // Check if tapped on distraction
    for (final distraction in distractions) {
      if (distraction.containsPoint(tapPosition) && !distraction.shouldRemove) {
        onDistractionClicked(distraction);
        return;
      }
    }
  }
}

class HazardTimerBar extends Component with HasGameReference<BathtimeMonitorGame> {
  @override
  void render(Canvas canvas) {
    priority = 15;
    
    // Find the hazard with the most time elapsed (closest to expiring)
    double maxProgress = 0.0;
    for (final hazard in game.hazards) {
      if (!hazard.isCleared) {
        final progress = hazard.lifetime / hazard.maxLifetime;
        if (progress > maxProgress) {
          maxProgress = progress;
        }
      }
    }
    
    // Draw bar higher up on screen
    final barWidth = game.size.x - 40;
    final barHeight = 20.0;
    final barX = 20.0;
    final barY = game.size.y - 100;
    
    // Background
    final bgPaint = Paint()..color = Colors.grey.shade300;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        Radius.circular(10),
      ),
      bgPaint,
    );
    
    // Progress fill - changes color as time runs out (bar empties from left to right)
    Color barColor;
    if (maxProgress < 0.5) {
      barColor = Colors.green;
    } else if (maxProgress < 0.75) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }
    
    final fillPaint = Paint()..color = barColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth * (1 - maxProgress), barHeight),
        Radius.circular(10),
      ),
      fillPaint,
    );
    
    // Border
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        Radius.circular(10),
      ),
      borderPaint,
    );
    
    // Eye icon on left
    final eyePaint = Paint()..color = Colors.black87;
    canvas.drawOval(Rect.fromLTWH(barX + 5, barY + 6, 12, 8), eyePaint);
    canvas.drawCircle(Offset(barX + 11, barY + 10), 3, Paint()..color = Colors.white);
    
    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'AWARENESS',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(barX + 22, barY + 4));
  }
}

class BathroomBackground extends Component with HasGameReference<BathtimeMonitorGame> {
  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE3F2FD),
          Color(0xFFBBDEFB),
        ],
      ).createShader(Rect.fromLTWH(0, 0, game.size.x, game.size.y));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      paint,
    );
    
    // Draw floor tiles
    final tilePaint = Paint()..color = Color(0xFFFFFFFF);
    
    final tileSize = 60.0;
    for (double y = game.size.y - 500; y < game.size.y; y += tileSize) {
      for (double x = 0; x < game.size.x; x += tileSize) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, tileSize - 2, tileSize - 2),
          tilePaint,
        );
      }
    }
  }
}

class Bathtub extends PositionComponent with HasGameReference<BathtimeMonitorGame> {
  @override
  Future<void> onLoad() async {
    size = Vector2(200, 150);
    position = Vector2((game.size.x - size.x) / 2, (game.size.y - size.y) / 2);
    priority = 1;
  }

  @override
  void render(Canvas canvas) {
    final bathtubPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFF5F5F5)],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.x, size.y),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
      topLeft: Radius.circular(10),
      topRight: Radius.circular(10),
    );
    
    canvas.drawRRect(rrect, bathtubPaint);
    
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF81D4FA),
          Color(0xFF4FC3F7),
        ],
      ).createShader(Rect.fromLTWH(10, 30, size.x - 20, size.y - 40));
    
    final waterRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(10, 30, size.x - 20, size.y - 40),
      bottomLeft: Radius.circular(15),
      bottomRight: Radius.circular(15),
    );
    
    canvas.drawRRect(waterRect, waterPaint);
    
    final rimPaint = Paint()
      ..color = Color(0xFFEEEEEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawRRect(rrect, rimPaint);
  }
}

class Baby extends PositionComponent with HasGameReference<BathtimeMonitorGame> {
  double bobTime = 0;

  Sprite? swimmerSprite;
  
  @override
  Future<void> onLoad() async {
    size = Vector2(60, 60);
    position = game.bathtub.position + Vector2(70, 50);
    priority = 2;
    swimmerSprite = await game.loadSprite('swimmer_0.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameStarted) {
      bobTime += dt * 2;
    }
  }

  @override
  void render(Canvas canvas) {
    final bobOffset = sin(bobTime) * 3;

    swimmerSprite!.render(
      canvas,
      position: Vector2(0, bobOffset), 
      size: size,
    );
  }
}

enum HazardType { soap, toy, water, temperature }

class Hazard extends PositionComponent with HasGameReference<BathtimeMonitorGame> {
  final HazardType type;
  final double maxLifetime;
  double lifetime = 0;
  bool shouldRemove = false;
  bool isCleared = false;

  Sprite? eyeSprite;

  
  Hazard({required this.type, required this.maxLifetime, required Vector2 position}) {
    this.position = position;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(50, 50);
    priority = 5;
    eyeSprite = await game.loadSprite('eye.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isCleared) {
      lifetime += dt;
      
      if (lifetime >= maxLifetime) {
        shouldRemove = true;
        removeFromParent();
      }
    } else {
      lifetime += dt * 3;
      if (lifetime > 0.5) {
        shouldRemove = true;
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    eyeSprite!.render(
      canvas,
      position: Vector2.zero(), 
      size: Vector2(50, 35),
    );
  }

  void clear() {
    isCleared = true;
    lifetime = 0;
  }
}

enum DistractionType { phone, doorbell, pet }

class Distraction extends PositionComponent with HasGameReference<BathtimeMonitorGame> {
  final DistractionType type;
  double lifetime = 0;
  final double maxLifetime = 10.0;
  bool shouldRemove = false;
  bool wasClicked = false;

  Sprite? phoneSprite;
  Sprite? doorBellSprite;
  Sprite? petSprite;
  
  Distraction({required this.type, required Vector2 position}) {
    this.position = position;
  }

  @override
    Future<void> onLoad() async {
        await super.onLoad(); 
        size = Vector2(50, 50);
        priority = 3;

        if (type == DistractionType.phone) {
          phoneSprite = await game.loadSprite('phone_hazard.png'); 
        }

        else if (type == DistractionType.doorbell) {
          doorBellSprite = await game.loadSprite('doorbell_hazard.png'); 
        }

        else if (type == DistractionType.pet) {
          petSprite = await game.loadSprite('dog_hazard.png');
        }
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifetime += dt;
    
    if (lifetime >= maxLifetime || wasClicked || shouldRemove) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = wasClicked ? 0.3 : 1.0;
    
    switch (type) {
      case DistractionType.phone:
        _drawPhone(canvas, alpha);
        break;
      case DistractionType.doorbell:
        _drawDoorbell(canvas, alpha);
        break;
      case DistractionType.pet:
        _drawPet(canvas, alpha);
        break;
    }
  }

  void _drawPhone(Canvas canvas, double alpha) {
    phoneSprite!.render(
        canvas,
        position: Vector2.zero(),
        size: Vector2(25, 50),
    );
  }

  void _drawDoorbell(Canvas canvas, double alpha) {
    doorBellSprite!.render(
        canvas,
        position: Vector2.zero(),
        size: Vector2(25, 50),
    );
  }

  void _drawPet(Canvas canvas, double alpha) {
        petSprite!.render(
        canvas,
        position: Vector2.zero(),
        size: Vector2(50, 50),
    );
  }

  void onClick() {
    wasClicked = true;
  }
}