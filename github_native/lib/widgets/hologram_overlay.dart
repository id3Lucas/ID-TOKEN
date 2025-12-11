import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
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
  Offset _velocity = Offset.zero; // For spring physics

  // Opacity driven by movement speed
  double _holoOpacity = 0.0;
  double _targetOpacity = 0.0;

  // Cached images for static patterns
  ui.Image? _hexImage;
  ui.Image? _textImage;
  ui.Image? _waveImage; 
  Size? _cachedSize;

  // Shader
  ui.FragmentProgram? _program;
  double _time = 0.0;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _initShader();

    _controller = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 16) 
    )..addListener(_updateLoop);
    
    _controller.repeat();
    _startListening();
  }

  Future<void> _initShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/hologram.frag');
      setState(() {
        _program = program;
      });
    } catch (e) {
      debugPrint('Shader init failed: $e');
    }
  }

  void _startListening() {
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      const double sensitivity = 0.3;
      final double dx = (event.y * sensitivity).clamp(-1.0, 1.0);
      final double dy = (event.x * sensitivity).clamp(-1.0, 1.0);
      
      final double speed = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final double newOpacity = (speed * 2.0).clamp(0.0, 1.0);

      setState(() {
         _targetOffset = Offset(dx, dy);
         _targetOpacity = newOpacity;
      });
    });
  }
  
  void _updateLoop() {
     const double lerpFactor = 0.1; // Smooth slide
     _time += 0.016; // Keep time increment for shader

     setState(() {
        // Reverted to simple Lerp (Slide) as requested
        _holoOffset = Offset.lerp(_holoOffset, _targetOffset, lerpFactor)!;
        
        // Reset velocity just in case
        _velocity = Offset.zero;

        _holoOpacity = ui.lerpDouble(_holoOpacity, _targetOpacity, 0.1) ?? 0.0;
     });
  }

  Future<void> _generateBitmaps(Size size) async {
    if (_hexImage != null && _cachedSize == size) return;
    _cachedSize = size; 

    // Important: Shader expects textures.
    // We render exact screen size (or scale factor?)
    // To keep it simple, we render exact size.
    // Parallax is handled in shader by shifting UVs, so we might need margin?
    // Actually shader parallax shifts UV lookup, so we don't need margin if wrap is Clamp.
    // But if we shift UV off edge, we need Repeated/Mirrored texture or transparent border.
    // Let's rely on standard drawing, shader should handle UVs within [0,1].
    
    final int w = size.width.toInt();
    final int h = size.height.toInt();

    // 1. Generate Hex Bitmap
    final ui.PictureRecorder hexRecorder = ui.PictureRecorder();
    _drawHexGrid(Canvas(hexRecorder), size);
    final ui.Image hexImg = await hexRecorder.endRecording().toImage(w, h);

    // 2. Generate Text Bitmap
    final ui.PictureRecorder textRecorder = ui.PictureRecorder();
    _drawTextGrid(Canvas(textRecorder), size);
    final ui.Image textImg = await textRecorder.endRecording().toImage(w, h);

    // 3. Generate Wave Bitmap
    final ui.PictureRecorder waveRecorder = ui.PictureRecorder();
    _drawWaveGrid(Canvas(waveRecorder), size);
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
    // We draw slightly larger grid to allow border sampling if needed, but 
    // for now we just match _drawHexGrid logic from before but target 'size' exactly.
    // We use WHITE color because Shader will mult by opacity/color.
    final Paint paint = Paint()
      ..color = Colors.white 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

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
      text: const TextSpan(
        text: 'ID TOKEN',
        style: TextStyle(
          color: Colors.white, // Pure white for texture mask
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
      ..color = Colors.white;

    const double cellSize = 60.0;
    
    for (double y = -cellSize; y < size.height + cellSize; y += cellSize) {
      for (double x = -cellSize; x < size.width + cellSize; x += cellSize) {
        final Offset center = Offset(x + cellSize/2, y + cellSize/2);
        for (double r = 5; r < 30; r += 5) {
           canvas.drawCircle(center, r, paint);
        }
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

        if (_program == null || _hexImage == null || _textImage == null || _waveImage == null) {
          return const SizedBox.shrink(); 
        }

        return CustomPaint(
          size: size,
          foregroundPainter: _ShaderHologramPainter(
            program: _program!,
            hexImage: _hexImage!,
            textImage: _textImage!,
            waveImage: _waveImage!,
            offset: _holoOffset,
            opacity: _holoOpacity,
            time: _time,
          ),
        );
      },
    );
  }
}

class _ShaderHologramPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final ui.Image hexImage;
  final ui.Image textImage;
  final ui.Image waveImage;
  final Offset offset;
  final double opacity;
  final double time;

  _ShaderHologramPainter({
    required this.program,
    required this.hexImage,
    required this.textImage,
    required this.waveImage,
    required this.offset,
    required this.opacity,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;

    final shader = program.fragmentShader();

    // Uniforms order must match GLSL:
    // uResolution (x, y)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    // uTime
    shader.setFloat(2, time);
    // uTilt (x, y)
    shader.setFloat(3, offset.dx);
    shader.setFloat(4, offset.dy);
    // uOpacity
    shader.setFloat(5, opacity);

    // Samplers:
    // uTexHex (0)
    shader.setImageSampler(0, hexImage);
    // uTexText (1)
    shader.setImageSampler(1, textImage);
    // uTexWave (2)
    shader.setImageSampler(2, waveImage);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShaderHologramPainter oldDelegate) {
    return oldDelegate.offset != offset || 
           oldDelegate.opacity != opacity ||
           oldDelegate.time != time;
  }
}
