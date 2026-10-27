import 'dart:math';

import 'package:flutter/material.dart';

import 'periodic_data.dart';

class PeriodicElement {
  const PeriodicElement(
    this.number,
    this.symbol,
    this.name,
    this.nameRu,
    this.mass,
    this.family,
  );
  final int number;
  final String symbol, name, nameRu, mass, family;
}

final periodicElements = List.generate(118, (i) {
  final row = periodicData[i];
  return PeriodicElement(i + 1, row[0], row[1], row[2], row[3], row[4]);
}, growable: false);

class PeriodicTablePage extends StatefulWidget {
  const PeriodicTablePage({super.key});
  @override
  State<PeriodicTablePage> createState() => _PeriodicTablePageState();
}

class _PeriodicTablePageState extends State<PeriodicTablePage> {
  String query = '';
  String? family;
  bool get russian => Localizations.localeOf(context).languageCode == 'ru';
  String label(String en, String ru) => russian ? ru : en;
  String familyLabel(String value) {
    if (!russian) return value;
    return const {
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
        }[value] ??
        value;
  }

  Color familyColor(String family) {
    final families = periodicElements.map((e) => e.family).toSet().toList();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return HSLColor.fromAHSL(
      1,
      families.indexOf(family) * 36.0,
      0.35,
      dark ? 0.28 : 0.88,
    ).toColor();
  }

  void showElement(PeriodicElement e) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${e.symbol} — ${russian ? e.nameRu : e.name}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text('${label('Atomic number', 'Атомный номер')}: ${e.number}'),
              Text(
                '${label('Atomic mass (PubChem)', 'Атомная масса (PubChem)')}: ${e.mass} u',
              ),
              Text('${label('Family', 'Семейство')}: ${familyLabel(e.family)}'),
              Text(
                '${label('Period', 'Период')}: ${e.number >= 57 && e.number <= 71
                    ? 6
                    : e.number >= 89 && e.number <= 103
                    ? 7
                    : position(e.number).$1 + 1}',
              ),
              if (!(e.number >= 57 && e.number <= 71) &&
                  !(e.number >= 89 && e.number <= 103))
                Text(
                  '${label('Group', 'Группа')}: ${position(e.number).$2 + 1}',
                ),
              if (e.number == 43 || e.number == 61 || e.number >= 84)
                Text(
                  label(
                    'For radioactive elements this value may refer to an isotope.',
                    'Для радиоактивных элементов значение может относиться к отдельному изотопу.',
                  ),
                ),
              const SizedBox(height: 8),
              Text(label('Data: PubChem / NCBI', 'Данные: PubChem / NCBI')),
            ],
          ),
        ),
      ),
    );
  }

  // Conventional long form, with lanthanoids and actinoids below.
  (int, int) position(int n) {
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

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final matches = periodicElements
        .where(
          (e) =>
              (family == null || e.family == family) &&
              (q.isEmpty ||
                  e.symbol.toLowerCase().contains(q) ||
                  e.name.toLowerCase().contains(q) ||
                  e.nameRu.toLowerCase().contains(q) ||
                  '${e.number}' == q),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(label('Periodic table', 'Таблица Менделеева')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: label(
                'Name, symbol or number',
                'Название, символ или номер',
              ),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          DropdownButton<String>(
            value: family ?? '',
            isExpanded: true,
            items: [
              DropdownMenuItem(
                value: '',
                child: Text(label('All families', 'Все группы')),
              ),
              for (final f in periodicElements.map((e) => e.family).toSet())
                DropdownMenuItem(value: f, child: Text(familyLabel(f))),
            ],
            onChanged: (value) =>
                setState(() => family = value == '' ? null : value),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _ElementPractice(),
                ),
              ),
              icon: const Icon(Icons.quiz_outlined),
              label: Text(label('Practise', 'Тренироваться')),
            ),
          ),
          const SizedBox(height: 16),
          if (q.isEmpty && family == null) ...[
            Text(
              label(
                'Scroll horizontally; select an element',
                'Прокрутите таблицу; выберите элемент',
              ),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(label('Colour legend', 'Обозначения цветов')),
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final f
                        in periodicElements.map((e) => e.family).toSet())
                      Chip(
                        backgroundColor: familyColor(f),
                        label: Text(familyLabel(f)),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 18 * 58 + 24,
                height: 9 * 58 + 24,
                child: Stack(
                  children: [
                    for (var col = 0; col < 18; col++)
                      Positioned(
                        left: 24 + col * 58,
                        top: 0,
                        width: 56,
                        child: Center(child: Text('${col + 1}')),
                      ),
                    for (var row = 0; row < 7; row++)
                      Positioned(
                        left: 0,
                        top: 24 + row * 58,
                        width: 24,
                        height: 56,
                        child: Center(child: Text('${row + 1}')),
                      ),
                    const Positioned(
                      left: 140,
                      top: 314,
                      width: 56,
                      height: 56,
                      child: Center(child: Text('57–71')),
                    ),
                    const Positioned(
                      left: 140,
                      top: 372,
                      width: 56,
                      height: 56,
                      child: Center(child: Text('89–103')),
                    ),
                    for (final e in periodicElements)
                      Positioned(
                        left: 24 + position(e.number).$2 * 58,
                        top: 24 + position(e.number).$1 * 58,
                        width: 56,
                        height: 56,
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: familyColor(e.family),
                          child: InkWell(
                            onTap: () => showElement(e),
                            child: Semantics(
                              label:
                                  '${e.number} ${russian ? e.nameRu : e.name}',
                              button: true,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${e.number}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                  Text(
                                    e.symbol,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label('All elements', 'Все элементы'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
          for (final e in matches)
            ListTile(
              leading: Text(
                e.symbol,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              title: Text(russian ? e.nameRu : e.name),
              subtitle: Text('${e.number}'),
              onTap: () => showElement(e),
            ),
          if (matches.isEmpty)
            Text(label('No elements found', 'Элементы не найдены')),
        ],
      ),
    );
  }
}

class _ElementPractice extends StatefulWidget {
  const _ElementPractice();
  @override
  State<_ElementPractice> createState() => _ElementPracticeState();
}

class _ElementPracticeState extends State<_ElementPractice> {
  int index = 0;
  int? selected;
  final random = Random();
  late List<int> choices = _choices();
  List<int> _choices() =>
      List.generate(4, (i) => (index + i) % periodicElements.length)
        ..shuffle(random);
  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final answer = periodicElements[index];
    return Scaffold(
      appBar: AppBar(title: Text(ru ? 'Тренировка' : 'Practise')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            ru
                ? 'Какой символ у элемента ${answer.nameRu}?'
                : 'Which symbol belongs to ${answer.name}?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          for (final choice in choices)
            OutlinedButton(
              onPressed: selected == null
                  ? () => setState(() => selected = choice)
                  : null,
              child: Text(periodicElements[choice].symbol),
            ),
          if (selected != null) ...[
            Text(
              '${selected == index ? (ru ? 'Верно' : 'Correct') : (ru ? 'Правильный ответ' : 'Correct answer')}: ${answer.symbol} — ${ru ? answer.nameRu : answer.name}',
            ),
            TextButton(
              onPressed: () => setState(() {
                index = (index + 1) % periodicElements.length;
                selected = null;
                choices = _choices();
              }),
              child: Text(ru ? 'Далее' : 'Next'),
            ),
          ],
        ],
      ),
    );
  }
}
