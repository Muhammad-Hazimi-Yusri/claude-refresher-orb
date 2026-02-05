import 'dart:math' as math;
import 'package:flutter/material.dart';

class UsageCircle extends StatelessWidget {
  final double percentage;
  final bool isLoading;

  const UsageCircle({super.key, required this.percentage, this.isLoading = false});

  Color get _color {
    if (percentage < 50) return Colors.green;
    if (percentage < 80) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(200, 200),
            painter: _CirclePainter(percentage: 100, color: Colors.grey.withOpacity(0.2), strokeWidth: 16),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                size: const Size(200, 200),
                painter: _CirclePainter(percentage: value, color: _color, strokeWidth: 16),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const CircularProgressIndicator()
              else ...[
                Text('${percentage.round()}%', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _color)),
                Text('Used', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;

  _CirclePainter({required this.percentage, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = (percentage / 100) * 2 * math.pi;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) =>
      oldDelegate.percentage != percentage || oldDelegate.color != color;
}
