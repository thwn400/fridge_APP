import 'dart:developer';

import 'package:naengjang/main.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'storage_state.g.dart';

/// 냉장고 종류
enum StorageType {
  frozen('냉동'),
  refrigerated('냉장'),
  roomTemp('실온');

  const StorageType(this.label);
  final String label;

  /// 이 냉장고에 넣을 수 있는 재료 타입 목록
  List<IngredientType> get allowedIngredientTypes {
    switch (this) {
      case StorageType.frozen:
        return IngredientType.values; // 모든 타입 가능
      case StorageType.refrigerated:
        return [IngredientType.refrigerated, IngredientType.roomTemp]; // 냉장, 실온만
      case StorageType.roomTemp:
        return [IngredientType.roomTemp]; // 실온만
    }
  }

  bool canStore(IngredientType ingredientType) {
    return allowedIngredientTypes.contains(ingredientType);
  }
}

/// 재료 타입
enum IngredientType {
  frozen('냉동'),
  refrigerated('냉장'),
  roomTemp('실온');

  const IngredientType(this.label);
  final String label;

  static IngredientType fromString(String? value) {
    return IngredientType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => IngredientType.refrigerated, // 기본값: 냉장
    );
  }
}

class Storage {
  final String id;
  final String name;
  final StorageType type;
  final DateTime createdAt;

  Storage({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  factory Storage.fromJson(Map<String, dynamic> json) {
    return Storage(
      id: json['id'] as String,
      name: json['name'] as String,
      type: StorageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StorageType.refrigerated,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

@Riverpod(keepAlive: true)
class StorageState extends _$StorageState {
  @override
  Future<List<Storage>> build() async {
    return _fetch();
  }

  Future<List<Storage>> _fetch() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('storages')
        .select()
        .eq('user_id', userId)
        .order('created_at');

    return response.map((e) => Storage.fromJson(e)).toList();
  }

  Future<bool> add(String name, StorageType type) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await supabase.from('storages').insert({
        'user_id': userId,
        'name': name.trim(),
        'type': type.name,
      });

      ref.invalidateSelf();
      return true;
    } catch (e) {
      log('Storage add error: $e', name: 'StorageState');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await supabase.from('storages').delete().eq('id', id);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      log('Storage delete error: $e', name: 'StorageState');
      return false;
    }
  }
}
