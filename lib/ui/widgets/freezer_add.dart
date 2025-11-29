import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naengjang/core/storage/storage_state.dart';
import 'package:naengjang/ui/common/bottomsheet.dart';
import 'package:naengjang/ui/common/extension.dart';
import 'package:naengjang/ui/layout.dart';

class FreezerAdd extends ConsumerStatefulWidget {
  const FreezerAdd({super.key});

  static Future<void> show(BuildContext context) async {
    CustomBottomSheet.show(
      context: context,
      title: '냉장고 추가',
      child: const FreezerAdd(),
    );
  }

  @override
  ConsumerState<FreezerAdd> createState() => _FreezerAddState();
}

class _FreezerAddState extends ConsumerState<FreezerAdd> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  StorageType selectedType = StorageType.refrigerated;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final success = await ref
        .read(storageStateProvider.notifier)
        .add(nameController.text, selectedType);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      context.showSnackBar('냉장고가 추가되었습니다.');
    } else {
      context.showSnackBar('추가 실패');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: '냉장고 이름',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '이름을 입력하세요.';
              }
              return null;
            },
          ),
          Layout.gap.medium,
          SegmentedButton<StorageType>(
            segments: StorageType.values
                .map((e) => ButtonSegment(value: e, label: Text(e.label)))
                .toList(),
            selected: {selectedType},
            onSelectionChanged: (v) => setState(() => selectedType = v.first),
          ),
          Layout.gap.large,
          FilledButton(
            onPressed: isLoading ? null : submit,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('추가'),
          ),
        ],
      ),
    );
  }
}
