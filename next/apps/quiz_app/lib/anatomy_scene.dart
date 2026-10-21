import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'russian_learning_text.dart';

class AnatomySceneMarker {
  const AnatomySceneMarker({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
  });
  final String id, label;
  final double x, y;
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
  });
  final String asset, zoomInLabel, zoomOutLabel, resetLabel, creditLabel;
  final double aspectRatio;
  final List<AnatomySceneMarker> markers;
  final AnatomySceneCredit credit;
  final ValueChanged<AnatomySceneMarker> onMarkerTap;
  @override
  State<AnatomyScene> createState() => _AnatomySceneState();
}

class _AnatomySceneState extends State<AnatomyScene> {
  final _controller = TransformationController();
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
                builder: (context, constraints) => Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(widget.asset, fit: BoxFit.contain),
                    for (final marker in widget.markers)
                      Positioned(
                        left: constraints.maxWidth * marker.x - 22,
                        top: constraints.maxHeight * marker.y - 22,
                        child: Semantics(
                          button: true,
                          label: marker.label,
                          child: IconButton.filledTonal(
                            key: Key('anatomy-marker-${marker.id}'),
                            tooltip: marker.label,
                            onPressed: () => widget.onMarkerTap(marker),
                            icon: const Icon(Icons.location_on, size: 20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
              label: Text(marker.label),
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
                      Text('${widget.credit.author}\n${russianLearningText(widget.credit.license)}'),
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse(widget.credit.source),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: const Text('Источник изображения'),
                      ),
                      if (widget.credit.license.contains('2.5'))
                        TextButton(
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'https://creativecommons.org/licenses/by/2.5/',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: const Text('Условия использования'),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
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
}
