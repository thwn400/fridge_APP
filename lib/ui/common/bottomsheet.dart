import 'package:flutter/material.dart';
import 'package:naengjang/ui/layout.dart';

class CustomBottomSheet {
  static Future<void> show({
    required BuildContext context,
    String? title,
    required Widget child,
    bool fullScreen = false,
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: fullScreen,
      useSafeArea: true,
      builder: (context) => fullScreen
          ? FractionallySizedBox(
              heightFactor: 0.9,
              child: _BottomSheetBase(title: title, child: child),
            )
          : _BottomSheetBase(title: title, child: child),
    );
  }
}

class _BottomSheetBase extends StatelessWidget {
  const _BottomSheetBase({this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Layout.padding.large,
      child: Column(children: [buildHeader(context), child]),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Row(
      children: [
        Layout.gap.large,
        Expanded(
          child: Text(
            title ?? '',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        CloseButton(),
      ],
    );
  }
}
