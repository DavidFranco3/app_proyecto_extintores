import 'package:flutter/material.dart';

class PremiumInputs {
  // Corporative Colors
  static const Color redCorporate = Color(0xFFE94742);
  static const Color deepBlue = Color(0xFF2C3E50);

  static InputDecoration decoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: deepBlue.withValues(alpha: 0.6), size: 20)
          : null,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(
        color: deepBlue.withValues(alpha: 0.7),
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: redCorporate,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: redCorporate, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
    );
  }
}

class PremiumCardField extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const PremiumCardField({
    super.key,
    required this.child,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PremiumSectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;

  const PremiumSectionTitle({
    super.key,
    required this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: const Color(0xFFE94742)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
