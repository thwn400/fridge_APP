import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naengjang/core/ingredient/ingredient_state.dart';
import 'package:naengjang/core/storage/storage_state.dart';
import 'package:naengjang/ui/common/extension.dart';
import 'package:naengjang/ui/layout.dart';
import 'package:naengjang/ui/page_base.dart';
import 'package:naengjang/ui/widgets/ingredient_edit.dart';

class IngredientDetailPage extends BasePage {
  final String ingredientId;

  const IngredientDetailPage({super.key, required this.ingredientId, super.gnb = false});

  @override
  BasePageState<IngredientDetailPage> createState() => _IngredientDetailPageState();
}

class _IngredientDetailPageState extends BasePageState<IngredientDetailPage> {
  @override
  String get title => '재료 상세';

  Ingredient? get ingredient {
    final asyncIngredients = ref.watch(ingredientStateProvider);
    if (asyncIngredients case AsyncData(:final value)) {
      return value.where((e) => e.id == widget.ingredientId).firstOrNull;
    }
    return null;
  }

  Storage? get storage {
    if (ingredient == null) return null;
    final asyncStorages = ref.watch(storageStateProvider);
    if (asyncStorages case AsyncData(:final value)) {
      return value.where((e) => e.id == ingredient!.storageId).firstOrNull;
    }
    return null;
  }

  @override
  Widget buildPage(BuildContext context) {
    final item = ingredient;

    if (item == null) {
      return const Center(child: Text('재료를 찾을 수 없습니다.'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 기본 정보 카드
          Card(
            child: Padding(
              padding: Layout.padding.large,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Layout.gap.small,
                  Row(
                    children: [
                      Chip(label: Text(item.type.label)),
                      Layout.gap.small,
                      if (item.category != null && item.category!.isNotEmpty)
                        Chip(label: Text(item.category!)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Layout.gap.medium,

          // 보관 정보
          Card(
            child: Padding(
              padding: Layout.padding.large,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('보관 정보', style: Theme.of(context).textTheme.titleMedium),
                  Layout.gap.medium,
                  buildInfoRow(Icons.kitchen, '냉장고', storage?.name ?? '-'),
                  if (storage != null)
                    buildInfoRow(Icons.thermostat, '냉장고 종류', storage!.type.label),
                ],
              ),
            ),
          ),
          Layout.gap.medium,

          // 날짜 정보
          Card(
            child: Padding(
              padding: Layout.padding.large,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('날짜 정보', style: Theme.of(context).textTheme.titleMedium),
                  Layout.gap.medium,
                  buildDateRow('소비기한', item.expiryDate),
                  buildDateRow('유통기한', item.useByDate),
                  buildDateRow('제조일자', item.manufacturedDate),
                ],
              ),
            ),
          ),
          Layout.gap.large,

          // 수정 버튼
          FilledButton.icon(
            onPressed: () => IngredientEdit.show(context, item),
            icon: const Icon(Icons.edit),
            label: const Text('수정'),
          ),
          Layout.gap.small,

          // 삭제 버튼
          OutlinedButton.icon(
            onPressed: () => confirmDelete(item),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: Layout.padding.small.copyVertical(),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          Layout.gap.small,
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }

  Widget buildDateRow(String label, DateTime? date) {
    final text = date != null ? formatDate(date) : '미설정';
    final isExpiringSoon = date != null && checkExpiringSoon(date);

    return Padding(
      padding: Layout.padding.small.copyVertical(),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 20,
            color: isExpiringSoon ? Colors.orange : Colors.grey,
          ),
          Layout.gap.small,
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(
            text,
            style: TextStyle(
              color: isExpiringSoon ? Colors.orange : null,
              fontWeight: isExpiringSoon ? FontWeight.bold : null,
            ),
          ),
          if (isExpiringSoon) ...[
            Layout.gap.small,
            const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
          ],
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool checkExpiringSoon(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    return diff <= 3;
  }

  Future<void> confirmDelete(Ingredient ingredient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제'),
        content: Text('${ingredient.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(ingredientStateProvider.notifier).delete(ingredient.id);
      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        context.showSnackBar('삭제되었습니다.');
      } else {
        context.showSnackBar('삭제 실패');
      }
    }
  }
}
