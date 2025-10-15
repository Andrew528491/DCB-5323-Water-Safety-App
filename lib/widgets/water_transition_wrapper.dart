import 'package:flutter/material.dart';
import 'water_transition_clipper.dart';
import 'dart:math' as math;

class WaterTransitionWrapper extends StatefulWidget {
  final Widget child;
  final Key contentKey;
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
  
  late AnimationController _riseFallController;
  late Animation<double> _riseFallAnimation;

  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  Widget? _oldChild;

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
      duration: const Duration(seconds: 4), // Speed of the full animation
    )..repeat(); 

    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_waveController);

    _waveController.addListener(() {
      if (mounted) setState(() {}); 
    });
  }

  @override
  void didUpdateWidget(covariant WaterTransitionWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.contentKey != oldWidget.contentKey) {
      _oldChild = oldWidget.child;
      
      _riseFallController.reset();
      _riseFallController.forward().then((_) {
        setState(() {
          _oldChild = null;
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