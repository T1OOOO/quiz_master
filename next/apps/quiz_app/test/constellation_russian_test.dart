import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/constellation_atlas.dart';

void main() {
  test(
    'Russian star labels prefer shipped Russian names and preserve English',
    () {
      expect(
        starLabel({'name': 'Sirius', 'name_ru': 'Сириус'}, true),
        'Сириус',
      );
      expect(
        starLabel({'name': 'Alpheratz', 'name_ru': 'Альферац'}, true),
        'Альферац',
      );
      expect(
        starLabel({'name': 'Alp Ant', 'name_ru': 'Альфа Насоса'}, true),
        'Альфа Насоса',
      );
      expect(
        starLabel({'name': '52TauCet', 'name_ru': '52 Тау Кита'}, true),
        '52 Тау Кита',
      );
      expect(
        starLabel({
          'name': '82 G. Eri',
          'name_ru': '82 по каталогу Гулда Эридана',
        }, true),
        '82 по каталогу Гулда Эридана',
      );
      expect(
        starLabel({'name': 'Sirius', 'name_ru': 'Сириус'}, false),
        'Sirius',
      );
    },
  );

  testWidgets(
    'shipped RU labels are Russian while English labels remain unchanged',
    (tester) async {
      await tester.runAsync(() async {
        final raw = await rootBundle.loadString(
          'assets/quizipedia/catalog.json',
        );
        final catalog = jsonDecode(raw) as Map<String, dynamic>;
        for (final row in (catalog['constellations'] as List).cast<Map>()) {
          final explanation = row['explanation_ru'] as String;
          expect(explanation, contains('Количество звёзд на учебной схеме:'));
          expect(explanation, contains('«Стеллариума»'));
          expect(
            explanation.replaceAll(RegExp(r'HIP \d+'), ''),
            isNot(contains(RegExp('[A-Za-z]'))),
          );
          for (final star in (row['stars'] as List).cast<Map>()) {
            expect(star['name_ru'], isA<String>());
            final russian = (star['name_ru'] as String).trim();
            expect(russian, isNotEmpty);
            expect(
              starLabel(star.cast<String, dynamic>(), false),
              star['name'],
            );
            if (!russian.startsWith('HIP ')) {
              expect(russian, isNot(contains(RegExp('[A-Za-z]'))));
            }
          }
        }
      });
    },
  );

  testWidgets('reviewed Russian star-name overrides and compact designations', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final raw = await rootBundle.loadString('assets/quizipedia/catalog.json');
      final catalog = jsonDecode(raw) as Map<String, dynamic>;
      final expected = <String, String>{
        '65Xi 1Cet': '65 Кси 1 Кита',
        '73Xi 2Cet': '73 Кси 2 Кита',
        '5Xi 2CMa': '5 Кси 2 Большого Пса',
        '7Nu 2CMa': '7 Ню 2 Большого Пса',
        '25Nu 2Dra': '25 Ню 2 Дракона',
        '27Pi 1Peg': '27 Пи 1 Пегаса',
        '37Xi 2Sgr': '37 Кси 2 Стрельца',
        'Schedar': 'Шедар',
        'Rigil Kentaurus': 'Ригиль Кентаврус',
        'Elnath': 'Эль-Нат',
        'Adhara': 'Адара',
        'Kaffaljidhma': 'Каффалидма',
        'Gienah': 'Гиена',
        'Cor Caroli': 'Кор Кароли',
        'Alhena': 'Альхена',
        'Hamal': 'Хамаль',
        'Gomeisa': 'Гомейза',
        'Rasalhague': 'Рас Альхаге',
        'Cebalrai': 'Цельбальрай',
        'Alrescha': 'Альреша',
        'Dschubba': 'Джубба',
        'Peacock': 'Пеакок',
        'Prima Hyadum': 'Прима Гиадум',
        'Secunda Hyadum': 'Секунда Гиадум',
        'Tianguan': 'Тянь-Гуань',
        'Alya': 'Алия',
        'Megrez': 'Мегрец',
      };
      final stars = <Map<String, dynamic>>[
        for (final row in (catalog['constellations'] as List).cast<Map>())
          for (final star in (row['stars'] as List).cast<Map>())
            star.cast<String, dynamic>(),
      ];
      for (final entry in expected.entries) {
        final matches = stars.where((star) => star['name'] == entry.key);
        expect(matches, isNotEmpty, reason: '${entry.key} is shipped');
        for (final star in matches) {
          expect(star['name_ru'], entry.value);
          expect(starLabel(star, false), entry.key);
        }
      }
    });
  });
}
