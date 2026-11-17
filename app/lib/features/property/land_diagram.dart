import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Schematic plot drawn with a double-headed arrow on each side and the net area in the middle.
class LandDiagram extends StatelessWidget {
  const LandDiagram({
    super.key,
    required this.northLabel,
    required this.southLabel,
    required this.eastLabel,
    required this.westLabel,
    required this.areaLabel,
  });

  final String northLabel;
  final String southLabel;
  final String eastLabel;
  final String westLabel;
  final String areaLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      label: '$northLabel, $southLabel, $eastLabel, $westLabel, $areaLabel',
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: CustomPaint(
          painter: _LandDiagramPainter(
            lineColor: colors.primary,
            fillColor: colors.primaryContainer,
            textStyle: theme.textTheme.bodySmall!
                .copyWith(color: colors.onSurfaceVariant),
            areaStyle: theme.textTheme.titleSmall!.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            northLabel: northLabel,
            southLabel: southLabel,
            eastLabel: eastLabel,
            westLabel: westLabel,
            areaLabel: areaLabel,
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class _LandDiagramPainter extends CustomPainter {
  _LandDiagramPainter({
    required this.lineColor,
    required this.fillColor,
    required this.textStyle,
    required this.areaStyle,
    required this.northLabel,
    required this.southLabel,
    required this.eastLabel,
    required this.westLabel,
    required this.areaLabel,
    required this.textDirection,
  });

  final Color lineColor;
  final Color fillColor;
  final TextStyle textStyle;
  final TextStyle areaStyle;
  final String northLabel;
  final String southLabel;
  final String eastLabel;
  final String westLabel;
  final String areaLabel;
  final TextDirection textDirection;

  static const double _sidePadding = 62;
  static const double _arrowInset = 24;
  static const double _verticalPadding = 54;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      _sidePadding,
      _verticalPadding,
      size.width - _sidePadding,
      size.height - _verticalPadding,
    );
    final rounded =
        RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rounded, Paint()..color = fillColor.withValues(alpha: 0.35));
    canvas.drawRRect(
      rounded,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final arrowPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    _arrow(
      canvas,
      arrowPaint,
      Offset(rect.left, 30),
      Offset(rect.right, 30),
      horizontal: true,
    );
    _arrow(
      canvas,
      arrowPaint,
      Offset(rect.left, size.height - 30),
      Offset(rect.right, size.height - 30),
      horizontal: true,
    );
    _arrow(
      canvas,
      arrowPaint,
      Offset(_arrowInset, rect.top),
      Offset(_arrowInset, rect.bottom),
      horizontal: false,
    );
    _arrow(
      canvas,
      arrowPaint,
      Offset(size.width - _arrowInset, rect.top),
      Offset(size.width - _arrowInset, rect.bottom),
      horizontal: false,
    );

    _horizontalText(canvas, northLabel, size.width / 2, 10, textStyle);
    _horizontalText(
      canvas,
      southLabel,
      size.width / 2,
      size.height - 28,
      textStyle,
    );
    _verticalText(canvas, westLabel, 14, rect.center.dy, textStyle);
    _verticalText(
      canvas,
      eastLabel,
      size.width - 14,
      rect.center.dy,
      textStyle,
    );
    _horizontalText(
      canvas,
      areaLabel,
      rect.center.dx,
      rect.center.dy - 9,
      areaStyle,
      maxWidth: rect.width - 16,
    );
  }

  void _arrow(
    Canvas canvas,
    Paint paint,
    Offset start,
    Offset end, {
    required bool horizontal,
  }) {
    canvas.drawLine(start, end, paint);
    const head = 6.0;
    if (horizontal) {
      canvas.drawLine(start, start + const Offset(head, -head), paint);
      canvas.drawLine(start, start + const Offset(head, head), paint);
      canvas.drawLine(end, end - const Offset(head, -head), paint);
      canvas.drawLine(end, end - const Offset(head, head), paint);
    } else {
      canvas.drawLine(start, start + const Offset(-head, head), paint);
      canvas.drawLine(start, start + const Offset(head, head), paint);
      canvas.drawLine(end, end - const Offset(-head, head), paint);
      canvas.drawLine(end, end - const Offset(head, head), paint);
    }
  }

  void _horizontalText(
    Canvas canvas,
    String text,
    double centerX,
    double top,
    TextStyle style, {
    double? maxWidth,
  }) {
    final painter = _layout(text, style, maxWidth ?? double.infinity);
    painter.paint(canvas, Offset(centerX - painter.width / 2, top));
  }

  void _verticalText(
    Canvas canvas,
    String text,
    double centerX,
    double centerY,
    TextStyle style,
  ) {
    final painter = _layout(text, style, double.infinity);
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(-math.pi / 2);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  TextPainter _layout(String text, TextStyle style, double maxWidth) =>
      TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: textDirection,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);

  @override
  bool shouldRepaint(covariant _LandDiagramPainter oldDelegate) =>
      oldDelegate.northLabel != northLabel ||
      oldDelegate.southLabel != southLabel ||
      oldDelegate.eastLabel != eastLabel ||
      oldDelegate.westLabel != westLabel ||
      oldDelegate.areaLabel != areaLabel ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.textStyle != textStyle ||
      oldDelegate.areaStyle != areaStyle ||
      oldDelegate.textDirection != textDirection;
}
