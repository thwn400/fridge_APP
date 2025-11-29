import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naengjang/core/category/category_state.dart';
import 'package:naengjang/core/ingredient/ingredient_state.dart';
import 'package:naengjang/core/storage/storage_state.dart';
import 'package:naengjang/ui/common/bottomsheet.dart';
import 'package:naengjang/ui/common/extension.dart';
import 'package:naengjang/ui/layout.dart';
import 'package:naengjang/ui/widgets/barcode_scanner.dart';
import 'package:naengjang/ui/widgets/freezer_add.dart';

class IngredientAdd extends ConsumerStatefulWidget {
  final String? initialStorageId;

  const IngredientAdd({super.key, this.initialStorageId});

  static Future<void> show(BuildContext context) async {
    CustomBottomSheet.show(
      context: context,
      title: '재료 추가',
      child: const IngredientAdd(),
      fullScreen: true,
    );
  }

  static Future<void> showWithStorage(BuildContext context, String storageId) async {
    CustomBottomSheet.show(
      context: context,
      title: '재료 추가',
      child: IngredientAdd(initialStorageId: storageId),
      fullScreen: true,
    );
  }

  @override
  ConsumerState<IngredientAdd> createState() => _IngredientAddState();
}

class _IngredientAddState extends ConsumerState<IngredientAdd> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final storageMenuController = TextEditingController();

  Storage? selectedStorage;
  IngredientType selectedType = IngredientType.refrigerated;
  DateTime? expiryDate;
  DateTime? useByDate;
  DateTime? manufacturedDate;
  bool isLoading = false;
  String? scannedBarcode;

  @override
  void initState() {
    super.initState();
    if (widget.initialStorageId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final storages = ref.read(storageStateProvider).requireValue;
        final storage = storages.where((e) => e.id == widget.initialStorageId).firstOrNull;
        if (storage != null) {
          setState(() => selectedStorage = storage);
        }
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    storageMenuController.dispose();
    super.dispose();
  }

  /// 선택된 냉장고에 넣을 수 있는 재료 타입 목록
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

  Future<void> scanBarcode() async {
    final result = await BarcodeScanner.scan(context);
    if (result == null || !mounted) return;

    setState(() {
      scannedBarcode = result.barcode;
    });

    final productInfo = result.productInfo;
    if (productInfo != null && productInfo.hasData) {
      // 제품명 채우기
      if (productInfo.name != null && nameController.text.isEmpty) {
        nameController.text = productInfo.name!;
      }

      // 카테고리 채우기
      if (productInfo.category != null && categoryController.text.isEmpty) {
        categoryController.text = productInfo.category!;
      }

      context.showSnackBar('제품 정보를 불러왔습니다: ${productInfo.name ?? result.barcode}');
    } else {
      context.showSnackBar('바코드: ${result.barcode}\n제품 정보를 찾을 수 없습니다.');
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedStorage == null) {
      context.showSnackBar('냉장고를 선택해주세요.');
      return;
    }

    // 선택된 타입이 냉장고에 허용되는지 확인
    if (!selectedStorage!.type.canStore(selectedType)) {
      context.showSnackBar('${selectedStorage!.type.label} 냉장고에는 ${selectedType.label} 재료를 넣을 수 없습니다.');
      return;
    }

    setState(() => isLoading = true);

    final success = await ref
        .read(ingredientStateProvider.notifier)
        .add(
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
      context.showSnackBar('재료가 추가되었습니다.');
    } else {
      context.showSnackBar('추가 실패');
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
    final hasStorage = storages.isNotEmpty;

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 냉장고 선택
            if (hasStorage)
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
                      // 냉장고 변경 시 허용되지 않는 타입이면 기본값으로 변경
                      if (v != null && !v.type.canStore(selectedType)) {
                        selectedType = v.type.allowedIngredientTypes.first;
                      }
                    });
                  },
                ),
              )
            else
              Column(
                children: [
                  const Text('등록된 냉장고가 없습니다.\n먼저 냉장고를 추가해주세요.', textAlign: TextAlign.center),
                  Layout.gap.medium,
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      FreezerAdd.show(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('냉장고 추가'),
                  ),
                ],
              ),
            Layout.gap.medium,

            // 재료 타입 선택
            if (hasStorage) ...[
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
            ],

            // 바코드 스캔 버튼
            if (hasStorage)
              OutlinedButton.icon(
                onPressed: scanBarcode,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(scannedBarcode != null
                    ? '바코드: $scannedBarcode'
                    : '바코드로 제품 검색'),
              ),
            Layout.gap.medium,

            // 재료 이름
            TextFormField(
              controller: nameController,
              enabled: hasStorage,
              decoration: const InputDecoration(
                labelText: '재료 이름',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '이름을 입력하세요.' : null,
            ),
            Layout.gap.medium,

            // 구분 (자동완성)
            LayoutBuilder(
              builder: (context, constraints) {
                final asyncCategories = ref.watch(categoryStateProvider);
                final categories = asyncCategories is AsyncData<List<Category>>
                    ? asyncCategories.value
                    : <Category>[];
                final categoryNames = categories.map((e) => e.name).toList();

                return Autocomplete<String>(
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return categoryNames;
                    }
                    return categoryNames.where((name) =>
                        name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (selection) {
                    categoryController.text = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // 초기값 동기화
                    if (controller.text != categoryController.text) {
                      controller.text = categoryController.text;
                    }
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: hasStorage,
                      decoration: const InputDecoration(
                        labelText: '구분 (선택)',
                        border: OutlineInputBorder(),
                        hintText: '예: 채소, 육류, 유제품',
                      ),
                      onChanged: (v) => categoryController.text = v,
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth,
                            maxHeight: 200,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Layout.gap.medium,

            // 날짜 선택들
            buildDateTile(
              '소비기한',
              expiryDate,
              hasStorage ? (d) => setState(() => expiryDate = d) : null,
            ),
            buildDateTile(
              '유통기한',
              useByDate,
              hasStorage ? (d) => setState(() => useByDate = d) : null,
            ),
            buildDateTile(
              '제조일자',
              manufacturedDate,
              hasStorage ? (d) => setState(() => manufacturedDate = d) : null,
            ),

            Layout.gap.large,
            FilledButton(
              onPressed: hasStorage && !isLoading ? submit : null,
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
      ),
    );
  }

  Widget buildDateTile(
    String label,
    DateTime? value,
    ValueChanged<DateTime?>? onChanged,
  ) {
    final enabled = onChanged != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      title: Text(label),
      subtitle: Text(formatDate(value)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: enabled ? () => onChanged(null) : null,
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: enabled ? () => selectDate(label, value, onChanged) : null,
          ),
        ],
      ),
    );
  }
}
