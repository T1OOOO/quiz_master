/// Vector geometry for the interactive body scene.
///
/// Every structure is a cached [Path] in a fixed 400×900 scene space (anterior
/// view, the viewer's left is the body's right). Positions are schematic
/// teaching placements; the written card gives the actual anatomy.
library;

import 'dart:math' as math;
import 'dart:ui';

enum BodyLayer { skeleton, organs, endocrine, vascular }

const bodySceneSize = Size(400, 900);

class BodyStructure {
  BodyStructure._({
    required this.id,
    required this.layers,
    required this.scope,
    required this.path,
    required this.color,
    required this.depth,
    required this.anchor,
    this.strokeWidth,
    this.polylines = const [],
  }) : bounds = strokeWidth == null
           ? path.getBounds()
           : path.getBounds().inflate(strokeWidth / 2);

  final String id;
  final Set<BodyLayer> layers;

  /// `organs` (organ atlas ids, including skeleton groups) or `vascular`.
  final String scope;
  final Path path;
  final Rect bounds;
  final Color color;

  /// Paint order inside a layer; higher values are painted later.
  final int depth;

  /// Where a label's leader line points.
  final Offset anchor;

  /// Non-null for structures drawn as strokes (vessels, long bones).
  final double? strokeWidth;
  final List<List<Offset>> polylines;

  bool get isStroke => strokeWidth != null;
  double get area => bounds.width * bounds.height;

  bool visibleIn(Set<BodyLayer> active) => layers.any(active.contains);

  /// A hit score, or `null` for a miss. [tolerance] is in scene units.
  /// Fills score 0 when the point is inside or within the probe margin;
  /// strokes score the distance outside their drawn width, so a tap on a
  /// vessel beats the organ behind it while a tap merely near one does not.
  double? hitScore(Offset point, double tolerance) {
    if (!bounds.inflate(tolerance).contains(point)) return null;
    final width = strokeWidth;
    if (width == null) {
      return path.contains(point) ||
              (tolerance > 0 && _nearPathEdge(point, tolerance))
          ? 0
          : null;
    }
    var nearest = double.infinity;
    for (final line in polylines) {
      for (var i = 0; i + 1 < line.length; i++) {
        nearest = math.min(
          nearest,
          _segmentDistance(point, line[i], line[i + 1]),
        );
      }
    }
    final outside = nearest - width / 2;
    return outside <= tolerance ? math.max(0, outside) : null;
  }

  /// Small glands need a forgiving target: sample a few points around the tap.
  bool _nearPathEdge(Offset point, double tolerance) {
    for (final angle in const [0.0, 1.5708, 3.1416, 4.7124]) {
      final probe =
          point + Offset(math.cos(angle), math.sin(angle)) * tolerance;
      if (path.contains(probe)) return true;
    }
    return false;
  }
}

double _segmentDistance(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final lengthSquared = ab.distanceSquared;
  if (lengthSquared == 0) return (p - a).distance;
  final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / lengthSquared).clamp(
    0.0,
    1.0,
  );
  return (p - (a + ab * t)).distance;
}

Offset _mirror(Offset o) => Offset(bodySceneSize.width - o.dx, o.dy);
List<Offset> _mirrorAll(List<Offset> points) =>
    points.map(_mirror).toList(growable: false);

/// A closed smooth blob through the midpoints of consecutive control points.
Path _blob(List<Offset> p) {
  final path = Path();
  final n = p.length;
  Offset mid(int i) => (p[i % n] + p[(i + 1) % n]) / 2;
  path.moveTo(mid(0).dx, mid(0).dy);
  for (var i = 1; i <= n; i++) {
    final c = p[i % n];
    final m = mid(i);
    path.quadraticBezierTo(c.dx, c.dy, m.dx, m.dy);
  }
  return path..close();
}

Path _oval(Offset center, double rx, double ry) =>
    Path()
      ..addOval(Rect.fromCenter(center: center, width: rx * 2, height: ry * 2));

