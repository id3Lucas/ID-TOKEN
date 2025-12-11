import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:github_native/widgets/hologram_overlay.dart';


class NativeIDCardFront extends StatelessWidget {
  final double cardWidth;
  final double cardHeight;
  final Orientation orientation;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color textColor;
  final Color darkGreyColor;

  const NativeIDCardFront({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    required this.orientation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.textColor,
    required this.darkGreyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildFrontBackground(),
        // Add hologram effect overlay
        const Positioned.fill(
          child: HologramOverlay(),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(orientation == Orientation.landscape ? cardWidth * 0.03 : _responsivePadding()), 
            // Note: Padding logic was slightly simplified; passed padding logic might be better but this works.
            // Using calculated padding based on extracted logic:
            child: _buildFrontContent(),
          ),
        ),
      ],
    );
  }

  double _responsivePadding() {
    // Replicating the logic from the main screen for padding if needed, 
    // or we can accept it as a parameter. For now, calculating commonly.
    // simplified:
    return cardWidth * 0.05; 
  }

  Widget _buildFrontBackground() {
    final baseGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        secondaryColor.withValues(alpha: 0.98),
        darkGreyColor,
      ],
      stops: const [0.0, 1.0],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: baseGradient,
      ),
    );
  }

  Widget _buildFrontContent() {
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
                  Icon(Icons.vpn_key_rounded, color: primaryColor, size: cardWidth * 0.08),
                  SizedBox(width: cardWidth * 0.02),
                  Text(
                    'ID Token',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: cardWidth * 0.045,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Chip
              SizedBox(
                width: cardWidth * 0.1,
                height: cardWidth * 0.1,
                child: SvgPicture.asset(
                  'assets/chip.svg',
                  colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
                ),
              ),
            ],
          ),
          SizedBox(height: cardHeight * 0.01),
          // Photo area
          Container(
            width: cardWidth * 0.35,
            height: cardWidth * 0.35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: cardWidth * 0.01),
              image: const DecorationImage(
                image: AssetImage('assets/photo.jpg'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          SizedBox(height: cardHeight * 0.015),
          // Name
          Text(
            'Sarah Connor',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: cardWidth * 0.055,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: cardHeight * 0.005),
          // Rank
          Text(
            'ID Document data',
            style: TextStyle(
              color: accentColor,
              fontSize: cardWidth * 0.04,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: cardHeight * 0.02),
          // Data Grid
          Container(
            width: cardWidth * 0.9,
            padding: EdgeInsets.all(cardWidth * 0.02),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(cardWidth * 0.02),
              border: Border(left: BorderSide(color: accentColor, width: cardWidth * 0.008)),
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
              color: accentColor,
              fontSize: cardWidth * 0.045,
              fontFamily: 'monospace',
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
                  width: cardHeight * 0.35,
                  height: cardHeight * 0.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: cardHeight * 0.01),
                    image: const DecorationImage(
                      image: AssetImage('assets/photo.jpg'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
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
                    color: textColor,
                    fontSize: _calculateFontSize(22, 1.2),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: cardHeight * 0.01),
                Text(
                  'ID Document data',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: _calculateFontSize(16, 1.2),
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
                    Text('ID Token', style: TextStyle(color: primaryColor, fontSize: _calculateFontSize(18, 1.2), fontWeight: FontWeight.w700)),
                    SizedBox(
                      width: cardHeight * 0.1,
                      height: cardHeight * 0.1,
                      child: SvgPicture.asset('assets/chip.svg', colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn)),
                    ),
                  ],
                ),
                SizedBox(height: cardHeight * 0.02),
                Container(
                  padding: EdgeInsets.all(cardHeight * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(cardHeight * 0.02),
                    border: Border(left: BorderSide(color: accentColor, width: cardHeight * 0.008)),
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
                  style: TextStyle(color: accentColor, fontSize: _calculateFontSize(18, 1.2), fontFamily: 'monospace'),
                ),
              ],
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
          Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: cardWidth * 0.035)),
          Text(
            value,
            style: TextStyle(
              color: isAccent ? accentColor : Colors.white,
              fontSize: cardWidth * 0.035,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateFontSize(double baseSize, double scaleFactor) {
    double scale = (cardWidth + cardHeight) / 1000;
    double fontSize = baseSize * scale * scaleFactor;
    return fontSize.clamp(8.0, baseSize);
  }
}
