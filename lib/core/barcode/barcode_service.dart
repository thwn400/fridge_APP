import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

/// Open Food Facts API에서 반환된 제품 정보
class ProductInfo {
  final String barcode;
  final String? name;
  final String? category;
  final String? imageUrl;

  ProductInfo({
    required this.barcode,
    this.name,
    this.category,
    this.imageUrl,
  });

  bool get hasData => name != null || category != null;
}

/// 바코드를 통해 Open Food Facts API에서 제품 정보를 조회하는 서비스
class BarcodeService {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  /// 바코드로 제품 정보 조회
  static Future<ProductInfo?> lookupBarcode(String barcode) async {
    try {
      final url = Uri.parse('$_baseUrl/$barcode.json');
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Naengjang App - Flutter',
        },
      );

      if (response.statusCode != 200) {
        log('Barcode lookup failed: ${response.statusCode}', name: 'BarcodeService');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['status'] != 1) {
        log('Product not found for barcode: $barcode', name: 'BarcodeService');
        return ProductInfo(barcode: barcode);
      }

      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) {
        return ProductInfo(barcode: barcode);
      }

      // 제품명 추출 (한국어 우선, 없으면 영어, 그것도 없으면 기본)
      String? productName = product['product_name_ko'] as String?;
      productName ??= product['product_name_en'] as String?;
      productName ??= product['product_name'] as String?;

      // 카테고리 추출 (한국어 우선)
      String? category = _extractCategory(product);

      // 이미지 URL
      String? imageUrl = product['image_front_small_url'] as String?;
      imageUrl ??= product['image_front_url'] as String?;

      return ProductInfo(
        barcode: barcode,
        name: productName?.isNotEmpty == true ? productName : null,
        category: category,
        imageUrl: imageUrl,
      );
    } catch (e) {
      log('Barcode lookup error: $e', name: 'BarcodeService');
      return null;
    }
  }

  /// 카테고리 추출 (기본 카테고리와 매핑)
  static String? _extractCategory(Map<String, dynamic> product) {
    // 카테고리 태그 확인
    final categoriesTags = product['categories_tags'] as List<dynamic>?;

    if (categoriesTags == null || categoriesTags.isEmpty) {
      return null;
    }

    // 카테고리 매핑
    final categoryMap = {
      'meats': '육류',
      'meat': '육류',
      'beef': '육류',
      'pork': '육류',
      'chicken': '육류',
      'poultry': '육류',
      'vegetables': '채소',
      'vegetable': '채소',
      'fruits': '과일',
      'fruit': '과일',
      'dairies': '유제품',
      'dairy': '유제품',
      'milk': '유제품',
      'cheese': '유제품',
      'yogurt': '유제품',
      'beverages': '음료',
      'beverage': '음료',
      'drinks': '음료',
      'drink': '음료',
      'water': '음료',
      'juice': '음료',
      'sauces': '조미료',
      'sauce': '조미료',
      'condiments': '조미료',
      'spices': '조미료',
      'frozen': '냉동식품',
      'frozen-foods': '냉동식품',
      'ice-cream': '냉동식품',
    };

    for (final tag in categoriesTags) {
      final tagStr = tag.toString().toLowerCase();
      for (final entry in categoryMap.entries) {
        if (tagStr.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    return null;
  }
}
