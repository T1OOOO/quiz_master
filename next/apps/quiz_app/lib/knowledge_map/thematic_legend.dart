import 'package:flutter/material.dart';

class ThematicLegend extends StatelessWidget {
  const ThematicLegend({
    super.key,
    required this.mode,
    required this.russian,
    required this.onClear,
  });

  final String mode;
  final bool russian;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final numeric = mode == 'population' || mode == 'area';
    final title = mode == 'population'
        ? (russian ? 'Население' : 'Population')
        : mode == 'area'
        ? (russian ? 'Площадь' : 'Area')
        : mode == 'capital'
        ? (russian ? 'Столицы' : 'Capitals')
        : (russian ? 'Блюда' : 'Dishes');
    final unit = mode == 'population'
        ? (russian ? 'чел.' : 'people')
        : mode == 'area'
        ? (russian ? 'км²' : 'km²')
        : (russian ? 'подписи на карте' : 'map labels');
    final colors = mode == 'population'
        ? const [
            Color(0xffeef7f5),
            Color(0xffcce9e1),
            Color(0xff8dcbbb),
            Color(0xff4a9c88),
            Color(0xff216556),
          ]
        : const [
            Color(0xfff8f2e5),
            Color(0xffead9b2),
            Color(0xffd5b477),
            Color(0xffb47f4c),
            Color(0xff815231),
          ];
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .94),
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width - 24).clamp(180.0, 340.0),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    Text(unit, style: Theme.of(context).textTheme.bodySmall),
                    if (numeric)
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          for (var i = 0; i < colors.length; i++)
                            _Swatch(
                              color: colors[i],
                              label: _thresholds(mode, russian)[i],
                            ),
                          _Swatch(
                            color: const Color(0xffb8bec0),
                            label: russian ? 'нет данных' : 'no data',
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: russian ? 'Сбросить' : 'Clear',
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _thresholds(String value, bool ru) => value == 'population'
      ? (ru
            ? const [
                '<1 млн',
                '1–10 млн',
                '10–50 млн',
                '50–150 млн',
                '≥150 млн',
              ]
            : const ['<1M', '1–10M', '10–50M', '50–150M', '≥150M'])
      : (ru
            ? const [
                '<10 тыс.',
                '10–100 тыс.',
                '100–500 тыс.',
                '500 тыс.–1 млн',
                '≥1 млн',
              ]
            : const ['<10k', '10–100k', '100–500k', '500k–1M', '≥1M']);
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 13, height: 9, color: color),
      const SizedBox(width: 2),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
