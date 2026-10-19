"""Apply the independent editorial findings to the reviewed candidate."""
import json
from pathlib import Path

root = Path(__file__).parent
doc = json.loads((root / 'food_atlas.reviewed-candidate.json').read_text(encoding='utf-8'))
by_id = {dish['id']: dish for dish in doc['dishes']}

by_id['pizza_marinara']['variants'][0].update(
    difference_ru='Маргарита STG использует моцареллу и базилик вместо чеснока и орегано; пропорции начинки также отличаются.',
    difference_en='Margherita STG uses mozzarella and basil instead of garlic and oregano; topping proportions also differ.')
by_id['paella_valenciana'].update(
    origin_ru='Региональный рецепт называет паэлью одним из наиболее известных блюд Валенсии и рекомендует рис Valencia DOP.',
    origin_en='The regional recipe presents paella as one of Valencia’s best-known dishes and recommends Valencia DOP rice.')
by_id['ceviche_peruano'].update(
    servings_ru='Рецептура на 1 кг рыбы; источник не задаёт количество порций.',
    servings_en='Recipe for 1 kg fish; the source does not specify a serving count.')
by_id['ceviche_peruano']['ingredients'][0]['name_ru'] = 'свежее рыбное филе и лаймы'
by_id['ukrainian_borscht_ribs']['variants'] = []

def ingredient(ru, en, amount_ru, amount_en):
    return dict(name_ru=ru, name_en=en, amount_ru=amount_ru, amount_en=amount_en)

def step(ru, en):
    return dict(text_ru=ru, text_en=en)

# Keep marinade, toppings and sauce quantities distinct rather than losing oil
# and sugar when the same ingredient appears in several components.
bibimbap = by_id['bibimbap']
bibimbap['ingredients'] = [
    ingredient('короткозёрный рис', 'short-grain rice', '3 чашки', '3 cups'),
    ingredient('тонко нарезанная говядина', 'thinly sliced beef', '8 унций (≈227 г)', '8 oz (about 227 g)'),
    ingredient('проростки маша и шпинат', 'mung bean sprouts and spinach', 'по 8 унций (≈227 г)', '8 oz each (about 227 g each)'),
    ingredient('огурцы, грибы и морковь', 'cucumbers, mushrooms and carrots', '5, 4 и 5 унций (≈142, 113 и 142 г)', '5, 4 and 5 oz (about 142, 113 and 142 g)'),
    ingredient('соевый соус, сахар, кунжутное масло и рисовое вино — маринад', 'soy sauce, sugar, sesame oil and rice wine — marinade', '1½ ст. л.; 2 ч. л.; 2 ч. л.; 2 ч. л.', '1½ tbsp; 2 tsp; 2 tsp; 2 tsp'),
    ingredient('измельчённый чеснок и зелёный лук', 'minced garlic and scallion', '2½ ч. л. и 4 ст. л. всего: 1 ч. л. и 1 ст. л. в маринад, остальное к овощам', '2½ tsp and 4 tbsp total: 1 tsp and 1 tbsp for marinade, the rest for vegetables'),
    ingredient('кунжутное масло — овощи', 'sesame oil — vegetables', 'по 1 ч. л. для проростков, шпината и огурцов', '1 tsp each for sprouts, spinach and cucumbers'),
    ingredient('кочхуджан, сахар, кунжутное масло и вода — соус', 'gochujang, sugar, sesame oil and water — sauce', '4 ст. л.; 2 ч. л.; 1 ст. л.; 1 ст. л.', '4 tbsp; 2 tsp; 1 tbsp; 1 tbsp'),
    ingredient('яйца', 'eggs', '4 шт.', '4'),
    ingredient('кунжут, соль, перец, растительное масло и вода для риса и бланширования', 'sesame seeds, salt, pepper, cooking oil and water for rice and blanching', 'по вкусу и для приготовления', 'to taste and as needed for cooking'),
]
bibimbap['steps'] = [
    step('Сварите рис чуть суше обычного. Смешайте говядину с маринадом, долей чеснока и лука, перцем и кунжутом; выдержите 20 минут и обжарьте 2–3 минуты.',
         'Cook rice slightly dry. Combine beef with marinade, its garlic and scallion share, pepper and sesame; rest 20 minutes, then sauté 2–3 minutes.'),
    step('Бланшируйте проростки 1 минуту, шпинат 40 секунд; охладите и отожмите. Огурцы посолите на 10–15 минут, отожмите. Приправьте эти три овоща оставшимися чесноком, луком, кунжутным маслом, солью и кунжутом.',
         'Blanch sprouts 1 minute and spinach 40 seconds; cool and drain. Salt cucumbers 10–15 minutes and squeeze. Season these vegetables with remaining garlic, scallion, sesame oil, salt and sesame.'),
    step('Отдельно обжарьте грибы и морковь с растительным маслом 1–2 минуты, посолите; пожарьте яйца. Смешайте ингредиенты соуса, разложите начинку на рис и подайте с соусом.',
         'Sauté mushrooms and carrots separately in cooking oil 1–2 minutes, season, and fry eggs. Mix sauce ingredients, arrange toppings over rice and serve with sauce.'),
]

