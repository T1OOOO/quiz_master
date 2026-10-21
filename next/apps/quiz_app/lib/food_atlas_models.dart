import 'dart:math';

const foodAtlasAsset = 'assets/quizipedia/food_atlas.json';

String _required(Map<String, dynamic> value, String key) {
  final result = value[key];
  if (result is! String || result.trim().isEmpty) {
    throw FormatException('$key required');
  }
  return result.trim();
}

List<Map<String, dynamic>> _rows(Object? value, String label) {
  if (value is! List) throw FormatException('$label list required');
  return value
      .map((row) {
        if (row is! Map) throw FormatException('$label row');
        return Map<String, dynamic>.from(row);
      })
      .toList(growable: false);
}

List<String> _ids(Object? value, String label) {
  if (value is! List || value.any((id) => id is! String || id.trim().isEmpty)) {
    throw FormatException('$label ids');
  }
  return List.unmodifiable(value.cast<String>());
}

void _date(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('checked_on date');
  }
  final parsed = DateTime.tryParse(value);
  final parts = value.split('-').map(int.parse).toList();
  if (parsed == null ||
      parsed.year != parts[0] ||
      parsed.month != parts[1] ||
      parsed.day != parts[2]) {
    throw const FormatException('checked_on date');
  }
}

class FoodSource {
  const FoodSource({
    required this.id,
    required this.title,
    required this.url,
    required this.checkedOn,
  });
  final String id, title, url, checkedOn;
  factory FoodSource.fromJson(Map<String, dynamic> json) {
    final url = _required(json, 'url');
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('source url');
    }
    final checkedOn = _required(json, 'checked_on');
    _date(checkedOn);
    return FoodSource(
      id: _required(json, 'id'),
      title: _required(json, 'title'),
      url: url,
      checkedOn: checkedOn,
    );
  }
}

class FoodIngredient {
  const FoodIngredient({
    required this.nameRu,
    required this.nameEn,
    required this.amountRu,
    required this.amountEn,
  });
  final String nameRu, nameEn, amountRu, amountEn;
  factory FoodIngredient.fromJson(Map<String, dynamic> json) => FoodIngredient(
    nameRu: _required(json, 'name_ru'),
    nameEn: _required(json, 'name_en'),
    amountRu: _required(json, 'amount_ru'),
    amountEn: _required(json, 'amount_en'),
  );
}

class FoodStep {
  const FoodStep({required this.textRu, required this.textEn});
  final String textRu, textEn;
  factory FoodStep.fromJson(Map<String, dynamic> json) => FoodStep(
    textRu: _required(json, 'text_ru'),
    textEn: _required(json, 'text_en'),
  );
}

class FoodFact {
  const FoodFact({
    required this.textRu,
    required this.textEn,
    required this.sourceIds,
  });
  final String textRu, textEn;
  final List<String> sourceIds;
  factory FoodFact.fromJson(Map<String, dynamic> json) => FoodFact(
    textRu: _required(json, 'text_ru'),
    textEn: _required(json, 'text_en'),
    sourceIds: _ids(json['source_ids'], 'fact source'),
  );
}

class FoodVariant {
  const FoodVariant({
    required this.nameRu,
    required this.nameEn,
    required this.regionRu,
    required this.regionEn,
    required this.differenceRu,
    required this.differenceEn,
    required this.sourceIds,
  });
  final String nameRu, nameEn, regionRu, regionEn, differenceRu, differenceEn;
  final List<String> sourceIds;
  factory FoodVariant.fromJson(Map<String, dynamic> json) => FoodVariant(
    nameRu: _required(json, 'name_ru'),
    nameEn: _required(json, 'name_en'),
    regionRu: _required(json, 'region_ru'),
    regionEn: _required(json, 'region_en'),
    differenceRu: _required(json, 'difference_ru'),
    differenceEn: _required(json, 'difference_en'),
    sourceIds: _ids(json['source_ids'], 'variant source'),
  );
}

