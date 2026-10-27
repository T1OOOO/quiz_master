import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/anatomy_scene.dart';

void main() {
  testWidgets('can hide pins without removing accessible marker actions', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnatomyScene(
            asset: 'assets/quizipedia/skeleton-display.png',
            aspectRatio: 500 / 967,
            markerDiameter: 32,
            markers: const [
              AnatomySceneMarker(id: 'spine', label: 'Spine', x: .46, y: .39),
              AnatomySceneMarker(id: 'pelvis', label: 'Pelvis', x: .46, y: .53),
            ],
            credit: const AnatomySceneCredit(
              author: 'Public domain source',
              license: 'Public domain',
              source: 'https://example.test/source',
            ),
            onMarkerTap: (_) => taps++,
            zoomInLabel: 'Zoom in',
            zoomOutLabel: 'Zoom out',
            resetLabel: 'Fit image',
            creditLabel: 'Image credit',
            hideMarkersLabel: 'Hide pins',
            showMarkersLabel: 'Show pins',
          ),
        ),
      ),
    );

    final spine = find.byKey(const Key('anatomy-marker-spine'));
    final pelvis = find.byKey(const Key('anatomy-marker-pelvis'));
    expect(spine, findsOneWidget);
    expect(pelvis, findsOneWidget);
    expect(tester.getSize(spine), const Size.square(48));
    expect(tester.getRect(spine).overlaps(tester.getRect(pelvis)), isFalse);
    await tester.tap(find.byKey(const Key('anatomy-scene-marker-toggle')));
    await tester.pump();

    expect(spine, findsNothing);
    expect(pelvis, findsNothing);
    expect(
      tester
          .getSize(find.byKey(const Key('anatomy-marker-action-spine')))
          .height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.byKey(const Key('anatomy-marker-action-spine')));
    expect(taps, 1);
  });

  testWidgets('uses the labelled control for colliding 48dp anchors', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnatomyScene(
            asset: 'assets/quizipedia/skeleton-display.png',
            aspectRatio: 500 / 967,
            markerDiameter: 32,
            markers: const [
              AnatomySceneMarker(id: 'spine', label: 'Spine', x: .46, y: .36),
              AnatomySceneMarker(id: 'pelvis', label: 'Pelvis', x: .46, y: .44),
            ],
            credit: const AnatomySceneCredit(
              author: 'Public domain source',
              license: 'Public domain',
              source: 'https://example.test/source',
            ),
            onMarkerTap: (marker) => selected = marker.id,
            zoomInLabel: 'Zoom in',
            zoomOutLabel: 'Zoom out',
            resetLabel: 'Fit image',
            creditLabel: 'Image credit',
            hideMarkersLabel: 'Hide pins',
            showMarkersLabel: 'Show pins',
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('anatomy-marker-spine')), findsOneWidget);
    expect(find.byKey(const Key('anatomy-marker-pelvis')), findsNothing);
    await tester.tap(find.byKey(const Key('anatomy-marker-action-pelvis')));
    expect(selected, 'pelvis');
  });

  testWidgets('links and hides a callout with its source point', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnatomyScene(
            asset: 'assets/quizipedia/skeleton-display.png',
            aspectRatio: 500 / 967,
            markerDiameter: 32,
            markers: const [
              AnatomySceneMarker(
                id: 'source',
                label: 'Source structure',
                x: .46,
                y: .36,
                calloutX: .10,
                calloutY: .10,
                calloutNumber: 1,
              ),
            ],
            credit: const AnatomySceneCredit(
              author: 'Public domain source',
              license: 'Public domain',
              source: 'https://example.test/source',
            ),
            onMarkerTap: (_) {},
            zoomInLabel: 'Zoom in',
            zoomOutLabel: 'Zoom out',
            resetLabel: 'Fit image',
            creditLabel: 'Image credit',
            hideMarkersLabel: 'Hide pins',
            showMarkersLabel: 'Show pins',
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('anatomy-scene-callout-lines')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('anatomy-source-marker-source')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('anatomy-marker-source')), findsOneWidget);

    await tester.tap(find.byKey(const Key('anatomy-scene-marker-toggle')));
    await tester.pump();

    expect(find.byKey(const Key('anatomy-scene-callout-lines')), findsNothing);
    expect(find.byKey(const Key('anatomy-source-marker-source')), findsNothing);
    expect(find.byKey(const Key('anatomy-marker-source')), findsNothing);
    expect(
      find.byKey(const Key('anatomy-marker-action-source')),
      findsOneWidget,
    );
  });
}
