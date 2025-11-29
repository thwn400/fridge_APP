import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naengjang/core/ingredient/ingredient_state.dart';
import 'package:naengjang/core/storage/storage_state.dart';
import 'package:naengjang/ui/layout.dart';
import 'package:naengjang/ui/page_base.dart';
import 'package:naengjang/ui/widgets/ingredient_add.dart';

class StorageDetailPage extends BasePage {
  final String storageId;

  const StorageDetailPage({super.key, required this.storageId, super.gnb = false});

  @override
  BasePageState<StorageDetailPage> createState() => _StorageDetailPageState();
}

class _StorageDetailPageState extends BasePageState<StorageDetailPage> {
  @override
  String get title => storage?.name ?? '냉장고';

  Storage? get storage {
    final asyncStorages = ref.watch(storageStateProvider);
    if (asyncStorages case AsyncData(:final value)) {
      return value.where((e) => e.id == widget.storageId).firstOrNull;
    }
    return null;
  }

  @override
  Widget buildPage(BuildContext context) {
    return FutureBuilder<List<Ingredient>>(
      future: ref.read(ingredientStateProvider.notifier).fetchByStorage(widget.storageId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ingredients = snapshot.data ?? [];

        return Stack(
          children: [
            ingredients.isEmpty
                ? const Center(child: Text('재료가 없습니다.\n아래 버튼으로 재료를 추가해주세요.', textAlign: TextAlign.center))
                : ListView.builder(
                    padding: Layout.padding.xxLarge.copyBottom() + Layout.padding.xxLarge.copyBottom(),
                    itemCount: ingredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = ingredients[index];
                      return buildIngredientCard(ingredient);
                    },
                  ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FilledButton.icon(
                onPressed: () => IngredientAdd.showWithStorage(context, widget.storageId),
                icon: const Icon(Icons.add),
                label: const Text('재료 추가'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildIngredientCard(Ingredient ingredient) {
    final isExpiringSoon = checkExpiringSoon(ingredient);

    return Dismissible(
      key: Key(ingredient.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: Layout.padding.large,
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => confirmDelete(ingredient),
      child: Card(
        color: isExpiringSoon ? Colors.orange.shade50 : null,
        child: ListTile(
          onTap: () => context.push('/ingredient/${ingredient.id}'),
          leading: Icon(
            Icons.fastfood,
            color: isExpiringSoon ? Colors.orange : null,
          ),
          title: Text(ingredient.name),
          subtitle: buildSubtitle(ingredient),
          trailing: isExpiringSoon
              ? const Icon(Icons.warning_amber, color: Colors.orange)
              : const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  Widget? buildSubtitle(Ingredient ingredient) {
    final parts = <String>[];

    if (ingredient.category != null && ingredient.category!.isNotEmpty) {
      parts.add(ingredient.category!);
    }

    final expiryText = getExpiryText(ingredient);
    if (expiryText != null) {
      parts.add(expiryText);
    }

    if (parts.isEmpty) return null;
    return Text(parts.join(' · '));
  }

  String? getExpiryText(Ingredient ingredient) {
    final date = ingredient.expiryDate ?? ingredient.useByDate;
    if (date == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) {
      return '${-diff}일 지남';
    } else if (diff == 0) {
      return '오늘 만료';
    } else if (diff <= 3) {
      return '$diff일 남음';
    }

    return '${date.month}/${date.day}까지';
  }

  bool checkExpiringSoon(Ingredient ingredient) {
    final date = ingredient.expiryDate ?? ingredient.useByDate;
    if (date == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    return diff <= 3;
  }

  Future<bool> confirmDelete(Ingredient ingredient) async {
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
      await ref.read(ingredientStateProvider.notifier).delete(ingredient.id);
      setState(() {});
      return true;
    }
    return false;
  }
}
