import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;

class NativeFlipCardScreen extends StatefulWidget {
  final String fileName; // Optional: to display file name in AppBar

  const NativeFlipCardScreen({super.key, required this.fileName});

  @override
  State<NativeFlipCardScreen> createState() => _NativeFlipCardScreenState();
}

class _NativeFlipCardScreenState extends State<NativeFlipCardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;

  double _currentDx = 0.0;
  double _currentDy = 0.0;
  double _targetDx = 0.0;
  double _targetDy = 0.0;
  double _filteredDx = 0.0;
  double _filteredDy = 0.0;

  double _holoOpacity = 0.0;
  double _targetHoloOpacity = 0.0;

  final double _gyroFilterFactor = 0.1;
  final double _movementSensitivity = 5.0;
  final double _speedThreshold = 0.15;
  final double _holoIntensity = 0.5;

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

    // Subscribe to gyroscope events
    gyroscopeEvents.listen((GyroscopeEvent event) {
      _handleGyroscope(event);
    });

    // We will need to set up a periodic timer or a game loop like update mechanism
    // if we want continuous animation for hologram. For now, it will update on gyro.
  }

  void _handleGyroscope(GyroscopeEvent event) {
    // Basic orientation handling, similar to the JS example
    // This is a simplification and might need calibration based on device orientation
    // For a more accurate orientation, device_orientation or fusion algorithms might be needed
    
    // Convert gyro data to movement in X/Y plane for hologram effect
    // event.y for rotation around X (pitch) affects Dy
    // event.x for rotation around Y (roll) affects Dx
    
    // Scale sensitivity
    double rawDx = -event.y / 5.0; // Invert and scale
    double rawDy = event.x / 5.0; // Scale

    rawDx = math.max(-1.0, math.min(1.0, rawDx));
    rawDy = math.max(-1.0, math.min(1.0, rawDy));

    final double diffX = (rawDx - _filteredDx).abs();
    final double diffY = (rawDy - _filteredDy).abs();
    double movementSpeed = diffX + diffY;

    if (movementSpeed < _speedThreshold) {
      movementSpeed = 0;
    } else {
      movementSpeed = movementSpeed - _speedThreshold;
    }

    _filteredDx = _filteredDx * (1 - _gyroFilterFactor) + rawDx * _gyroFilterFactor;
    _filteredDy = _filteredDy * (1 - _gyroFilterFactor) + rawDy * _gyroFilterFactor;

    _targetDx = _filteredDx;
    _targetDy = _filteredDy;
    _targetHoloOpacity = math.min(1.0, movementSpeed * _movementSensitivity);

    _updateHologramAnimation(); // Call update from here
  }

  void _updateHologramAnimation() {
    // This function will be called frequently (e.g., from gyroscope listener)
    // or by a separate ticker/timer.
    // For simplicity, let's just update directly and use setState.
    setState(() {
      _currentDx += (_targetDx - _currentDx) * 0.1; // posEasing
      _currentDy += (_targetDy - _currentDy) * 0.1; // posEasing
      _holoOpacity += (_targetHoloOpacity - _holoOpacity) * 0.15; // opacityEasing
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Center(
        child: GestureDetector(
          onTap: _handleFlip,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value * math.pi; // 0 to pi
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..rotateY(angle);

              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    // Back of the card
                    _buildCardFace(
                      isFront: false,
                      // Apply inverse transform to back face to keep text readable
                      transform: Matrix4.identity().rotateY(math.pi),
                    ),
                    // Front of the card
                    _buildCardFace(
                      isFront: true,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace({required bool isFront, Matrix4? transform}) {
    // Adjust opacity for a smooth fade during flip
    final isHidden = isFront ? _flipAnimation.value >= 0.5 : _flipAnimation.value < 0.5;

    return Transform(
      transform: transform ?? Matrix4.identity(),
      alignment: Alignment.center,
      child: Opacity(
        opacity: isHidden ? 0.0 : 1.0, // Fade out hidden face
        child: Container(
          width: 300, // Example size
          height: 480, // Example size
          decoration: BoxDecoration(
            color: isFront ? Colors.blueGrey[900] : Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Hologram effect (simplified)
              _buildHologramEffect(isFront),
              // Content (Text, Image etc.)
              Center(
                child: Text(
                  isFront ? 'Front Content' : 'Back Content',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHologramEffect(bool isFront) {
    final double holoShiftX = _currentDx * 5.0; // Similar to JS depth * 5
    final double holoShiftY = _currentDy * 5.0;

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: _holoOpacity * _holoIntensity,
          child: Transform.translate(
            offset: Offset(-holoShiftX, -holoShiftY),
            child: Container(
              // Simplified holo-gradient, similar to the HTML CSS
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    Color.fromRGBO(0, 242, 255, 0.1), // Adjusted from rgba(0, 242, 255, 0.1)
                    Colors.white30,                 // Adjusted from rgba(255, 255, 255, 0.3)
                    Color.fromRGBO(0, 242, 255, 0.1),
                    Colors.transparent,
                  ],
                  stops: [0.30, 0.45, 0.50, 0.55, 0.70],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }
}
