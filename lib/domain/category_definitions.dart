class CategoryIds {
  static const freshProduce = 'fresh_produce';
  static const dairyEggsBakery = 'dairy_eggs_bakery';
  static const packagedPantry = 'packaged_pantry';
  static const drinksSnacks = 'drinks_snacks';
  static const householdGoods = 'household_goods';
  static const misc = 'misc';
}

class CategoryDefinition {
  const CategoryDefinition({
    required this.id,
    required this.label,
    this.keywords = const <String>[],
    this.legacyIds = const <String>[],
  });

  final String id;
  final String label;
  final List<String> keywords;
  final List<String> legacyIds;
}

const List<CategoryDefinition> categoryDefinitions = [
  CategoryDefinition(
    id: CategoryIds.freshProduce,
    label: 'Fresh Produce & Vegetables',
    keywords: const [
      'jabł',
      'jabl',
      'banan',
      'pomidor',
      'ogór',
      'ogor',
      'warzyw',
      'owoc',
      'sałat',
      'salat',
      'ziemni',
      'marchew',
      'papryk',
      'kapust',
      'grzyb',
      'por',
      'pietruszk',
      'koper',
      'fruit',
      'vegetable',
      'fresh',
      'greens',
      'lettuc',
      'apple',
      'banana',
      'tomato',
      'cucumber',
      'berry',
      'herb',
    ],
    legacyIds: const ['produce'],
  ),
  CategoryDefinition(
    id: CategoryIds.dairyEggsBakery,
    label: 'Dairy, Eggs & Bakery',
    keywords: const [
      'mleko',
      'milk',
      'ser',
      'cheese',
      'jogurt',
      'yoghurt',
      'yogurt',
      'masł',
      'masl',
      'butter',
      'śmiet',
      'smiet',
      'cream',
      'twaróg',
      'twarog',
      'kefir',
      'jaja',
      'egg',
      'chleb',
      'bread',
      'buł',
      'bul',
      'pieczy',
      'bagiet',
      'ciasto',
      'cake',
      'croissant',
      'pastr',
      'bagel',
      'roll',
      'bake',
      'bakery',
    ],
    legacyIds: const ['dairy', 'bakery'],
  ),
  CategoryDefinition(
    id: CategoryIds.packagedPantry,
    label: 'Packaged & Pantry Foods',
    keywords: const [
      'makaron',
      'pasta',
      'ryż',
      'ryz',
      'rice',
      'kasz',
      'cereal',
      'płatk',
      'platk',
      'mąk',
      'mak',
      'flour',
      'cukier',
      'sugar',
      'sól',
      'sol',
      'salt',
      'olej',
      'oil',
      'oliw',
      'puszk',
      'konserw',
      'can',
      'canned',
      'sos',
      'sauce',
      'przypraw',
      'spice',
      'zupa',
      'soup',
      'mroż',
      'mroz',
      'frozen',
      'mięso',
      'mieso',
      'kiełb',
      'kielb',
      'szynk',
      'kurczak',
      'wołow',
      'wolow',
      'wieprz',
      'indyk',
      'fish',
      'łosoś',
      'losos',
      'tuńczyk',
      'tunczyk',
      'broth',
      'bouillon',
    ],
    legacyIds: const ['meat'],
  ),
  CategoryDefinition(
    id: CategoryIds.drinksSnacks,
    label: 'Drinks & Snacks',
    keywords: const [
      'napój',
      'napoj',
      'sok',
      'juice',
      'cola',
      'pepsi',
      'piwo',
      'beer',
      'wino',
      'wine',
      'kawa',
      'coffee',
      'herbat',
      'tea',
      'woda',
      'water',
      'chips',
      'crisps',
      'snack',
      'przekąsk',
      'przekask',
      'baton',
      'bar',
      'czekol',
      'chocolate',
      'energet',
      'energy',
      'drink',
      'nap',
      'fanta',
      'sprite',
      'lemon',
    ],
  ),
  CategoryDefinition(
    id: CategoryIds.householdGoods,
    label: 'Household Goods',
    keywords: const [
      'papier',
      'deterg',
      'mydł',
      'mydl',
      'soap',
      'proszek',
      'chemia',
      'środek',
      'srodek',
      'clean',
      'ręcz',
      'recz',
      'pranie',
      'laundry',
      'zmyw',
      'dish',
      'płyn',
      'plyn',
      'gąb',
      'gab',
      'sponge',
      'świec',
      'swiec',
      'świecz',
      'worki',
      'trash',
      'mop',
      'broom',
      'toalet',
      'toilet',
    ],
    legacyIds: const ['household'],
  ),
  CategoryDefinition(
    id: CategoryIds.misc,
    label: 'Miscellaneous / Other',
    legacyIds: const ['other'],
  ),
];

final Map<String, CategoryDefinition> _definitionsById = {
  for (final definition in categoryDefinitions) definition.id: definition,
};

final Map<String, String> _legacyIdToDefinitionId = {
  for (final definition in categoryDefinitions)
    for (final legacyId in definition.legacyIds) legacyId: definition.id,
};

String normalizeCategoryId(String? rawId) {
  if (rawId == null || rawId.isEmpty) {
    return CategoryIds.misc;
  }
  final id = rawId.trim();
  if (_definitionsById.containsKey(id)) {
    return id;
  }
  final legacyMapping = _legacyIdToDefinitionId[id];
  if (legacyMapping != null) {
    return legacyMapping;
  }
  return CategoryIds.misc;
}

String categorizeItemName(String name) {
  final lower = name.toLowerCase();
  for (final definition in categoryDefinitions) {
    if (definition.keywords.isEmpty) {
      continue;
    }
    if (definition.keywords.any((keyword) => lower.contains(keyword))) {
      return definition.id;
    }
  }
  return CategoryIds.misc;
}
