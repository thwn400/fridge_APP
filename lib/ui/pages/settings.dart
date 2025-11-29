import 'package:flutter/material.dart';
import 'package:naengjang/core/auth/auth_state.dart';
import 'package:naengjang/ui/layout.dart';
import 'package:naengjang/ui/page_base.dart';

class SettingsPage extends BasePage {
  const SettingsPage({super.key});

  @override
  BasePageState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends BasePageState<SettingsPage> {
  @override
  String get title => '설정';

  @override
  Widget buildPage(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('설정'),
        Layout.gap.large,
        FilledButton.icon(
          onPressed: () {
            ref.read(authStateProvider.notifier).logout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('로그아웃'),
        ),
      ],
    );
  }
}
