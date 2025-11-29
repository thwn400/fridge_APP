import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naengjang/core/storage/storage_state.dart';
import 'package:naengjang/ui/layout.dart';
import 'package:naengjang/ui/page_base.dart';
import 'package:naengjang/ui/widgets/freezer_add.dart';

class FreezerPage extends BasePage {
  const FreezerPage({super.key});

  @override
  BasePageState<FreezerPage> createState() => _FreezerPageState();
}

class _FreezerPageState extends BasePageState<FreezerPage> {
  @override
  String get title => '냉장고 목록';

  @override
  Widget buildPage(BuildContext context) {
    final storages = ref.watch(storageStateProvider).requireValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: storages.isEmpty
              ? const Center(child: Text('냉장고를 추가해주세요.'))
              : ListView.builder(
                  itemCount: storages.length,
                  itemBuilder: (context, index) {
                    final storage = storages[index];
                    return buildStorageCard(storage);
                  },
                ),
        ),
        Layout.gap.medium,
        FilledButton.icon(
          onPressed: () => FreezerAdd.show(context),
          icon: const Icon(Icons.add),
          label: const Text('냉장고 추가'),
        ),
      ],
    );
  }

  Widget buildStorageCard(Storage storage) {
    return Card(
      child: ListTile(
        onTap: () => context.push('/storage/${storage.id}'),
        leading: Icon(getStorageIcon(storage.type)),
        title: Text(storage.name),
        subtitle: Text(storage.type.label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => confirmDelete(storage),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  IconData getStorageIcon(StorageType type) {
    switch (type) {
      case StorageType.frozen:
        return Icons.ac_unit;
      case StorageType.refrigerated:
        return Icons.kitchen;
      case StorageType.roomTemp:
        return Icons.shelves;
    }
  }

  Future<void> confirmDelete(Storage storage) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제'),
        content: Text('${storage.name}을(를) 삭제하시겠습니까?'),
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
      ref.read(storageStateProvider.notifier).delete(storage.id);
    }
  }
}
