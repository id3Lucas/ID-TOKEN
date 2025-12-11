import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/native_id_card_front.dart';
import '../widgets/native_id_card_back.dart';

class NativeFlipCardScreen extends StatefulWidget {
  final String fileName;

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
            border: Border.all(color: _accentColor.withValues(alpha: 0.2), width: 1.0), // 1px solid rgba(0, 242, 255, 0.2)
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5), // 0 10px 20px rgba(0, 0, 0, 0.5)
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: _accentColor.withValues(alpha: 0.1), // 0 0 15px rgba(0, 242, 255, 0.1)
                blurRadius: 15,
                spreadRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Content (Text, Image etc.)
              if (isFront)
                NativeIDCardFront(
                  cardWidth: cardWidth,
                  cardHeight: cardHeight,
                  orientation: orientation,
                  primaryColor: _primaryColor,
                  secondaryColor: _secondaryColor,
                  accentColor: _accentColor,
                  textColor: _textColor,
                  darkGreyColor: _darkGreyColor,
                )
              else
                NativeIDCardBack(
                  cardWidth: cardWidth,
                  cardHeight: cardHeight,
                  orientation: orientation,
                  primaryColor: _primaryColor,
                  textColor: _textColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}