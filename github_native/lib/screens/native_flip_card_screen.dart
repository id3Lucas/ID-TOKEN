import 'package:flutter/material.dart';
import 'dart:math' as math;
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
    super.dispose();
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
      cardWidth = screenWidth * 0.75; // Take up 75% of screen width in landscape
      cardHeight = cardWidth / 1.58; // Maintain aspect ratio based on new width
      borderRadius = cardWidth * 0.02; // Responsive border radius
      padding = cardWidth * 0.03; // Responsive padding
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
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Container(
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
                            orientation: orientation,
                          ),
                          // Front of the card
                          _buildCardFace(
                            isFront: true,
                            cardWidth: cardWidth,
                            cardHeight: cardHeight,
                            borderRadius: borderRadius,
                            padding: padding,
                            orientation: orientation,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
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
    required Orientation orientation,
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
            border: Border.all(color: _accentColor.withAlpha((255 * 0.2).round()), width: 1.0), // 1px solid rgba(0, 242, 255, 0.2)
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.5).round()), // 0 10px 20px rgba(0, 0, 0, 0.5)
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: _accentColor.withAlpha((255 * 0.1).round()), // 0 0 15px rgba(0, 242, 255, 0.1)
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
                  child: isFront
                      ? _buildFrontContent(cardWidth, cardHeight, orientation)
                      : _buildBackContent(cardWidth, cardHeight, orientation),
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
        _secondaryColor.withAlpha((255 * 0.98).round()), // rgba(10, 17, 40, 0.98)
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
  // Helper to build data grid rows
  Widget _buildDataGridRow(String label, String value, double cardWidth, {bool isAccent = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: cardWidth * 0.008), // Responsive vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _textColor.withAlpha((255 * 0.7).round()), fontSize: cardWidth * 0.035)), // Responsive font size
          Text(
            value,
            style: TextStyle(
              color: isAccent ? _accentColor : Colors.white,
              fontSize: cardWidth * 0.035, // Responsive font size
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateFontSize(double baseSize, double scaleFactor, double cardWidth, double cardHeight) {
    // Use a combination of width and height to determine the scale
    double scale = (cardWidth + cardHeight) / 1000;
    double fontSize = baseSize * scale * scaleFactor;
    // Clamp the font size to a reasonable range
    return fontSize.clamp(8.0, baseSize);
  }

  Widget _buildFrontContent(double cardWidth, double cardHeight, Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return Column(
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
                  Icon(Icons.vpn_key_rounded, color: _primaryColor, size: cardWidth * 0.08), // Responsive icon size
                  SizedBox(width: cardWidth * 0.02), // Responsive gap
                  Text(
                    'ID Token', // Extracted from HTML
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: cardWidth * 0.045, // Responsive font size
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: _accentColor.withAlpha((255 * 0.4).round()),
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
                width: cardWidth * 0.1, // Responsive width
                height: cardWidth * 0.1, // Responsive height
                child: SvgPicture.asset(
                  'assets/chip.svg',
                  colorFilter: ColorFilter.mode(_primaryColor, BlendMode.srcIn), // Color the SVG path with primary color
                ),
              ),
            ],
          ),
          SizedBox(height: cardHeight * 0.01), // Responsive vertical spacing
          // Photo area
          Container(
            width: cardWidth * 0.35, // Responsive photo size
            height: cardWidth * 0.35, // Responsive photo size
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryColor, width: cardWidth * 0.01), // Responsive border width
              image: const DecorationImage(
                image: AssetImage('assets/photo.jpg'), // User-provided image name
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withAlpha((255 * 0.4).round()),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          SizedBox(height: cardHeight * 0.015), // Responsive vertical spacing
          // Name
          Text(
            'Sarah Connor', // Extracted from HTML
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textColor,
              fontSize: cardWidth * 0.055, // Responsive font size
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: cardHeight * 0.005), // Responsive vertical spacing
          // Rank
          Text(
            'ID Document data', // Extracted from HTML
            style: TextStyle(
              color: _accentColor,
              fontSize: cardWidth * 0.04, // Responsive font size
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: cardHeight * 0.02), // Responsive vertical spacing
          // Data Grid
          Container(
            width: cardWidth * 0.9, // Make data grid responsive to card width
            padding: EdgeInsets.all(cardWidth * 0.02), // Responsive padding
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((255 * 0.03).round()),
              borderRadius: BorderRadius.circular(cardWidth * 0.02), // Responsive border radius
              border: Border(left: BorderSide(color: _accentColor, width: cardWidth * 0.008)), // Responsive border width
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Use min size for column
              children: [
                _buildDataGridRow('TYPE', 'P', cardWidth),
                _buildDataGridRow('ISSUER', 'USA', cardWidth),
                _buildDataGridRow('NATIONALITY', 'American', cardWidth),
                _buildDataGridRow('GENDER', 'F', cardWidth),
                _buildDataGridRow('BIRTH DATE', '12/2029', cardWidth),
                _buildDataGridRow('PLACE', 'Chicago', cardWidth),
                _buildDataGridRow('ISSUED', '2022-12-31', cardWidth),
                _buildDataGridRow('EXPIRES', '2030-12-22', cardWidth, isAccent: true), // #expiry-date
              ],
            ),
          ),
          SizedBox(height: cardHeight * 0.02), // Responsive vertical spacing
          Text(
            '>> 8473 9283 1102 <<', // Extracted from HTML
            style: TextStyle(
              color: _accentColor,
              fontSize: cardWidth * 0.045, // Responsive font size
              fontFamily: 'monospace', // Fallback for 'Courier New'
              letterSpacing: 2.0,
            ),
          ),
        ],
      );
    } else { // Landscape layout
      return Row(
        children: [
          // Left side: Photo and basic info
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: cardHeight * 0.35, // Responsive to card height
                  height: cardHeight * 0.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _primaryColor, width: cardHeight * 0.01),
                    image: const DecorationImage(
                      image: AssetImage('assets/photo.jpg'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withAlpha((255 * 0.4).round()),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: cardHeight * 0.02),
                Text(
                  'Sarah Connor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: _calculateFontSize(22, 1.2, cardWidth, cardHeight),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: cardHeight * 0.01),
                Text(
                  'ID Document data',
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: _calculateFontSize(16, 1.2, cardWidth, cardHeight),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Right side: Data grid
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ID Token', style: TextStyle(color: _primaryColor, fontSize: _calculateFontSize(18, 1.2, cardWidth, cardHeight), fontWeight: FontWeight.w700)),
                    SizedBox(
                      width: cardHeight * 0.1,
                      height: cardHeight * 0.1,
                      child: SvgPicture.asset('assets/chip.svg', colorFilter: ColorFilter.mode(_primaryColor, BlendMode.srcIn)),
                    ),
                  ],
                ),
                SizedBox(height: cardHeight * 0.02),
                Container(
                  padding: EdgeInsets.all(cardHeight * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.03).round()),
                    borderRadius: BorderRadius.circular(cardHeight * 0.02),
                    border: Border(left: BorderSide(color: _accentColor, width: cardHeight * 0.008)),
                  ),
                  child: Column(
                    children: [
                      _buildDataGridRow('TYPE', 'P', cardWidth),
                      _buildDataGridRow('ISSUER', 'USA', cardWidth),
                      _buildDataGridRow('NATIONALITY', 'American', cardWidth),
                      _buildDataGridRow('GENDER', 'F', cardWidth),
                      _buildDataGridRow('BIRTH DATE', '12/2029', cardWidth),
                      _buildDataGridRow('PLACE', 'Chicago', cardWidth),
                    ],
                  ),
                ),
                SizedBox(height: cardHeight * 0.02),
                Text(
                  '>> 8473 9283 1102 <<',
                  style: TextStyle(color: _accentColor, fontSize: _calculateFontSize(18, 1.2, cardWidth, cardHeight), fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildBackContent(double cardWidth, double cardHeight, Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR Code
          Container(
            width: cardWidth * 0.4, // Responsive width
            height: cardWidth * 0.4, // Responsive height
            padding: EdgeInsets.all(cardWidth * 0.015), // Responsive padding
            color: Colors.white, // background #fff
            child: Image.asset('assets/qr.png', fit: BoxFit.contain), // User-provided image name
          ),
          SizedBox(height: cardHeight * 0.02), // Responsive vertical spacing
          // Disclaimer Text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.03), // Responsive horizontal padding
            child: Column(
              children: [
                Text(
                  'BIOSEAL CODE', // Extracted from HTML
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _primaryColor, fontSize: cardWidth * 0.045, fontWeight: FontWeight.bold), // Responsive font size
                ),
                SizedBox(height: cardHeight * 0.01),
                                Text(
                                  'BioSeal Code provides secure multi-factor authentication for verifying identities and authenticating documents through its innovative integration of Visible Digital Seal\'s technology (VDS).', // Extracted from HTML
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: _textColor.withAlpha((255 * 0.7).round()), fontSize: cardWidth * 0.03), // Responsive font size
                                ),
                                SizedBox(height: cardHeight * 0.005),
                                Text(
                                  'It complies with ISO 22385 & 22376 standards.', // Extracted from HTML
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: _textColor.withAlpha((255 * 0.7).round()), fontSize: cardWidth * 0.03), // Responsive font size
                                ),            ],
            ),
          ),
          SizedBox(height: cardHeight * 0.02), // Responsive vertical spacing
          // Bottom Text
          Text(
            'ID3 TECHNOLOGIES', // Extracted from HTML
            style: TextStyle(color: _primaryColor, fontSize: cardWidth * 0.035), // Responsive font size
          ),
        ],
      );
    } else { // Landscape layout
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left side: QR Code
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: cardHeight * 0.4, // Responsive to card height
                  height: cardHeight * 0.4,
                  padding: EdgeInsets.all(cardHeight * 0.015),
                  color: Colors.white,
                  child: Image.asset('assets/qr.png', fit: BoxFit.contain),
                ),
              ],
            ),
          ),
          // Right side: Disclaimer text
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(cardHeight * 0.03),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'BIOSEAL CODE',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _primaryColor, fontSize: _calculateFontSize(18, 1.2, cardWidth, cardHeight), fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: cardHeight * 0.01),
                  Text(
                    'BioSeal Code provides secure multi-factor authentication for verifying identities and authenticating documents through its innovative integration of Visible Digital Seal\'s technology (VDS).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _textColor.withAlpha((255 * 0.7).round()), fontSize: _calculateFontSize(12, 1.2, cardWidth, cardHeight)),
                  ),
                  SizedBox(height: cardHeight * 0.005),
                  Text(
                    'It complies with ISO 22385 & 22376 standards.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _textColor.withAlpha((255 * 0.7).round()), fontSize: _calculateFontSize(12, 1.2, cardWidth, cardHeight)),
                  ),
                  SizedBox(height: cardHeight * 0.02),
                  Text(
                    'ID3 TECHNOLOGIES',
                    style: TextStyle(color: _primaryColor, fontSize: _calculateFontSize(14, 1.2, cardWidth, cardHeight)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildHologramEffect(double borderRadius) {
    // A more authentic holographic gradient with a rainbow sheen
    final holoSecurityGradient = LinearGradient(
      begin: Alignment(-1.0 - (_currentDx * 1.5), -1.0 - (_currentDy * 1.5)),
      end: Alignment(1.0 - (_currentDx * 1.5), 1.0 - (_currentDy * 1.5)),
      colors: [
        Colors.red.withOpacity(0.3),
        Colors.yellow.withOpacity(0.3),
        Colors.green.withOpacity(0.3),
        Colors.blue.withOpacity(0.3),
        Colors.indigo.withOpacity(0.3),
        Colors.purple.withOpacity(0.3),
        Colors.red.withOpacity(0.3),
      ],
      stops: const [0.0, 0.16, 0.33, 0.5, 0.66, 0.83, 1.0],
    );

    // SVG Data URLs for patterns
    const String patternHexSvg = """
      <svg width='40' height='70' viewBox='0 0 40 70' xmlns='http://www.w3.org/2000/svg'>
        <g fill='none' stroke='rgba(255, 255, 255, 0.2)' stroke-width='1'>
          <path d='M20 5 L35 15 L35 35 L20 45 L5 35 L5 15 Z' />
        </g>
      </svg>
    """;

    const String patternTextSvg = """
      <svg width='100' height='100' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'>
        <text x='50' y='50' font-family='Arial' font-weight='bold' font-size='12' fill='rgba(255,255,255,0.2)' text-anchor='middle' transform='rotate(-45 50 50)'>ID TOKEN</text>
      </svg>
    """;

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Opacity(
          opacity: _holoOpacity * 0.7, // Control the overall visibility
          child: ShaderMask(
            shaderCallback: (bounds) {
              return holoSecurityGradient.createShader(bounds);
            },
            blendMode: BlendMode.srcIn, // Apply the gradient to the patterns
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Pattern Layers
                Transform.translate(
                  offset: Offset(-_currentDx * 20, -_currentDy * 20),
                  child: Transform.scale(
                    scale: 3,
                    child: SvgPicture.string(
                      patternHexSvg,
                      fit: BoxFit.none,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(-_currentDx * 40, -_currentDy * 40),
                  child: Transform.scale(
                    scale: 4,
                    child: SvgPicture.string(
                      patternTextSvg,
                      fit: BoxFit.none,
                    ),
                  ),
                ),
                // Surface Glare
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.5),
                      ],
                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                    ),
                  ),
                ),
              ],
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