import 'package:flutter/material.dart';
import 'dart:math';

class WaveClipper extends CustomClipper<Path> {
  // Receives the animated value from the HomeScreen (0 to 2*pi)
  final double wavePhase; 

  const WaveClipper({required this.wavePhase});

  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Line to the top-left corner
    path.lineTo(0, size.height * 0.85); 

    // Define wave parameters
    double waveHeight = size.height * 0.08; // 8% of the header height for amplitude
    double yOffset = size.height * 0.85; // Baseline y-position for the wave

    // Draw the wave by connecting small line segments
    // We iterate across the width (x-axis)
    for (double x = 0; x < size.width; x += 2) { // x+=2 for a balance between smoothness and performance
      // Sine function calculates the y-coordinate for the wave
      // (x / size.width) scales x to a 0-1 range
      // (2 * pi * 2) sets the number of full waves visible (2 waves)
      // + wavePhase shifts the entire curve horizontally over time
      double y = yOffset + waveHeight * sin((x / size.width) * (2 * pi * 2) + wavePhase);
      
      path.lineTo(x, y);
    }

    // Connect the last point of the wave to the top-right corner
    path.lineTo(size.width, 0); 
    path.lineTo(size.width, 0); 
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant WaveClipper oldClipper) {
    // Reclip whenever the phase changes to drive the animation
    return oldClipper.wavePhase != wavePhase;
  }
}