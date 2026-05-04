import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

/// Springy gradient CTA button with haptic feedback and
/// smooth press-scale animation — Instagram/Snapchat feel.
class GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final IconData? icon;
  final Gradient? gradient;
  final double height;
  final double? width;
  final double fontSize;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.icon,
    this.gradient,
    this.height = 52,
    this.width,
    this.fontSize = 15,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onPressed == null) return;
    _ctrl.reverse();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(_) => _ctrl.forward();
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final grad = widget.gradient ?? AppColors.primaryGradient;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: enabled ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: enabled ? grad : null,
            color: enabled ? null : AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: enabled ? AppShadows.button : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 17),
                        const SizedBox(width: 7),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: enabled ? Colors.white : AppColors.textLight,
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Compact pill-shaped secondary button (outline style)
class OutlineButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final Color? color;

  const OutlineButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: c, width: 1.5),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: c, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
