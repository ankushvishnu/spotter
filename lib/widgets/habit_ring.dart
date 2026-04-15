import 'dart:math';
import 'package:flutter/material.dart';

class HabitRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final IconData icon;
  final Color baseColor;
  final String label;

  const HabitRing({
    super.key,
    required this.progress,
    required this.icon,
    required this.baseColor,
    required this.label,
  });

  @override
  State<HabitRing> createState() => _HabitRingState();
}

class _HabitRingState extends State<HabitRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant HabitRing oldWidget) {
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(begin: oldWidget.progress, end: widget.progress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(70, 70),
                    painter: _RingPainter(
                      progress: _animation.value,
                      ringColor: widget.baseColor,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.progress >= 1.0 
                          ? widget.baseColor.withValues(alpha: 0.2)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      widget.progress >= 1.0 ? Icons.check_rounded : widget.icon,
                      color: widget.progress >= 1.0 ? Colors.white : widget.baseColor,
                      size: 24,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color backgroundColor;

  _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc with glowing shadow
    final progressPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4); // Organic glow

    final shadowPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final sweepAngle = 2 * pi * progress;
    const startAngle = -pi / 2;

    // Draw shadow/glow
    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, shadowPaint);
    }
    // Draw actual ring
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ringColor != ringColor;
  }
}

