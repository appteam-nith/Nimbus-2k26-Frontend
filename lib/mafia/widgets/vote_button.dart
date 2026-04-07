import 'package:flutter/material.dart';

/// Stub vote button — actual vote submission logic is owned by Dev 4.
///
/// Dev 4 will replace the [onPressed] implementation.
/// Dev 5 uses this widget for layout in VotingScreen and NightScreen.
class VoteButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onPressed;
  final Color? accentColor;

  const VoteButton({
    super.key,
    required this.label,
    this.isSelected = false,
    this.isDisabled = false,
    this.onPressed,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? const Color(0xFF135BEC);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? color : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isDisabled
                        ? color.withValues(alpha: 0.35)
                        : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skip / abstain button variant
class SkipVoteButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDisabled;

  const SkipVoteButton({
    super.key,
    this.onPressed,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isDisabled ? null : onPressed,
      child: Text(
        'Skip / Abstain',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: const Color(0xFF9CA3AF).withValues(alpha: isDisabled ? 0.4 : 1),
        ),
      ),
    );
  }
}
