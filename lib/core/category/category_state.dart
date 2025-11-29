import 'dart:developer';

import 'package:naengjang/main.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_state.g.dart';

/// 기본 카테고리 목록
const defaultCategories = [
  '육류',
  '채소',
  '과일',
  '유제품',
  '음료',
  '조미료',
  '냉동식품',
  '기타',
];

class Category {
  final String id;
  final String name;
  final bool isDefault;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 기본 카테고리를 위한 팩토리
  factory Category.defaultCategory(String name) {
    return Category(
      id: 'default_$name',
      name: name,
      isDefault: true,
      createdAt: DateTime.now(),
    );
  }
}

@Riverpod(keepAlive: true)
class CategoryState extends _$CategoryState {
  @override
  Future<List<Category>> build() async {
    return _fetch();
  }

  Future<List<Category>> _fetch() async {
    final userId = supabase.auth.currentUser?.id;

    // 기본 카테고리
    final defaults = defaultCategories.map((e) => Category.defaultCategory(e)).toList();

    if (userId == null) return defaults;

    try {
      // 사용자 정의 카테고리 조회
      final response = await supabase
          .from('categories')
          .select()
          .eq('user_id', userId)
          .order('created_at');

      final userCategories = response.map((e) => Category.fromJson(e)).toList();

      // 기본 카테고리 + 사용자 정의 카테고리
      return [...defaults, ...userCategories];
    } catch (e) {
      log('Category fetch error: $e', name: 'CategoryState');
      return defaults;
    }
  }

  /// 모든 카테고리 이름 목록 반환 (자동완성용)
  List<String> get categoryNames {
    if (state case AsyncData(:final value)) {
      return value.map((e) => e.name).toList();
    }
    return [];
  }

  Future<bool> add(String name) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    // 이미 존재하는 카테고리인지 확인
    if (state case AsyncData(:final value)) {
      if (value.any((e) => e.name == name.trim())) {
        return false;
      }
    }

    try {
      await supabase.from('categories').insert({
        'user_id': userId,
        'name': name.trim(),
        'is_default': false,
      });

      ref.invalidateSelf();
      return true;
    } catch (e) {
      log('Category add error: $e', name: 'CategoryState');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    // 기본 카테고리는 삭제 불가
    if (id.startsWith('default_')) return false;

    try {
      await supabase.from('categories').delete().eq('id', id);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      log('Category delete error: $e', name: 'CategoryState');
      return false;
    }
  }
}