Path _polyline(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final p in points.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  return path;
}

Path _join(Iterable<Path> parts) {
  final path = Path();
  for (final part in parts) {
    path.addPath(part, Offset.zero);
  }
  return path;
}

BodyStructure _fill(
  String id,
  Set<BodyLayer> layers,
  List<Path> parts, {
  required Color color,
  required int depth,
  Offset? anchor,
  String scope = 'organs',
}) {
  final path = _join(parts);
  return BodyStructure._(
    id: id,
    layers: layers,
    scope: scope,
    path: path,
    color: color,
    depth: depth,
    anchor: anchor ?? parts.first.getBounds().center,
  );
}

BodyStructure _line(
  String id,
  Set<BodyLayer> layers,
  List<List<Offset>> lines, {
  required double width,
  required Color color,
  required int depth,
  Offset? anchor,
  String scope = 'organs',
}) {
  final first = lines.first;
  return BodyStructure._(
    id: id,
    layers: layers,
    scope: scope,
    path: _join(lines.map(_polyline)),
    color: color,
    depth: depth,
    anchor: anchor ?? first[first.length ~/ 2],
    strokeWidth: width,
    polylines: lines,
  );
}

const _skeleton = {BodyLayer.skeleton};
const _organs = {BodyLayer.organs};
const _glands = {BodyLayer.organs, BodyLayer.endocrine};
const _vessels = {BodyLayer.vascular};

const boneColor = Color(0xFFEDE6D6);
const endocrineColor = Color(0xFFF2A64D);
const arteryColor = Color(0xFFD3473F);
const veinColor = Color(0xFF3F6FD1);
const pulmonaryArteryColor = Color(0xFF5B7FD6);
const pulmonaryVeinColor = Color(0xFFD96A6A);
const portalVeinColor = Color(0xFF7B5FC2);

/// Silhouette parts: filled shapes and thick strokes in one soft colour.
class BodySilhouette {
  BodySilhouette._();
  static final fills = <Path>[
    _oval(const Offset(200, 72), 46, 54),
    Path()..addRect(const Rect.fromLTRB(180, 118, 220, 162)),
    _blob(const [
      Offset(95, 160),
      Offset(305, 160),
      Offset(318, 182),
      Offset(300, 330),
      Offset(292, 420),
      Offset(306, 500),
      Offset(296, 598),
      Offset(200, 642),
      Offset(104, 598),
      Offset(94, 500),
      Offset(108, 420),
      Offset(100, 330),
      Offset(82, 182),
    ]),
  ];
  static final strokes = <(Path, double)>[
    (_polyline(const [Offset(92, 178), Offset(64, 320), Offset(48, 450)]), 46),
    (
      _polyline(
        _mirrorAll(const [Offset(92, 178), Offset(64, 320), Offset(48, 450)]),
      ),
      46,
    ),
    (_polyline(const [Offset(48, 450), Offset(42, 520)]), 34),
    (_polyline(_mirrorAll(const [Offset(48, 450), Offset(42, 520)])), 34),
    (
      _polyline(const [Offset(152, 585), Offset(146, 720), Offset(142, 855)]),
      62,
    ),
    (
      _polyline(
        _mirrorAll(const [
          Offset(152, 585),
          Offset(146, 720),
          Offset(142, 855),
        ]),
      ),
      62,
    ),
    (_polyline(const [Offset(142, 855), Offset(118, 876)]), 40),
    (_polyline(_mirrorAll(const [Offset(142, 855), Offset(118, 876)])), 40),
  ];
}

List<List<Offset>> _paired(List<Offset> line) => [line, _mirrorAll(line)];

