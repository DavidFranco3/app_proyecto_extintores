import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum PremiumButtonStyle { primary, secondary, danger }

class PremiumActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final List<Color>? gradientColors;
  final bool isFullWidth;
  final bool isLoading;
  final PremiumButtonStyle style;

  final bool iconRight;

  const PremiumActionButton({
    super.key,
    this.onPressed,
    required this.label,
    required this.icon,
    this.gradientColors,
    this.isFullWidth = false,
    this.isLoading = false,
    this.style = PremiumButtonStyle.primary,
    this.iconRight = false,
  });

  List<Color> _getGradientColors() {
    if (onPressed == null && !isLoading) {
      return [const Color(0xFFBDC3C7), const Color(0xFF95A5A6)];
    }
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
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: iconRight
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
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
                else if (!iconRight) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isLoading && iconRight) ...[
                  const SizedBox(width: 10),
                  Icon(icon, color: Colors.white, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return buttonContent;
  }
}

class PremiumTableActions extends StatelessWidget {
  final List<PopupMenuEntry<String>> items;
  final Function(String) onSelected;

  const PremiumTableActions({
    super.key,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const gradientColors = [Color(0xFF2C3E50), Color(0xFFE94742)];

    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 45),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const FaIcon(
          FontAwesomeIcons.ellipsisVertical,
          size: 16,
          color: Colors.white,
        ),
      ),
      itemBuilder: (context) => items,
    );
  }
}
