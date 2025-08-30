import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = "splash";
  static const String routeURL = "/splash";

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();
    _fadeController.forward();

    // 3초 후 메인 화면으로 이동
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary, // #0055A4
              Color(0xFF003D7A), // 더 진한 파랑
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 로고 (세계지도 + 라인차트)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              // 세계지도 아이콘
                              Positioned(
                                top: 20,
                                child: FaIcon(
                                  FontAwesomeIcons.earthAmericas,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                              // 라인차트 아이콘
                              Positioned(
                                bottom: 20,
                                child: FaIcon(
                                  FontAwesomeIcons.chartLine,
                                  size: 32,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: Sizes.size32),

                        // 앱 이름
                        Text(
                          'Geo Economy Dashboard',
                          style: AppTypography.heading1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: Sizes.size12),

                        // 슬로건
                        Text(
                          '한국의 경제지표를\nOECD와 쉽게 비교하세요',
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 18,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: Sizes.size48),

                        // 로딩 인디케이터
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}