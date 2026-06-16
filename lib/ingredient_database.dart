class IngredientInfo {
  final String name;
  final int comedogenicRating; // 0-5
  final bool isIrritant;
  final bool isBeneficial;
  final String note;

  const IngredientInfo({
    required this.name,
    required this.comedogenicRating,
    required this.isIrritant,
    required this.isBeneficial,
    required this.note,
  });
}

class IngredientWarning {
  final String foundAs;
  final IngredientInfo info;

  const IngredientWarning({required this.foundAs, required this.info});

  bool get isDangerous => info.comedogenicRating >= 4 || info.isIrritant;
}

class IngredientDatabase {
  static const Map<String, IngredientInfo> _db = {
    // High comedogenic oils & esters
    'coconut oil': IngredientInfo(
      name: 'Coconut Oil',
      comedogenicRating: 4,
      isIrritant: false,
      isBeneficial: false,
      note: 'Highly pore-clogging — avoid if acne-prone',
    ),
    'cocoa butter': IngredientInfo(
      name: 'Cocoa Butter',
      comedogenicRating: 4,
      isIrritant: false,
      isBeneficial: false,
      note: 'High comedogenic rating — can clog pores',
    ),
    'wheat germ oil': IngredientInfo(
      name: 'Wheat Germ Oil',
      comedogenicRating: 5,
      isIrritant: false,
      isBeneficial: false,
      note: 'Highest comedogenic rating — avoid for acne-prone skin',
    ),
    'flaxseed oil': IngredientInfo(
      name: 'Flaxseed Oil',
      comedogenicRating: 4,
      isIrritant: false,
      isBeneficial: false,
      note: 'Highly comedogenic — can aggravate breakouts',
    ),
    'isopropyl myristate': IngredientInfo(
      name: 'Isopropyl Myristate',
      comedogenicRating: 5,
      isIrritant: false,
      isBeneficial: false,
      note: 'Extremely pore-clogging synthetic ester — avoid if acne-prone',
    ),
    'isopropyl palmitate': IngredientInfo(
      name: 'Isopropyl Palmitate',
      comedogenicRating: 4,
      isIrritant: false,
      isBeneficial: false,
      note: 'Highly comedogenic — frequently causes closed comedones',
    ),
    'myristyl myristate': IngredientInfo(
      name: 'Myristyl Myristate',
      comedogenicRating: 5,
      isIrritant: false,
      isBeneficial: false,
      note: 'Highly pore-clogging wax ester',
    ),
    'butyl stearate': IngredientInfo(
      name: 'Butyl Stearate',
      comedogenicRating: 3,
      isIrritant: false,
      isBeneficial: false,
      note: 'Moderately comedogenic synthetic ester',
    ),
    'lanolin': IngredientInfo(
      name: 'Lanolin',
      comedogenicRating: 3,
      isIrritant: false,
      isBeneficial: false,
      note: 'Moderately comedogenic — can trap sebum in pores',
    ),
    'acetylated lanolin': IngredientInfo(
      name: 'Acetylated Lanolin',
      comedogenicRating: 4,
      isIrritant: false,
      isBeneficial: false,
      note: 'Modified lanolin with high comedogenic potential',
    ),
    'algae extract': IngredientInfo(
      name: 'Algae Extract',
      comedogenicRating: 5,
      isIrritant: false,
      isBeneficial: false,
      note: 'Highly pore-clogging despite sounding natural',
    ),
    'soybean oil': IngredientInfo(
      name: 'Soybean Oil',
      comedogenicRating: 3,
      isIrritant: false,
      isBeneficial: false,
      note: 'Moderately comedogenic plant oil',
    ),
    'palm oil': IngredientInfo(
      name: 'Palm Oil',
      comedogenicRating: 4,
      isIrritant: false,
      isBeneficial: false,
      note: 'High comedogenic rating — can clog pores',
    ),
    'linseed oil': IngredientInfo(
      name: 'Linseed Oil',
      comedogenicRating: 4,
      isIrritant: false,
      isBeneficial: false,
      note: 'Same as flaxseed oil — highly comedogenic',
    ),
    // Irritants / sensitizers
    'fragrance': IngredientInfo(
      name: 'Fragrance',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Common allergen and skin irritant — top cause of contact dermatitis',
    ),
    'parfum': IngredientInfo(
      name: 'Parfum',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'EU term for fragrance blend — frequent sensitizer',
    ),
    'alcohol denat': IngredientInfo(
      name: 'Alcohol Denat',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Drying alcohol that disrupts skin barrier — avoid for dry/sensitive skin',
    ),
    'denatured alcohol': IngredientInfo(
      name: 'Denatured Alcohol',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Strips natural oils and weakens the moisture barrier',
    ),
    'linalool': IngredientInfo(
      name: 'Linalool',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Fragrance component — common allergen, especially when oxidized',
    ),
    'limonene': IngredientInfo(
      name: 'Limonene',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Citrus-derived fragrance — sensitizing, especially oxidized',
    ),
    'citronellol': IngredientInfo(
      name: 'Citronellol',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Floral fragrance allergen — can cause contact sensitization',
    ),
    'eugenol': IngredientInfo(
      name: 'Eugenol',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Found in clove and cinnamon — known skin sensitizer',
    ),
    'geraniol': IngredientInfo(
      name: 'Geraniol',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Rose fragrance component — potential allergen',
    ),
    'sodium lauryl sulfate': IngredientInfo(
      name: 'Sodium Lauryl Sulfate',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Harsh surfactant — strips lipids and causes irritation and barrier damage',
    ),
    'sls': IngredientInfo(
      name: 'SLS',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Sodium Lauryl Sulfate — harsh detergent that damages skin barrier',
    ),
    'methylparaben': IngredientInfo(
      name: 'Methylparaben',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Preservative — contact allergen for some people',
    ),
    'propylparaben': IngredientInfo(
      name: 'Propylparaben',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Preservative — potential sensitizer and endocrine concern',
    ),
    'formaldehyde': IngredientInfo(
      name: 'Formaldehyde',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Preservative — known allergen and carcinogen, avoid completely',
    ),
    'dmdm hydantoin': IngredientInfo(
      name: 'DMDM Hydantoin',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Formaldehyde-releasing preservative — linked to scalp and skin irritation',
    ),
    'benzalkonium chloride': IngredientInfo(
      name: 'Benzalkonium Chloride',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Preservative/antiseptic — disrupts skin barrier and causes irritation',
    ),
    'essential oils': IngredientInfo(
      name: 'Essential Oils',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Concentrated plant extracts — common sensitizers, can cause phototoxicity',
    ),
    'tea tree oil': IngredientInfo(
      name: 'Tea Tree Oil',
      comedogenicRating: 1,
      isIrritant: true,
      isBeneficial: false,
      note: 'Antibacterial but can be irritating at >5% concentration — use diluted',
    ),
    'peppermint oil': IngredientInfo(
      name: 'Peppermint Oil',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Sensitizing fragrance — can cause menthol-induced irritation',
    ),
    'lavender oil': IngredientInfo(
      name: 'Lavender Oil',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Contains linalool and linalyl acetate — both skin sensitizers',
    ),
    // Moderately comedogenic
    'olive oil': IngredientInfo(
      name: 'Olive Oil',
      comedogenicRating: 2,
      isIrritant: false,
      isBeneficial: false,
      note: 'Mildly comedogenic — can aggravate sensitive or acne-prone skin',
    ),
    'shea butter': IngredientInfo(
      name: 'Shea Butter',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Non-comedogenic and anti-inflammatory — great for dry and sensitive skin',
    ),
    'mineral oil': IngredientInfo(
      name: 'Mineral Oil',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: false,
      note: 'Non-comedogenic occlusive — safe but provides no active benefit',
    ),
    'petrolatum': IngredientInfo(
      name: 'Petrolatum',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Gold-standard occlusive barrier ingredient — non-comedogenic and healing',
    ),
    // Beneficial
    'niacinamide': IngredientInfo(
      name: 'Niacinamide',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Clinically proven to reduce pores, regulate sebum, fade dark spots',
    ),
    'hyaluronic acid': IngredientInfo(
      name: 'Hyaluronic Acid',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Humectant that holds 1000x its weight in water — essential for hydration',
    ),
    'retinol': IngredientInfo(
      name: 'Retinol',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Gold-standard anti-aging ingredient — start low and increase slowly',
    ),
    'ascorbic acid': IngredientInfo(
      name: 'Ascorbic Acid',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Pure Vitamin C — brightens, antioxidant, boosts collagen',
    ),
    'vitamin c': IngredientInfo(
      name: 'Vitamin C',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Antioxidant that brightens skin and protects against UV damage',
    ),
    'ceramides': IngredientInfo(
      name: 'Ceramides',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Essential barrier lipids — critical for skin repair and moisture retention',
    ),
    'peptides': IngredientInfo(
      name: 'Peptides',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Signal proteins that stimulate collagen and elastin production',
    ),
    'glycolic acid': IngredientInfo(
      name: 'Glycolic Acid',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'AHA exfoliant that resurfaces skin texture and fades pigmentation',
    ),
    'salicylic acid': IngredientInfo(
      name: 'Salicylic Acid',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'BHA that penetrates pores to dissolve excess sebum — ideal for acne',
    ),
    'azelaic acid': IngredientInfo(
      name: 'Azelaic Acid',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Targets acne, rosacea, and hyperpigmentation simultaneously',
    ),
    'panthenol': IngredientInfo(
      name: 'Panthenol',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Provitamin B5 — soothes irritation and strengthens the moisture barrier',
    ),
    'squalane': IngredientInfo(
      name: 'Squalane',
      comedogenicRating: 1,
      isIrritant: false,
      isBeneficial: true,
      note: 'Lightweight skin-identical lipid — non-greasy and non-comedogenic',
    ),
    'tocopherol': IngredientInfo(
      name: 'Tocopherol',
      comedogenicRating: 2,
      isIrritant: false,
      isBeneficial: true,
      note: 'Vitamin E antioxidant — protects skin cells but can be comedogenic in oily skin',
    ),
    'zinc oxide': IngredientInfo(
      name: 'Zinc Oxide',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Mineral sunscreen and anti-inflammatory — safe for acne-prone skin',
    ),
    'centella asiatica': IngredientInfo(
      name: 'Centella Asiatica',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Powerhouse anti-inflammatory — heals wounds and calms redness',
    ),
    'aloe vera': IngredientInfo(
      name: 'Aloe Vera',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Soothing humectant with anti-inflammatory properties',
    ),
    'benzoyl peroxide': IngredientInfo(
      name: 'Benzoyl Peroxide',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Kills acne bacteria — most effective OTC acne treatment available',
    ),
    'tranexamic acid': IngredientInfo(
      name: 'Tranexamic Acid',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Brightening ingredient that targets stubborn dark spots and melasma',
    ),
    'alpha arbutin': IngredientInfo(
      name: 'Alpha Arbutin',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Stable skin brightener — inhibits melanin production safely',
    ),
    'lactic acid': IngredientInfo(
      name: 'Lactic Acid',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Gentle AHA that exfoliates and hydrates simultaneously',
    ),
    'mandelic acid': IngredientInfo(
      name: 'Mandelic Acid',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Gentle AHA with antibacterial properties — ideal for sensitive or darker skin',
    ),
    'kojic acid': IngredientInfo(
      name: 'Kojic Acid',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Natural tyrosinase inhibitor — fades dark spots and hyperpigmentation',
    ),
    'resveratrol': IngredientInfo(
      name: 'Resveratrol',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Potent antioxidant from grape skin — protects against environmental damage',
    ),
    'retinaldehyde': IngredientInfo(
      name: 'Retinaldehyde',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'One step away from retinoic acid — faster acting than retinol with less irritation',
    ),
    'bakuchiol': IngredientInfo(
      name: 'Bakuchiol',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Plant-based retinol alternative — gentler, safe for pregnancy',
    ),
    'polyglutamic acid': IngredientInfo(
      name: 'Polyglutamic Acid',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Next-gen humectant that holds 4x more moisture than hyaluronic acid',
    ),
    'ferulic acid': IngredientInfo(
      name: 'Ferulic Acid',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Antioxidant that doubles the effectiveness of Vitamins C and E',
    ),
    'glycerin': IngredientInfo(
      name: 'Glycerin',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Most effective humectant — draws water into the skin from the environment',
    ),
    'propylene glycol': IngredientInfo(
      name: 'Propylene Glycol',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Penetration enhancer — can irritate sensitive skin at high concentrations',
    ),
    'titanium dioxide': IngredientInfo(
      name: 'Titanium Dioxide',
      comedogenicRating: 0,
      isIrritant: false,
      isBeneficial: true,
      note: 'Mineral UV filter — safe, non-irritating, broad-spectrum protection',
    ),
    'oxybenzone': IngredientInfo(
      name: 'Oxybenzone',
      comedogenicRating: 0,
      isIrritant: true,
      isBeneficial: false,
      note: 'Chemical UV filter — potential endocrine disruptor and skin sensitizer',
    ),
  };

  static List<IngredientWarning> scan(String routineText) {
    if (routineText.trim().isEmpty) return [];
    final lower = routineText.toLowerCase();
    final warnings = <IngredientWarning>[];
    final seen = <String>{};

    for (final entry in _db.entries) {
      if (seen.contains(entry.key)) continue;
      if (lower.contains(entry.key)) {
        final info = entry.value;
        if (info.comedogenicRating >= 3 || info.isIrritant) {
          warnings.add(IngredientWarning(foundAs: entry.key, info: info));
          seen.add(entry.key);
        }
      }
    }

    warnings.sort((a, b) {
      final aScore = (a.info.comedogenicRating * 10) + (a.info.isIrritant ? 5 : 0);
      final bScore = (b.info.comedogenicRating * 10) + (b.info.isIrritant ? 5 : 0);
      return bScore.compareTo(aScore);
    });

    return warnings;
  }

  static IngredientInfo? lookup(String ingredient) =>
      _db[ingredient.toLowerCase().trim()];
}
