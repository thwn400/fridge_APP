import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naengjang/core/ingredient/ingredient_state.dart';
import 'package:naengjang/core/storage/storage_state.dart';
import 'package:naengjang/ui/layout.dart';
import 'package:naengjang/ui/page_base.dart';
import 'package:naengjang/ui/widgets/freezer_add.dart';
import 'package:naengjang/ui/widgets/ingredient_add.dart';

class HomePage extends BasePage {
  const HomePage({super.key});

  @override
  BasePageState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends BasePageState<HomePage> {
  @override
  String get title => '홈화면';

  /// 소비기한이 3일 이내인 재료들
  List<Ingredient> get expiringIngredients {
    final asyncIngredients = ref.watch(ingredientStateProvider);
    if (asyncIngredients case AsyncData(:final value)) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return value.where((ingredient) {
        final date = ingredient.expiryDate ?? ingredient.useByDate;
        if (date == null) return false;

        final target = DateTime(date.year, date.month, date.day);
        final diff = target.difference(today).inDays;
        return diff <= 3;
      }).toList()
        ..sort((a, b) {
          final dateA = a.expiryDate ?? a.useByDate ?? DateTime(2100);
          final dateB = b.expiryDate ?? b.useByDate ?? DateTime(2100);
          return dateA.compareTo(dateB);
        });
    }
    return [];
  }

  Storage? getStorage(String storageId) {
    final asyncStorages = ref.watch(storageStateProvider);
    if (asyncStorages case AsyncData(:final value)) {
      return value.where((e) => e.id == storageId).firstOrNull;
    }
    return null;
  }

  @override
  Widget buildPage(BuildContext context) {
    final expiring = expiringIngredients;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 빠른 추가 버튼들
          buildCard(Icons.add, '냉장고 추가', () {
            FreezerAdd.show(context);
          }),
          Layout.gap.medium,
          buildCard(Icons.add, '재료 추가', () {
            IngredientAdd.show(context);
          }),

          // 소비기한 임박 섹션
          if (expiring.isNotEmpty) ...[
            Layout.gap.xLarge,
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                Layout.gap.small,
                Text(
                  '곧 만료되는 재료 (${expiring.length}개)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            Layout.gap.small,
            ...expiring.map((ingredient) => buildExpiringCard(ingredient)),
          ],
        ],
      ),
    );
  }

  Widget buildCard(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: Layout.padding.large,
          child: Row(children: [Icon(icon), Layout.gap.small, Text(text)]),
        ),
      ),
    );
  }

  Widget buildExpiringCard(Ingredient ingredient) {
    final storage = getStorage(ingredient.storageId);
    final expiryText = getExpiryText(ingredient);

    return Card(
      color: Colors.orange.shade50,
      child: ListTile(
        onTap: () => context.push('/ingredient/${ingredient.id}'),
        leading: const Icon(Icons.warning_amber, color: Colors.orange),
        title: Text(ingredient.name),
        subtitle: Text(
          '${storage?.name ?? ''} · $expiryText',
          style: const TextStyle(color: Colors.orange),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String getExpiryText(Ingredient ingredient) {
    final date = ingredient.expiryDate ?? ingredient.useByDate;
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) {
      return '${-diff}일 지남';
    } else if (diff == 0) {
      return '오늘 만료';
    } else {
      return '$diff일 남음';
    }
  }
}
