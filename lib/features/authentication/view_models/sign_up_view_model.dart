import 'dart:async';
import 'package:geo_economy_dashboard/features/users/view_models/users_view_model.dart';
import 'package:geo_economy_dashboard/common/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geo_economy_dashboard/features/authentication/repos/authentication_repo.dart';
import 'package:go_router/go_router.dart';

class SignUpViewModel extends AsyncNotifier<void> {
  late final AuthenticationRepository _authenticationRepository;

  @override
  FutureOr<void> build() {
    _authenticationRepository = ref.read(authRepo);
  }

  Future<void> signUp(BuildContext context) async {
    state = AsyncValue.loading();
    final users = ref.read(userProvider.notifier);
    final form = ref.read(signUpForm);
    state = await AsyncValue.guard(() async {
      final UserCredential userCredential = await _authenticationRepository
          .signUp(email: form["email"], password: form["password"]);
      final User? createdUser =
          userCredential.user ?? _authenticationRepository.user;
      if (createdUser == null) throw Exception("Account not created");
      if (context.mounted) {
        await users.createProfile(user: createdUser, context: context);
      }
    });
    if (state.hasError && context.mounted) {
      final error = state.error ?? '알 수 없는 오류가 발생했습니다.';

      // Check if this is a keychain error
      if (_isKeychainError(error)) {
        // Wait a moment for Firebase auth state to update
        await Future.delayed(Duration(milliseconds: 500));

        // Check if user is actually logged in despite the error
        if (_authenticationRepository.isLoggedIn && context.mounted) {
          // Authentication succeeded despite keychain issues
          context.go("/home");
          return;
        }
      }

      // Show error for genuine authentication failures
      if (context.mounted) {
        showFirebaseErrorSnack(context: context, error: error);
      }
    } else if (context.mounted) {
      context.go("/home");
    }
  }

  bool _isKeychainError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('keychain') ||
        errorString.contains('nslocalizedfailurereasonerrorkey') ||
        errorString.contains('로컬 저장소 접근에 문제가');
  }
}

final signUpForm = StateProvider((ref) => {});
final signUpProvider = AsyncNotifierProvider<SignUpViewModel, void>(
  () => SignUpViewModel(),
);
