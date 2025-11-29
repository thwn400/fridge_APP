import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naengjang/core/auth/auth_state.dart';
import 'package:naengjang/main.dart';
import 'package:naengjang/ui/layout.dart';

enum _GNB {
  home('홈', Icons.home, Pages.home),
  freezer('냉장고', Icons.kitchen, Pages.freezer),
  settings('설정', Icons.settings, Pages.settings);

  const _GNB(this.label, this.icon, this.page);

  final String label;
  final IconData icon;
  final Pages page;

  static int getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (final e in _GNB.values) {
      if (e.page.path == location) {
        return e.index;
      }
    }

    return 0;
  }

  BottomNavigationBarItem buildNaviBarItem() =>
      BottomNavigationBarItem(icon: Icon(icon), label: label);
}

abstract class BasePage extends ConsumerStatefulWidget {
  final bool needLogin;
  final bool gnb;

  const BasePage({super.key, this.needLogin = true, this.gnb = true});
}

abstract class BasePageState<T extends BasePage> extends ConsumerState<T> {
  // 타이틀
  String get title;

  @override
  void initState() {
    super.initState();
    final state = ref.read(authStateProvider);
    needLogin(state);
  }

  void needLogin(AuthenticationState state) {
    if (state.isInitial && widget.needLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      needLogin(next);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      body: SafeArea(
        child: Padding(
          padding: Layout.padding.xLarge,
          child: Center(child: buildPage(context)),
        ),
      ),
      bottomNavigationBar: widget.gnb
          ? BottomNavigationBar(
              currentIndex: _GNB.getCurrentIndex(context),
              onTap: (value) => context.go(_GNB.values[value].page.path),
              items: _GNB.values.map((e) => e.buildNaviBarItem()).toList(),
            )
          : null,
    );
  }

  // 상속하는 클래스가 구현
  Widget buildPage(BuildContext context);
}
