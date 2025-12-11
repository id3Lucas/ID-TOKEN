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
  ui.Image? _waveImage; // New cached wave layer
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
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
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
    _cachedSize = size; 

    // Make texture slightly larger than screen to allow movement without gaps
    final Size texSize = Size(size.width * 1.5, size.height * 1.5);
    final int w = texSize.width.toInt();
    final int h = texSize.height.toInt();

    // 1. Generate Hex Bitmap
    final ui.PictureRecorder hexRecorder = ui.PictureRecorder();
    _drawHexGrid(Canvas(hexRecorder), texSize);
    final ui.Image hexImg = await hexRecorder.endRecording().toImage(w, h);

    // 2. Generate Text Bitmap
    final ui.PictureRecorder textRecorder = ui.PictureRecorder();
    _drawTextGrid(Canvas(textRecorder), texSize);
    final ui.Image textImg = await textRecorder.endRecording().toImage(w, h);

    // 3. Generate Wave Bitmap (New)
    final ui.PictureRecorder waveRecorder = ui.PictureRecorder();
    _drawWaveGrid(Canvas(waveRecorder), texSize);
    final ui.Image waveImg = await waveRecorder.endRecording().toImage(w, h);

    if (mounted) {
      setState(() {
        _hexImage = hexImg;
        _textImage = textImg;
        _waveImage = waveImg;
      });
    }
  }

  void _drawHexGrid(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF00F2FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 
      ..blendMode = BlendMode.srcOver; 

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
          color: Colors.white.withValues(alpha: 0.15),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double spacing = 120.0; 

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

  void _drawWaveGrid(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.08)
      ..blendMode = BlendMode.srcOver;

    // Based on CSS: repeating-radial-gradient... 60px 60px
    const double cellSize = 60.0;
    
    // Draw repeating circles in a grid
    for (double y = -cellSize; y < size.height + cellSize; y += cellSize) {
      for (double x = -cellSize; x < size.width + cellSize; x += cellSize) {
        final Offset center = Offset(x + cellSize/2, y + cellSize/2);
        // Draw ripples inside each cell
        canvas.drawCircle(center, cellSize * 0.2, paint);
        canvas.drawCircle(center, cellSize * 0.4, paint);
      }
    }
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    _controller.dispose();
    _hexImage?.dispose();
    _textImage?.dispose();
    _waveImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = Size(constraints.maxWidth, constraints.maxHeight);
        
        if (_cachedSize != size) {
          _generateBitmaps(size);
        }

        if (_hexImage == null || _textImage == null || _waveImage == null) {
          return const SizedBox.shrink(); 
        }

        return CustomPaint(
          size: size,
          foregroundPainter: _OptimizedHologramPainter(
            offset: _holoOffset,
            hexImage: _hexImage!,
            textImage: _textImage!,
            waveImage: _waveImage!,
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
  final ui.Image waveImage;

  _OptimizedHologramPainter({
    required this.offset,
    required this.hexImage,
    required this.textImage,
    required this.waveImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // LAYER 1: HEX PATTERN (Background, Deepest)
    // Parallax: 0.2
    _paintBitmapLayer(canvas, hexImage, size, offset * 0.2, BlendMode.overlay);

    // LAYER 2: TEXT PATTERN (Mid-depth)
    // Parallax: 0.5
    _paintBitmapLayer(canvas, textImage, size, offset * 0.5, BlendMode.softLight);

    // LAYER 3: WAVE PATTERN (Mid-depth foreground)
    // Parallax: 0.8
    _paintBitmapLayer(canvas, waveImage, size, offset * 0.8, BlendMode.screen);
    
    // REMOVED: Holo Gradient
    // REMOVED: Surface Glare
  }

  void _paintBitmapLayer(Canvas canvas, ui.Image image, Size size, Offset layerOffset, BlendMode blendMode) {
    final Paint paint = Paint()..blendMode = blendMode;
    
    final double texW = image.width.toDouble();
    final double texH = image.height.toDouble();
    
    final double dx = layerOffset.dx * size.width * 0.5;
    final double dy = layerOffset.dy * size.height * 0.5;

    final double left = (size.width - texW) / 2 + dx;
    final double top = (size.height - texH) / 2 + dy;

    canvas.drawImage(image, Offset(left, top), paint);
  }

  @override
  bool shouldRepaint(covariant _OptimizedHologramPainter oldDelegate) {
    return oldDelegate.offset != offset || 
           oldDelegate.hexImage != hexImage;
  }
}