class FoodDish {
  const FoodDish({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    required this.categoryRu,
    required this.categoryEn,
    required this.countryRu,
    required this.countryEn,
    required this.regionRu,
    required this.regionEn,
    required this.summaryRu,
    required this.summaryEn,
    required this.classicNoteRu,
    required this.classicNoteEn,
    required this.originRu,
    required this.originEn,
    required this.servingsRu,
    required this.servingsEn,
    required this.ingredients,
    required this.steps,
    required this.facts,
    required this.variants,
    required this.sourceIds,
  });
  final String id,
      nameRu,
      nameEn,
      categoryRu,
      categoryEn,
      countryRu,
      countryEn,
      regionRu,
      regionEn,
      summaryRu,
      summaryEn,
      classicNoteRu,
      classicNoteEn,
      originRu,
      originEn,
      servingsRu,
      servingsEn;
  final List<FoodIngredient> ingredients;
  final List<FoodStep> steps;
  final List<FoodFact> facts;
  final List<FoodVariant> variants;
  final List<String> sourceIds;
  factory FoodDish.fromJson(Map<String, dynamic> json) {
    final ingredients = _rows(
      json['ingredients'],
      'ingredients',
    ).map(FoodIngredient.fromJson).toList(growable: false);
    final steps = _rows(
      json['steps'],
      'steps',
    ).map(FoodStep.fromJson).toList(growable: false);
    final facts = _rows(
      json['facts'],
      'facts',
    ).map(FoodFact.fromJson).toList(growable: false);
    final variants = _rows(
      json['variants'],
      'variants',
    ).map(FoodVariant.fromJson).toList(growable: false);
    if (ingredients.length < 3 || steps.length < 3 || facts.isEmpty) {
      throw const FormatException('dish minimum detail');
    }
    return FoodDish(
      id: _required(json, 'id'),
      nameRu: _required(json, 'name_ru'),
      nameEn: _required(json, 'name_en'),
      categoryRu: _required(json, 'category_ru'),
      categoryEn: _required(json, 'category_en'),
      countryRu: _required(json, 'country_ru'),
      countryEn: _required(json, 'country_en'),
      regionRu: _required(json, 'region_ru'),
      regionEn: _required(json, 'region_en'),
      summaryRu: _required(json, 'summary_ru'),
      summaryEn: _required(json, 'summary_en'),
      classicNoteRu: _required(json, 'classic_note_ru'),
      classicNoteEn: _required(json, 'classic_note_en'),
      originRu: _required(json, 'origin_ru'),
      originEn: _required(json, 'origin_en'),
      servingsRu: _required(json, 'servings_ru'),
      servingsEn: _required(json, 'servings_en'),
      ingredients: ingredients,
      steps: steps,
      facts: facts,
      variants: variants,
      sourceIds: _ids(json['source_ids'], 'dish source'),
    );
  }
}

enum FoodQuestionKind { origin, composition }

class FoodQuestion {
  const FoodQuestion({
    required this.dishId,
    required this.kind,
    required this.promptRu,
    required this.promptEn,
    required this.answerRu,
    required this.answerEn,
    required this.optionsRu,
    required this.optionsEn,
    required this.explanationRu,
    required this.explanationEn,
    required this.sourceIds,
  });
  final String dishId,
      promptRu,
      promptEn,
      answerRu,
      answerEn,
      explanationRu,
      explanationEn;
  final FoodQuestionKind kind;
  final List<String> optionsRu, optionsEn, sourceIds;
}

