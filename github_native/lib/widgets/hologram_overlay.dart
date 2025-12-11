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
    
    // LAYER 1: HEX PATTERN (Background, slow movement)
    // Parallax factor: 0.2 (Moves slightly)
    _paintHexPattern(canvas, size, offset * 0.2);

    // LAYER 2: TEXT PATTERN (Mid-depth)
    // Parallax factor: 0.5
    _paintTextPattern(canvas, size, offset * 0.5);

    // LAYER 3: WAVE PATTERN (Mid-depth foreground)
    // Parallax factor: 0.8
    _paintWavePattern(canvas, size, offset * 0.8);

    // LAYER 4: HOLO GRADIENT (Foreground effect)
    // Parallax factor: -0.5 (Opposite movement for depth)
    _paintHoloGradient(canvas, rect, offset * -0.5);
    
    // LAYER 5: SURFACE GLARE (Topmost glass effect)
    // Parallax factor: 1.2 (Moves with tilt)
    _paintSurfaceGlare(canvas, rect, offset * 1.2);
  }

  void _paintHexPattern(Canvas canvas, Size size, Offset layerOffset) {
    final Paint paint = Paint()
      ..color = const Color(0xFF00F2FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..blendMode = BlendMode.overlay;

    final double width = 40.0;
    final double height = 70.0;
    // Shift grid by offset
    final double dx = layerOffset.dx * size.width;
    final double dy = layerOffset.dy * size.height;

    canvas.save();
    canvas.translate(dx, dy);

    // Draw grid covering the whole area + buffer for movement
    // Simple tiling logic
    for (double y = -height; y < size.height + height; y += height * 0.75) {
      for (double x = -width; x < size.width + width; x += width) {
        // Offset every other row
        double xPos = x;
        if ((y ~/ (height * 0.75)) % 2 != 0) {
          xPos += width * 0.5;
        }
        
        // Hexagon Path
        final Path path = Path();
        path.moveTo(xPos + width * 0.5, y); // Top Center
        path.lineTo(xPos + width, y + height * 0.25);
        path.lineTo(xPos + width, y + height * 0.75);
        path.lineTo(xPos + width * 0.5, y + height); // Bottom Center
        path.lineTo(xPos, y + height * 0.75);
        path.lineTo(xPos, y + height * 0.25);
        path.close();
        
        canvas.drawPath(path, paint);
      }
    }
    canvas.restore();
  }

  void _paintTextPattern(Canvas canvas, Size size, Offset layerOffset) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: 'ID TOKEN',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.1),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double spacing = 80.0;
    // Shift by offset
    final double dx = layerOffset.dx * size.width;
    final double dy = layerOffset.dy * size.height;

    canvas.save();
    canvas.translate(dx, dy);
    
    // Rotate entire layer -45 deg around center
    // Or tile rotated text. CSS rotates the text itself.
    // Let's rotate individual text items for better tiling control
    
    // Grid loop
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
         canvas.save();
         canvas.translate(x, y);
         canvas.rotate(-math.pi / 4); // -45 degrees
         textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
         canvas.restore();
      }
    }
    canvas.restore();
  }

  void _paintWavePattern(Canvas canvas, Size size, Offset layerOffset) {
     final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.05)
      ..blendMode = BlendMode.screen;

    // Center of wave, shifted by offset
    final Offset center = Offset(size.width / 2, size.height / 2) + 
                          Offset(layerOffset.dx * size.width, layerOffset.dy * size.height);

    // Draw concentric circles
    final double maxRadius = math.max(size.width, size.height) * 1.5;
    for (double r = 0; r < maxRadius; r += 20) {
      canvas.drawCircle(center, r, paint);
    }
  }

  void _paintSurfaceGlare(Canvas canvas, Rect rect, Offset layerOffset) {
    final Paint paint = Paint()..blendMode = BlendMode.overlay;

    // Movement: Shift gradient center based on offset
    final double slideX = layerOffset.dx * rect.width; 
    final double slideY = layerOffset.dy * rect.height;

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

  void _paintHoloGradient(Canvas canvas, Rect rect, Offset layerOffset) {
    final Paint paint = Paint()..blendMode = BlendMode.colorDodge;
    
    // Movement
    final double slideX = layerOffset.dx * rect.width;
    final double slideY = layerOffset.dy * rect.height;

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
