import 'package:flutter/material.dart';
import 'water_transition_clipper.dart';
import 'dart:math' as math;

// Responsible for handling the rise/fall water animation effect on switching screens with the main navigation.

class WaterTransitionWrapper extends StatefulWidget {
  final Widget child; // New content to display
  final Key contentKey; // Used to detect when content changes
  final VoidCallback onTransitionComplete;

  const WaterTransitionWrapper({
    super.key,
    required this.child,
    required this.contentKey,
    required this.onTransitionComplete,
  });

  @override
  State<WaterTransitionWrapper> createState() => _WaterTransitionWrapperState();
}

class _WaterTransitionWrapperState extends State<WaterTransitionWrapper>
    with TickerProviderStateMixin { 
  
  late AnimationController _riseFallController; // Vertical movement
  late Animation<double> _riseFallAnimation;

  late AnimationController _waveController; // Wave movement
  late Animation<double> _waveAnimation;

  Widget? _oldChild; // Stores old screen content during transition

  @override
  void initState() {
    super.initState();

    // Controls vertical movement
    _riseFallController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), 
    );
    _riseFallAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _riseFallController, curve: Curves.easeInOut),
    );

    // Controls wave movement
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(); 

    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_waveController);

    _waveController.addListener(() {
      if (mounted) setState(() {}); 
    });
  }

  @override
  void didUpdateWidget(covariant WaterTransitionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Detects screen change via provided key
    if (widget.contentKey != oldWidget.contentKey) {
      _oldChild = oldWidget.child;
      _riseFallController.reset();

      // Starts transition sequence
      _riseFallController.forward().then((_) {
        setState(() {
          _oldChild = null; // Remove old content once covered via the transition
        });
        widget.onTransitionComplete();
        _riseFallController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _riseFallController.dispose();
    _waveController.dispose();
    super.dispose();
  }


  // Uses controllers and water_clipper to render the overlay on both screens
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(

      animation: Listenable.merge([_riseFallAnimation, _waveAnimation]),
      builder: (context, child) {
        double heightFactor = _riseFallAnimation.value;
        
        return Stack(
          children: <Widget>[
            _oldChild ?? widget.child, 
            
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: MediaQuery.of(context).size.height * (1.0 - heightFactor) - 25, 
              
              child: ClipPath(
                clipper: WaterClipper(
                  waveHeightFactor: heightFactor, 
                  wavePhaseValue: _waveAnimation.value,
                ), 
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 58, 175, 183),
                  ),
                  height: double.infinity,
                  width: double.infinity,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}