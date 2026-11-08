/// Element model for the periodic table: layout positions, classification and
/// search. Values come from `periodic_data.dart` (PubChem); nothing here is
/// invented, only derived (period, group, block) from the element number.
library;

import 'dart:math';

import 'periodic_data.dart';

enum ElementBlock { s, p, d, f }

enum MatterState { solid, liquid, gas, unknown }

enum MetalKind { metal, metalloid, nonmetal }

/// How cells are coloured.
enum ElementColorMode { category, state, block, metal }

class PeriodicElement {
  PeriodicElement._(this.number, List<String> row)
    : symbol = row[0],
      name = row[1],
      nameRu = row[2],
      mass = row[3],
      family = row[4],
      electronConfiguration = row[5].replaceAll(' (predicted)', ''),
      configurationPredicted = row[5].endsWith('(predicted)'),
      electronegativity = row[6],
      oxidationStates = row[7],
      state = switch (row[8].replaceAll(' (predicted)', '')) {
        'Solid' => MatterState.solid,
        'Liquid' => MatterState.liquid,
        'Gas' => MatterState.gas,
        _ => MatterState.unknown,
      },
      statePredicted = row[8].endsWith('(predicted)'),
      meltingPointK = double.tryParse(row[9]),
      boilingPointK = double.tryParse(row[10]),
      density = row[11],
      yearDiscovered = row[12];

  final int number;
  final String symbol, name, nameRu, mass, family;
  final String electronConfiguration;
  final bool configurationPredicted;
  final String electronegativity, oxidationStates;
  final MatterState state;
  final bool statePredicted;
  final double? meltingPointK, boilingPointK;
  final String density, yearDiscovered;

  /// Lanthanoids and actinoids (La–Lu, Ac–Lr) sit in the detached rows.
  bool get isLanthanoid => number >= 57 && number <= 71;
  bool get isActinoid => number >= 89 && number <= 103;
  bool get isFBlockRow => isLanthanoid || isActinoid;

  int get period {
    if (isLanthanoid) return 6;
    if (isActinoid) return 7;
    return gridRow + 1;
  }

  /// 1–18, or null for the detached f-block rows.
  int? get group => isFBlockRow ? null : gridColumn + 1;

  /// Logical grid row: 0–6 for periods 1–7, 7 lanthanoids, 8 actinoids.
  int get gridRow => _position(number).$1;

  /// Logical grid column 0–17 (f-block rows use columns 2–16).
  int get gridColumn => _position(number).$2;

  ElementBlock get block {
    if (isFBlockRow) return ElementBlock.f;
    final g = group!;
    if (number == 2 || g <= 2) return ElementBlock.s;
    if (g >= 13) return ElementBlock.p;
    return ElementBlock.d;
  }

  MetalKind get metalKind => switch (family) {
    'Metalloid' => MetalKind.metalloid,
    'Nonmetal' || 'Noble gas' || 'Halogen' => MetalKind.nonmetal,
    _ => MetalKind.metal,
  };

  /// PubChem lists an isotope mass for elements without a stable isotope.
  bool get massIsIsotope => number == 43 || number == 61 || number >= 84;

  String get pubChemUrl => 'https://pubchem.ncbi.nlm.nih.gov/element/$number';

  /// Legend key for the given colouring.
  String colorKey(ElementColorMode mode) => switch (mode) {
    ElementColorMode.category => family,
    ElementColorMode.state => state.name,
    ElementColorMode.block => block.name,
    ElementColorMode.metal => metalKind.name,
  };

  @override
  String toString() => '$symbol($number)';
}

// Conventional 18-column long form with lanthanoids and actinoids below.
(int, int) _position(int n) {
  if (n == 1) return (0, 0);
  if (n == 2) return (0, 17);
  if (n <= 10) return (1, n <= 4 ? n - 3 : n + 7);
  if (n <= 18) return (2, n <= 12 ? n - 11 : n - 1);
  if (n <= 36) return (3, n - 19);
  if (n <= 54) return (4, n - 37);
  if (n <= 56) return (5, n - 55);
  if (n <= 71) return (7, n - 57 + 2);
  if (n <= 86) return (5, n - 69);
  if (n <= 88) return (6, n - 87);
  if (n <= 103) return (8, n - 89 + 2);
  return (6, n - 101);
}

final List<PeriodicElement> periodicElements = List.unmodifiable(
  List.generate(
    periodicData.length,
    (i) => PeriodicElement._(i + 1, periodicData[i]),
  ),
);

/// Element at a logical grid cell, or null for an empty cell.
PeriodicElement? elementAt(int row, int column) => _byCell[(row, column)];

final Map<(int, int), PeriodicElement> _byCell = {
  for (final e in periodicElements) (e.gridRow, e.gridColumn): e,
};

PeriodicElement elementByNumber(int number) => periodicElements[number - 1];

/// Family keys in table order, used for legend chips.
const elementFamilies = [
  'Alkali metal',
  'Alkaline earth metal',
  'Transition metal',
  'Post-transition metal',
  'Metalloid',
  'Nonmetal',
  'Halogen',
  'Noble gas',
  'Lanthanide',
  'Actinide',
];

