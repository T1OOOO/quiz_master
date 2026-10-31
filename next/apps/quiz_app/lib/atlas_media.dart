import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'russian_learning_text.dart';

final _mediaByBundle = Expando<Future<Map<String, Map<String, dynamic>>>>();

Future<Map<String, Map<String, dynamic>>> _load(AssetBundle bundle) =>
    _mediaByBundle[bundle] ??= () async {
      try {
        final rows = jsonDecode(
          await bundle.loadString('assets/quizipedia/atlas_media.json'),
        ) as List;
        return {
          for (final row in rows)
            '${row['scope']}:${row['id']}': Map<String, dynamic>.from(
              row as Map,
            ),
        };
      } catch (_) {
        return const <String, Map<String, dynamic>>{};
      }
    }();

/// Metadata loads on first use; each visible widget requests only its own image.
class AtlasMedia extends StatelessWidget {
  const AtlasMedia({
    super.key,
    required this.scope,
    required this.entityId,
    this.fieldPath,
    this.compact = false,
    this.hideWhenMissing = false,
  });
  final String scope, entityId;
  final String? fieldPath;
  final bool compact, hideWhenMissing;

  Map<String, dynamic>? _resolveRow(Map<String, Map<String, dynamic>>? data) {
    if (data == null) return null;
    final fp = fieldPath?.trim() ?? '';
    if (fp.isNotEmpty) {
      final exact = data['$scope:$entityId:$fp'];
      if (exact != null) return exact;
      final prefix = fp.split('.').first;
      final byPrefix = data['$scope:$entityId:$prefix'];
      if (byPrefix != null) return byPrefix;
    }
    return data['$scope:$entityId'];
  }

  static bool _validAssetPath(Object? value) =>
      value is String &&
      (value.startsWith('assets/quizipedia/media-') ||
          value.startsWith('assets/quizipedia/landmark-') ||
          value.startsWith('assets/quizipedia/thumb-')) &&
      !value.contains('..');

  Widget _buildImage(
    String asset,
    Object? rawCell,
    Widget Function() fallback,
  ) {
    if (rawCell is List && rawCell.length == 4) {
      final col = (rawCell[0] as num).toInt();
      final rowIdx = (rawCell[1] as num).toInt();
      final cols = (rawCell[2] as num).toInt();
      final rows = (rawCell[3] as num).toInt();
      if (cols > 0 && rows > 0 && col >= 0 && col < cols && rowIdx >= 0 && rowIdx < rows) {
        final boxW = compact ? 52.0 : 300.0;
        final boxH = compact ? 52.0 : 240.0;
        final ax = cols <= 1 ? 0.0 : -1.0 + (2.0 * col) / (cols - 1);
        final ay = rows <= 1 ? 0.0 : -1.0 + (2.0 * rowIdx) / (rows - 1);
        final sliced = SizedBox(
          width: boxW,
          height: boxH,
          child: ClipRect(
            child: OverflowBox(
              minWidth: boxW * cols,
              maxWidth: boxW * cols,
              minHeight: boxH * rows,
              maxHeight: boxH * rows,
              alignment: Alignment(ax, ay),
              child: Image.asset(
                asset,
                width: boxW * cols,
                height: boxH * rows,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stack) => fallback(),
              ),
            ),
          ),
        );
        return compact ? sliced : Center(child: sliced);
      }
    }
    return Image.asset(
      asset,
      width: compact ? 52 : double.infinity,
      height: compact ? 52 : 240,
      fit: compact && scope != 'brands' ? BoxFit.cover : BoxFit.contain,
      errorBuilder: (context, error, stack) => fallback(),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<Map<String, Map<String, dynamic>>>(
    future: _load(DefaultAssetBundle.of(context)),
    builder: (context, snapshot) {
      final row = _resolveRow(snapshot.data);
      Widget fallback() => compact && !hideWhenMissing
          ? const SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.image_outlined),
            )
          : const SizedBox.shrink();
      if (row == null) return fallback();
      final asset = row[compact ? 'thumbnail_asset' : 'asset'] ?? row['asset'];
      if (!_validAssetPath(asset)) {
        return fallback();
      }
      final image = _buildImage(asset as String, row['cell'], fallback);
      final displayImage = scope == 'brands' && row['cell'] == null
          ? ColoredBox(
              color: Colors.white,
              child: Padding(padding: const EdgeInsets.all(4), child: image),
            )
          : image;
      if (compact) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: displayImage,
        );
      }
      final atlasAsset = _validAssetPath(row['atlas_asset'])
          ? row['atlas_asset'] as String
          : (row['cell'] != null && _validAssetPath(row['asset'])
                ? row['asset'] as String
                : null);
      final rawTitle = (row['atlas_title_ru'] ?? row['atlas_title']) as String?;
      final atlasTitle = rawTitle?.trim().isNotEmpty == true
          ? rawTitle!.trim()
          : 'Визуальный атлас';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          displayImage,
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('Изображение и автор'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Об изображении'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${row['attribution']}\n${russianLearningText('${row['license']}')}'),
                          TextButton(
                            onPressed: () => _open(row['source_url']),
                            child: const Text('Источник изображения'),
                          ),
                          TextButton(
                            onPressed: () => _open(row['license_url']),
                            child: const Text('Условия использования'),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Закрыть'),
                      ),
                    ],
                  ),
                ),
              ),
              if (atlasAsset != null)
                TextButton.icon(
                  icon: const Icon(Icons.grid_view_outlined, size: 16),
                  label: const Text('Визуальный атлас'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(atlasTitle),
                      content: SizedBox(
                        width: 640,
                        height: 480,
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Image.asset(
                            atlasAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) =>
                                const Center(child: Icon(Icons.image_outlined)),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Закрыть'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );

  void _open(Object? value) {
    final uri = Uri.tryParse('$value');
    if (uri?.scheme == 'https' && uri!.host.isNotEmpty) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
