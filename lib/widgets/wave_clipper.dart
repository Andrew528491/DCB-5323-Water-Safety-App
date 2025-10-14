import 'package:flutter/material.dart';
import 'dart:math';

class WaveClipper extends CustomClipper<Path> {
  final double wavePhase; 

  const WaveClipper({required this.wavePhase});

  @override
  Path getClip(Size size) {
    final path = Path();
    
    path.lineTo(0, size.height * 0.85); 

    double waveHeight = size.height * 0.08; 
    double yOffset = size.height * 0.85;

    for (double x = 0; x < size.width; x += 2) {

      double y = yOffset + waveHeight * sin((x / size.width) * (2 * pi * 2) + wavePhase);
      
      path.lineTo(x, y);
    }

    path.lineTo(size.width, 0); 
    path.lineTo(size.width, 0); 
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant WaveClipper oldClipper) {
    return oldClipper.wavePhase != wavePhase;
  }
}