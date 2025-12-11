import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class HologramOverlay extends StatefulWidget {
  final Widget? child;

  const HologramOverlay({super.key, this.child});

  @override
  State<HologramOverlay> createState() => _HologramOverlayState();
}

class _HologramOverlayState extends State<HologramOverlay>
    with SingleTickerProviderStateMixin {
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  // Offset range: -1.0 to 1.0
  Offset _holoOffset = Offset.zero; 
  
  // Smooth out the sensor data
  Offset _targetOffset = Offset.zero;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 16) // ~60fps ticker
    )..addListener(_updateOffset);
    
    _controller.repeat();

    _startListening();
  }

  void _startListening() {
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      // Gyro gives rate of rotation (rad/s). 
      // We'll treat it as an offset accumulator for a "glare" feel, 
      // or map tilt directly if we used accelerometer. 
      // For a "glimmer" that responds to movement, generic gyro is good.
      
      // Let's accumulate rotation to shift the gradient, damped.
      // Alternatively, we can just map the instantaneous rotation rate 
      // to the offset to make it "flare" when moved.
      
      // Experiment: Map rotation rate directly to offset.
      // y rotation is tilting left/right (affects X offset)
      // x rotation is tilting forward/back (affects Y offset)
      
      final double sensitivity = 0.5;
      final double dx = (event.y * sensitivity).clamp(-1.5, 1.5);
      final double dy = (event.x * sensitivity).clamp(-1.5, 1.5);
      
      setState(() {
         _targetOffset = Offset(dx, dy);
      });
    });
  }
  
  void _updateOffset() {
     // visual lerp for smoothness
     final double lerpFactor = 0.1;
     setState(() {
        _holoOffset = Offset.lerp(_holoOffset, _targetOffset, lerpFactor)!;
     });
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _HologramPainter(offset: _holoOffset),
      child: widget.child,
    );
  }
}

class _HologramPainter extends CustomPainter {
  final Offset offset;

  _HologramPainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    
    // We'll draw two layers:
    // 1. Surface Glare (Overlay) - white shimmer
    // 2. Rainbow/Holo Gradient (ColorDodge/Screen) - colors

    _paintSurfaceGlare(canvas, rect);
    _paintHoloGradient(canvas, rect);
  }

  void _paintSurfaceGlare(Canvas canvas, Rect rect) {
    final Paint paint = Paint()..blendMode = BlendMode.overlay;

    // Movement: Shift gradient center based on offset
    // Offset is roughly -1 to 1.
    // We want the band to move across the card.
    
    final double slideX = offset.dx * rect.width; 
    final double slideY = offset.dy * rect.height;

    // Create a gradient that is larger than the card and shifts
    // Angle 115 degrees ~ 2rad
    // We simulate the angle by start/end points.
    
    paint.shader = ui.Gradient.linear(
       rect.topLeft + Offset(slideX - rect.width, slideY - rect.height),
       rect.bottomRight + Offset(slideX + rect.width, slideY + rect.height),
       [
         Colors.transparent,
         Colors.white.withValues(alpha: 0.0),
         Colors.white.withValues(alpha: 0.4), // Peak glare
         Colors.white.withValues(alpha: 0.0),
         Colors.transparent,
       ],
       [0.2, 0.4, 0.5, 0.6, 0.8], 
    );

    canvas.drawRect(rect, paint);
  }

  void _paintHoloGradient(Canvas canvas, Rect rect) {
    final Paint paint = Paint()..blendMode = BlendMode.colorDodge;
    
    // Opposite movement for depth effect
    final double slideX = -offset.dx * rect.width * 0.5;
    final double slideY = -offset.dy * rect.height * 0.5;

    paint.shader = ui.Gradient.linear(
       rect.topLeft + Offset(slideX, slideY),
       rect.bottomRight + Offset(slideX, slideY),
       [
          Colors.transparent,
          const Color(0xFF00F2FF).withValues(alpha: 0.2), // Cyan
          Colors.white.withValues(alpha: 0.3),
          const Color(0xFF00F2FF).withValues(alpha: 0.2), // Cyan
          Colors.transparent
       ],
       [0.3, 0.45, 0.5, 0.55, 0.7],
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _HologramPainter oldDelegate) {
    return oldDelegate.offset != offset;
  }
}
