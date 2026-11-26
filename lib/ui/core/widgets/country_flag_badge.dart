import 'package:flutter/material.dart';

/// Crisp, cross-platform vector country flag badge (avoids missing emoji glyphs
/// on desktop/test renderers and looks uniform across iOS and Android).
class CountryFlagBadge extends StatelessWidget {
  const CountryFlagBadge({
    super.key,
    required this.countryCode,
    this.size = 44,
  });

  final String countryCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final code = countryCode.toUpperCase();

    if (code == 'AUTO' || code.length != 2) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Icon(
          Icons.public_rounded,
          color: colors.primary,
          size: size * 0.56,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.14),
        child: CustomPaint(
          painter: _FlagPainter(code),
          size: Size.square(size * 0.72),
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter(this.code);
  final String code;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..isAntiAlias = true;

    switch (code) {
      case 'NL': // Netherlands: Red / White / Blue horizontal
        paint.color = const Color(0xFFAE1C28);
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h / 3), paint);
        paint.color = Colors.white;
        canvas.drawRect(Rect.fromLTWH(0, h / 3, w, h / 3), paint);
        paint.color = const Color(0xFF21468B);
        canvas.drawRect(Rect.fromLTWH(0, 2 * h / 3, w, h / 3), paint);

      case 'DE': // Germany: Black / Red / Gold horizontal
        paint.color = const Color(0xFF111111);
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h / 3), paint);
        paint.color = const Color(0xFFDD0000);
        canvas.drawRect(Rect.fromLTWH(0, h / 3, w, h / 3), paint);
        paint.color = const Color(0xFFFFCE00);
        canvas.drawRect(Rect.fromLTWH(0, 2 * h / 3, w, h / 3), paint);

      case 'FI': // Finland: White with blue Nordic cross
        paint.color = Colors.white;
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
        paint.color = const Color(0xFF003580);
        canvas.drawRect(Rect.fromLTWH(0, h * 0.38, w, h * 0.24), paint);
        canvas.drawRect(Rect.fromLTWH(w * 0.28, 0, w * 0.22, h), paint);

      case 'GB': // United Kingdom: Simplified crisp Union Jack
        paint.color = const Color(0xFF012169);
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
        paint
          ..color = Colors.white
          ..strokeWidth = h * 0.16;
        canvas.drawLine(Offset.zero, Offset(w, h), paint);
        canvas.drawLine(Offset(w, 0), Offset(0, h), paint);
        paint
          ..color = const Color(0xFFC8102E)
          ..strokeWidth = h * 0.08;
        canvas.drawLine(Offset.zero, Offset(w, h), paint);
        canvas.drawLine(Offset(w, 0), Offset(0, h), paint);
        paint.color = Colors.white;
        canvas.drawRect(Rect.fromLTWH(0, h * 0.36, w, h * 0.28), paint);
        canvas.drawRect(Rect.fromLTWH(w * 0.38, 0, w * 0.24, h), paint);
        paint.color = const Color(0xFFC8102E);
        canvas.drawRect(Rect.fromLTWH(0, h * 0.42, w, h * 0.16), paint);
        canvas.drawRect(Rect.fromLTWH(w * 0.43, 0, w * 0.14, h), paint);

      case 'US': // United States: Red/white stripes + blue canton
        final stripeH = h / 7;
        for (int i = 0; i < 7; i++) {
          paint.color = i.isEven ? const Color(0xFFB22234) : Colors.white;
          canvas.drawRect(Rect.fromLTWH(0, i * stripeH, w, stripeH), paint);
        }
        paint.color = const Color(0xFF3C3B6E);
        canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.46, stripeH * 4), paint);

      case 'SG': // Singapore: Red over White + white crescent dot
        paint.color = const Color(0xFFEF3340);
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h / 2), paint);
        paint.color = Colors.white;
        canvas.drawRect(Rect.fromLTWH(0, h / 2, w, h / 2), paint);
        canvas.drawCircle(Offset(w * 0.28, h * 0.25), h * 0.14, paint);
        paint.color = const Color(0xFFEF3340);
        canvas.drawCircle(Offset(w * 0.33, h * 0.25), h * 0.12, paint);

      case 'JP': // Japan: White with crimson sun
        paint.color = Colors.white;
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
        paint.color = const Color(0xFFBC002D);
        canvas.drawCircle(Offset(w / 2, h / 2), h * 0.28, paint);

      default:
        paint.color = const Color(0xFF10D978);
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) =>
      oldDelegate.code != code;
}
