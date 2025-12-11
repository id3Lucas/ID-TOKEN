import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:developer' as developer;

// Simplified CustomPainter for debugging
class HologramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    developer.log('HologramPainter: paint method called.', name: 'Debug');
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for debugging
  }
}

class NativeFlipCardScreenV4 extends StatefulWidget {
  final String fileName;

  const NativeFlipCardScreenV4({super.key, required this.fileName});

  @override
  State<NativeFlipCardScreenV4> createState() => _NativeFlipCardScreenV4State();
}

class _NativeFlipCardScreenV4State extends State<NativeFlipCardScreenV4> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;

  static const Color _primaryColor = Color(0xFF00D084);
  static const Color _secondaryColor = Color(0xFF0A1128);
  static const Color _accentColor = Color(0xFF00F2FF);
  static const Color _textColor = Color(0xFFE0F7FA);
  static const Color _darkGreyColor = Color(0xFF05050A);

  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOut,
      ),
    );

    _setupMotionDetection();
  }

  void _setupMotionDetection() {
    _accelerometerSubscription = accelerometerEventStream(samplingPeriod: const Duration(microseconds: 60000)).listen((AccelerometerEvent event) {
      // For debugging, we don't need to do anything here yet
    });
  }
  
  void _handleFlip() {
    if (_flipController.isAnimating) return;
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  void dispose() {
    _flipController.dispose();
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simplified build method for debugging the hologram effect
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: _secondaryColor,
        foregroundColor: _textColor,
      ),
      body: Container(
        color: _darkGreyColor,
        child: Center(
          child: GestureDetector(
            onTap: _handleFlip,
            child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                final angle = _flipAnimation.value * math.pi;
                return Transform(
                    transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                    alignment: Alignment.center,
                    child: _buildCardFace(
                      isFront: _isFront,
                      cardWidth: 300,
                      cardHeight: 500,
                      borderRadius: 15,
                    ),
                );
                },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace({
    required bool isFront,
    Matrix4? transform,
    required double cardWidth,
    required double cardHeight,
    required double borderRadius,
  }) {
    final isHidden = isFront ? _flipAnimation.value >= 0.5 : _flipAnimation.value < 0.5;

    return Transform(
      transform: transform ?? Matrix4.identity(),
      alignment: Alignment.center,
      child: Opacity(
        opacity: isHidden ? 0.0 : 1.0,
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: isFront ? _secondaryColor : const Color(0xFF080808),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Stack(
            children: [
              // _buildFrontBackground() is removed
              _buildHologramEffect(borderRadius),
              // Content is removed for debugging
            ],
          ),
        ),
      ),
    );
  }

  // Simplified hologram effect for debugging
  Widget _buildHologramEffect(double borderRadius) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          painter: HologramPainter(),
          child: Container(),
        ),
      ),
    );
  }
}
