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
