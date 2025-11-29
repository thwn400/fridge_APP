import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:naengjang/core/auth/auth_error_code.dart';
import 'package:naengjang/core/auth/auth_state.dart';
import 'package:naengjang/ui/common/extension.dart';
import 'package:naengjang/ui/common/regex.dart';
import 'package:naengjang/ui/layout.dart';
import 'package:naengjang/ui/page_base.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends BasePage {
  const SignUpPage({super.key, super.needLogin = false, super.gnb = false});

  @override
  BasePageState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends BasePageState<SignUpPage> {
  final idTextController = TextEditingController();
  final nameTextController = TextEditingController();
  final pwTextController = TextEditingController();
  final pwConfirmTextController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String get id => idTextController.text.trim();
  String get name => nameTextController.text.trim();
  String get pw => pwTextController.text.trim();
  String get pwConfirm => pwConfirmTextController.text.trim();

  @override
  void dispose() {
    idTextController.dispose();
    nameTextController.dispose();
    pwTextController.dispose();
    pwConfirmTextController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final userId = idTextController.text.trim();
    final password = pwTextController.text;
    final authState = ref.read(authStateProvider.notifier);

    try {
      await authState.signUp(userId: userId, password: password, name: name);

      if (!mounted) {
        return;
      }

      // 회원가입 성공 시 홈으로 이동
      context.go('/');
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }

      context.showSnackBar(
        AuthErrorCode.fromCode(e.code).defaultMessage!,
        isError: true,
      );
    }
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
              final trimmed = value?.trim() ?? '';

              if (trimmed.isEmpty) {
                return '이메일을 입력해주세요.';
              }

              if (!Regex.email.hasMatch(trimmed)) {
                return '유효한 이메일 주소를 입력해주세요.';
              }

              return null;
            },
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
          ),
          Layout.gap.medium,
          TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '이름',
            ),
            controller: nameTextController,
            validator: (value) {
              final trimmed = value?.trim() ?? '';

              if (trimmed.isEmpty) {
                return '이름을 입력해주세요.';
              }

              return null;
            },
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
            validator: (value) {
              final trimmed = value?.trim() ?? '';

              if (trimmed.isEmpty) {
                return '비밀번호를 입력해주세요.';
              }

              if (!Regex.password.hasMatch(trimmed)) {
                return '비밀번호는 영문자 + 숫자 + 8자 이상이어야 합니다.';
              }

              return null;
            },
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.password],
          ),
          Layout.gap.large,
          TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '비밀번호 확인',
            ),
            controller: pwConfirmTextController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) {
              final trimmed = value?.trim() ?? '';

              if (pw != trimmed) {
                return '비밀번호가 일치하지 않습니다.';
              }

              return null;
            },
            onFieldSubmitted: (_) => signUp(),
            autofillHints: const [AutofillHints.password],
          ),
          Layout.gap.large,
          OutlinedButton(onPressed: signUp, child: const Text('회원 가입')),
        ],
      ),
    );
  }
}
