import 'package:flutter/material.dart';

/// Hexagonal badge logo for Nimbus City.
///
/// Clips [assets/game/NimbusCity/logo.jpeg] into a pointy-top hexagon shape
/// (vertex at top and bottom, flat edges on left and right) — matching the
/// orientation of the hexagonal badge artwork in the source image.
///
/// Usage:
///   NimbusCityLogo(size: 72)   // lobby hero header
///   NimbusCityLogo(size: 54)   // home screen game card
class NimbusCityLogo extends StatelessWidget {
  final double size;

  const NimbusCityLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipPath(
        clipper: _HexClipper(),
        child: Image.asset(
          'assets/game/NimbusCity/logo.jpeg',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Clips a rectangle into a pointy-top hexagon:
///
///        /\
///       /  \
///      |    |
///      |    |
///       \  /
///        \/
///
/// Vertices (as fractions of width × height):
///   (0.5, 0) → (1, 0.25) → (1, 0.75) → (0.5, 1) → (0, 0.75) → (0, 0.25)
class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(_HexClipper oldClipper) => false;
}
