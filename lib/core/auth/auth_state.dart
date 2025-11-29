import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/legacy.dart';
import 'package:naengjang/core/ingredient/ingredient_state.dart';
import 'package:naengjang/core/storage/storage_state.dart';
import 'package:naengjang/main.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_state.g.dart';

enum AuthenticationState {
  initial,
  loading,
  success,
  error;

  bool get isInitial => this == AuthenticationState.initial;
  bool get isLoading => this == AuthenticationState.loading;
  bool get isSuccess => this == AuthenticationState.success;
  bool get isError => this == AuthenticationState.error;
}

final numProvier = StateProvider((ref) => 0);

@Riverpod(keepAlive: true)
class AuthState extends _$AuthState {
  bool get isInitial => state == AuthenticationState.initial;
  bool get isLoading => state == AuthenticationState.loading;
  bool get isSuccess => state == AuthenticationState.success;
  bool get isError => state == AuthenticationState.error;

  @override
  AuthenticationState build() {
    // 기존 세션이 있으면 로그인 상태 유지
    if (supabase.auth.currentSession != null) {
      warmUpData();
      return AuthenticationState.success;
    }
    return AuthenticationState.initial;
  }

  /// 로그인 후 필요한 데이터를 미리 로드
  void warmUpData() {
    ref.read(storageStateProvider);
    ref.read(ingredientStateProvider);
  }

  Future<void> login({required String userId, required String password}) async {
    state = AuthenticationState.loading;

    try {
      await supabase.auth.signInWithPassword(
        email: userId.trim(),
        password: password,
      );
      warmUpData();
      state = AuthenticationState.success;
    } on AuthException catch (e) {
      log('AuthException: ${e.message}', name: 'AuthState');
      state = AuthenticationState.error;
    } catch (e) {
      log('Unexpected error: $e', name: 'AuthState');
      state = AuthenticationState.error;
    }
  }

  void logout() {
    state = AuthenticationState.initial;
  }

  Future<void> signUp({
    required String userId,
    required String name,
    required String password,
  }) async {
    await supabase.auth.signUp(
      email: userId,
      password: password,
      data: {'full_name': name},
    );
  }
}
