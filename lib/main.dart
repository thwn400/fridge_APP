import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naengjang/core/notification/notification_service.dart';
import 'package:naengjang/ui/pages/freezer.dart';
import 'package:naengjang/ui/pages/home.dart';
import 'package:naengjang/ui/pages/ingredient_detail.dart';
import 'package:naengjang/ui/pages/login.dart';
import 'package:naengjang/ui/pages/settings.dart';
import 'package:naengjang/ui/pages/sign_up.dart';
import 'package:naengjang/ui/pages/storage_detail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );

  // 알림 서비스 초기화
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();

  runApp(const NaengjangApp());
}

class NaengjangApp extends StatelessWidget {
  const NaengjangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(child: MaterialApp.router(routerConfig: _router));
  }
}

// 유지보수의 편의를 위해 goRouter의 childRoute를 사용하지 않고 fullPath로 사용한다.
enum Pages {
  home('/', HomePage(), true),
  freezer('/freezer', FreezerPage(), true),
  login('/login', LoginPage(), false),
  signUp('/signup', SignUpPage(), false),
  settings('/settings', SettingsPage(), true);

  const Pages(this.path, this.page, this.isGnb);

  final Widget page;
  final String path;
  final bool isGnb;
}

final _router = GoRouter(
  routes: [
    ...Pages.values.map((e) => _createPageRoute(e)),
    // 동적 라우트
    GoRoute(
      path: '/storage/:id',
      builder: (context, state) => StorageDetailPage(
        storageId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/ingredient/:id',
      builder: (context, state) => IngredientDetailPage(
        ingredientId: state.pathParameters['id']!,
      ),
    ),
  ],
);

GoRoute _createPageRoute(Pages page) {
  if (page.isGnb) {
    return GoRoute(
      path: page.path,
      pageBuilder: (context, state) => NoTransitionPage(child: page.page),
    );
  }
  return GoRoute(path: page.path, builder: (context, state) => page.page);
}
