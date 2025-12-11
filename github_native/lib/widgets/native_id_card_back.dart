import 'package:flutter/material.dart';

class NativeIDCardBack extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  final Orientation orientation;
  final Color primaryColor;
  final Color textColor;

  const NativeIDCardBack({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    required this.orientation,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
     return Padding(
        padding: EdgeInsets.all(orientation == Orientation.landscape ? cardWidth * 0.03 : cardWidth * 0.05),
        child: _buildBackContent(),
    );
  }

  double _calculateFontSize(double baseSize, double scaleFactor) {
    double scale = (cardWidth + cardHeight) / 1000;
    double fontSize = baseSize * scale * scaleFactor;
    return fontSize.clamp(8.0, baseSize);
  }

  Widget _buildBackContent() {
    if (orientation == Orientation.portrait) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR Code
          Container(
            width: cardWidth * 0.4,
            height: cardWidth * 0.4,
            padding: EdgeInsets.all(cardWidth * 0.015),
            color: Colors.white,
            child: Image.asset('assets/qr.png', fit: BoxFit.contain),
          ),
          SizedBox(height: cardHeight * 0.02),
          // Disclaimer Text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.03),
            child: Column(
              children: [
                Text(
                  'BIOSEAL CODE',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: primaryColor, fontSize: cardWidth * 0.045, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: cardHeight * 0.01),
                Text(
                  'BioSeal Code provides secure multi-factor authentication for verifying identities and authenticating documents through its innovative integration of Visible Digital Seal\'s technology (VDS).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: cardWidth * 0.03),
                ),
                SizedBox(height: cardHeight * 0.005),
                Text(
                  'It complies with ISO 22385 & 22376 standards.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: cardWidth * 0.03),
                ),
              ],
            ),
          ),
          SizedBox(height: cardHeight * 0.02),
          // Bottom Text
          Text(
            'ID3 TECHNOLOGIES',
            style: TextStyle(color: primaryColor, fontSize: cardWidth * 0.035),
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
                  width: cardHeight * 0.4,
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
                    style: TextStyle(color: primaryColor, fontSize: _calculateFontSize(18, 1.2), fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: cardHeight * 0.01),
                  Text(
                    'BioSeal Code provides secure multi-factor authentication for verifying identities and authenticating documents through its innovative integration of Visible Digital Seal\'s technology (VDS).',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: _calculateFontSize(12, 1.2)),
                  ),
                  SizedBox(height: cardHeight * 0.005),
                  Text(
                    'It complies with ISO 22385 & 22376 standards.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: _calculateFontSize(12, 1.2)),
                  ),
                  SizedBox(height: cardHeight * 0.02),
                  Text(
                    'ID3 TECHNOLOGIES',
                    style: TextStyle(color: primaryColor, fontSize: _calculateFontSize(14, 1.2)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }
}
