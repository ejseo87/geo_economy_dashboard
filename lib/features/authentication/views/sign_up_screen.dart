import 'package:geo_economy_dashboard/common/widgets/app_bar_widget.dart';
import 'package:geo_economy_dashboard/common/widgets/form_button_widget.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/gaps.dart';
import 'package:geo_economy_dashboard/constants/sizes.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/features/authentication/view_models/sign_up_view_model.dart';
import 'package:geo_economy_dashboard/features/authentication/views/login_screen.dart';
import 'package:geo_economy_dashboard/features/settings/view_models/settings_view_model.dart';
import 'package:geo_economy_dashboard/common/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  static const String routeName = "signup";
  static const String routeURL = "/signup";

  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
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
    //final regExp = RegExp()
    //r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    final regExp = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (!regExp.hasMatch(email)) {
      return "Not valid email";
    }

    return null;
  }

  String? _passwordValidator(String? password) {
    if (password == null || password == "") {
      return "Enter your password";
    } else {
      if (password.length < 8) {
        return "At least 8 characters";
      }

      return null;
    }
  }

  void _onSubmitted(BuildContext context) {
    if (_formKey.currentState != null) {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        ref.read(signUpProvider.notifier).signUp(context);

        showInfoSnackBar(title: "Creating your accout", context: context);
      }
    }
  }

  void _onLoginTap(BuildContext context) {
    context.pushNamed(LoginScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(settingsProvider).darkmode;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBarWidget(showGear: false),
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: Sizes.size20),
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Gaps.v96,
              Text(
                "Join!",
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
                            ref.read(signUpForm.notifier).state = {
                              "email": newValue,
                            };
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "Email",
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade800
                              : AppColors.white,
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
                            final state = ref.read(signUpForm.notifier).state;
                            ref.read(signUpForm.notifier).state = {
                              ...state,
                              "password": newValue,
                            };
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
                              width: Sizes.size1,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Sizes.size8),
                            borderSide: BorderSide(
                              color: AppColors.warning,
                              width: Sizes.size1,
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
                      onTap: _isValid && !ref.watch(signUpProvider).isLoading
                          ? () => _onSubmitted(context)
                          : null,
                      child: FormButtonWidget(
                        isValid:
                            _isValid && !ref.watch(signUpProvider).isLoading,
                        text: "Create Account",
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
              onTap: () => _onLoginTap(context),
              child: FormButtonWidget(
                isValid: true,
                text: "Log in →",
                type: ButtonType.secondary,
                onPressed: () => _onLoginTap(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
