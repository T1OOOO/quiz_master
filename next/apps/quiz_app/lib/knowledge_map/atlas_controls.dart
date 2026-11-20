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
  });

  final bool russian, globe, showProjection;
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onProjection, onAbout;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xfffffef9),
    elevation: 2,
    shadowColor: const Color(0x55324c44),
    borderRadius: BorderRadius.circular(16),
    child: LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < (onAbout == null ? 245 : 280);
        final projection = globe
            ? (russian ? '2D-карта' : '2D map')
            : (russian ? '3D-глобус' : '3D globe');
        final glyph = Icon(globe ? Icons.map_outlined : Icons.public, size: 19);
        final back = IconButton(
          tooltip: russian ? 'Назад' : 'Back',
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: onBack,
        );
        final actions = <Widget>[
          if (showProjection)
            if (compact)
              IconButton(
                tooltip: projection,
                onPressed: onProjection,
                icon: glyph,
              )
            else
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xff215b53),
                ),
                onPressed: onProjection,
                icon: glyph,
                label: Text(projection),
              ),
          if (onAbout != null)
            IconButton(
              tooltip: russian ? 'Об источнике' : 'About the data',
              onPressed: onAbout,
              icon: const Icon(Icons.info_outline, size: 20),
            ),
        ];
        final iconWidth = (1 + actions.length) * 48;
        if (box.maxWidth < iconWidth) return Wrap(children: [back, ...actions]);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            back,
            if (title.isNotEmpty &&
                (!compact || box.maxWidth >= iconWidth + 70))
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Georgia',
                      fontWeight: FontWeight.w700,
                      color: Color(0xff214b41),
                    ),
                  ),
                ),
              ),
            ...actions,
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
