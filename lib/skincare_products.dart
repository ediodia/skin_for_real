// skincare_products.dart
// Product database for SkinForReal recommendations

class SkincareProduct {
  final String name;
  final String brand;
  final String imageUrl;
  final String amazonUrl;
  final String priceRange;
  final String category;
  final List<String> skinTypes;
  final List<String> keywords;

  const SkincareProduct({
    required this.name,
    required this.brand,
    required this.imageUrl,
    required this.amazonUrl,
    required this.priceRange,
    required this.category,
    required this.skinTypes,
    required this.keywords,
  });
}

class ProductDatabase {
  static const List<SkincareProduct> products = [
    // CLEANSERS
    SkincareProduct(
      name: 'Hydrating Facial Cleanser',
      brand: 'CeraVe',
      imageUrl: 'https://m.media-amazon.com/images/I/61S5A7RFkNL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B01MSSDEPK',
      priceRange: '\$14-18',
      category: 'Cleanser',
      skinTypes: ['Dry', 'Normal', 'Combination/Normal'],
      keywords: ['cerave hydrating', 'cerave cleanser', 'hydrating cleanser'],
    ),
    SkincareProduct(
      name: 'Foaming Facial Cleanser',
      brand: 'CeraVe',
      imageUrl: 'https://m.media-amazon.com/images/I/71Z5UMnHRIL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B00TTD9BRC',
      priceRange: '\$14-18',
      category: 'Cleanser',
      skinTypes: ['Oily', 'Acne-prone'],
      keywords: ['cerave foaming', 'foaming cleanser'],
    ),
    SkincareProduct(
      name: 'Rice Facial Cleanser',
      brand: 'Anua',
      imageUrl: 'https://m.media-amazon.com/images/I/61+jHpvHJWL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B0BVQN3DKP',
      priceRange: '\$22-28',
      category: 'Cleanser',
      skinTypes: ['All', 'Sensitive'],
      keywords: ['anua cleanser', 'anua rice', 'rice cleanser'],
    ),
    SkincareProduct(
      name: 'Low pH Good Morning Gel Cleanser',
      brand: 'COSRX',
      imageUrl: 'https://m.media-amazon.com/images/I/51gQnJVvBRL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B01MFAPIC2',
      priceRange: '\$12-16',
      category: 'Cleanser',
      skinTypes: ['Oily', 'Acne-prone', 'Combination/Normal'],
      keywords: ['cosrx cleanser', 'cosrx morning', 'low ph cleanser'],
    ),
    SkincareProduct(
      name: 'Effaclar Purifying Foaming Gel',
      brand: 'La Roche-Posay',
      imageUrl: 'https://m.media-amazon.com/images/I/51w9yAoHStL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B004HHTQB6',
      priceRange: '\$18-22',
      category: 'Cleanser',
      skinTypes: ['Oily', 'Acne-prone'],
      keywords: ['la roche posay cleanser', 'effaclar cleanser', 'la roche cleanser'],
    ),

    // TONERS
    SkincareProduct(
      name: 'Heartleaf 77% Toner',
      brand: 'Anua',
      imageUrl: 'https://m.media-amazon.com/images/I/61nZjFfRZkL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B09NWJRLS7',
      priceRange: '\$22-28',
      category: 'Toner',
      skinTypes: ['All', 'Sensitive', 'Acne-prone'],
      keywords: ['anua toner', 'anua heartleaf', 'heartleaf toner'],
    ),
    SkincareProduct(
      name: 'AHA/BHA Clarifying Treatment Toner',
      brand: 'COSRX',
      imageUrl: 'https://m.media-amazon.com/images/I/51xyNmFDRzL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B073DHN5FK',
      priceRange: '\$22-28',
      category: 'Toner',
      skinTypes: ['Oily', 'Acne-prone'],
      keywords: ['cosrx toner', 'aha bha toner', 'cosrx aha'],
    ),
    SkincareProduct(
      name: 'Glycolic Acid 7% Toning Solution',
      brand: 'The Ordinary',
      imageUrl: 'https://m.media-amazon.com/images/I/51tzYnFLWLL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B07HG7JNMG',
      priceRange: '\$10-14',
      category: 'Toner',
      skinTypes: ['All', 'Dull skin'],
      keywords: ['ordinary glycolic', 'glycolic toner', 'the ordinary toner'],
    ),

    // SERUMS
    SkincareProduct(
      name: 'Niacinamide 10% + Zinc 1%',
      brand: 'The Ordinary',
      imageUrl: 'https://m.media-amazon.com/images/I/41QNFkiOyBL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B07DPL7TCM',
      priceRange: '\$6-10',
      category: 'Serum',
      skinTypes: ['Oily', 'Acne-prone', 'All'],
      keywords: ['niacinamide', 'ordinary niacinamide', 'niacinamide zinc'],
    ),
    SkincareProduct(
      name: 'Vitamin C Suspension 23% + HA Spheres 2%',
      brand: 'The Ordinary',
      imageUrl: 'https://m.media-amazon.com/images/I/41hkQzXeRXL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B07MFZMWRK',
      priceRange: '\$6-10',
      category: 'Serum',
      skinTypes: ['All', 'Dull skin'],
      keywords: ['vitamin c serum', 'ordinary vitamin c', 'vitamin c suspension'],
    ),
    SkincareProduct(
      name: 'C E Ferulic',
      brand: 'SkinCeuticals',
      imageUrl: 'https://m.media-amazon.com/images/I/31WlXKNmr7L._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B000MYZGXK',
      priceRange: '\$160-180',
      category: 'Serum',
      skinTypes: ['All', 'Mature'],
      keywords: ['skinceuticals', 'ce ferulic', 'skinceuticals vitamin c'],
    ),
    SkincareProduct(
      name: 'Hyaluronic Acid 2% + B5',
      brand: 'The Ordinary',
      imageUrl: 'https://m.media-amazon.com/images/I/51BfMIHNFFL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B07QXZRL1P',
      priceRange: '\$8-12',
      category: 'Serum',
      skinTypes: ['Dry', 'All'],
      keywords: ['hyaluronic acid', 'ordinary hyaluronic', 'ha serum'],
    ),
    SkincareProduct(
      name: 'Advanced Snail 96 Mucin Power Essence',
      brand: 'COSRX',
      imageUrl: 'https://m.media-amazon.com/images/I/51iFCHFbIuL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B00PBX3L7K',
      priceRange: '\$18-24',
      category: 'Serum',
      skinTypes: ['Dry', 'All', 'Sensitive'],
      keywords: ['cosrx snail', 'snail mucin', 'snail essence'],
    ),
    SkincareProduct(
      name: 'Azelaic Acid Suspension 10%',
      brand: 'The Ordinary',
      imageUrl: 'https://m.media-amazon.com/images/I/41P6ZFLLFNL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B07L1CLG1Q',
      priceRange: '\$8-12',
      category: 'Serum',
      skinTypes: ['Acne-prone', 'Sensitive', 'All'],
      keywords: ['azelaic acid', 'ordinary azelaic', 'azelaic suspension'],
    ),
    SkincareProduct(
      name: 'Azelaic Acid Intense Calming Serum 15%',
      brand: 'Anua',
      imageUrl: 'https://m.media-amazon.com/images/I/61iy+RpxgFL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B0BVQQF7XW',
      priceRange: '\$28-34',
      category: 'Serum',
      skinTypes: ['Acne-prone', 'Sensitive'],
      keywords: ['anua azelaic', 'anua serum', 'azelaic 15'],
    ),
    SkincareProduct(
      name: 'Salicylic Acid 2% Solution',
      brand: 'The Ordinary',
      imageUrl: 'https://m.media-amazon.com/images/I/41XO8y-3oiL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B07TH7M6RH',
      priceRange: '\$6-10',
      category: 'Serum',
      skinTypes: ['Oily', 'Acne-prone'],
      keywords: ['salicylic acid', 'ordinary salicylic', 'bha serum'],
    ),
    SkincareProduct(
      name: '10% Azelaic Acid Booster',
      brand: 'Paula\'s Choice',
      imageUrl: 'https://m.media-amazon.com/images/I/51XgFCNJQHL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B01MS6BUPN',
      priceRange: '\$38-44',
      category: 'Serum',
      skinTypes: ['Acne-prone', 'Sensitive'],
      keywords: ['paulas choice azelaic', 'paula\'s choice booster'],
    ),
    SkincareProduct(
      name: 'Skin Perfecting 2% BHA Liquid Exfoliant',
      brand: 'Paula\'s Choice',
      imageUrl: 'https://m.media-amazon.com/images/I/41I0VQFRFZL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B00949CTQQ',
      priceRange: '\$32-38',
      category: 'Serum',
      skinTypes: ['Oily', 'Acne-prone'],
      keywords: ['paulas choice bha', 'paula\'s choice exfoliant', 'bha exfoliant'],
    ),

    // MOISTURIZERS
    SkincareProduct(
      name: 'PM Facial Moisturizing Lotion',
      brand: 'CeraVe',
      imageUrl: 'https://m.media-amazon.com/images/I/71AkFB1TPML._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B00365DAGG',
      priceRange: '\$14-18',
      category: 'Moisturizer',
      skinTypes: ['All', 'Dry', 'Normal'],
      keywords: ['cerave pm', 'cerave moisturizer', 'cerave lotion'],
    ),
    SkincareProduct(
      name: 'Moisturizing Cream',
      brand: 'CeraVe',
      imageUrl: 'https://m.media-amazon.com/images/I/61S5A7RFkNL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B00TTD9BRC',
      priceRange: '\$16-20',
      category: 'Moisturizer',
      skinTypes: ['Dry', 'Sensitive'],
      keywords: ['cerave cream', 'cerave moisturizing cream'],
    ),
    SkincareProduct(
      name: 'Effaclar Mat Mattifying Moisturizer',
      brand: 'La Roche-Posay',
      imageUrl: 'https://m.media-amazon.com/images/I/61KTpFuNRML._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B004D2CUKY',
      priceRange: '\$32-38',
      category: 'Moisturizer',
      skinTypes: ['Oily', 'Acne-prone'],
      keywords: ['la roche posay moisturizer', 'effaclar mat', 'mattifying moisturizer'],
    ),
    SkincareProduct(
      name: 'Oil-Free Moisture SPF 35',
      brand: 'Neutrogena',
      imageUrl: 'https://m.media-amazon.com/images/I/71mJiHAJFuL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B00027DIZA',
      priceRange: '\$14-18',
      category: 'Moisturizer',
      skinTypes: ['Oily', 'Combination/Normal'],
      keywords: ['neutrogena oil free', 'neutrogena moisturizer', 'oil free moisturizer'],
    ),
    SkincareProduct(
      name: 'Natural Moisturizing Factors + HA',
      brand: 'The Ordinary',
      imageUrl: 'https://m.media-amazon.com/images/I/51XqSJDlNuL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B074CGVWP5',
      priceRange: '\$8-12',
      category: 'Moisturizer',
      skinTypes: ['Dry', 'All'],
      keywords: ['ordinary moisturizer', 'natural moisturizing factors', 'ordinary nmf'],
    ),

    // SUNSCREEN
    SkincareProduct(
      name: 'Relief Sun Aqua-Fresh Rice+B5',
      brand: 'Beauty of Joseon',
      imageUrl: 'https://m.media-amazon.com/images/I/61xJJ3BPJCL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B0BVQMVX8T',
      priceRange: '\$16-22',
      category: 'Sunscreen',
      skinTypes: ['All', 'Sensitive'],
      keywords: ['beauty of joseon sunscreen', 'joseon sunscreen', 'relief sun'],
    ),
    SkincareProduct(
      name: 'Invisible Fluid SPF 50+',
      brand: 'La Roche-Posay Anthelios',
      imageUrl: 'https://m.media-amazon.com/images/I/61sxlyHHWqL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B078HHY8T4',
      priceRange: '\$32-38',
      category: 'Sunscreen',
      skinTypes: ['All', 'Sensitive'],
      keywords: ['la roche posay spf', 'anthelios sunscreen', 'la roche sunscreen'],
    ),
    SkincareProduct(
      name: 'Ultra Light Daily UV Defense SPF 50',
      brand: 'Kiehl\'s',
      imageUrl: 'https://m.media-amazon.com/images/I/51sSGvp5iYL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B00AEGYZT2',
      priceRange: '\$38-46',
      category: 'Sunscreen',
      skinTypes: ['All', 'Oily'],
      keywords: ['kiehls sunscreen', 'ultra light uv', 'kiehls spf'],
    ),
    SkincareProduct(
      name: 'Clear Face Liquid SPF 55',
      brand: 'Neutrogena',
      imageUrl: 'https://m.media-amazon.com/images/I/71iGPPVRZPL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B003NE5WH4',
      priceRange: '\$12-16',
      category: 'Sunscreen',
      skinTypes: ['Oily', 'Acne-prone'],
      keywords: ['neutrogena sunscreen', 'neutrogena spf', 'clear face spf'],
    ),

    // RETINOIDS
    SkincareProduct(
      name: 'Retinol 0.5% in Squalane',
      brand: 'The Ordinary',
      imageUrl: 'https://m.media-amazon.com/images/I/41yBsXaJoIL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B07PKPSFCD',
      priceRange: '\$8-12',
      category: 'Retinoid',
      skinTypes: ['All'],
      keywords: ['retinol', 'ordinary retinol', 'retinol 0.5'],
    ),
    SkincareProduct(
      name: 'Granactive Retinoid 2% Emulsion',
      brand: 'The Ordinary',
      imageUrl: 'https://m.media-amazon.com/images/I/41sWqXhcFkL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B07L1GXBL5',
      priceRange: '\$10-14',
      category: 'Retinoid',
      skinTypes: ['All', 'Sensitive'],
      keywords: ['granactive retinoid', 'ordinary retinoid', 'retinoid emulsion'],
    ),
    SkincareProduct(
      name: 'Clinical Grade Resurfacing Retinol Serum',
      brand: 'RoC',
      imageUrl: 'https://m.media-amazon.com/images/I/71DqBdmHM2L._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B08VCL5KZH',
      priceRange: '\$24-30',
      category: 'Retinoid',
      skinTypes: ['All'],
      keywords: ['roc retinol', 'roc serum', 'clinical retinol'],
    ),

    // SPOT TREATMENT
    SkincareProduct(
      name: 'Acne Foaming Cream Cleanser',
      brand: 'La Roche-Posay Effaclar',
      imageUrl: 'https://m.media-amazon.com/images/I/71R2MoSxnlL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B08FKYNXG4',
      priceRange: '\$16-22',
      category: 'Spot Treatment',
      skinTypes: ['Acne-prone', 'Oily'],
      keywords: ['effaclar', 'la roche acne', 'acne treatment'],
    ),
    SkincareProduct(
      name: 'Acne Pimple Master Patch',
      brand: 'COSRX',
      imageUrl: 'https://m.media-amazon.com/images/I/71LRqRWlJOL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B07HCBP8SR',
      priceRange: '\$10-14',
      category: 'Spot Treatment',
      skinTypes: ['Acne-prone', 'All'],
      keywords: ['cosrx patch', 'pimple patch', 'acne patch', 'cosrx acne'],
    ),
    SkincareProduct(
      name: 'Invisible Spot Treatment',
      brand: 'Peter Thomas Roth',
      imageUrl: 'https://m.media-amazon.com/images/I/61ZnTr3IDJL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B0BGM8JLNR',
      priceRange: '\$26-32',
      category: 'Spot Treatment',
      skinTypes: ['Acne-prone'],
      keywords: ['spot treatment', 'peter thomas roth', 'benzoyl peroxide treatment'],
    ),

    // EYE CREAM
    SkincareProduct(
      name: 'Caffeine Solution 5% + EGCG',
      brand: 'The Ordinary',
      imageUrl: 'https://m.media-amazon.com/images/I/41rR0FBHXML._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B07HG7JNMG',
      priceRange: '\$8-12',
      category: 'Eye Cream',
      skinTypes: ['All'],
      keywords: ['caffeine solution', 'ordinary caffeine', 'eye serum'],
    ),

    // LIP CARE
    SkincareProduct(
      name: 'Healing Ointment',
      brand: 'Vaseline',
      imageUrl: 'https://m.media-amazon.com/images/I/51fMwSWbkQL._SL1500_.jpg',
      amazonUrl: 'https://www.amazon.com/dp/B00S8YJFBY',
      priceRange: '\$6-10',
      category: 'Lip Care',
      skinTypes: ['All'],
      keywords: ['vaseline', 'healing ointment', 'petrolatum', 'occlusive'],
    ),
  ];

  static SkincareProduct? findProduct(String text) {
    final lower = text.toLowerCase();
    SkincareProduct? best;
    int bestScore = 0;

    for (final product in products) {
      int score = 0;
      for (final kw in product.keywords) {
        if (lower.contains(kw.toLowerCase())) {
          score += kw.split(' ').length;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = product;
      }
    }

    return bestScore > 0 ? best : null;
  }

  static List<SkincareProduct> findProductsInText(String text) {
    final found = <SkincareProduct>[];
    final seen = <String>{};
    final lower = text.toLowerCase();

    for (final product in products) {
      for (final kw in product.keywords) {
        if (lower.contains(kw.toLowerCase()) && !seen.contains(product.name)) {
          found.add(product);
          seen.add(product.name);
          break;
        }
      }
    }

    return found;
  }
}