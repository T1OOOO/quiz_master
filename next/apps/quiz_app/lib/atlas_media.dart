import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'russian_learning_text.dart';

final _mediaByBundle = Expando<Future<Map<String, Map<String, dynamic>>>>();

Future<Map<String, Map<String, dynamic>>> _load(AssetBundle bundle) =>
    _mediaByBundle[bundle] ??= () async {
      final rows = jsonDecode(
        await bundle.loadString('assets/quizipedia/atlas_media.json'),
      ) as List;
      return {
        for (final row in rows)
          '${row['scope']}:${row['id']}': Map<String, dynamic>.from(row as Map),
      };
    }();

/// Metadata loads on first use; each visible widget requests only its own image.
class AtlasMedia extends StatelessWidget {
  const AtlasMedia({
    super.key,
    required this.scope,
    required this.entityId,
    this.compact = false,
  });
  final String scope, entityId;
  final bool compact;

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<Map<String, Map<String, dynamic>>>(
    future: _load(DefaultAssetBundle.of(context)),
    builder: (context, snapshot) {
      final row = snapshot.data?['$scope:$entityId'];
      Widget fallback() => compact
          ? const SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.image_outlined),
            )
          : const SizedBox.shrink();
      if (row == null) return fallback();
      final asset = row[compact ? 'thumbnail_asset' : 'asset'] ?? row['asset'];
      if (asset is! String ||
          !asset.startsWith('assets/quizipedia/media-') ||
          asset.contains('..')) {
        return fallback();
      }
      final image = Image.asset(
        asset,
        width: compact ? 52 : double.infinity,
        height: compact ? 52 : 240,
        fit: compact && scope != 'brands' ? BoxFit.cover : BoxFit.contain,
        errorBuilder: (context, error, stack) => fallback(),
      );
      final displayImage = scope == 'brands'
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          displayImage,
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
