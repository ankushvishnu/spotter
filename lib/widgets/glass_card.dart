import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final double blurAmount;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 24.0, // Squircles/organic flow
    this.blurAmount = 20.0,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardChild = Container(
      width: width,
      height: height == double.infinity ? null : height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03), // Very subtle white tint
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1), // Thin glass edge
          width: 1.0,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.01),
          ],
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      cardChild = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: Colors.white.withValues(alpha: 0.1),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: cardChild,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: cardChild,
      ),
    );
  }
}

