import 'package:flutter/material.dart';

// Clips the navigation bar for the more interesting shape
class NavBarClipper extends CustomClipper<Path> {
  // Height of the dip/curve
  static const double curveDepth = 25.0; 

  @override
  Path getClip(Size size) {
    final Path path = Path();
    
    path.moveTo(0, size.height); 
    path.lineTo(0, 0);
    path.quadraticBezierTo(
      size.width / 2,          
      curveDepth * 2,          
      size.width,              
      0,                       
    );
    
    path.lineTo(size.width, size.height);
    path.close(); 
    return path;
  }

  @override
  bool shouldReclip(NavBarClipper oldClipper) => false;
}