class FoodAtlas {
  const FoodAtlas({
    required this.coverageNoteRu,
    required this.coverageNoteEn,
    required this.sources,
    required this.dishes,
  });
  final String coverageNoteRu, coverageNoteEn;
  final List<FoodSource> sources;
  final List<FoodDish> dishes;
  factory FoodAtlas.fromJson(Map<String, dynamic> json) {
    if (json['schema_version'] != 'qm-food-atlas/v1') {
      throw const FormatException('food atlas schema');
    }
    final sources = _rows(
      json['sources'],
      'sources',
    ).map(FoodSource.fromJson).toList(growable: false);
    final dishes = _rows(
      json['dishes'],
      'dishes',
    ).map(FoodDish.fromJson).toList(growable: false);
    void unique(Iterable<String> values, String label) {
      if (values.toSet().length != values.length) {
        throw FormatException('duplicate $label');
      }
    }

    unique(sources.map((source) => source.id), 'source');
    unique(dishes.map((dish) => dish.id), 'dish');
    unique(
      dishes.map((dish) => dish.nameEn.toLowerCase()),
      'English dish name',
    );
    unique(
      dishes.map((dish) => dish.nameRu.toLowerCase()),
      'Russian dish name',
    );
    final sourceIds = sources.map((source) => source.id).toSet();
    bool refs(Iterable<String> ids) =>
        ids.isNotEmpty && ids.every(sourceIds.contains);
    final signaturesEn = <String>{}, signaturesRu = <String>{};
    final regionsEn = <String, String>{}, regionsRu = <String, String>{};
    for (final dish in dishes) {
      final regionEn = dish.regionEn.toLowerCase(),
          regionRu = dish.regionRu.toLowerCase();
      if ((regionsEn.containsKey(regionEn) &&
              regionsEn[regionEn] != regionRu) ||
          (regionsRu.containsKey(regionRu) &&
              regionsRu[regionRu] != regionEn)) {
        throw const FormatException('inconsistent region translations');
      }
      regionsEn[regionEn] = regionRu;
      regionsRu[regionRu] = regionEn;
      if (!refs(dish.sourceIds) ||
          !dish.facts.every((fact) => refs(fact.sourceIds)) ||
          !dish.variants.every((variant) => refs(variant.sourceIds))) {
        throw const FormatException('dish source relation');
      }
      final signatureEn =
          dish.ingredients
              .map((item) => item.nameEn.trim().toLowerCase())
              .toList()
            ..sort();
      final signatureRu =
          dish.ingredients
              .map((item) => item.nameRu.trim().toLowerCase())
              .toList()
            ..sort();
      if (!signaturesEn.add(signatureEn.join('|')) ||
          !signaturesRu.add(signatureRu.join('|'))) {
        throw const FormatException('ambiguous ingredient signature');
      }
    }
    if (dishes.length >= 10 && regionsEn.length < 4) {
      throw const FormatException(
        'four distinct regions required for training',
      );
    }
    return FoodAtlas(
      coverageNoteRu: _required(json, 'coverage_note_ru'),
      coverageNoteEn: _required(json, 'coverage_note_en'),
      sources: List.unmodifiable(sources),
      dishes: List.unmodifiable(dishes),
    );
  }
  FoodSource sourceFor(String id) =>
      sources.firstWhere((source) => source.id == id);
  List<FoodQuestion> round({int seed = 0, FoodQuestionKind? topic}) {
    if (dishes.length < 10) {
      throw const FormatException('ten dishes required for training');
    }
    final pool = List<FoodDish>.from(dishes)..shuffle(Random(seed));
    final selected = pool.take(10).toList(growable: false);
    return List.unmodifiable([
      for (var i = 0; i < selected.length; i++)
        _question(
          selected[i],
          topic ??
              (i.isEven
                  ? FoodQuestionKind.origin
                  : FoodQuestionKind.composition),
          seed + i,
        ),
    ]);
  }

  FoodQuestion _question(FoodDish dish, FoodQuestionKind kind, int seed) {
    final answerEn = kind == FoodQuestionKind.origin
        ? dish.regionEn
        : dish.nameEn;
    final answerRu = kind == FoodQuestionKind.origin
        ? dish.regionRu
        : dish.nameRu;
    final candidates = kind == FoodQuestionKind.origin
        ? dishes
              .map((item) => (en: item.regionEn, ru: item.regionRu))
              .where((item) => item.en != answerEn)
              .toSet()
              .toList()
        : dishes
              .map((item) => (en: item.nameEn, ru: item.nameRu))
              .where((item) => item.en != answerEn)
              .toList();
    candidates.shuffle(Random(seed));
    final distinctEn = {answerEn.toLowerCase()},
        distinctRu = {answerRu.toLowerCase()};
    final options = <({String en, String ru})>[];
    for (final candidate in candidates) {
      if (distinctEn.contains(candidate.en.toLowerCase()) ||
          distinctRu.contains(candidate.ru.toLowerCase())) {
        continue;
      }
      distinctEn.add(candidate.en.toLowerCase());
      distinctRu.add(candidate.ru.toLowerCase());
      options.add(candidate);
      if (options.length == 5) break;
    }
    if (options.length < 5) {
      throw const FormatException('six unambiguous question options required');
    }
    options.add((en: answerEn, ru: answerRu));
    options.shuffle(Random(seed));
    final ingredientsEn = dish.ingredients
        .map((item) => item.nameEn)
        .join(', ');
    return FoodQuestion(
      dishId: dish.id,
      kind: kind,
      answerRu: answerRu,
      answerEn: answerEn,
      optionsRu: List.unmodifiable(options.map((item) => item.ru)),
      optionsEn: List.unmodifiable(options.map((item) => item.en)),
      sourceIds: dish.sourceIds,
      promptRu: kind == FoodQuestionKind.origin
          ? 'С каким регионом связана эта справочная версия блюда «${dish.nameRu}»?'
          : 'Какое блюдо в справочнике готовят из: ${dish.ingredients.map((item) => item.nameRu).join(', ')}?',
      promptEn: kind == FoodQuestionKind.origin
          ? 'Which region is this reference version of “${dish.nameEn}” associated with?'
          : 'Which reference dish uses these named classic ingredients: $ingredientsEn?',
      explanationRu: kind == FoodQuestionKind.origin
          ? dish.originRu
          : '${dish.nameRu}: ${dish.classicNoteRu}',
      explanationEn: kind == FoodQuestionKind.origin
          ? dish.originEn
          : '${dish.nameEn}: ${dish.classicNoteEn}',
    );
  }
}
