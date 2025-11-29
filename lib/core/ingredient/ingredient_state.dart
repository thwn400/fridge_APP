import 'dart:developer';

import 'package:naengjang/core/notification/notification_service.dart';
import 'package:naengjang/core/storage/storage_state.dart';
import 'package:naengjang/main.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ingredient_state.g.dart';

class Ingredient {
  final String id;
  final String storageId;
  final String name;
  final IngredientType type;
  final String? category;
  final DateTime? expiryDate;
  final DateTime? useByDate;
  final DateTime? manufacturedDate;
  final String? imageUrl;
  final DateTime createdAt;

  Ingredient({
    required this.id,
    required this.storageId,
    required this.name,
    required this.type,
    this.category,
    this.expiryDate,
    this.useByDate,
    this.manufacturedDate,
    this.imageUrl,
    required this.createdAt,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      storageId: json['storage_id'] as String,
      name: json['name'] as String,
      type: IngredientType.fromString(json['type'] as String?),
      category: json['category'] as String?,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      useByDate: json['use_by_date'] != null
          ? DateTime.parse(json['use_by_date'] as String)
          : null,
      manufacturedDate: json['manufactured_date'] != null
          ? DateTime.parse(json['manufactured_date'] as String)
          : null,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

@Riverpod(keepAlive: true)
class IngredientState extends _$IngredientState {
  @override
  Future<List<Ingredient>> build() async {
    return _fetch();
  }

  Future<List<Ingredient>> _fetch() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('ingredients')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response.map((e) => Ingredient.fromJson(e)).toList();
  }

  Future<List<Ingredient>> fetchByStorage(String storageId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('ingredients')
        .select()
        .eq('user_id', userId)
        .eq('storage_id', storageId)
        .order('created_at', ascending: false);

    return response.map((e) => Ingredient.fromJson(e)).toList();
  }

  Future<bool> add({
    required String storageId,
    required String name,
    IngredientType type = IngredientType.refrigerated,
    String? category,
    DateTime? expiryDate,
    DateTime? useByDate,
    DateTime? manufacturedDate,
    String? imageUrl,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await supabase.from('ingredients').insert({
        'user_id': userId,
        'storage_id': storageId,
        'name': name.trim(),
        'type': type.name,
        'category': category,
        'expiry_date': expiryDate?.toIso8601String().split('T').first,
        'use_by_date': useByDate?.toIso8601String().split('T').first,
        'manufactured_date': manufacturedDate?.toIso8601String().split('T').first,
        'image_url': imageUrl,
      }).select().single();

      // 알림 예약
      final ingredient = Ingredient.fromJson(response);
      await NotificationService.instance.scheduleExpiryNotifications(ingredient);

      ref.invalidateSelf();
      return true;
    } catch (e) {
      log('Ingredient add error: $e', name: 'IngredientState');
      return false;
    }
  }

  Future<bool> edit({
    required String id,
    required String storageId,
    required String name,
    IngredientType type = IngredientType.refrigerated,
    String? category,
    DateTime? expiryDate,
    DateTime? useByDate,
    DateTime? manufacturedDate,
    String? imageUrl,
  }) async {
    try {
      final response = await supabase.from('ingredients').update({
        'storage_id': storageId,
        'name': name.trim(),
        'type': type.name,
        'category': category,
        'expiry_date': expiryDate?.toIso8601String().split('T').first,
        'use_by_date': useByDate?.toIso8601String().split('T').first,
        'manufactured_date': manufacturedDate?.toIso8601String().split('T').first,
        'image_url': imageUrl,
      }).eq('id', id).select().single();

      // 알림 재예약
      final ingredient = Ingredient.fromJson(response);
      await NotificationService.instance.scheduleExpiryNotifications(ingredient);

      ref.invalidateSelf();
      return true;
    } catch (e) {
      log('Ingredient edit error: $e', name: 'IngredientState');
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await supabase.from('ingredients').delete().eq('id', id);

      // 알림 취소
      await NotificationService.instance.cancelNotifications(id);

      ref.invalidateSelf();
      return true;
    } catch (e) {
      log('Ingredient delete error: $e', name: 'IngredientState');
      return false;
    }
  }
}
