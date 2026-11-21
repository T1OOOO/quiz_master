import 'dart:math' as math;

import 'package:flutter/material.dart';

class AtlasHeader extends StatelessWidget {
  const AtlasHeader({
    super.key,
    required this.russian,
    required this.onBack,
    required this.title,
    required this.globe,
    this.showProjection = true,
    this.onProjection,
    this.onAbout,
    this.onAtlasSwitch,
    this.showAtlasSwitch = false,
    this.history = false,
  });

  final bool russian, globe, showProjection, history, showAtlasSwitch;
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onProjection, onAbout, onAtlasSwitch;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xfffcf7ed),
    elevation: 2,
    shadowColor: const Color(0x55473425),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xffdfd1bd)),
    ),
    child: LayoutBuilder(
      builder: (context, box) {
        final paired = showAtlasSwitch || onAtlasSwitch != null;
        final scale = math.max(
          1.0,
          MediaQuery.textScalerOf(context).scale(14) / 14,
        );
        final compact =
            box.maxWidth < (paired ? 116 + 208 * scale : 220 * scale);
        final flat = russian ? '2D-карта' : '2D map';
        final globeName = russian ? '3D-глобус' : '3D globe';
        final world = russian ? 'Атлас мира' : 'World atlas';
        final chronology = russian ? 'Исторический атлас' : 'Historical atlas';
        const ink = Color(0xff48392c);
        const accent = Color(0xff754524);
        Widget action(String tooltip, IconData icon, VoidCallback? callback) =>
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                tooltip: tooltip,
                onPressed: callback,
                color: ink,
                icon: Icon(icon, size: 19),
              ),
            );
        Widget option(
          String label,
          String tooltip,
          bool active,
          double width,
          VoidCallback? change,
        ) => Semantics(
          selected: active,
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: width * scale,
              height: 40,
              child: TextButton(
                onPressed: active ? null : change,
                style: TextButton.styleFrom(
                  foregroundColor: ink,
                  disabledForegroundColor: active ? accent : null,
                  disabledBackgroundColor: active
                      ? const Color(0xffefd7b5)
                      : null,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
              ),
            ),
          ),
        );
        Widget group(List<Widget> options) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xfff1e8d9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(mainAxisSize: MainAxisSize.min, children: options),
            ),
          ),
        );
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            action(
              russian ? 'Назад' : 'Back',
              Icons.arrow_back_rounded,
              onBack,
            ),
            if (paired)
              if (compact)
                action(
                  history ? world : chronology,
                  history ? Icons.public : Icons.history_edu_outlined,
                  onAtlasSwitch,
                )
              else
                group([
                  option(
                    russian ? 'Мир' : 'World',
                    world,
                    !history,
                    50,
                    onAtlasSwitch,
                  ),
                  option(
                    russian ? 'История' : 'History',
                    chronology,
                    history,
                    70,
                    onAtlasSwitch,
                  ),
                ]),
            if (!paired && title.isNotEmpty && box.maxWidth >= 245 * scale)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
            if (showProjection)
              if (compact)
                action(
                  globe ? flat : globeName,
                  globe ? Icons.map_outlined : Icons.public,
                  onProjection,
                )
              else
                group([
                  option('2D', flat, !globe, 44, onProjection),
                  option('3D', globeName, globe, 44, onProjection),
                ]),
            if (onAbout != null)
              action(
                russian ? 'Об источнике' : 'About the data',
                Icons.info_outline,
                onAbout,
              )
            else if (paired)
              const SizedBox(width: 48, height: 48),
          ],
        );
      },
    ),
  );
}

class AtlasCameraControls extends StatelessWidget {
  const AtlasCameraControls({
    super.key,
    required this.russian,
    required this.viewport,
    required this.onFit,
    required this.onZoomIn,
    required this.onZoomOut,
    this.showSearch = false,
    this.onSearch,
  });

  final bool russian, showSearch;
  final Size viewport;
  final VoidCallback? onFit, onZoomIn, onZoomOut, onSearch;

  static Rect bounds(Size viewport, {required bool search}) {
    final length = 44.0 * (search ? 4 : 3);
    final horizontal =
        viewport.height < length + 88 && viewport.width >= length + 24;
    return Rect.fromLTWH(
      math.max(0, viewport.width - 12 - (horizontal ? length : 44)),
      math.max(0, viewport.height - 12 - (horizontal ? 44 : length)),
      horizontal ? length : 44,
      horizontal ? 44 : length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rect = bounds(viewport, search: showSearch);
    final horizontal = rect.width > rect.height;
    Widget button(
      String en,
      String ru,
      IconData icon,
      VoidCallback? action,
    ) => Tooltip(
      message: russian ? ru : en,
      excludeFromSemantics: true,
      positionDelegate: (c) {
        // Place the hint beside the rail so it cannot cover the next button.
        final hint = c.tooltipSize;
        final x = horizontal
            ? c.target.dx - hint.width / 2
            : c.target.dx - c.targetSize.width / 2 - 6 - hint.width;
        final y = horizontal
            ? c.target.dy - c.targetSize.height / 2 - 6 - hint.height
            : c.target.dy - hint.height / 2;
        return Offset(
          x.clamp(0.0, math.max(0.0, c.overlaySize.width - hint.width)),
          y.clamp(0.0, math.max(0.0, c.overlaySize.height - hint.height)),
        );
      },
      child: SizedBox.square(
        dimension: 44,
        child: IconButton(
          onPressed: action,
          icon: Icon(icon, size: 21, semanticLabel: russian ? ru : en),
        ),
      ),
    );
    return Material(
      color: const Color(0xfffffef9),
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      shadowColor: const Color(0x55324c44),
      child: IconTheme(
        data: const IconThemeData(color: Color(0xff215b53)),
        child: Flex(
          direction: horizontal ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSearch) button('Search', 'Поиск', Icons.search, onSearch),
            button('Whole map', 'Вся карта', Icons.fit_screen_outlined, onFit),
            button('Zoom in', 'Увеличить', Icons.add, onZoomIn),
            button('Zoom out', 'Уменьшить', Icons.remove, onZoomOut),
          ],
        ),
      ),
    );
  }
}
