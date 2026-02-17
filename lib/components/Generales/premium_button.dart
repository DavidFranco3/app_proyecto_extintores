import 'package:flutter/material.dart';

enum PremiumButtonStyle { primary, secondary, danger }

class PremiumActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final List<Color>? gradientColors;
  final bool isFullWidth;
  final bool isLoading;
  final PremiumButtonStyle style;

  const PremiumActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.gradientColors,
    this.isFullWidth = false,
    this.isLoading = false,
    this.style = PremiumButtonStyle.primary,
  });

  List<Color> _getGradientColors() {
    if (gradientColors != null) return gradientColors!;
    switch (style) {
      case PremiumButtonStyle.secondary:
        return [const Color(0xFFBDC3C7), const Color(0xFF95A5A6)];
      case PremiumButtonStyle.danger:
        return [const Color(0xFFE74C3C), const Color(0xFFC0392B)];
      case PremiumButtonStyle.primary:
        return [const Color(0xFF2C3E50), const Color(0xFFE94742)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getGradientColors();

    Widget buttonContent = Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return isFullWidth ? buttonContent : buttonContent;
  }
}
