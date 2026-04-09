import 'package:flutter/material.dart';

/// Nimbus City logo widget.
///
/// Displays [assets/game/NimbusCity/logo.png] directly — no clipping needed
/// since the PNG has a transparent background with the hexagonal badge shape
/// baked into the artwork itself.
///
/// Usage:
///   NimbusCityLogo(size: 72)   // lobby hero header
///   NimbusCityLogo(size: 54)   // home screen game card
class NimbusCityLogo extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const NimbusCityLogo({super.key, this.size = 72, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pushNamed(context, '/mafia/lobby'),
      child: Image.asset(
        'assets/game/NimbusCity/logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