/// All drawable structures, keyed by organ-atlas or vascular-atlas id.
final List<BodyStructure> bodyStructures = List.unmodifiable([
  // ---- skeleton -----------------------------------------------------------
  _fill(
    'skeleton-skull',
    _skeleton,
    [
      _oval(const Offset(200, 66), 40, 46),
      _blob(const [
        Offset(170, 92),
        Offset(230, 92),
        Offset(226, 122),
        Offset(200, 130),
        Offset(174, 122),
      ]),
    ],
    color: boneColor,
    depth: 1,
    anchor: const Offset(200, 56),
  ),
  _line(
    'skeleton-vertebral-column',
    _skeleton,
    [
      const [Offset(200, 118), Offset(200, 480)],
    ],
    width: 14,
    color: boneColor,
    depth: 0,
    anchor: const Offset(200, 380),
  ),
  _line(
    'skeleton-thoracic-cage',
    _skeleton,
    [
      const [Offset(200, 176), Offset(200, 292)],
      for (var i = 0; i < 7; i++)
        ..._paired([
          Offset(196, 186 + i * 18),
          Offset(162, 192 + i * 18),
          Offset(132, 206 + i * 18),
          Offset(120, 226 + i * 18),
          Offset(132, 242 + i * 18),
          Offset(156, 248 + i * 18),
        ]),
    ],
    width: 7,
    color: boneColor,
    depth: 2,
    anchor: const Offset(126, 250),
  ),
  _line(
    'skeleton-pectoral-girdle',
    _skeleton,
    _paired(const [Offset(195, 168), Offset(150, 160), Offset(100, 172)]),
    width: 9,
    color: boneColor,
    depth: 3,
    anchor: const Offset(150, 160),
  ),
  _line(
    'skeleton-upper-limbs',
    _skeleton,
    [
      ..._paired(const [Offset(92, 180), Offset(66, 318)]),
      ..._paired(const [Offset(62, 322), Offset(48, 448)]),
      ..._paired(const [Offset(76, 326), Offset(60, 452)]),
      ..._paired(const [Offset(50, 452), Offset(42, 516)]),
    ],
    width: 14,
    color: boneColor,
    depth: 2,
    anchor: const Offset(66, 318),
  ),
  _fill(
    'skeleton-pelvic-girdle',
    _skeleton,
    [
      _blob(const [
        Offset(200, 468),
        Offset(150, 460),
        Offset(118, 476),
        Offset(112, 520),
        Offset(130, 550),
        Offset(162, 562),
        Offset(186, 552),
        Offset(200, 538),
      ]),
      _blob(
        _mirrorAll(const [
          Offset(200, 468),
          Offset(150, 460),
          Offset(118, 476),
          Offset(112, 520),
          Offset(130, 550),
          Offset(162, 562),
          Offset(186, 552),
          Offset(200, 538),
        ]),
      ),
    ],
    color: boneColor,
    depth: 1,
    anchor: const Offset(150, 510),
  ),
  _line(
    'skeleton-lower-limbs',
    _skeleton,
    [
      ..._paired(const [Offset(158, 544), Offset(148, 700)]),
      ..._paired(const [Offset(148, 704), Offset(142, 848)]),
      ..._paired(const [Offset(162, 708), Offset(158, 846)]),
      ..._paired(const [Offset(142, 850), Offset(118, 870)]),
    ],
    width: 15,
    color: boneColor,
    depth: 2,
    anchor: const Offset(148, 700),
  ),
  // ---- organs -------------------------------------------------------------
  _line(
    'spinal_cord',
    _organs,
    [
      const [Offset(200, 118), Offset(200, 470)],
    ],
    width: 6,
    color: const Color(0xFFEADFB8),
    depth: 0,
    anchor: const Offset(200, 470),
  ),
  _fill(
    'brain',
    _organs,
    [
      _blob(const [
        Offset(166, 62),
        Offset(172, 40),
        Offset(196, 28),
        Offset(224, 31),
        Offset(238, 48),
        Offset(236, 70),
        Offset(222, 82),
        Offset(196, 84),
        Offset(172, 78),
      ]),
    ],
    color: const Color(0xFFE6B3C7),
    depth: 2,
    anchor: const Offset(176, 44),
  ),
  _fill(
    'eyes',
    _organs,
    [_oval(const Offset(184, 92), 6, 6), _oval(const Offset(216, 92), 6, 6)],
    color: const Color(0xFF6FA8DC),
    depth: 6,
    anchor: const Offset(216, 92),
  ),
  _fill(
    'ears',
    _organs,
    [_oval(const Offset(156, 92), 5, 9), _oval(const Offset(244, 92), 5, 9)],
    color: const Color(0xFFE5B8A8),
    depth: 5,
    anchor: const Offset(156, 92),
  ),
  _fill(
    'nasal_cavity',
    _organs,
    [
      Path()..addPolygon(const [
        Offset(200, 98),
        Offset(191, 114),
        Offset(209, 114),
      ], true),
    ],
    color: const Color(0xFFE3A5A0),
    depth: 5,
  ),
  _fill(
    'larynx',
    _organs,
    [
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(189, 120, 22, 30),
          const Radius.circular(8),
        ),
      ),
    ],
    color: const Color(0xFFD9C6A5),
    depth: 3,
  ),
  _fill(
    'trachea',
    _organs,
    [
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(193, 148, 14, 70),
          const Radius.circular(6),
        ),
      ),
    ],
    color: const Color(0xFFD8D3C4),
    depth: 3,
    anchor: const Offset(200, 200),
  ),
  _line(
    'esophagus',
    _organs,
    [
      const [
        Offset(208, 150),
        Offset(209, 230),
        Offset(212, 300),
        Offset(224, 338),
      ],
    ],
    width: 9,
    color: const Color(0xFFD4A58A),
    depth: 2,
    anchor: const Offset(211, 290),
  ),
  _fill(
    'lungs',
    _organs,
    [
      _blob(const [
        Offset(150, 172),
        Offset(175, 178),
        Offset(186, 210),
        Offset(184, 260),
        Offset(176, 310),
        Offset(150, 330),
        Offset(118, 320),
        Offset(106, 280),
        Offset(108, 225),
        Offset(125, 185),
      ]),
      _blob(const [
        Offset(250, 172),
        Offset(225, 178),
        Offset(216, 205),
        Offset(222, 240),
        Offset(238, 275),
        Offset(236, 310),
        Offset(255, 328),
        Offset(284, 318),
        Offset(294, 280),
        Offset(292, 225),
        Offset(275, 185),
      ]),
    ],
    color: const Color(0xFFA7C8DE),
    depth: 1,
    anchor: const Offset(140, 250),
  ),
  _fill(
    'heart',
    _organs,
    [
      _blob(const [
        Offset(210, 222),
        Offset(228, 214),
        Offset(246, 222),
        Offset(254, 244),
        Offset(246, 272),
        Offset(228, 296),
        Offset(206, 300),
        Offset(190, 284),
        Offset(186, 256),
        Offset(194, 234),
      ]),
    ],
    color: const Color(0xFFD9706E),
    depth: 4,
    anchor: const Offset(236, 268),
  ),
  _fill(
    'thymus',
    _glands,
    [
      _oval(const Offset(196, 212), 6, 17),
      _oval(const Offset(208, 210), 6, 17),
    ],
    color: const Color(0xFFF2C7A0),
    depth: 5,
    anchor: const Offset(202, 206),
  ),
  _fill(
    'liver',
    _organs,
    [
      _blob(const [
        Offset(104, 338),
        Offset(160, 332),
        Offset(228, 338),
        Offset(240, 356),
        Offset(226, 384),
        Offset(190, 400),
        Offset(150, 404),
        Offset(118, 392),
        Offset(102, 366),
      ]),
    ],
    color: const Color(0xFFB3745A),
    depth: 3,
    anchor: const Offset(136, 366),
  ),
  _fill(
    'gallbladder',
    _organs,
    [_oval(const Offset(166, 396), 9, 14)],
    color: const Color(0xFF7FA653),
    depth: 6,
  ),
  _fill(
    'stomach',
    _organs,
    [
      _blob(const [
        Offset(226, 342),
        Offset(252, 336),
        Offset(282, 350),
        Offset(296, 378),
        Offset(288, 406),
        Offset(264, 420),
        Offset(240, 414),
        Offset(228, 396),
        Offset(236, 374),
        Offset(224, 358),
      ]),
    ],
    color: const Color(0xFFE8B98B),
    depth: 4,
    anchor: const Offset(268, 380),
  ),
  _fill(
    'spleen',
    _organs,
    [_oval(const Offset(302, 372), 13, 24)],
    color: const Color(0xFF9C5B7A),
    depth: 2,
  ),
  _fill(
    'pancreas',
    _glands,
    [
      _blob(const [
        Offset(178, 412),
        Offset(214, 406),
        Offset(250, 408),
        Offset(284, 412),
        Offset(292, 422),
        Offset(280, 432),
        Offset(246, 430),
        Offset(210, 432),
        Offset(180, 430),
        Offset(168, 422),
      ]),
    ],
    color: const Color(0xFFF0C56A),
    depth: 3,
    anchor: const Offset(230, 420),
  ),
  _fill(
    'kidneys',
    _organs,
    [
      _oval(const Offset(124, 450), 17, 29),
      _oval(const Offset(276, 452), 17, 29),
    ],
    color: const Color(0xFF8E6B9E),
    depth: 1,
    anchor: const Offset(120, 452),
  ),
  _fill(
    'adrenals',
    _glands,
    [
      Path()..addPolygon(const [
        Offset(114, 420),
        Offset(140, 412),
        Offset(142, 426),
      ], true),
      Path()..addPolygon(const [
        Offset(286, 420),
        Offset(260, 412),
        Offset(258, 426),
      ], true),
    ],
    color: endocrineColor,
    depth: 2,
    anchor: const Offset(128, 418),
  ),
  _line(
    'ureters',
    _organs,
    [
      const [Offset(132, 478), Offset(146, 530), Offset(188, 574)],
      const [Offset(268, 480), Offset(254, 530), Offset(212, 574)],
    ],
    width: 5,
    color: const Color(0xFFD8C27A),
    depth: 1,
    anchor: const Offset(146, 530),
  ),
  _fill(
    'small_intestine',
    _organs,
    [
      _blob(const [
        Offset(165, 455),
        Offset(200, 448),
        Offset(236, 456),
        Offset(242, 490),
        Offset(236, 528),
        Offset(205, 546),
        Offset(172, 532),
        Offset(160, 500),
      ]),
    ],
    color: const Color(0xFFF0B9A0),
    depth: 3,
    anchor: const Offset(200, 500),
  ),
  _line(
    'large_intestine',
    _organs,
    [
      const [
        Offset(150, 512),
        Offset(150, 440),
        Offset(165, 430),
        Offset(240, 428),
        Offset(252, 440),
        Offset(254, 515),
        Offset(240, 545),
        Offset(214, 556),
      ],
    ],
    width: 22,
    color: const Color(0xFFD79A6A),
    depth: 4,
    anchor: const Offset(254, 480),
  ),
  _fill(
    'uterus',
    _organs,
    [
      _blob(const [
        Offset(180, 540),
        Offset(220, 540),
        Offset(224, 556),
        Offset(210, 570),
        Offset(190, 570),
        Offset(176, 556),
      ]),
    ],
    color: const Color(0xFFD98AA6),
    depth: 5,
  ),
  _fill(
    'ovaries',
    _glands,
    [
      _oval(const Offset(166, 552), 7, 10),
      _oval(const Offset(234, 552), 7, 10),
    ],
    color: endocrineColor,
    depth: 6,
    anchor: const Offset(166, 552),
  ),
  _fill(
    'bladder',
    _organs,
    [_oval(const Offset(200, 592), 26, 20)],
    color: const Color(0xFFE9D27A),
    depth: 3,
  ),
  _fill(
    'prostate',
    _organs,
    [_oval(const Offset(200, 620), 11, 8)],
    color: const Color(0xFFC9A0B8),
    depth: 4,
  ),
  _fill(
    'testes',
    _glands,
    [
      _oval(const Offset(190, 646), 8, 11),
      _oval(const Offset(210, 646), 8, 11),
    ],
    color: endocrineColor,
    depth: 4,
    anchor: const Offset(210, 646),
  ),
  // ---- endocrine-only glands ---------------------------------------------
  _fill(
    'hypothalamus',
    _glands,
    [_oval(const Offset(200, 72), 7, 5)],
    color: const Color(0xFFE8862E),
    depth: 7,
  ),
  _fill(
    'pituitary',
    _glands,
    [_oval(const Offset(200, 84), 5, 5)],
    color: endocrineColor,
    depth: 8,
  ),
  _fill(
    'pineal',
    _glands,
    [_oval(const Offset(214, 64), 4, 4)],
    color: endocrineColor,
    depth: 8,
  ),
  _fill(
    'thyroid',
    _glands,
    [
      _oval(const Offset(189, 158), 8, 13),
      _oval(const Offset(211, 158), 8, 13),
      Path()..addRect(const Rect.fromLTWH(192, 160, 16, 7)),
    ],
    color: endocrineColor,
    depth: 7,
    anchor: const Offset(211, 156),
  ),
  _fill(
    'parathyroids',
    _glands,
    [
      _oval(const Offset(180, 152), 3, 3),
      _oval(const Offset(180, 164), 3, 3),
      _oval(const Offset(220, 152), 3, 3),
      _oval(const Offset(220, 164), 3, 3),
    ],
    color: const Color(0xFFE8862E),
    depth: 8,
    anchor: const Offset(180, 164),
  ),
  // ---- vascular -----------------------------------------------------------
  _line(
    'aorta',
    _vessels,
    [
      const [
        Offset(218, 232),
        Offset(214, 210),
        Offset(222, 196),
        Offset(236, 198),
        Offset(244, 212),
        Offset(240, 250),
        Offset(214, 300),
        Offset(212, 400),
        Offset(212, 470),
      ],
    ],
    width: 11,
    color: arteryColor,
    depth: 5,
    anchor: const Offset(213, 360),
    scope: 'vascular',
  ),
  _line(
    'common_carotid_arteries',
    _vessels,
    [
      const [Offset(224, 198), Offset(212, 160), Offset(212, 118)],
      const [Offset(220, 198), Offset(190, 160), Offset(188, 118)],
    ],
    width: 6,
    color: arteryColor,
    depth: 4,
    anchor: const Offset(212, 140),
    scope: 'vascular',
  ),
  _line(
    'subclavian_arteries',
    _vessels,
    [
      const [Offset(220, 200), Offset(170, 172), Offset(118, 178)],
      const [Offset(234, 200), Offset(262, 174), Offset(290, 180)],
    ],
    width: 6,
    color: arteryColor,
    depth: 4,
    anchor: const Offset(262, 174),
    scope: 'vascular',
  ),
  _line(
    'pulmonary_trunk',
    _vessels,
    [
      const [Offset(206, 236), Offset(200, 218)],
    ],
    width: 9,
    color: pulmonaryArteryColor,
    depth: 6,
    scope: 'vascular',
  ),
  _line(
    'pulmonary_arteries',
    _vessels,
    [
      const [Offset(200, 218), Offset(165, 214), Offset(140, 226)],
      const [Offset(200, 218), Offset(240, 220), Offset(262, 232)],
    ],
    width: 6,
    color: pulmonaryArteryColor,
    depth: 5,
    anchor: const Offset(152, 220),
    scope: 'vascular',
  ),
  _line(
    'pulmonary_veins',
    _vessels,
    [
      const [Offset(150, 250), Offset(190, 250)],
      const [Offset(262, 250), Offset(232, 252)],
    ],
    width: 5,
    color: pulmonaryVeinColor,
    depth: 5,
    anchor: const Offset(262, 250),
    scope: 'vascular',
  ),
  _line(
    'superior_vena_cava',
    _vessels,
    [
      const [Offset(180, 170), Offset(188, 200), Offset(194, 238)],
    ],
    width: 10,
    color: veinColor,
    depth: 4,
    anchor: const Offset(186, 196),
    scope: 'vascular',
  ),
  _line(
    'inferior_vena_cava',
    _vessels,
    [
      const [
        Offset(198, 286),
        Offset(190, 330),
        Offset(188, 400),
        Offset(188, 470),
      ],
    ],
    width: 10,
    color: veinColor,
    depth: 4,
    anchor: const Offset(188, 330),
    scope: 'vascular',
  ),
  _line(
    'renal_arteries',
    _vessels,
    [
      const [Offset(212, 440), Offset(170, 436), Offset(142, 440)],
      const [Offset(212, 440), Offset(242, 436), Offset(258, 440)],
    ],
    width: 5,
    color: arteryColor,
    depth: 4,
    anchor: const Offset(242, 436),
    scope: 'vascular',
  ),
  _line(
    'renal_veins',
    _vessels,
    [
      const [Offset(188, 452), Offset(160, 450), Offset(142, 454)],
      const [Offset(188, 452), Offset(230, 450), Offset(258, 454)],
    ],
    width: 5,
    color: veinColor,
    depth: 3,
    anchor: const Offset(160, 452),
    scope: 'vascular',
  ),
  _line(
    'common_iliac_arteries',
    _vessels,
    [
      const [Offset(212, 470), Offset(230, 500), Offset(238, 530)],
      const [Offset(212, 470), Offset(196, 500), Offset(182, 530)],
    ],
    width: 7,
    color: arteryColor,
    depth: 4,
    anchor: const Offset(230, 500),
    scope: 'vascular',
  ),
  _line(
    'common_iliac_veins',
    _vessels,
    [
      const [Offset(188, 470), Offset(176, 500), Offset(170, 530)],
      const [Offset(188, 470), Offset(214, 500), Offset(226, 530)],
    ],
    width: 7,
    color: veinColor,
    depth: 3,
    anchor: const Offset(176, 500),
    scope: 'vascular',
  ),
  _line(
    'femoral_arteries',
    _vessels,
    [
      const [Offset(182, 530), Offset(164, 580), Offset(150, 690)],
      const [Offset(238, 530), Offset(238, 580), Offset(250, 690)],
    ],
    width: 6,
    color: arteryColor,
    depth: 4,
    anchor: const Offset(244, 640),
    scope: 'vascular',
  ),
  _line(
    'femoral_veins',
    _vessels,
    [
      const [Offset(170, 530), Offset(154, 580), Offset(138, 690)],
      const [Offset(226, 530), Offset(250, 580), Offset(262, 690)],
    ],
    width: 6,
    color: veinColor,
    depth: 3,
    anchor: const Offset(146, 640),
    scope: 'vascular',
  ),
  _line(
    'hepatic_portal_vein',
    _vessels,
    [
      const [
        Offset(252, 472),
        Offset(228, 440),
        Offset(196, 400),
        Offset(170, 378),
      ],
    ],
    width: 7,
    color: portalVeinColor,
    depth: 5,
    anchor: const Offset(212, 420),
    scope: 'vascular',
  ),
]);

final Map<String, BodyStructure> bodyStructureById = Map.unmodifiable({
  for (final structure in bodyStructures) structure.id: structure,
});
