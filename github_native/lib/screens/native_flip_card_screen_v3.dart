import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

// New CustomPainter class for drawing the hologram patterns
class HologramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Replicating the repeating-linear-gradient for the grid pattern on the front face
    final gridPaint = Paint()
      ..color = const Color(0xFF00F2FF).withOpacity(0.03)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Replicating .pattern-hex
    final hexPaint = Paint()
      ..color = const Color(0xFF00F2FF).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final hexPath = Path();
    for (double y = -35; y < size.height + 35; y += 70) {
      for (double x = -20; x < size.width + 20; x += 40) {
        hexPath.moveTo(x + 20, y + 5);
        hexPath.lineTo(x + 35, y + 15);
        hexPath.lineTo(x + 35, y + 35);
        hexPath.lineTo(x + 20, y + 45);
        hexPath.lineTo(x + 5, y + 35);
        hexPath.lineTo(x + 5, y + 15);
        hexPath.close();
      }
    }
    canvas.drawPath(hexPath, hexPaint);

    // Replicating .pattern-text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'ID TOKEN',
        style: TextStyle(
          fontFamily: 'Arial',
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    for (double y = -50; y < size.height + 50; y += 80) {
      for (double x = -50; x < size.width + 50; x += 80) {
        canvas.save();
        canvas.translate(x + 50, y + 50);
        canvas.rotate(-math.pi / 4);
        textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class NativeFlipCardScreenV3 extends StatefulWidget {
  final String fileName;

  const NativeFlipCardScreenV3({super.key, required this.fileName});

  @override
  State<NativeFlipCardScreenV3> createState() => _NativeFlipCardScreenV3State();
}

class _NativeFlipCardScreenV3State extends State<NativeFlipCardScreenV3> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;

  static const Color _primaryColor = Color(0xFF00D084);
  static const Color _secondaryColor = Color(0xFF0A1128);
  static const Color _accentColor = Color(0xFF00F2FF);
  static const Color _textColor = Color(0xFFE0F7FA);
  static const Color _darkGreyColor = Color(0xFF05050A);

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
      _handleAccelerometer(event);
    });
  }

  void _handleAccelerometer(AccelerometerEvent event) {
    double g = event.x / 5.0;
    double b = event.y / 5.0;

    g = g.clamp(-1.0, 1.0);
    b = b.clamp(-1.0, 1.0);

    final currentOrientation = MediaQuery.of(context).orientation;
    double rawDx = 0, rawDy = 0;

    if (currentOrientation == Orientation.portrait) {
      rawDx = g;
      rawDy = b;
    } else {
      rawDx = b;
      rawDy = -g;
    }

    _filteredDx = _filteredDx * (1 - _gyroFilterFactor) + rawDx * _gyroFilterFactor;
    _filteredDy = _filteredDy * (1 - _gyroFilterFactor) + rawDy * _gyroFilterFactor;

    double normalizedDx = _filteredDx;
    double normalizedDy = _filteredDy;

    final double diffX = (normalizedDx - _currentDx).abs();
    final double diffY = (normalizedDy - _currentDy).abs();
    double movementSpeed = diffX + diffY;

    if (movementSpeed < _speedThreshold) {
      movementSpeed = 0;
    } else {
      movementSpeed = movementSpeed - _speedThreshold;
    }

    _targetDx = normalizedDx;
    _targetDy = normalizedDy;
    _targetHoloOpacity = math.min(1.0, movementSpeed * _movementSensitivity);

    _updateHologramAnimation();
  }

  void _updateHologramAnimation() {
    setState(() {
      _currentDx += (_targetDx - _currentDx) * 0.1;
      _currentDy += (_targetDy - _currentDy) * 0.1;
      _holoOpacity += (_targetHoloOpacity - _holoOpacity) * 0.05;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double cardHeight;
    double cardWidth;
    double borderRadius;
    double padding;

    if (screenHeight < 500 && screenWidth > screenHeight) {
      cardWidth = screenWidth * 0.75;
      cardHeight = cardWidth / 1.58;
      borderRadius = cardWidth * 0.02;
      padding = cardWidth * 0.03;
    } else {
      cardHeight = math.min(screenWidth * 1.36, screenHeight * 0.80);
      cardWidth = cardHeight * 0.625;
      borderRadius = screenWidth * 0.04;
      padding = screenWidth * 0.05;
    }

    cardWidth = math.max(300, math.min(cardWidth, screenWidth * 0.9));
    cardHeight = math.max(480, math.min(cardHeight, screenHeight * 0.9));
    borderRadius = math.max(8, math.min(borderRadius, 18));
    padding = math.max(15, math.min(padding, 24));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: _secondaryColor,
        foregroundColor: _textColor,
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Container(
            color: _darkGreyColor,
            child: Center(
              child: GestureDetector(
                onTap: _handleFlip,
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * math.pi;
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle);

                    return Transform(
                      transform: transform,
                      alignment: Alignment.center,
                      child: Stack(
                        children: [
                          _buildCardFace(
                            isFront: false,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            cardWidth: cardWidth,
                            cardHeight: cardHeight,
                            borderRadius: borderRadius,
                            padding: padding,
                            orientation: orientation,
                          ),
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
            border: Border.all(color: _accentColor.withOpacity(0.2), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: _accentColor.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isFront) _buildFrontBackground(),
              _buildHologramEffect(borderRadius),
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
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _secondaryColor.withOpacity(0.98),
              _darkGreyColor,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildHologramEffect(double borderRadius) {
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

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Opacity(
          opacity: _holoOpacity * 0.7,
          child: ShaderMask(
            shaderCallback: (bounds) {
              return holoSecurityGradient.createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: CustomPaint(
              painter: HologramPainter(),
              child: Container(),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateFontSize(double baseSize, double scaleFactor, double cardWidth, double cardHeight) {
    double scale = (cardWidth + cardHeight) / 1000;
    double fontSize = baseSize * scale * scaleFactor;
    return fontSize.clamp(8.0, baseSize);
  }

  Widget _buildFrontContent(double cardWidth, double cardHeight, Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.vpn_key_rounded, color: _primaryColor, size: cardWidth * 0.08),
                  SizedBox(width: cardWidth * 0.02),
                  Text(
                    'ID Token',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: cardWidth * 0.045,
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
              SizedBox(
                width: cardWidth * 0.1,
                height: cardWidth * 0.1,
                child: SvgPicture.asset(
                  'assets/chip.svg',
                  colorFilter: ColorFilter.mode(_primaryColor, BlendMode.srcIn),
                ),
              ),
            ],
          ),
          SizedBox(height: cardHeight * 0.01),
          Container(
            width: cardWidth * 0.35,
            height: cardWidth * 0.35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryColor, width: cardWidth * 0.01),
              image: const DecorationImage(
                image: AssetImage('assets/photo.jpg'),
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
          ),
          SizedBox(height: cardHeight * 0.015),
          Text(
            'Sarah Connor',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textColor,
              fontSize: cardWidth * 0.055,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: cardHeight * 0.005),
          Text(
            'ID Document data',
            style: TextStyle(
              color: _accentColor,
              fontSize: cardWidth * 0.04,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: cardHeight * 0.02),
          Container(
            width: cardWidth * 0.9,
            padding: EdgeInsets.all(cardWidth * 0.02),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(cardWidth * 0.02),
              border: Border(left: BorderSide(color: _accentColor, width: cardWidth * 0.008)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDataGridRow('TYPE', 'P', cardWidth),
                _buildDataGridRow('ISSUER', 'USA', cardWidth),
                _buildDataGridRow('NATIONALITY', 'American', cardWidth),
                _buildDataGridRow('GENDER', 'F', cardWidth),
                _buildDataGridRow('BIRTH DATE', '12/2029', cardWidth),
                _buildDataGridRow('PLACE', 'Chicago', cardWidth),
                _buildDataGridRow('ISSUED', '2022-12-31', cardWidth),
                _buildDataGridRow('EXPIRES', '2030-12-22', cardWidth, isAccent: true),
              ],
            ),
          ),
          SizedBox(height: cardHeight * 0.02),
          Text(
            '>> 8473 9283 1102 <<',
            style: TextStyle(
              color: _accentColor,
              fontSize: cardWidth * 0.045,
              fontFamily: 'monospace',
              letterSpacing: 2.0,
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: cardHeight * 0.35,
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
                        color: _primaryColor.withOpacity(0.4),
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
                    color: Colors.white.withOpacity(0.03),
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
          Container(
            width: cardWidth * 0.4,
            height: cardWidth * 0.4,
            padding: EdgeInsets.all(cardWidth * 0.015),
            color: Colors.white,
            child: Image.asset('assets/qr.png', fit: BoxFit.contain),
          ),
          SizedBox(height: cardHeight * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.03),
            child: Column(
              children: [
                Text(
                  'BIOSEAL CODE',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _primaryColor, fontSize: cardWidth * 0.045, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: cardHeight * 0.01),
                Text(
                  'BioSeal Code provides secure multi-factor authentication for verifying identities and authenticating documents through its innovative integration of Visible Digital Seal\'s technology (VDS).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: cardWidth * 0.03),
                ),
                SizedBox(height: cardHeight * 0.005),
                Text(
                  'It complies with ISO 22385 & 22376 standards.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: cardWidth * 0.03),
                ),
              ],
            ),
          ),
          SizedBox(height: cardHeight * 0.02),
          Text(
            'ID3 TECHNOLOGIES',
            style: TextStyle(color: _primaryColor, fontSize: cardWidth * 0.035),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: cardHeight * 0.4,
                  height: cardHeight * 0.4,
                  padding: EdgeInsets.all(cardHeight * 0.015),
                  color: Colors.white,
                  child: Image.asset('assets/qr.png', fit: BoxFit.contain),
                ),
              ],
            ),
          ),
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
                    style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: _calculateFontSize(12, 1.2, cardWidth, cardHeight)),
                  ),
                  SizedBox(height: cardHeight * 0.005),
                  Text(
                    'It complies with ISO 22385 & 22376 standards.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: _calculateFontSize(12, 1.2, cardWidth, cardHeight)),
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

  Widget _buildDataGridRow(String label, String value, double cardWidth, {bool isAccent = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: cardWidth * 0.008),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: cardWidth * 0.035)),
          Text(
            value,
            style: TextStyle(
              color: isAccent ? _accentColor : Colors.white,
              fontSize: cardWidth * 0.035,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}