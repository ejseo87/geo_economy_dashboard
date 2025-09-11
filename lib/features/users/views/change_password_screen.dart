import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';
import '../../../common/widgets/app_bar_widget.dart';
import '../../../common/widgets/form_button_widget.dart';
import '../../../common/utils.dart';
import '../../authentication/repos/authentication_repo.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  static const String routeName = 'changePassword';
  static const String routeURL = '/user/change-password';

  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되어 있지 않습니다.');
      }

      // 현재 비밀번호로 재인증
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // 새 비밀번호로 업데이트
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        // 성공 메시지 표시
        showInfoSnackBar(
          title: '비밀번호가 성공적으로 변경되었습니다.',
          context: context,
        );

        // 로그아웃 처리
        await ref.read(authRepo).signOut(context);
        
        // 로그인 화면으로 이동
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '비밀번호 변경에 실패했습니다.';
        
        if (e.toString().contains('wrong-password') || 
            e.toString().contains('invalid-credential')) {
          errorMessage = '현재 비밀번호가 올바르지 않습니다.';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = '새 비밀번호가 너무 약합니다.';
        }
        
        showFirebaseErrorSnack(
          context: context,
          error: errorMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBarWidget(
        title: '비밀번호 변경',
        showGlobe: false,
        showLogin: false,
        showGear: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Sizes.size16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 메시지
              Container(
                padding: const EdgeInsets.all(Sizes.size16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.circleInfo,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '보안을 위해 비밀번호 변경 후 자동으로 로그아웃됩니다.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: Sizes.size32),

              // 현재 비밀번호
              Text(
                '현재 비밀번호',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Sizes.size8),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  hintText: '현재 비밀번호를 입력하세요',
                  prefixIcon: const FaIcon(FontAwesomeIcons.lock, size: 16),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                    icon: FaIcon(
                      _obscureCurrentPassword 
                          ? FontAwesomeIcons.eyeSlash 
                          : FontAwesomeIcons.eye,
                      size: 16,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '현재 비밀번호를 입력하세요';
                  }
                  return null;
                },
                enabled: !_isChangingPassword,
              ),

              const SizedBox(height: Sizes.size24),

              // 새 비밀번호
              Text(
                '새 비밀번호',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Sizes.size8),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  hintText: '새 비밀번호를 입력하세요 (최소 6자)',
                  prefixIcon: const FaIcon(FontAwesomeIcons.key, size: 16),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                    icon: FaIcon(
                      _obscureNewPassword 
                          ? FontAwesomeIcons.eyeSlash 
                          : FontAwesomeIcons.eye,
                      size: 16,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '새 비밀번호를 입력하세요';
                  }
                  if (value.length < 6) {
                    return '비밀번호는 최소 6자 이상이어야 합니다';
                  }
                  if (value == _currentPasswordController.text) {
                    return '새 비밀번호는 현재 비밀번호와 달라야 합니다';
                  }
                  return null;
                },
                enabled: !_isChangingPassword,
              ),

              const SizedBox(height: Sizes.size16),

              // 비밀번호 확인
              Text(
                '새 비밀번호 확인',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Sizes.size8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: '새 비밀번호를 다시 입력하세요',
                  prefixIcon: const FaIcon(FontAwesomeIcons.key, size: 16),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: FaIcon(
                      _obscureConfirmPassword 
                          ? FontAwesomeIcons.eyeSlash 
                          : FontAwesomeIcons.eye,
                      size: 16,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호 확인을 입력하세요';
                  }
                  if (value != _newPasswordController.text) {
                    return '비밀번호가 일치하지 않습니다';
                  }
                  return null;
                },
                enabled: !_isChangingPassword,
              ),

              const SizedBox(height: Sizes.size48),

              // 변경 버튼
              SizedBox(
                width: double.infinity,
                child: FormButtonWidget(
                  text: _isChangingPassword ? '변경 중...' : '비밀번호 변경',
                  type: ButtonType.primary,
                  isValid: !_isChangingPassword,
                  onPressed: _changePassword,
                ),
              ),

              const SizedBox(height: Sizes.size16),

              // 취소 버튼
              SizedBox(
                width: double.infinity,
                child: FormButtonWidget(
                  text: '취소',
                  type: ButtonType.secondary,
                  isValid: !_isChangingPassword,
                  onPressed: () => context.pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}