import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class HologramOverlay extends StatefulWidget {
  const HologramOverlay({super.key});

  @override
  State<HologramOverlay> createState() => _HologramOverlayState();
}

class _HologramOverlayState extends State<HologramOverlay>
    with SingleTickerProviderStateMixin {
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  Offset _holoOffset = Offset.zero; 
  Offset _targetOffset = Offset.zero;

  // Cached images for static patterns
  ui.Image? _hexImage;
  ui.Image? _textImage;
  Size? _cachedSize;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 16) 
    )..addListener(_updateOffset);
    
    _controller.repeat();
    _startListening();
  }

  void _startListening() {
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      // Lower sensitivity for smoother/less chaotic movement
      const double sensitivity = 0.3;
      final double dx = (event.y * sensitivity).clamp(-1.0, 1.0);
      final double dy = (event.x * sensitivity).clamp(-1.0, 1.0);
      
      setState(() {
         _targetOffset = Offset(dx, dy);
      });
    });
  }
  
  void _updateOffset() {
     const double lerpFactor = 0.1;
     setState(() {
        _holoOffset = Offset.lerp(_holoOffset, _targetOffset, lerpFactor)!;
     });
  }

  /// Generates the static pattern bitmaps ONCE
  Future<void> _generateBitmaps(Size size) async {
    if (_hexImage != null && _cachedSize == size) return;
    _cachedSize = size; // Lock execution

    // Make texture slightly larger than screen to allow movement without gaps
    final Size texSize = Size(size.width * 1.5, size.height * 1.5);

    // 1. Generate Hex Bitmap
    final ui.PictureRecorder hexRecorder = ui.PictureRecorder();
    final Canvas hexCanvas = Canvas(hexRecorder);
    _drawHexGrid(hexCanvas, texSize);
    final ui.Image hexImg = await hexRecorder.endRecording().toImage(texSize.width.toInt(), texSize.height.toInt());

    // 2. Generate Text Bitmap
    final ui.PictureRecorder textRecorder = ui.PictureRecorder();
    final Canvas textCanvas = Canvas(textRecorder);
    _drawTextGrid(textCanvas, texSize);
    final ui.Image textImg = await textRecorder.endRecording().toImage(texSize.width.toInt(), texSize.height.toInt());

    if (mounted) {
      setState(() {
        _hexImage = hexImg;
        _textImage = textImg;
      });
    }
  }

  void _drawHexGrid(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF00F2FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 // Thicker line for better visibility
      ..blendMode = BlendMode.srcOver; // We apply blend mode on the layer instead

    // Increased size for simpler, less noisy look
    const double width = 60.0;
    const double height = 100.0; 

    for (double y = -height; y < size.height + height; y += height * 0.75) {
      for (double x = -width; x < size.width + width; x += width) {
        double xPos = x;
        if ((y ~/ (height * 0.75)) % 2 != 0) {
          xPos += width * 0.5;
        }
        
        final Path path = Path();
        path.moveTo(xPos + width * 0.5, y);
        path.lineTo(xPos + width, y + height * 0.25);
        path.lineTo(xPos + width, y + height * 0.75);
        path.lineTo(xPos + width * 0.5, y + height);
        path.lineTo(xPos, y + height * 0.75);
        path.lineTo(xPos, y + height * 0.25);
        path.close();
        
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawTextGrid(Canvas canvas, Size size) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: 'ID TOKEN',
        style: TextStyle(
          // Very subtle white text
          color: Colors.white.withValues(alpha: 0.15),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double spacing = 120.0; // More spacing = simpler

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
         canvas.save();
         canvas.translate(x, y);
         canvas.rotate(-math.pi / 4);
         textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
         canvas.restore();
      }
    }
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    _controller.dispose();
    _hexImage?.dispose();
    _textImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        
        // Trigger bitmap gen if needed
        if (_cachedSize != size) {
          _generateBitmaps(size);
        }

        if (_hexImage == null || _textImage == null) {
          return const SizedBox.shrink(); // Loading frame
        }

        return CustomPaint(
          size: size,
          foregroundPainter: _OptimizedHologramPainter(
            offset: _holoOffset,
            hexImage: _hexImage!,
            textImage: _textImage!,
          ),
        );
      },
    );
  }
}

