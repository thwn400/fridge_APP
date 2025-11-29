import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naengjang/core/auth/auth_state.dart';
import 'package:naengjang/ui/common/extension.dart';
import 'package:naengjang/ui/layout.dart';
import 'package:naengjang/ui/page_base.dart';

class LoginPage extends BasePage {
  const LoginPage({super.key, super.needLogin = false, super.gnb = false});

  @override
  BasePageState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends BasePageState<LoginPage> {
  final idTextController = TextEditingController();
  final pwTextController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool canLogin = false;

  String get id => idTextController.text.trim();
  String get pw => pwTextController.text.trim();

  @override
  void dispose() {
    idTextController.dispose();
    pwTextController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    formKey.currentState!.validate();

    if (!canLogin) {
      return;
    }

    final authState = ref.read(authStateProvider.notifier);
    await authState.login(userId: id, password: pw);

    if (!mounted) return;

    if (authState.isSuccess) {
      context.go('/');
    }
    if (authState.isError) {
      context.showSnackBar('아이디 혹은 비밀번호가 일치하지 않습니다.');
    }
  }

  void updateCanSubmit(String? text) {
    final newCanSubmit = id.isNotEmpty && pw.isNotEmpty;
    if (canLogin == newCanSubmit) {
      return;
    }
    canLogin = newCanSubmit;
    setState(() {});
  }

  @override
  String get title => '로그인';

  @override
  Widget buildPage(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '아이디',
            ),
            controller: idTextController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '아이디를 입력하세요.';
              }
              return null;
            },
            onChanged: updateCanSubmit,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
          ),
          Layout.gap.medium,
          TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '비밀번호',
            ),
            controller: pwTextController,
            obscureText: true,
            onChanged: updateCanSubmit,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 입력하세요.';
              }
              return null;
            },
            onFieldSubmitted: (_) => submit(),
            autofillHints: const [AutofillHints.password],
          ),
          Layout.gap.large,
          FilledButton(onPressed: submit, child: const Text('로그인')),
          Layout.gap.small,
          OutlinedButton(
            onPressed: () {
              context.push('/signup');
            },

            child: const Text('회원 가입'),
          ),
        ],
      ),
    );
  }
}
