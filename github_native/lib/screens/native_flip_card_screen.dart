import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;
import 'dart:async'; // Import for StreamSubscription
import 'package:flutter_svg/flutter_svg.dart'; // Import for SVG support

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

  // CSS Variables as Dart Constants
  static const Color _primaryColor = Color(0xFF00D084); // --primary
  static const Color _secondaryColor = Color(0xFF0A1128); // --secondary
  static const Color _accentColor = Color(0xFF00F2FF); // --accent
  static const Color _textColor = Color(0xFFE0F7FA); // --text-color
  static const Color _darkGreyColor = Color(0xFF05050A); // rgba(5, 5, 10, 1)

  double _currentDx = 0.0;
  double _currentDy = 0.0;
  double _targetDx = 0.0;
  double _targetDy = 0.0;
  double _filteredDx = 0.0;
  double _filteredDy = 0.0;

  double _holoOpacity = 0.0;
  double _targetHoloOpacity = 0.0;

  final double _gyroFilterFactor = 0.1;
  final double _movementSensitivity = 5.0; // Adjusted from 5.0 to 1.0 in JS, so let's try 5.0
  final double _speedThreshold = 0.15;
  final double _holoIntensity = 0.5;

  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;

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
    // Subscribe to gyroscope events
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      _handleGyroscope(event);
    });
  }

  void _handleGyroscope(GyroscopeEvent event) {
    // Convert gyro data to movement in X/Y plane for hologram effect
    // event.y for rotation around X (pitch) affects Dy (vertical movement of holo)
    // event.x for rotation around Y (roll) affects Dx (horizontal movement of holo)

    // Raw input from gyroscope (angular velocity)
    double rawDx = -event.y; // Invert as per typical parallax expectations
    double rawDy = event.x;

    // Filter to smooth out jitter
    _filteredDx = _filteredDx * (1 - _gyroFilterFactor) + rawDx * _gyroFilterFactor;
    _filteredDy = _filteredDy * (1 - _gyroFilterFactor) + rawDy * _gyroFilterFactor;

    // Normalize filtered values to a range (e.g., -1 to 1) for consistent parallax
    double normalizedDx = _filteredDx / _movementSensitivity;
    double normalizedDy = _filteredDy / _movementSensitivity;

    normalizedDx = math.max(-1.0, math.min(1.0, normalizedDx));
    normalizedDy = math.max(-1.0, math.min(1.0, normalizedDy));

    final double diffX = (normalizedDx - _currentDx).abs();
    final double diffY = (normalizedDy - _currentDy).abs();
    double movementSpeed = diffX + diffY;

    // Adjust movementSpeed based on threshold for opacity
    if (movementSpeed < _speedThreshold) {
      movementSpeed = 0;
    } else {
      movementSpeed = movementSpeed - _speedThreshold;
    }

    _targetDx = normalizedDx;
    _targetDy = normalizedDy;
    _targetHoloOpacity = math.min(1.0, movementSpeed * _holoIntensity); // Use _holoIntensity here

    _updateHologramAnimation();
  }

  void _updateHologramAnimation() {
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
    // Responsive card dimensions based on CSS variables
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double cardHeight;
    double cardWidth;
    double borderRadius;
    double padding;

    // Apply media query like logic for landscape orientation (max-height: 500px)
    if (screenHeight < 500 && screenWidth > screenHeight) { // Landscape mode
      cardHeight = screenHeight * 0.85; // 85vh
      cardWidth = cardHeight * 1.58; // 85vh * 1.58 (Original was 1.58, not 0.625)
      borderRadius = 12.0; // 12px
      padding = 15.0; // 15px
    } else { // Portrait or larger screens
      cardHeight = math.min(screenWidth * 1.36, screenHeight * 0.80); // min(136vw, 80vh)
      cardWidth = cardHeight * 0.625; // calc(var(--card-h) * 0.625)
      borderRadius = screenWidth * 0.04; // 4vw
      padding = screenWidth * 0.05; // 5vw
    }

    // Ensure min/max values for dimensions if necessary
    cardWidth = math.max(300, math.min(cardWidth, screenWidth * 0.9)); // Max 90vw
    cardHeight = math.max(480, math.min(cardHeight, screenHeight * 0.9)); // Max 90vh
    borderRadius = math.max(8, math.min(borderRadius, 18)); // Min 8, Max 18 (based on CSS values)
    padding = math.max(15, math.min(padding, 24)); // Min 15, Max 24 (based on CSS values)

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: _secondaryColor,
        foregroundColor: _textColor,
      ),
      body: Container(
        color: _darkGreyColor, // Match body background from CSS
        child: Center(
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
                        transform: Matrix4.identity()..rotateY(math.pi),
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        borderRadius: borderRadius,
                        padding: padding,
                      ),
                      // Front of the card
                      _buildCardFace(
                        isFront: true,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        borderRadius: borderRadius,
                        padding: padding,
                      ),
                    ],
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
    required double padding,
  }) {
    // Adjust opacity for a smooth fade during flip
    final isHidden = isFront ? _flipAnimation.value >= 0.5 : _flipAnimation.value < 0.5;

    return Transform(
      transform: transform ?? Matrix4.identity(),
      alignment: Alignment.center,
      child: Opacity(
        opacity: isHidden ? 0.0 : 1.0, // Fade out hidden face
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: isFront ? _secondaryColor : const Color(0xFF080808), // Front: var(--secondary), Back: #080808
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: _accentColor.withOpacity(0.2), width: 1.0), // 1px solid rgba(0, 242, 255, 0.2)
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5), // 0 10px 20px rgba(0, 0, 0, 0.5)
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: _accentColor.withOpacity(0.1), // 0 0 15px rgba(0, 242, 255, 0.1)
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Complex Front Card Background
              if (isFront) _buildFrontBackground(),
              // Hologram effect
              _buildHologramEffect(borderRadius),
              // Content (Text, Image etc.)
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isFront) _buildFrontContent(),
                      if (!isFront) _buildBackContent(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontBackground() {
    // Main linear gradient background
    final baseGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _secondaryColor.withOpacity(0.98), // rgba(10, 17, 40, 0.98)
        _darkGreyColor, // rgba(5, 5, 10, 1)
      ],
      stops: const [0.0, 1.0],
    );

    // Repeating linear gradients for the grid pattern
    // This is more complex in Flutter. We can simulate it by layering.
    // For exact replication, CustomPaint might be needed.
    // For now, let's keep it simple with just the base gradient.
    // We can add a simulated grid pattern later if required.

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: baseGradient,
          // For repeating gradients, we'd typically use a CustomPainter
          // or layer multiple containers with slightly different gradients.
          // This is a simplification.
        ),
      ),
    );
  }

  // Actual content widgets
  Widget _buildFrontContent() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top row (logo, company name, chip)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Area
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.vpn_key_rounded, color: _primaryColor, size: 30), // Example icon for logo
                  const SizedBox(width: 8), // gap: 10px
                  Text(
                    'ID Token', // Extracted from HTML
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: _accentColor.withOpacity(0.4),
                          blurRadius: 10,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Chip
              SizedBox(
                width: 40, // width based on CSS example
                height: 40, // height based on CSS example
                child: SvgPicture.asset(
                  'assets/chip.svg',
                  colorFilter: ColorFilter.mode(_primaryColor, BlendMode.srcIn), // Color the SVG path with primary color
                ),
              ),
            ],
          ),
          // Photo area
          Builder(
            builder: (context) {
              final cardWidth = MediaQuery.of(context).size.width; // Need cardWidth here
              final photoSize = math.max(100.0, math.min(cardWidth * 0.3, 150.0)); // clamp(100px, 30vw, 150px)
              return Container(
                width: photoSize,
                height: photoSize,
                margin: const EdgeInsets.only(bottom: 4), // margin: auto auto 10px auto, reduced
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryColor, width: 4), // padding 4px + 2px border (simulated)
                  image: const DecorationImage(
                    image: AssetImage('assets/photo.jpg'), // User-provided image name
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            }
          ),
          // Name
          Flexible( // Make Flexible
            child: Container(
              constraints: BoxConstraints(maxHeight: 2.5 * 22), // Approx 2.5em, assuming base font size of 22 for clamp max
              child: Text(
                'Sarah Connor', // Extracted from HTML
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 22, // clamp(10px, 5vmin, 22px)
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Rank
          Text(
            'ID Document data', // Extracted from HTML
            style: TextStyle(
              color: _accentColor,
              fontSize: 16, // clamp(10px, 2.5vmin, 16px)
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10), // Reduced from 20
          // Data Grid
          Flexible( // Make Flexible
            child: Container(
              padding: const EdgeInsets.all(8), // Reduced from 10
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: _accentColor, width: 3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TYPE', style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 14)), // data-label
                      Text('P', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), // data-val
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ISSUER', style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 14)), // data-label
                      Text('USA', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), // data-val
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('NATIONALITY', style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 14)), // data-label
                      Text('American', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), // data-val
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GENDER', style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 14)), // data-label
                      Text('F', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), // data-val
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('BIRTH DATE', style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 14)), // data-label
                      Text('12/2029', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), // data-val
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PLACE', style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 14)), // data-label
                      Text('Chicago', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), // data-val
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ISSUED', style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 14)), // data-label
                      Text('2022-12-31', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), // data-val
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('EXPIRES', style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 14)), // data-label
                      Text('2030-12-22', style: TextStyle(color: _accentColor, fontSize: 14, fontWeight: FontWeight.w600)), // data-val #expiry-date
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '>> 8473 9283 1102 <<', // Extracted from HTML
            style: TextStyle(
              color: _accentColor,
              fontSize: 18,
              fontFamily: 'monospace', // Fallback for 'Courier New'
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackContent() {
    return Expanded( // Use Expanded to fill available space in Column
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR Code
          Container(
            width: 150, height: 150,
            padding: const EdgeInsets.all(5), // padding 5px in CSS
            color: Colors.white, // background #fff
            child: Image.asset('assets/qr.png', fit: BoxFit.contain), // User-provided image name
          ),
          const SizedBox(height: 10), // Reduced from 20
          // Disclaimer Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Text(
                  'BIOSEAL CODE', // Extracted from HTML
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'BioSeal Code provides secure multi-factor authentication for verifying identities and authenticating documents through its innovative integration of Visible Digital Seal\'s technology (VDS).', // Extracted from HTML
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  'It complies with ISO 22385 & 22376 standards.', // Extracted from HTML
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10), // Reduced from 20
          // Bottom Text
          Text(
            'ID3 TECHNOLOGIES', // Extracted from HTML
            style: TextStyle(color: _primaryColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHologramEffect(double borderRadius) {
    // Implementing multiple hologram layers as per the HTML/CSS
    final double holoShiftX = _currentDx * 15.0; // depth * 15 (increased sensitivity for more visual effect)
    final double holoShiftY = _currentDy * 15.0;

    // Holo-gradient from CSS
    final holoGradient = LinearGradient(
      begin: Alignment.topLeft, // Corresponds to 115deg roughly
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        _accentColor.withOpacity(0.1), // rgba(0, 242, 255, 0.1)
        Colors.white.withOpacity(0.3), // rgba(255, 255, 255, 0.3)
        _accentColor.withOpacity(0.1),
        Colors.transparent,
      ],
      stops: const [0.30, 0.45, 0.50, 0.55, 0.70],
    );

    // Surface Glare gradient from CSS
    final surfaceGlareGradient = LinearGradient(
      begin: Alignment.topLeft, // Corresponds to 115deg
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        Colors.white.withOpacity(0.4), // rgba(255, 255, 255, 0.4)
        Colors.transparent,
      ],
      stops: const [0.4, 0.5, 0.6],
    );

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Opacity(
          opacity: _holoOpacity * _holoIntensity,
          child: Stack(
            children: [
              // Layer 1: Base Hologram Gradient
              // Simulate background-size: 200% 200% by scaling up the container
              Transform.translate(
                offset: Offset(-holoShiftX * 0.7, -holoShiftY * 0.7), // Less depth
                child: Transform.scale(
                  scale: 2.0, // Simulate background-size: 200%
                  child: Container(
                    decoration: BoxDecoration(gradient: holoGradient),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.1), BlendMode.screen), // mix-blend-mode: screen
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              // Layer 2: Deeper Parallax
              Transform.translate(
                offset: Offset(-holoShiftX * 1.0, -holoShiftY * 1.0), // More depth
                child: Transform.scale(
                  scale: 2.0, // Simulate background-size: 200%
                  child: Container(
                    decoration: BoxDecoration(gradient: holoGradient),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.15), BlendMode.screen), // mix-blend-mode: screen
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              // Layer 3: Even Deeper Parallax
               Transform.translate(
                offset: Offset(-holoShiftX * 1.3, -holoShiftY * 1.3), // Even more depth
                child: Transform.scale(
                  scale: 2.0, // Simulate background-size: 200%
                  child: Container(
                    decoration: BoxDecoration(gradient: holoGradient),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.2), BlendMode.screen), // mix-blend-mode: screen
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              // Surface Glare (from CSS)
              Transform.translate(
                offset: Offset(-holoShiftX * 0.5, -holoShiftY * 0.5), // Less parallax for glare
                child: Transform.scale(
                  scale: 2.0, // Simulate background-size: 200%
                  child: Container(
                    decoration: BoxDecoration(gradient: surfaceGlareGradient),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.1), BlendMode.overlay), // mix-blend-mode: overlay
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _gyroscopeSubscription.cancel();
    super.dispose();
  }
}
