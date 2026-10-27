import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'russian_learning_text.dart';

class AnatomySceneMarker {
  const AnatomySceneMarker({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    this.calloutX,
    this.calloutY,
    this.calloutNumber,
  });
  final String id, label;
  final double x, y;

  final double? calloutX, calloutY;
  final int? calloutNumber;
}

class AnatomySceneCredit {
  const AnatomySceneCredit({
    required this.author,
    required this.license,
    required this.source,
  });
  final String author, license, source;
}

/// A touch-first, labelled overlay for an illustration whose marker positions
/// were checked against visible parts of that illustration.
class AnatomyScene extends StatefulWidget {
  const AnatomyScene({
    super.key,
    required this.asset,
    required this.aspectRatio,
    required this.markers,
    required this.credit,
    required this.onMarkerTap,
    required this.zoomInLabel,
    required this.zoomOutLabel,
    required this.resetLabel,
    required this.creditLabel,
    required this.hideMarkersLabel,
    required this.showMarkersLabel,
    this.caption,
    this.markerDiameter = 48,
  });
  final String asset,
      zoomInLabel,
      zoomOutLabel,
      resetLabel,
      creditLabel,
      hideMarkersLabel,
      showMarkersLabel;

  /// A short orientation note for the source illustration. It deliberately
  /// distinguishes the learning pins from anatomical labels in the artwork.
  final String? caption;
  final double aspectRatio;

  /// The visual pin size. Direct pins have a 48dp hit target; where those
  /// targets would overlap, the labelled chips below remain the safe control.
  final double markerDiameter;
  final List<AnatomySceneMarker> markers;
  final AnatomySceneCredit credit;
  final ValueChanged<AnatomySceneMarker> onMarkerTap;
  @override
  State<AnatomyScene> createState() => _AnatomySceneState();
}

