import 'package:geo_economy_dashboard/common/widgets/app_bar_widget.dart';
import 'package:geo_economy_dashboard/common/widgets/form_button_widget.dart';
import 'package:geo_economy_dashboard/constants/gaps.dart';
import 'package:geo_economy_dashboard/constants/sizes.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/features/authentication/view_models/login_view_model.dart';
import 'package:geo_economy_dashboard/features/settings/view_models/settings_view_model.dart';
import 'package:geo_economy_dashboard/common/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const String routeName = "login";
  static const String routeURL = "/login";

  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final Map<String, String> _formData = {};
  bool _obsecureText = true;
  bool _isValid = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? email) {
    if (email == null || email == "") {
      return "Enter your email";
    }

    return null;
  }

  String? _passwordValidator(String? password) {
    if (password == null || password == "") {
      return "Enter your password";
    }
    return null;
  }

  void _onSubmitted(BuildContext context) {
    if (_formKey.currentState != null) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        final email = _formData["email"];
        final password = _formData["password"];
        if (email != null && password != null) {
          ref
              .read(loginProvider.notifier)
              .login(email: email, password: password, context: context);
        }

        showInfoSnackBar(title: "Login...", context: context);
      }
    }
  }

  void _onSignUpTap(BuildContext context) {
    context.pop();
  }

  void _onSocialLogin(String provider) {
    // TODO: SNS 로그인 구현
    showInfoSnackBar(title: "$provider 로그인 준비중...", context: context);
  }

  Widget _buildSocialLoginButtons() {
    return FractionallySizedBox(
      widthFactor: 0.8,
      child: Column(
        children: [
          // Google 로그인
          _buildSocialLoginButton(
            icon: FontAwesomeIcons.google,
            label: 'Google로 로그인',
            backgroundColor: Colors.white,
            textColor: AppColors.textPrimary,
            borderColor: AppColors.textSecondary,
            onTap: () => _onSocialLogin('Google'),
          ),
          Gaps.v12,
          // Apple 로그인
          _buildSocialLoginButton(
            icon: FontAwesomeIcons.apple,
            label: 'Apple로 로그인',
            backgroundColor: Colors.black,
            textColor: Colors.white,
            onTap: () => _onSocialLogin('Apple'),
          ),
          Gaps.v12,
          // 카카오 로그인
          _buildSocialLoginButton(
            icon: FontAwesomeIcons.commentDots,
            label: '카카오로 로그인',
            backgroundColor: const Color(0xFFFEE500),
            textColor: Colors.black87,
            onTap: () => _onSocialLogin('Kakao'),
          ),
          Gaps.v12,
          // GitHub 로그인
          _buildSocialLoginButton(
            icon: FontAwesomeIcons.github,
            label: 'GitHub로 로그인',
            backgroundColor: const Color(0xFF24292e),
            textColor: Colors.white,
            onTap: () => _onSocialLogin('GitHub'),
          ),
          Gaps.v24,
          // 게스트 모드 링크
          GestureDetector(
            onTap: () {
              context.go('/');
            },
            child: Text(
              '게스트로 둘러보기',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              size: 18,
              color: textColor,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(settingsProvider).darkmode;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.background,
        appBar: AppBarWidget(showGear: false),
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: Sizes.size20),
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Gaps.v96,
              Text(
                "Welcome!",
                textAlign: TextAlign.center,
                style: AppTypography.heading1.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Gaps.v32,
              Form(
                key: _formKey,
                onChanged: () {
                  setState(() {
                    _isValid = _formKey.currentState!.validate();
                  });
                },
                child: Column(
                  children: [
                    FractionallySizedBox(
                      widthFactor: 0.8,
                      child: TextFormField(
                        autocorrect: false,
                        autovalidateMode: AutovalidateMode.always,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) => _emailValidator(value),
                        onSaved: (newValue) {
                          if (newValue != null) {
                            _formData['email'] = newValue;
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "Email",
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.size8),
                            borderSide: BorderSide(
                              color: AppColors.textSecondary,
                              width: Sizes.size1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.size8),
                            borderSide: BorderSide(
                              color: AppColors.textSecondary,
                              width: Sizes.size1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.size8),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: Sizes.size2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.size8),
                            borderSide: BorderSide(
                              color: AppColors.warning,
                              width: Sizes.size2,
                            ),
                          ),
                          contentPadding: EdgeInsets.all(Sizes.size12),
                        ),
                      ),
                    ),
                    Gaps.v10,
                    FractionallySizedBox(
                      widthFactor: 0.8,
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obsecureText,
                        autocorrect: false,
                        autovalidateMode: AutovalidateMode.always,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        validator: (value) => _passwordValidator(value),
                        onSaved: (newValue) {
                          if (newValue != null) {
                            _formData['password'] = newValue;
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.size8),
                            borderSide: BorderSide(
                              color: AppColors.textSecondary,
                              width: Sizes.size1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.size8),
                            borderSide: BorderSide(
                              color: AppColors.textSecondary,
                              width: Sizes.size1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.size8),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: Sizes.size2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.size8),
                            borderSide: BorderSide(
                              color: AppColors.warning,
                              width: Sizes.size2,
                            ),
                          ),
                          contentPadding: EdgeInsets.all(Sizes.size12),
                          suffix: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _passwordController.clear(),
                                child: FaIcon(
                                  FontAwesomeIcons.solidCircleXmark,
                                  color: AppColors.textSecondary,
                                  size: Sizes.size20,
                                ),
                              ),
                              Gaps.h16,
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _obsecureText = !_obsecureText;
                                  });
                                },
                                child: FaIcon(
                                  _obsecureText
                                      ? FontAwesomeIcons.eye
                                      : FontAwesomeIcons.eyeSlash,
                                  color: AppColors.textSecondary,
                                  size: Sizes.size20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Gaps.v20,
                    GestureDetector(
                      onTap: _isValid && !ref.watch(loginProvider).isLoading
                          ? () => _onSubmitted(context)
                          : null,
                      child: FormButtonWidget(
                        isValid:
                            _isValid && !ref.watch(loginProvider).isLoading,
                        text: "Enter",
                        onPressed: () => _onSubmitted(context),
                      ),
                    ),
                    Gaps.v32,
                    // SNS 로그인 구분선
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: AppColors.textSecondary,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '또는 SNS로 로그인',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: AppColors.textSecondary,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    Gaps.v24,
                    // SNS 로그인 버튼들
                    _buildSocialLoginButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          height: MediaQuery.of(context).size.height * 0.1,
          child: Container(
            width: MediaQuery.of(context).size.width,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              vertical: Sizes.size10,
              horizontal: Sizes.size20,
            ),
            child: GestureDetector(
              onTap: () => _onSignUpTap(context),
              child: FormButtonWidget(
                isValid: true,
                text: "Create an account →",
                type: ButtonType.secondary,
                onPressed: () => _onSignUpTap(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
