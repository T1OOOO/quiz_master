import 'dart:math' as math;

import 'package:flutter/material.dart';

const double historyPinTarget = 44;

typedef HistoryEventPin = ({
  double longitude,
  double latitude,
  String title,
  String kind,
});

class HistoryEventStyle {
  const HistoryEventStyle(this.ru, this.en, this.color, this.icon);
  final String ru, en;
  final Color color;
  final IconData icon;

  static HistoryEventStyle forKind(String kind) => switch (kind) {
    'war' => const HistoryEventStyle(
      'Война',
      'War',
      Color(0xff813b38),
      Icons.shield_outlined,
    ),
    'revolution' => const HistoryEventStyle(
      'Революция',
      'Revolution',
      Color(0xff883f56),
      Icons.campaign_outlined,
    ),
    'disaster' => const HistoryEventStyle(
      'Катастрофа',
      'Disaster',
      Color(0xff834a24),
      Icons.warning_amber_rounded,
    ),
    'epidemic' => const HistoryEventStyle(
      'Эпидемия',
      'Epidemic',
      Color(0xff6b4580),
      Icons.coronavirus_outlined,
    ),
    'health' => const HistoryEventStyle(
      'Здоровье',
      'Health',
      Color(0xff386e63),
      Icons.medical_services_outlined,
    ),
    'science' => const HistoryEventStyle(
      'Наука',
      'Science',
      Color(0xff235f85),
      Icons.science_outlined,
    ),
    'culture' => const HistoryEventStyle(
      'Культура',
      'Culture',
      Color(0xff87522a),
      Icons.theater_comedy_outlined,
    ),
    'independence' => const HistoryEventStyle(
      'Независимость',
      'Independence',
      Color(0xff306e55),
      Icons.outlined_flag,
    ),
    'treaty' => const HistoryEventStyle(
      'Договор',
      'Treaty',
      Color(0xff715231),
      Icons.history_edu_outlined,
    ),
    'exploration' => const HistoryEventStyle(
      'Исследования',
      'Exploration',
      Color(0xff246b75),
      Icons.explore_outlined,
    ),
    _ => const HistoryEventStyle(
      'Событие',
      'Event',
      Color(0xff3b5868),
      Icons.account_balance_outlined,
    ),
  };
}

class HistoryEventSeal extends StatelessWidget {
  const HistoryEventSeal(this.kind, {this.size = 38, super.key});
  final String kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = HistoryEventStyle.forKind(kind);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(style.color, Colors.white, .16)!, style.color],
        ),
        border: Border.all(color: const Color(0xffddc397), width: 1.15),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: kind == 'war'
              ? CustomPaint(
                  size: Size.square(size * .72),
                  painter: const _Cannon(),
                )
              : Icon(
                  style.icon,
                  size: size * .59,
                  color: const Color(0xfffff5df),
                ),
        ),
      ),
    );
  }
}

class _Cannon extends CustomPainter {
  const _Cannon();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 32, size.height / 32);
    final ink = Paint()
      ..color = const Color(0xfffff5df)
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(6, 16);
    canvas.rotate(-math.pi / 7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, -3, 22, 6),
        const Radius.circular(2),
      ),
      ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, -4.4, 3.5, 8.8),
        const Radius.circular(1),
      ),
      ink,
    );
    canvas.restore();
    ink.strokeWidth = 2.5;
    canvas.drawLine(const Offset(14, 18), const Offset(3, 26), ink);
    ink.style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(15, 22), 5.4, ink);
    ink.strokeWidth = 1.3;
    canvas.drawLine(const Offset(10, 22), const Offset(20, 22), ink);
    canvas.drawLine(const Offset(15, 17), const Offset(15, 27), ink);
  }

  @override
  bool shouldRepaint(_Cannon oldDelegate) => false;
}

Widget historyPinWidget(HistoryEventPin pin, VoidCallback onTap) => Semantics(
  button: true,
  label: pin.title,
  child: Tooltip(
    message: pin.title,
    excludeFromSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(child: HistoryEventSeal(pin.kind, size: 29)),
    ),
  ),
);
