import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';
import '../../../common/widgets/app_bar_widget.dart';
import '../../../common/widgets/form_button_widget.dart';
import '../view_models/user_profile_view_model.dart';
import '../models/user_profile.dart';
import '../../../common/services/user_permission_service.dart';
import 'change_password_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  static const String routeName = 'userProfile';
  static const String routeURL = '/user/profile';

  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUpdatingProfile = false;
  File? _selectedImage;
  String? _lastProfileName;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileViewModelProvider);
    final subscriptionStatusAsync = ref.watch(subscriptionStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBarWidget(
        title: '프로필',
        showGlobe: false,
        showLogin: false,
        showGear: false,
      ),
      body: userProfileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _buildErrorScreen(error.toString()),
        data: (profile) {
          if (profile == null) {
            return _buildNoProfileScreen();
          }
          
          // 닉네임 컨트롤러 초기화 (중복 방지)
          if (_lastProfileName != profile.displayName) {
            _nicknameController.text = profile.displayName;
            _lastProfileName = profile.displayName;
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Sizes.size16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(profile),
                  const SizedBox(height: Sizes.size24),
                  _buildSubscriptionInfo(subscriptionStatusAsync),
                  const SizedBox(height: Sizes.size24),
                  _buildBasicInfo(profile),
                  const SizedBox(height: Sizes.size24),
                  _buildPasswordSection(),
                  const SizedBox(height: Sizes.size32),
                  _buildActionButtons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(
            FontAwesomeIcons.triangleExclamation,
            size: 48,
            color: AppColors.warning,
          ),
          const SizedBox(height: 16),
          Text(
            '프로필을 불러올 수 없습니다',
            style: AppTypography.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.invalidate(userProfileViewModelProvider),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProfileScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(
            FontAwesomeIcons.user,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            '프로필이 없습니다',
            style: AppTypography.heading2,
          ),
          const SizedBox(height: 8),
          Text(
            '로그인이 필요합니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.size20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null) as ImageProvider?,
                  child: _selectedImage == null && profile.avatarUrl == null
                      ? const FaIcon(
                          FontAwesomeIcons.user,
                          color: Colors.white,
                          size: 32,
                        )
                      : null,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.camera,
                      size: 16,
                      color: Colors.white,
                    ),
                    onPressed: _pickImage,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              profile.displayName,
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profile.email,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getRoleColor(profile.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                profile.roleDisplayName,
                style: AppTypography.caption.copyWith(
                  color: _getRoleColor(profile.role),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionInfo(AsyncValue<SubscriptionStatus> subscriptionAsync) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.size16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.crown,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '구독 정보',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            subscriptionAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text(
                'Error: $error',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.warning,
                ),
              ),
              data: (status) => Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '구독 플랜',
                        style: AppTypography.bodyMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getSubscriptionColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getSubscriptionDisplayName(status),
                          style: AppTypography.caption.copyWith(
                            color: _getSubscriptionColor(status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (status.planType == PlanType.free) ...[
                    LinearProgressIndicator(
                      value: 0.7, // 예시 값
                      backgroundColor: AppColors.outline.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getSubscriptionColor(status),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '이번 달 사용량',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '70/100',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FormButtonWidget(
                        text: '프리미엄으로 업그레이드',
                        type: ButtonType.primary,
                        isValid: true,
                        onPressed: _upgradeToPremium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(UserProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.size16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.user,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '기본 정보',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                hintText: '닉네임을 입력하세요',
                prefixIcon: FaIcon(FontAwesomeIcons.signature, size: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '닉네임을 입력해주세요';
                }
                if (value.trim().length < 2) {
                  return '닉네임은 2자 이상이어야 합니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInfoRow('이메일', profile.email),
            const SizedBox(height: 8),
            _buildInfoRow('가입일', _formatDate(profile.createdAt)),
            const SizedBox(height: 8),
            if (profile.lastLogin != null)
              _buildInfoRow('마지막 로그인', _formatDate(profile.lastLogin!)),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(Sizes.size16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.lock,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '보안 설정',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.shield,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '계정 보안을 위해 정기적으로 비밀번호를 변경하세요.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FormButtonWidget(
                text: '비밀번호 변경',
                type: ButtonType.secondary,
                isValid: true,
                onPressed: () {
                  context.pushNamed(ChangePasswordScreen.routeName);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: _isUpdatingProfile
              ? const Center(child: CircularProgressIndicator())
              : FormButtonWidget(
                  text: '프로필 저장',
                  type: ButtonType.primary,
                  isValid: true,
                  onPressed: _updateProfile,
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.warning;
      case 'premium_user':
        return AppColors.accent;
      case 'free_user':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getSubscriptionColor(SubscriptionStatus status) {
    switch (status.planType) {
      case PlanType.pro:
        return AppColors.accent;
      case PlanType.basic:
        return AppColors.primary;
      case PlanType.free:
        return AppColors.primary;
    }
  }

  String _getSubscriptionDisplayName(SubscriptionStatus status) {
    switch (status.planType) {
      case PlanType.pro:
        return '프리미엄';
      case PlanType.basic:
        return '베이직';
      case PlanType.free:
        return '무료';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지를 선택할 수 없습니다: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdatingProfile = true;
    });

    try {
      await ref.read(userProfileViewModelProvider.notifier).updateProfile(
        displayName: _nicknameController.text.trim(),
        avatarFile: _selectedImage,
      );

      if (mounted) {
        setState(() {
          _selectedImage = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 성공적으로 업데이트되었습니다'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 업데이트 실패: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingProfile = false;
        });
      }
    }
  }


  void _upgradeToPremium() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('프리미엄 업그레이드 기능은 준비 중입니다'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}