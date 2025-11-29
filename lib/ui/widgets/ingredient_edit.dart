import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naengjang/core/ingredient/ingredient_state.dart';
import 'package:naengjang/core/storage/storage_state.dart';
import 'package:naengjang/ui/common/bottomsheet.dart';
import 'package:naengjang/ui/common/extension.dart';
import 'package:naengjang/ui/layout.dart';

class IngredientEdit extends ConsumerStatefulWidget {
  final Ingredient ingredient;

  const IngredientEdit({super.key, required this.ingredient});

  static Future<void> show(BuildContext context, Ingredient ingredient) async {
    CustomBottomSheet.show(
      context: context,
      title: '재료 수정',
      child: IngredientEdit(ingredient: ingredient),
      fullScreen: true,
    );
  }

  @override
  ConsumerState<IngredientEdit> createState() => _IngredientEditState();
}

class _IngredientEditState extends ConsumerState<IngredientEdit> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController categoryController;

  late Storage? selectedStorage;
  late IngredientType selectedType;
  late DateTime? expiryDate;
  late DateTime? useByDate;
  late DateTime? manufacturedDate;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.ingredient.name);
    categoryController = TextEditingController(text: widget.ingredient.category ?? '');
    selectedType = widget.ingredient.type;
    expiryDate = widget.ingredient.expiryDate;
    useByDate = widget.ingredient.useByDate;
    manufacturedDate = widget.ingredient.manufacturedDate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storages = ref.read(storageStateProvider).requireValue;
      setState(() {
        selectedStorage = storages.where((e) => e.id == widget.ingredient.storageId).firstOrNull;
      });
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  List<IngredientType> get allowedTypes {
    if (selectedStorage == null) return IngredientType.values;
    return selectedStorage!.type.allowedIngredientTypes;
  }

  Future<void> selectDate(
    String label,
    DateTime? initial,
    ValueChanged<DateTime?> onSelected,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: label,
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedStorage == null) {
      context.showSnackBar('냉장고를 선택해주세요.');
      return;
    }

    if (!selectedStorage!.type.canStore(selectedType)) {
      context.showSnackBar('${selectedStorage!.type.label} 냉장고에는 ${selectedType.label} 재료를 넣을 수 없습니다.');
      return;
    }

    setState(() => isLoading = true);

    final success = await ref
        .read(ingredientStateProvider.notifier)
        .edit(
          id: widget.ingredient.id,
          storageId: selectedStorage!.id,
          name: nameController.text,
          type: selectedType,
          category: categoryController.text.isNotEmpty
              ? categoryController.text
              : null,
          expiryDate: expiryDate,
          useByDate: useByDate,
          manufacturedDate: manufacturedDate,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      context.showSnackBar('재료가 수정되었습니다.');
    } else {
      context.showSnackBar('수정 실패');
      setState(() => isLoading = false);
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '선택 안함';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final storages = ref.watch(storageStateProvider).requireValue;

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 냉장고 선택
            LayoutBuilder(
              builder: (context, constraints) => DropdownMenu<Storage>(
                width: constraints.maxWidth,
                label: const Text('냉장고'),
                initialSelection: selectedStorage,
                expandedInsets: EdgeInsets.zero,
                inputDecorationTheme: InputDecorationTheme(
                  border: const OutlineInputBorder(),
                  contentPadding: Layout.padding.medium.copyHorizontal() +
                      Layout.padding.large.copyVertical(),
                ),
                dropdownMenuEntries: storages
                    .map(
                      (e) => DropdownMenuEntry<Storage>(
                        value: e,
                        label: '${e.name} (${e.type.label})',
                      ),
                    )
                    .toList(),
                onSelected: (v) {
                  setState(() {
                    selectedStorage = v;
                    if (v != null && !v.type.canStore(selectedType)) {
                      selectedType = v.type.allowedIngredientTypes.first;
                    }
                  });
                },
              ),
            ),
            Layout.gap.medium,

            // 재료 타입 선택
            const Text('재료 타입', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Layout.gap.xSmall,
            SegmentedButton<IngredientType>(
              segments: IngredientType.values
                  .map((e) => ButtonSegment(
                        value: e,
                        label: Text(e.label),
                        enabled: allowedTypes.contains(e),
                      ))
                  .toList(),
              selected: {selectedType},
              onSelectionChanged: (v) => setState(() => selectedType = v.first),
            ),
            Layout.gap.medium,

            // 재료 이름
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '재료 이름',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '이름을 입력하세요.' : null,
            ),
            Layout.gap.medium,

            // 구분
            TextFormField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: '구분 (선택)',
                border: OutlineInputBorder(),
                hintText: '예: 채소, 육류, 유제품',
              ),
            ),
            Layout.gap.medium,

            // 날짜 선택들
            buildDateTile(
              '소비기한',
              expiryDate,
              (d) => setState(() => expiryDate = d),
            ),
            buildDateTile(
              '유통기한',
              useByDate,
              (d) => setState(() => useByDate = d),
            ),
            buildDateTile(
              '제조일자',
              manufacturedDate,
              (d) => setState(() => manufacturedDate = d),
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
                  : const Text('수정'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDateTile(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(formatDate(value)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => onChanged(null),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => selectDate(label, value, onChanged),
          ),
        ],
      ),
    );
  }
}
