import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaterClipper extends CustomClipper<Path> {
  final double waveHeightFactor;
  final double wavePhaseValue;

  WaterClipper({required this.waveHeightFactor, required this.wavePhaseValue});

  @override
  Path getClip(Size size) {
    final Path path = Path();

    double waveAmplitude = 10;
    int numberOfWaves = 2;

    double currentMeanY = size.height * (1.0 - waveHeightFactor); 

    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    
    for (double x = size.width; x >= 0; x -= 2) {
      double waveYOffset = waveAmplitude * math.sin((x / size.width * 2 * math.pi * numberOfWaves) + wavePhaseValue);
      double y = currentMeanY + waveYOffset;
      
      path.lineTo(x, y); 
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(WaterClipper oldClipper) =>
      oldClipper.waveHeightFactor != waveHeightFactor || 
      oldClipper.wavePhaseValue != wavePhaseValue;
}