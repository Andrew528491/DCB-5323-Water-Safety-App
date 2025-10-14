import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaterClipper extends CustomClipper<Path> {
  final double waveHeightFactor;
  final double wavePhaseValue;

  WaterClipper({required this.waveHeightFactor, required this.wavePhaseValue});

  @override
  Path getClip(Size size) {
    final Path path = Path();

    double waveAmplitude = 15.0; 

    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);

    int numberOfWaveSegments = 40; 
    double segmentWidth = size.width / numberOfWaveSegments;

    // wave algo. Its just a sin function
    for (int i = numberOfWaveSegments; i >= 0; i--) {
      double x = i * segmentWidth;
      double y = waveAmplitude * math.sin((x / size.width * 2 * math.pi) + wavePhaseValue);
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