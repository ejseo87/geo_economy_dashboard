import 'dart:async';

import 'package:geo_economy_dashboard/features/authentication/repos/authentication_repo.dart';
import 'package:geo_economy_dashboard/common/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginViewModel extends AsyncNotifier<void> {
  late final AuthenticationRepository _authenticationRepository;

  @override
  FutureOr<void> build() {
    _authenticationRepository = ref.read(authRepo);
  }

  Future<void> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    state = AsyncValue.loading();
    state = await AsyncValue.guard(
      () async =>
          _authenticationRepository.signIn(email: email, password: password),
    );
    if (state.hasError) {
      final error = state.error ?? '알 수 없는 오류가 발생했습니다.';
      
      // Check if this is a keychain error
      if (_isKeychainError(error)) {
        // Wait a moment for Firebase auth state to update
        await Future.delayed(Duration(milliseconds: 500));
        
        // Check if user is actually logged in despite the error
        if (_authenticationRepository.isLoggedIn && context.mounted) {
          // Authentication succeeded despite keychain issues
          context.go("/");
          return;
        }
      }
      
      // Show error for genuine authentication failures
      if (context.mounted) {
        showFirebaseErrorSnack(
          context: context,
          error: error,
        );
      }
    } else {
      if (context.mounted) {
        context.go("/");
      }
    }
  }

  bool _isKeychainError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('keychain') ||
        errorString.contains('nslocalizedfailurereasonerrorkey') ||
        errorString.contains('로컬 저장소 접근에 문제가');
  }
}

final loginProvider = AsyncNotifierProvider<LoginViewModel, void>(
  () => LoginViewModel(),
);
