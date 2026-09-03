import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class MapPin extends StatelessWidget {
  const MapPin({required this.isSelected, super.key});

  static const double width = 34;
  static const double height = 44;

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(width, height),
      painter: _PinPainter(
        color: isSelected ? AppTheme.favorite : AppTheme.star,
        ringColor: isSelected ? Colors.white : Colors.white70,
      ),
    );
  }
}

class MapDot extends StatelessWidget {
  const MapDot({super.key});

  static const double size = 14;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.seedColor.withValues(alpha: 0.75),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white70, width: 1.5),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  const _PinPainter({required this.color, required this.ringColor});

  final Color color;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final centre = Offset(radius, radius);

    final tail = Path()
      ..moveTo(radius * 0.42, size.height * 0.66)
      ..lineTo(radius, size.height)
      ..lineTo(size.width - radius * 0.42, size.height * 0.66)
      ..close();

    canvas.drawShadow(
      Path()
        ..addOval(Rect.fromCircle(center: centre, radius: radius))
        ..addPath(tail, Offset.zero),
      Colors.black45,
      2,
      true,
    );

    final fill = Paint()..color = color;
    canvas.drawPath(tail, fill);
    canvas.drawCircle(centre, radius, fill);

    canvas.drawCircle(centre, radius * 0.32, Paint()..color = ringColor);
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.ringColor != ringColor;
  }
}