String familyLabel(String family, {required bool russian}) => russian
    ? const {
            'Nonmetal': 'Неметаллы',
            'Noble gas': 'Благородные газы',
            'Alkali metal': 'Щелочные металлы',
            'Alkaline earth metal': 'Щёлочноземельные металлы',
            'Metalloid': 'Металлоиды',
            'Halogen': 'Галогены',
            'Post-transition metal': 'Постпереходные металлы',
            'Transition metal': 'Переходные металлы',
            'Lanthanide': 'Лантаноиды',
            'Actinide': 'Актиноиды',
          }[family] ??
          family
    : const {
            'Lanthanide': 'Lanthanoids',
            'Actinide': 'Actinoids',
            'Noble gas': 'Noble gases',
          }[family] ??
          '${family}s';

/// Singular family name for a sentence about one element.
String familySingular(String family, {required bool russian}) => russian
    ? const {
            'Nonmetal': 'неметалл',
            'Noble gas': 'благородный газ',
            'Alkali metal': 'щелочной металл',
            'Alkaline earth metal': 'щёлочноземельный металл',
            'Metalloid': 'металлоид',
            'Halogen': 'галоген',
            'Post-transition metal': 'постпереходный металл',
            'Transition metal': 'переходный металл',
            'Lanthanide': 'лантаноид',
            'Actinide': 'актиноид',
          }[family] ??
          family
    : family.toLowerCase();

/// Legend entries (key, label) for a colour mode.
List<(String, String)> legendEntries(
  ElementColorMode mode, {
  required bool russian,
}) => switch (mode) {
  ElementColorMode.category => [
    for (final f in elementFamilies) (f, familyLabel(f, russian: russian)),
  ],
  ElementColorMode.state => [
    ('solid', russian ? 'Твёрдое' : 'Solid'),
    ('liquid', russian ? 'Жидкое' : 'Liquid'),
    ('gas', russian ? 'Газ' : 'Gas'),
    ('unknown', russian ? 'Неизвестно' : 'Unknown'),
  ],
  ElementColorMode.block => [
    ('s', russian ? 's-блок' : 's-block'),
    ('p', russian ? 'p-блок' : 'p-block'),
    ('d', russian ? 'd-блок' : 'd-block'),
    ('f', russian ? 'f-блок' : 'f-block'),
  ],
  ElementColorMode.metal => [
    ('metal', russian ? 'Металлы' : 'Metals'),
    ('metalloid', russian ? 'Металлоиды' : 'Metalloids'),
    ('nonmetal', russian ? 'Неметаллы' : 'Nonmetals'),
  ],
};

/// Search by symbol, name (en/ru) or number; best matches first.
List<PeriodicElement> searchElements(String query) {
  final q = query.trim().toLowerCase().replaceAll('ё', 'е');
  if (q.isEmpty) return const [];
  int rank(PeriodicElement e) {
    final symbol = e.symbol.toLowerCase();
    final name = e.name.toLowerCase();
    final nameRu = e.nameRu.toLowerCase().replaceAll('ё', 'е');
    if ('${e.number}' == q || symbol == q || name == q || nameRu == q) {
      return 0;
    }
    if (symbol.startsWith(q) || name.startsWith(q) || nameRu.startsWith(q)) {
      return 1;
    }
    if ('${e.number}'.startsWith(q) && q.length <= 3) return 2;
    if (name.contains(q) || nameRu.contains(q)) return 3;
    return -1;
  }

  final ranked =
      [
        for (final e in periodicElements)
          if (rank(e) >= 0) (rank(e), e),
      ]..sort((a, b) {
        final byRank = a.$1.compareTo(b.$1);
        return byRank != 0 ? byRank : a.$2.number.compareTo(b.$2.number);
      });
  return [for (final r in ranked) r.$2];
}

enum GridDirection { left, right, up, down }

/// The next element from [from] in [direction], skipping empty cells;
/// null at the table edge.
PeriodicElement? neighborElement(PeriodicElement from, GridDirection dir) {
  var row = from.gridRow;
  var col = from.gridColumn;
  for (var i = 0; i < 18; i++) {
    switch (dir) {
      case GridDirection.left:
        col--;
      case GridDirection.right:
        col++;
      case GridDirection.up:
        row--;
      case GridDirection.down:
        row++;
    }
    if (row < 0 || row > 8 || col < 0 || col > 17) return null;
    final e = elementAt(row, col);
    if (e != null) return e;
  }
  return null;
}

/// Distractors for a quiz about [target]: nearest by period/group first.
List<PeriodicElement> elementDistractors(
  PeriodicElement target,
  int count,
  Random random,
) {
  double distance(PeriodicElement e) {
    final sameRow = e.gridRow == target.gridRow;
    final sameCol = e.gridColumn == target.gridColumn;
    final d =
        (e.gridRow - target.gridRow).abs() +
        (e.gridColumn - target.gridColumn).abs();
    // Period and group neighbours come first; a little noise varies the set.
    return (sameRow || sameCol ? d : d + 6) + random.nextDouble() * 2.5;
  }

  final scores = {
    for (final e in periodicElements)
      if (e.number != target.number) e.number: distance(e),
  };
  final others = [
    for (final e in periodicElements)
      if (e.number != target.number) e,
  ]..sort((a, b) => scores[a.number]!.compareTo(scores[b.number]!));
  return others.take(count).toList();
}