# GNTO's list contains wine without a corresponding instruction. Use a complete
# named Greek author's traditional recipe instead of inventing the missing step.
doc['sources'].append(dict(
    id='moussaka-giannopoulos', title='Eli K. Giannopoulos: Traditional Greek Moussaka',
    url='https://www.mygreekdish.com/recipe/mousakas/', checked_on='2026-10-19'))
moussaka = by_id['moussaka']
moussaka.update(
    origin_ru='GNTO относит мусаку к блюдам, которые готовят по всей Греции. Эта карточка следует семейному рецепту Эли К. Яннопулоса.',
    origin_en='GNTO places moussaka throughout Greece. This card follows Eli K. Giannopoulos’s family recipe.',
    summary_ru='Слоёная запеканка из картофеля, баклажанов, баранины и бешамеля.',
    summary_en='Layered potato, eggplant, lamb and béchamel casserole.',
    classic_note_ru='Классическая семейная версия Эли К. Яннопулоса (My Greek Dish), с обжаренными овощами и картофелем.',
    classic_note_en='Eli K. Giannopoulos’s traditional family version (My Greek Dish), with fried vegetables and potatoes.',
    servings_ru='8 кусков, форма 20×30×8 см', servings_en='8 pieces, 20×30×8 cm baking dish',
    source_ids=['moussaka-giannopoulos', 'moussaka-gnto'])
moussaka['ingredients'] = [
    ingredient('баклажаны и картофель', 'eggplants and potatoes', '6 шт. и 5 шт.', '6 and 5'),
    ingredient('растительное масло', 'vegetable oil', 'для жарки овощей', 'for frying vegetables'),
    ingredient('бараний фарш', 'lamb mince', '750 г', '750 g'),
    ingredient('красный лук и чеснок', 'red onions and garlic', '2 шт. и 2 зубчика', '2 and 2 cloves'),
    ingredient('резаные консервированные томаты и томатная паста', 'canned chopped tomatoes and tomato paste', '400 г и 2 ст. л.', '400 g and 2 tbsp'),
    ingredient('сахар, красное вино и оливковое масло', 'sugar, red wine and olive oil', '1 ч. л.; 1 стакан; ¼ чашки', '1 tsp; 1 glass; ¼ cup'),
    ingredient('лавровый лист, корица, соль и перец', 'bay leaf, cinnamon, salt and pepper', '1 лист; щепотка корицы; соль и перец по вкусу', '1 leaf; a pinch of cinnamon; salt and pepper to taste'),
    ingredient('молоко, сливочное масло и мука — бешамель', 'milk, butter and flour — béchamel', '900 мл; 120 г; 120 г', '900 ml; 120 g; 120 g'),
    ingredient('желтки, кефалотири и мускатный орех', 'egg yolks, Kefalotyri and nutmeg', '2 шт.; 100 г; щепотка', '2; 100 g; a pinch'),
]
moussaka['steps'] = [
    step('Нарежьте баклажаны, посолите на 30 минут, промойте, обсушите и обжарьте. Картофель нарежьте и тоже обжарьте.',
         'Slice eggplants, salt 30 minutes, rinse, dry and fry. Slice and fry potatoes too.'),
    step('На оливковом масле подрумяньте лук и фарш, добавьте чеснок и пасту. Выпарите вино; добавьте томаты, сахар и приправы, тушите около 30 минут до густоты.',
         'Brown onion and mince in olive oil; add garlic and paste. Reduce wine, then add tomatoes, sugar and seasonings; simmer about 30 minutes until thick.'),
    step('Загустите масло, муку и постепенно добавленное молоко. Снимите с огня, вмешайте желтки, мускат и большую часть сыра. Ложку бешамеля добавьте к мясу.',
         'Thicken butter, flour and gradually added milk. Off heat, whisk in yolks, nutmeg and most cheese. Stir a spoonful into the meat.'),
    step('Уберите лавровый лист. В смазанной форме уложите картофель, половину баклажанов, мясо, остальные баклажаны и бешамель; посыпьте сыром. Пеките при 180°C около 60 минут, немного остудите перед нарезкой.',
         'Remove bay leaf. In a buttered dish layer potatoes, half the eggplants, meat, remaining eggplants and béchamel; sprinkle cheese. Bake at 180°C about 60 minutes; cool slightly before cutting.'),
]
moussaka['facts'] = [dict(text_ru='Автор передаёт этот рецепт как семейный, полученный от бабушки.',
    text_en='The author presents this as a family recipe passed down by his grandmother.',
    source_ids=['moussaka-giannopoulos'])]

(root / 'food_atlas.final-candidate.json').write_text(
    json.dumps(doc, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
print(f"{len(doc['dishes'])} dishes; {len(doc['sources'])} sources")