class _AnatomySceneState extends State<AnatomyScene> {
  static const _markerTapDiameter = 48.0;
  final _controller = TransformationController();
  var _markersVisible = true;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoom(double scale) {
    final next = Matrix4.copy(_controller.value)
      ..scaleByDouble(scale, scale, 1, 1);
    final value = next.storage[0].abs();
    if (value >= .7 && value <= 4) setState(() => _controller.value = next);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 360,
        child: InteractiveViewer(
          key: const Key('anatomy-scene'),
          transformationController: _controller,
          minScale: .7,
          maxScale: 4,
          child: Center(
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final directMarkers = <AnatomySceneMarker>[];
                  if (_markersVisible) {
                    for (final marker in widget.markers) {
                      final candidate = Rect.fromCenter(
                        center: Offset(
                          constraints.maxWidth * (marker.calloutX ?? marker.x),
                          constraints.maxHeight * (marker.calloutY ?? marker.y),
                        ),
                        width: _markerTapDiameter,
                        height: _markerTapDiameter,
                      );
                      final overlapsDirectMarker = directMarkers.any((other) {
                        final otherRect = Rect.fromCenter(
                          center: Offset(
                            constraints.maxWidth * (other.calloutX ?? other.x),
                            constraints.maxHeight * (other.calloutY ?? other.y),
                          ),
                          width: _markerTapDiameter,
                          height: _markerTapDiameter,
                        );
                        return candidate.overlaps(otherRect);
                      });
                      if (!overlapsDirectMarker) directMarkers.add(marker);
                    }
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(widget.asset, fit: BoxFit.contain),
                      if (_markersVisible &&
                          widget.markers.any(
                            (marker) =>
                                marker.calloutX != null &&
                                marker.calloutY != null,
                          ))
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              key: const Key('anatomy-scene-callout-lines'),
                              painter: _CalloutLinesPainter(
                                markers: widget.markers,
                              ),
                            ),
                          ),
                        ),
                      if (_markersVisible)
                        for (final marker in widget.markers)
                          if (marker.calloutX != null &&
                              marker.calloutY != null)
                            Positioned(
                              left: constraints.maxWidth * marker.x - 4,
                              top: constraints.maxHeight * marker.y - 4,
                              child: ExcludeSemantics(
                                child: DecoratedBox(
                                  key: Key(
                                    'anatomy-source-marker-${marker.id}',
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const SizedBox.square(dimension: 8),
                                ),
                              ),
                            ),
                      for (final marker in directMarkers)
                        Positioned(
                          left:
                              constraints.maxWidth *
                                  (marker.calloutX ?? marker.x) -
                              _markerTapDiameter / 2,
                          top:
                              constraints.maxHeight *
                                  (marker.calloutY ?? marker.y) -
                              _markerTapDiameter / 2,
                          child: IconButton(
                            key: Key('anatomy-marker-${marker.id}'),
                            tooltip: marker.label,
                            style: IconButton.styleFrom(
                              minimumSize: const Size.square(
                                _markerTapDiameter,
                              ),
                              maximumSize: const Size.square(
                                _markerTapDiameter,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => widget.onMarkerTap(marker),
                            icon: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox.square(
                                dimension: widget.markerDiameter,
                                child: marker.calloutNumber == null
                                    ? Icon(
                                        Icons.location_on,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                        size: widget.markerDiameter * .5,
                                      )
                                    : Center(
                                        child: Text(
                                          '${marker.calloutNumber}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      if (widget.caption case final caption?)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Semantics(
            container: true,
            child: Text(
              caption,
              key: const Key('anatomy-scene-caption'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final marker in {
            for (final item in widget.markers) item.label: item,
          }.values)
            ActionChip(
              key: Key('anatomy-marker-action-${marker.id}'),
              label: Text(marker.label),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              onPressed: () => widget.onMarkerTap(marker),
            ),
        ],
      ),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          IconButton(
            tooltip: widget.zoomInLabel,
            onPressed: () => _zoom(1.25),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: widget.zoomOutLabel,
            onPressed: () => _zoom(.8),
            icon: const Icon(Icons.remove),
          ),
          Tooltip(
            message: _markersVisible
                ? widget.hideMarkersLabel
                : widget.showMarkersLabel,
            child: TextButton.icon(
              key: const Key('anatomy-scene-marker-toggle'),
              onPressed: () =>
                  setState(() => _markersVisible = !_markersVisible),
              icon: Icon(
                _markersVisible
                    ? Icons.visibility_off_outlined
                    : Icons.pin_drop,
              ),
              label: Text(
                _markersVisible
                    ? widget.hideMarkersLabel
                    : widget.showMarkersLabel,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () =>
                setState(() => _controller.value = Matrix4.identity()),
            icon: const Icon(Icons.center_focus_strong),
            label: Text(widget.resetLabel),
          ),
          TextButton.icon(
            key: const Key('anatomy-scene-credit'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(widget.creditLabel),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.credit.author}\n${russianLearningText(widget.credit.license)}',
                      ),
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse(widget.credit.source),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Text(
                          _isRussian(context)
                              ? 'Источник изображения'
                              : 'Image source',
                        ),
                      ),
                      if (widget.credit.license.contains('2.5'))
                        TextButton(
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'https://creativecommons.org/licenses/by/2.5/',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Text(
                            _isRussian(context)
                                ? 'Условия использования'
                                : 'License terms',
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_isRussian(context) ? 'Закрыть' : 'Close'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.info_outline),
            label: Text(widget.creditLabel),
          ),
        ],
      ),
    ],
  );

  bool _isRussian(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'ru';
}

class _CalloutLinesPainter extends CustomPainter {
  const _CalloutLinesPainter({required this.markers});

  final List<AnatomySceneMarker> markers;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final marker in markers) {
      final calloutX = marker.calloutX;
      final calloutY = marker.calloutY;
      if (calloutX == null || calloutY == null) continue;
      canvas.drawLine(
        Offset(size.width * marker.x, size.height * marker.y),
        Offset(size.width * calloutX, size.height * calloutY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalloutLinesPainter oldDelegate) =>
      oldDelegate.markers != markers;
}
