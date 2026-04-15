import 'dart:math' as math;
import 'package:flutter/material.dart';

class DynamicMeshBackground extends StatefulWidget {
  final Widget child;

  const DynamicMeshBackground({super.key, required this.child});

  @override
  State<DynamicMeshBackground> createState() => _DynamicMeshBackgroundState();
}

class _DynamicMeshBackgroundState extends State<DynamicMeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 20-second loop for a very slow, organic movement
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Spotter JSX Theme Colors (Orange, Violet, Gold)
  List<Color> _getThemeColors() {
    return const [
      Color(0xFFFF5C1A), // Orange
      Color(0xFF8B3DFF), // Violet
      Color(0xFFF5C842), // Gold
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getThemeColors();
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Base dark background
        Container(
          color: const Color(0xFF050510),
        ),
        
        // Animated Mesh Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                _buildBlob(
                  colors[0],
                  top: size.height * 0.1 + math.sin(_controller.value * 2 * math.pi) * 100,
                  left: size.width * 0.1 + math.cos(_controller.value * 2 * math.pi) * 50,
                  radius: size.width * 0.8,
                ),
                _buildBlob(
                  colors[1],
                  bottom: size.height * 0.2 + math.cos(_controller.value * 2 * math.pi + math.pi/2) * 80,
                  right: -50 + math.sin(_controller.value * 2 * math.pi + math.pi/2) * 80,
                  radius: size.width * 0.9,
                ),
                _buildBlob(
                  colors[2],
                  top: size.height * 0.4 + math.sin(_controller.value * 2 * math.pi + math.pi) * 120,
                  left: size.width * 0.3 + math.cos(_controller.value * 2 * math.pi + math.pi) * 90,
                  radius: size.width * 0.7,
                  opacity: 0.6,
                ),
              ],
            );
          },
        ),

        // Foreground content
        Positioned.fill(child: widget.child),
      ],
    );
  }

  Widget _buildBlob(Color color,
      {double? top, double? bottom, double? left, double? right, required double radius, double opacity = 0.4}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