class _OptimizedHologramPainter extends CustomPainter {
  final Offset offset;
  final ui.Image hexImage;
  final ui.Image textImage;

  _OptimizedHologramPainter({
    required this.offset,
    required this.hexImage,
    required this.textImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    
    // LAYER 1: HEX PATTERN (Bitmap)
    // Shift the bitmap based on offset * parallax
    _paintBitmapLayer(canvas, hexImage, size, offset * 0.2, BlendMode.overlay);

    // LAYER 2: TEXT PATTERN (Bitmap)
    _paintBitmapLayer(canvas, textImage, size, offset * 0.5, BlendMode.softLight);

    // LAYER 3: WAVE PATTERN (Still programmatic, cheap circles)
    _paintWavePattern(canvas, size, offset * 0.8);

    // LAYER 4: HOLO GRADIENT (Cheap linear gradient)
    _paintHoloGradient(canvas, rect, offset * -0.5);
    
    // LAYER 5: SURFACE GLARE
    _paintSurfaceGlare(canvas, rect, offset * 1.5);
  }

  void _paintBitmapLayer(Canvas canvas, ui.Image image, Size size, Offset layerOffset, BlendMode blendMode) {
    final Paint paint = Paint()..blendMode = blendMode;
    
    // Center the larger texture
    final double texW = image.width.toDouble();
    final double texH = image.height.toDouble();
    
    // Current shift
    final double dx = layerOffset.dx * size.width * 0.5;
    final double dy = layerOffset.dy * size.height * 0.5;

    // Center alignment + shift
    final double left = (size.width - texW) / 2 + dx;
    final double top = (size.height - texH) / 2 + dy;

    canvas.drawImage(image, Offset(left, top), paint);
  }

  void _paintWavePattern(Canvas canvas, Size size, Offset layerOffset) {
     final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 // Slightly thicker
      ..color = Colors.white.withValues(alpha: 0.08) // More subtle
      ..blendMode = BlendMode.screen;

    final Offset center = Offset(size.width / 2, size.height / 2) + 
                          Offset(layerOffset.dx * size.width * 0.5, layerOffset.dy * size.height * 0.5);

    // Fewer circles for simpler look
    final double maxRadius = math.max(size.width, size.height) * 1.2;
    for (double r = 0; r < maxRadius; r += 40) { // Gap 20 -> 40
      canvas.drawCircle(center, r, paint);
    }
  }

  void _paintSurfaceGlare(Canvas canvas, Rect rect, Offset layerOffset) {
    final Paint paint = Paint()..blendMode = BlendMode.overlay;

    final double slideX = layerOffset.dx * rect.width; 
    final double slideY = layerOffset.dy * rect.height;

    paint.shader = ui.Gradient.linear(
       rect.topLeft + Offset(slideX - rect.width, slideY - rect.height),
       rect.bottomRight + Offset(slideX + rect.width, slideY + rect.height),
       [
         Colors.transparent,
         Colors.white.withValues(alpha: 0.0),
         Colors.white.withValues(alpha: 0.5), // Stronger peak
         Colors.white.withValues(alpha: 0.0),
         Colors.transparent,
       ],
       [0.2, 0.4, 0.5, 0.6, 0.8], 
    );

    canvas.drawRect(rect, paint);
  }

  void _paintHoloGradient(Canvas canvas, Rect rect, Offset layerOffset) {
    final Paint paint = Paint()..blendMode = BlendMode.colorDodge;
    
    final double slideX = layerOffset.dx * rect.width;
    final double slideY = layerOffset.dy * rect.height;

    paint.shader = ui.Gradient.linear(
       rect.topLeft + Offset(slideX, slideY),
       rect.bottomRight + Offset(slideX, slideY),
       [
          Colors.transparent,
          const Color(0xFF00F2FF).withValues(alpha: 0.2), 
          Colors.white.withValues(alpha: 0.3),
          const Color(0xFF00F2FF).withValues(alpha: 0.2),
          Colors.transparent
       ],
       [0.3, 0.45, 0.5, 0.55, 0.7],
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _OptimizedHologramPainter oldDelegate) {
    return oldDelegate.offset != offset || 
           oldDelegate.hexImage != hexImage;
  }
}
